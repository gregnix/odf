#!/usr/bin/env tclsh
## chart-demo.tcl -- embedded charts in a text document.
## appendObject is the generic embedding primitive (a sub-document stored as
## "Object N/" + a draw:frame > draw:object reference); appendChart builds a
## minimal valid office:chart sub-document (with its own local-table of data)
## and embeds it through that primitive. The chart is self-contained and stays
## editable in a consumer such as LibreOffice.
## Output: out/chart-demo.odt
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]

$t appendHeading "Quarterly report" 1
$t appendParagraph "Revenue and cost by quarter, two product lines."

# A stacked column chart with two series, custom colours and a legend.
$t appendChart {Q1 Q2 Q3 Q4} \
    {Revenue {120 150 138 175} Cost {80 96 92 110}} \
    -type column -stacked 1 -colors {#1A56DB #C5221F} -legend end \
    -title "Revenue vs Cost" -name RevCost -width 14cm -height 8cm

$t appendHeading "Trend" 2
# A line chart with one series.
$t appendChart {Jan Feb Mar Apr May} \
    {Users {1200 1500 2100 2600 3400}} \
    -type line -colors {#137333} -legend bottom -title "Active users" -name UserTrend

$t flush
set path [$pkg save [file join $out chart-demo.odt]]
$pkg destroy
puts "created $path"
