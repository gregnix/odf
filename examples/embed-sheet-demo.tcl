#!/usr/bin/env tclsh
## embed-sheet-demo.tcl -- an editable spreadsheet object embedded in a text doc.
## appendSpreadsheet builds a small .ods with odf::sheet and embeds it as an OLE
## object (via the same appendObject machinery as charts). The object stays
## editable in LibreOffice. Here it is paired with a chart over the same numbers
## -- the typical report layout.
## Output: out/embed-sheet-demo.odt
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]

$t appendHeading "Quarterly figures" 1
$t appendParagraph "The data table below is a live, editable spreadsheet object."

# An embedded spreadsheet with a total row (formula cells carry a cached result).
$t appendSpreadsheet {
    {{string Region} {string Q1} {string Q2} {string Q3}}
    {{string North}  {float 120} {float 150} {float 138}}
    {{string South}  {float 90}  {float 96}  {float 110}}
    {{string Total}  {formula "of:=SUM([.B2:.B3])" float 210}
                     {formula "of:=SUM([.C2:.C3])" float 246}
                     {formula "of:=SUM([.D2:.D3])" float 248}}
} -sheet Figures -name FiguresObj -width 14cm -height 4cm

$t appendHeading "As a chart" 2
$t appendChart {Q1 Q2 Q3} {North {120 150 138} South {90 96 110}} \
    -type column -colors {#1A56DB #C5221F} -legend end -title "Regions by quarter" -name FiguresChart

$t flush
set path [$pkg save [file join $out embed-sheet-demo.odt]]
$pkg destroy
puts "created $path"
