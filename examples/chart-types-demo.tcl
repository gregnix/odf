#!/usr/bin/env tclsh
# chart-types-demo.tcl -- one .odt with one embedded chart per type, so the
# render-verification round (deferred from chart 0.4 slice) can be done
# visually across all nine types: bar / column / line / pie / area / ring /
# scatter / radar / bubble.

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out

package require odf::text

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]

$t appendHeading "Chart types -- LO render check" 1
$t appendParagraph "Each section embeds one chart of the named type. Same data,\
 same call shape, only -type differs. Gridlines on x+y axis (where the type\
 supports them) so the axis subsystem is exercised too."

set cats {Q1 Q2 Q3 Q4}
set ser  {Sales {100 150 130 180}  Costs {80 90 110 100}}

foreach type {bar column line pie area ring scatter radar bubble} {
    $t appendHeading "Type: $type" 2
    $t appendChart $cats $ser -type $type -title "Type: $type" \
        -legend end -labels value -xgrid major -ygrid major
}

$pkg save [file join $out chart-types-demo.odt]
puts "wrote: [file join $out chart-types-demo.odt]"
$t destroy; $pkg destroy
