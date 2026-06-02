## examples/read-sheet.tcl  --  Demo: read an ODS and dump its structure
##
## Shows odf::sheet on the reading side: sheets, dimensions (repeat-expanded,
## trailing fill trimmed), and per-cell type / value / formula. Works on files
## written by odf::sheet AND on real LibreOffice Calc files.
##
## Usage:  tclsh read-sheet.tcl file.ods ?maxrows?
##         (maxrows default 8 per sheet; 0 = all)

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

if {[llength $argv] < 1} {
    puts stderr "usage: tclsh [file tail [info script]] file.ods ?maxrows?"
    exit 2
}
set path [lindex $argv 0]
set maxrows [expr {[llength $argv] >= 2 ? [lindex $argv 1] : 8}]
if {![file exists $path]} { puts stderr "no such file: $path"; exit 2 }

set pkg [odf::Package new $path]
if {[$pkg mimetype] ne "application/vnd.oasis.opendocument.spreadsheet"} {
    puts stderr "warning: not a spreadsheet mimetype: [$pkg mimetype]"
}
set sh [odf::Sheet new $pkg]

puts "ODS: $path"
puts "parts: [$pkg parts]"
foreach t [$sh tables] {
    set rows [$sh rows $t]
    puts ""
    puts "== \"[$sh tableName $t]\"  rows=[llength $rows]  width=[$sh width $t]  cols=[llength [$sh columns $t]] =="
    set i 0
    foreach r $rows {
        if {$maxrows > 0 && $i >= $maxrows} { puts "   ... ([expr {[llength $rows] - $maxrows}] more rows)"; break }
        set out {}
        foreach c [$sh cells $r] {
            set ty [$sh cellType $c]
            set tag [expr {$ty eq "" ? "-" : $ty}]
            if {[$sh cellCovered $c]} {
                lappend out "<<"
            } else {
                set f [$sh cellFormula $c]
                set cell "$tag:[$sh cellValue $c]"
                set span [$sh cellSpan $c]
                if {$span ne {1 1}} { append cell " span=$span" }
                if {$f ne ""} { append cell " {$f}" }
                lappend out $cell
            }
        }
        puts "   | [join $out " | "]"
        incr i
    }
}
$sh destroy
$pkg destroy
