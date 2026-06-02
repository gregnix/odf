#!/usr/bin/env tclsh
# Demo: a table with merged cells (column span for a title row, row span for a
# category cell). Output: out/span.odt
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]

$t defineAutoTable  T1 {style:width 15cm table:align center}
$t defineAutoColumn Cat {style:column-width 5cm}
$t defineAutoColumn Col {style:column-width 5cm}
$t defineAutoCellStyle Title -border "0.5pt solid #1F3864" -background #305080 \
   -color #FFFFFF -bold true -align center -valign middle -padding 0.15cm
$t defineAutoCellStyle Cell  -border "0.5pt solid #AAAAAA" -valign middle -padding 0.1cm

$t appendHeading "Quarterly plan" 1

set tab [$t appendTableCols {Cat Col Col} T1]
# Title row spanning all three columns
$t addRow $tab {Overview {} {}} {Title Title Title}
# Category "Q1" spanning two rows, then two detail rows
$t addRow $tab {Q1 Marketing 10k} {Cell Cell Cell}
$t addRow $tab {{} Sales     20k} {Cell Cell Cell}
$t addRow $tab {Q2 Marketing 12k} {Cell Cell Cell}

$t spanCell $tab 0 0 -columns 3      ;# title across all columns
$t spanCell $tab 1 0 -rows 2         ;# "Q1" category across its two rows

$t flush; $t destroy
set path [$pkg save [file join $out span.odt]]; $pkg destroy
puts "created $path"
