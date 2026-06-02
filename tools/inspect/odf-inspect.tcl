## odf-inspect.tcl  --  dump the structure of an .odt
##
## Format-level diagnostic for ODF text documents. Pure consumer of the
## public odf API (odf::Package + odf::Text) -- adds no library code and does
## not depend on docir. Replaces odtread::inspect.
##
## Usage:  tclsh odf-inspect.tcl file.odt
##
## Sets stdout to utf-8 so German content (umlauts) prints correctly; only
## this runner touches the global channel, the modules stay untouched.

fconfigure stdout -encoding utf-8

## tm path: runner sits at <repo>/tools/inspect/ ; <repo> holds odf-0.9.tm and
## the odf/ subdir with text-/style-*.tm. Three dirnames up reach <repo>.
set repo [file dirname [file dirname [file dirname [file normalize [info script]]]]]
::tcl::tm::path add $repo

package require odf::text   ;# pulls odf
package require odf::style

if {[llength $argv] != 1} {
    puts stderr "usage: tclsh [file tail [info script]] file.odt"
    exit 2
}
set path [lindex $argv 0]
if {![file exists $path]} {
    puts stderr "no such file: $path"
    exit 2
}

## ---- helpers ----------------------------------------------------------

## One inline run rendered compactly: plain text verbatim, spans/links/tabs/
## breaks shown with a small marker so the run structure stays visible.
proc fmtRun {txtObj run} {
    switch -- [$txtObj runKind $run] {
        text      { return [$txtObj runText $run] }
        span      {
            set s [$txtObj runStyle $run]
            return "\[$s\][$txtObj runText $run]"
        }
        link      {
            set h [$txtObj linkHref $run]
            return "\u2192($h)\[[$txtObj runText $run]\]"
        }
        tab       { return "\u21e5" }
        linebreak { return "\u21b5" }
        default   { return "<[$run nodeName]>" }
    }
}

## A paragraph/heading as a single inline string built from its runs.
proc inlineOf {txtObj node} {
    set out ""
    foreach r [$txtObj runs $node] { append out [fmtRun $txtObj $r] }
    return $out
}

proc indent {n} { return [string repeat "  " $n] }

## ---- structure walk ---------------------------------------------------

proc walkList {txtObj listNode depth} {
    foreach item [$txtObj listItems $listNode] {
        puts "[indent $depth]- [$txtObj itemText $item]"
        set sub [$txtObj itemSublist $item]
        if {$sub ne ""} { walkList $txtObj $sub [expr {$depth + 1}] }
    }
}

proc walkTable {txtObj tableNode depth} {
    set cols [llength [$txtObj tableColumns $tableNode]]
    puts "[indent $depth]table  (cols=$cols)"
    foreach row [$txtObj tableRows $tableNode] {
        set hdr [expr {[$txtObj isHeaderRow $row] ? "H" : " "}]
        set cells {}
        foreach c [$txtObj rowCells $row] { lappend cells [$txtObj cellText $c] }
        puts "[indent [expr {$depth + 1}]]$hdr| [join $cells " | "]"
    }
}

proc walkImage {txtObj node depth} {
    foreach fr [$node getElementsByTagName draw:frame] {
        set nm [$fr getAttribute draw:name ""]
        set label [expr {$nm ne "" ? $nm : "(unnamed)"}]
        set info [$txtObj imageInfo $nm]
        if {$info eq ""} {
            puts "[indent $depth]image  $label"
            continue
        }
        puts "[indent $depth]image  $label  href=[dict get $info href]  w=[dict get $info width] h=[dict get $info height]  anchor=[dict get $info anchor] style=[dict get $info style]"
        if {[dict get $info title] ne "" || [dict get $info desc] ne ""} {
            puts "[indent [expr {$depth + 1}]]title=[dict get $info title]  desc=[dict get $info desc]"
        }
    }
}

proc walkBlock {txtObj node depth} {
    switch -- [$txtObj kind $node] {
        heading   {
            set lvl [$txtObj level $node]
            puts "[indent $depth]h$lvl  ([$txtObj style $node])  [inlineOf $txtObj $node]"
        }
        paragraph {
            puts "[indent $depth]p   ([$txtObj style $node])  [inlineOf $txtObj $node]"
        }
        list      { walkList  $txtObj $node $depth }
        table     { walkTable $txtObj $node $depth }
        image     { walkImage $txtObj $node $depth }
        default   { puts "[indent $depth]? <[$node nodeName]>" }
    }
}

## ---- registry dump ----------------------------------------------------

proc dumpRegistry {reg} {
    if {[dict size $reg] == 0} { puts "  (none)"; return }
    foreach name [lsort [dict keys $reg]] {
        set e [dict get $reg $name]
        set parent [dict get $e parent]
        set tail [expr {$parent ne "" ? " <- $parent" : ""}]
        puts "  $name  (family=[dict get $e family])$tail"
        dict for {grp attrs} [dict get $e props] {
            set kv {}
            dict for {k v} $attrs { lappend kv "$k=$v" }
            if {[llength $kv]} { puts "      $grp: [join $kv {  }]" }
        }
    }
}

## ---- main -------------------------------------------------------------

set pkg [odf::Package new $path]
if {[$pkg mimetype] ne "application/vnd.oasis.opendocument.text"} {
    puts stderr "warning: unexpected mimetype: [$pkg mimetype]"
}

set txt [odf::Text new $pkg]
set reg [$txt styleRegistry]

puts "ODT: $path"
puts "parts:    [$pkg parts]"
puts "manifest: [dict size [$pkg manifest]] entries   styles: [dict size $reg]   fonts: [llength [$txt fonts]]"
puts ""
puts "---- styles ----"
dumpRegistry $reg
puts ""
puts "---- structure ----"
foreach b [$txt blocks] { walkBlock $txt $b 0 }

$txt destroy
$pkg destroy
