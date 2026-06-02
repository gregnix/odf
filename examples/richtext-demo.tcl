## examples/richtext-demo.tcl  --  ODS rich-text cells
##
## ODS slice 0.23 (sheet 0.23): demonstrates `setCellRichText cell
## paragraph ?paragraph2 ...?`. Each paragraph is a list of inline
## run tokens:
##
##   {text "X"}            -- plain text node
##   {span STYLE "X"}      -- text:span with text:style-name
##   {link HREF "X" STYLE} -- text:a (xlink:href + display text)
##   lb                    -- text:line-break  (bare word)
##   tab                   -- text:tab
##   {space N}             -- text:s text:c=N  (collapsed whitespace)
##
## Multiple paragraphs become multiple `text:p` children inside the
## cell. The cell becomes string-typed; any prior numeric value is
## stripped. cellText reads back the concatenated plain text.
##
## Usage:  tclsh richtext-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet
package require odf::style

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out richtext-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]
set sty [odf::Styles new $pkg]

# Inline text-family styles for the rich-text run spans (styles.xml)
$sty defineText Bold   {fo:font-weight bold}
$sty defineText Red    {fo:color #cc0000 fo:font-weight bold}
$sty defineText Italic {fo:font-style italic}
$sty defineText Code   {style:font-name "Courier New"}

set t [$sh addTable "Hinweise"]
$sh addColumns $t 2
$sh addStringRow $t {Feld Inhalt}

# Plain placeholders -- will be replaced with rich content
$sh addRow $t {{string "Warnung"}  {string ""}}
$sh addRow $t {{string "URL"}      {string ""}}
$sh addRow $t {{string "Hinweis"}  {string ""}}
$sh addRow $t {{string "Befehl"}   {string ""}}

set rows [$sh rows $t]

# Row 1: bold red WARNUNG + plain follow-up
set c [lindex [$sh cells [lindex $rows 1]] 1]
$sh setCellRichText $c \
    [list {span Red "WARNUNG"} {text ": bitte vor dem Speichern pruefen."}]

# Row 2: link with style
set c [lindex [$sh cells [lindex $rows 2]] 1]
$sh setCellRichText $c \
    [list {text "Spec: "} \
          {link "https://www.oasis-open.org/standard/opendocument-v1-3-os/" \
                "OpenDocument 1.3" "Bold"}]

# Row 3: multi-paragraph mit lb, tab, space, italic span
set c [lindex [$sh cells [lindex $rows 3]] 1]
$sh setCellRichText $c \
    [list {text "Punkt 1: Datenquelle pruefen."} lb \
          {text "Punkt 2: Filter aktivieren."}] \
    [list {text "Beispiel:"} tab {span Italic "Region=Nord"}] \
    [list {text "Resultat:"} {space 3} {span Bold "OK"}]

# Row 4: monospace + plain text mix
set c [lindex [$sh cells [lindex $rows 4]] 1]
$sh setCellRichText $c \
    [list {span Code "SELECT * FROM Verkaeufe"} {text " (SQL-Stil)"}]

# Verify via reader
puts "Cell readout (cellText concatenates spans/breaks):"
foreach r [lrange $rows 1 end] {
    set label [$sh cellText [lindex [$sh cells $r] 0]]
    set rich  [$sh cellText [lindex [$sh cells $r] 1]]
    puts "  $label:"
    foreach line [split $rich "\n"] {
        puts "    | $line"
    }
}

$pkg save $outPath
puts "wrote $outPath"
$sh destroy; $sty destroy; $pkg destroy
