#!/usr/bin/env tclsh
# Demo: three-part header/footer (center + right tab stops, the way Writer
# renders multi-part headers), different left/right pages, and a styled header
# box (bottom rule + light background). Output: out/headerfooter.odt
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set pkg [odf::newTextDoc]
set s   [odf::Styles new $pkg]
$s defineStandardPage {fo:page-width 21cm fo:page-height 29.7cm \
    fo:margin-left 2cm fo:margin-right 2cm fo:margin-top 2.2cm fo:margin-bottom 2cm}
$s setPageUsage PMstandard mirrored

# right / odd pages: company left, date center, page right
$s setHeaderParts Standard -left "Mustermann GmbH" -center "%date%" -right "Page %page% / %pages%"
# left / even pages: mirror (page number to the outer/left edge)
$s setHeaderParts Standard -side left -left "Page %page% / %pages%" -center "%date%" -right "Mustermann GmbH"
# footer on both sides
$s setFooterParts Standard -left "Confidential" -right "%date%"

# style the header box: a little taller, a bottom rule and a light background
$s setHeaderFooterProps Standard -which header -min-height 1.0cm \
    -border-bottom "0.5pt solid #1F3864" -background #F2F4F8 -dynamic-spacing true
$s flush; $s destroy

set t [odf::Text new $pkg]
$t appendHeading "Header / Footer demo" 1
$t appendParagraph "Three-part header via tab stops (company left, date center, page right), mirrored on left/right pages, with a styled header box (bottom rule + light background)."
$t flush; $t destroy

set path [$pkg save [file join $out headerfooter.odt]]; $pkg destroy
puts "created $path"
