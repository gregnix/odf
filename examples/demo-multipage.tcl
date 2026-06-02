## examples/demo-multipage.tcl  --  Demo: first page different + master chaining
##
## Page 1 uses master "First" (tall top margin = letterhead zone); via
## style:next-style-name the following pages use master "Rest" (normal). The
## first body paragraph carries the master via defineMasterPageStyle.
##
## Usage:  tclsh demo-multipage.tcl   ->  out/multipage.odt

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
set s   [odf::Styles new $pkg]

# First page: tall top margin; the rest: normal top margin
$s definePageFormat PMfirst A4 -margins {8cm 2cm 2cm 2.5cm}
$s definePageFormat PMrest  A4 -margins {2.5cm 2cm 2cm 2.5cm}
$s defineMasterPage First -pagelayout PMfirst
$s defineMasterPage Rest  -pagelayout PMrest
$s setNextPage First Rest
$s setFooter First {{"Page %page% of %pages%"}}
$s setFooter Rest  {{"Page %page% of %pages%"}}
$s defineMasterPageStyle FirstStart First
$s defineParagraph Body -text {fo:font-size 11pt} \
   -paragraph {fo:margin-bottom 0.2cm fo:text-align justify}
$s flush; $s destroy

$t appendParagraph "The first page begins lower (letterhead zone); the following pages start at the normal top margin." FirstStart
set para "This running text exists only to fill several pages so the different\
 first page becomes visible. Page 1 uses the First master with a tall top\
 margin; from page 2 on the Rest master applies, set via style:next-style-name."
for {set i 1} {$i <= 30} {incr i} {
    $t appendParagraph "($i) $para" Body
}
$t flush; $t destroy

set odt [file join $out multipage.odt]
$pkg save $odt
$pkg destroy
puts "created $odt"
