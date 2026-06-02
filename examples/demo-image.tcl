#!/usr/bin/env tclsh
# Demo: a centered image (as-char) with alt text, and a floating image
# (frame style: wrap + border, right-positioned) with text wrapping around it.
# Output: out/image.odt
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set fix  [file join $base tests fixtures]
set out  [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]

$t appendHeading "Image demo" 1
$t appendParagraph "A centered image with alternative text (anchored as-char in a centered paragraph):"
$t appendImageFile [file join $fix odt-lib-volltest-bild1.png] -name logo \
    -maxwidth 7cm -align center -title "Logo" -desc "Sample logo image"

$t defineFrameStyle Float -wrap parallel -hpos right -hrel paragraph \
    -border "0.5pt solid #888888" -padding 0.15cm
$t appendImageFile [file join $fix test640.jpg] -name photo \
    -maxwidth 5cm -anchor paragraph -style Float
set lorem "This paragraph flows next to the floating image on the right. The frame style sets wrap=parallel and positions the image at the right edge of the paragraph, so the text wraps along its left side. "
$t appendParagraph "$lorem$lorem$lorem"

$t flush; $t destroy
set path [$pkg save [file join $out image.odt]]; $pkg destroy
puts "created $path"
