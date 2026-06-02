## examples/demo-columns.tcl  --  Demo: multi-column page (style:columns)
##
## Usage:  tclsh demo-columns.tcl ?columns? ?gap?
##         columns (default 2), gap (default 0.7cm)
##   ->  out/columns.odt

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set n   [expr {[llength $argv] >= 1 ? [lindex $argv 0] : 2}]
set gap [expr {[llength $argv] >= 2 ? [lindex $argv 1] : "0.7cm"}]

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
set s   [odf::Styles new $pkg]
$s defineParagraph Body -text {fo:font-size 11pt} \
   -paragraph {fo:margin-bottom 0.2cm fo:text-align justify}
$s defineStandardFormat A4 -margin 2cm
$s pageProperties PMstandard -columns $n -column-gap $gap
$s flush; $s destroy

$t appendHeading "Multi-column layout ($n columns, gap $gap)" 1

set para "This paragraph demonstrates running text flowing across multiple\
 columns. ODF lays the body text into the columns defined on the page-layout\
 through style:columns. The library writes fo:column-count and fo:column-gap;\
 the application then distributes the running text into equal columns by itself."
for {set i 1} {$i <= 12} {incr i} {
    $t appendParagraph "($i) $para" Body
}
$t flush; $t destroy

set odt [file join $out columns.odt]
$pkg save $odt
$pkg destroy
puts "created $odt"
