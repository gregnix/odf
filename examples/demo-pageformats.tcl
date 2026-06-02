## examples/demo-pageformats.tcl  --  Demo: page-format presets (paper size + orientation)
##
## Usage:  tclsh demo-pageformats.tcl ?format? ?orientation?
##         format      = A3|A4|A5|A6|Letter|Legal   (default A5)
##         orientation = portrait|landscape          (default landscape)
##   ->  out/pageformat-<format>-<orientation>.odt

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set fmt    [expr {[llength $argv] >= 1 ? [lindex $argv 0] : "A5"}]
set orient [expr {[llength $argv] >= 2 ? [lindex $argv 1] : "landscape"}]

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
set s   [odf::Styles new $pkg]
set props [$s pageFormat $fmt -orientation $orient]      ;# pure helper, for the heading text
$s defineParagraph Body -text {fo:font-size 11pt}
$s defineStandardFormat $fmt -orientation $orient -margin 1.5cm
$s flush; $s destroy

$t appendHeading "Page format: $fmt $orient" 1
$t appendParagraph "defineStandardFormat $fmt -orientation $orient -margin 1.5cm" Body
$t appendParagraph "Page [dict get $props fo:page-width] x [dict get $props fo:page-height], uniform 1.5 cm margins." Body
$t flush; $t destroy

set odt [file join $out pageformat-[string tolower $fmt]-$orient.odt]
$pkg save $odt
$pkg destroy
puts "created $odt"
