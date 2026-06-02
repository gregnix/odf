#!/usr/bin/env tclsh
## chart-doc-demo.tcl -- a standalone OpenDocument chart document (.odc).
## newChartDoc (odf::chart) wraps the same chart content that appendChart embeds,
## but as its own package. Same options as the embedded chart.
## Output: out/chart-doc-demo.odc
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::chart

set pkg [odf::newChartDoc \
    {Q1 Q2 Q3 Q4} \
    {North {120 150 138 162} South {90 96 110 118}} \
    -type column -colors {#1A56DB #C5221F} -legend end -labels value \
    -xtitle "Quarter" -ytitle "Units" -title "Regions by quarter"]
set path [$pkg save [file join $out chart-doc-demo.odc]]
$pkg destroy
puts "created $path"
