#!/usr/bin/env tclsh
## draw-fills-demo.tcl -- ODG Fuell-/Appearance-Familie (Slice 17, draw 0.18):
## Hatch, Bitmap-Fill und Opacity. Erzeugt out/draw-fills-demo.odg.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::draw

set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]

# Hatch
$d defineHatch diag -style single -color #336699 -distance 0.12cm -rotation 45
$d defineGraphicStyle s_hatch -hatch diag -fill-hatch-solid 1 \
    -stroke solid -stroke-color #336699 -stroke-width 0.04cm

# Bitmap-Fill (kleines eingebettetes PNG, gekachelt)
set png [binary decode base64 iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNgAAIAAAUAAen63NgAAAAASUVORK5CYII=]
set fh [open [file join $out _tile.png] wb]; fconfigure $fh -translation binary
puts -nonewline $fh $png; close $fh
$d defineFillImage tile -path [file join $out _tile.png]
$d defineGraphicStyle s_bitmap -bitmap tile -repeat repeat \
    -fill-image-width 0.4cm -fill-image-height 0.4cm -stroke solid -stroke-color #000000

# Opacity (halbtransparente Fuellung + Kontur)
$d defineGraphicStyle s_ghost -fill solid -fill-color #e8453c -opacity 40 \
    -stroke solid -stroke-color #000000 -stroke-opacity 60 -stroke-width 0.06cm

set p [$d addPage "Fuellungen"]
$d addRect $p 1cm  2cm 5cm 4cm -style s_hatch  -text "hatch"
$d addRect $p 7cm  2cm 5cm 4cm -style s_bitmap -text "bitmap"
$d addRect $p 13cm 2cm 5cm 4cm -style s_ghost  -text "opacity 40%"
# Overlap, um die Transparenz sichtbar zu machen
$d addEllipse $p 12cm 3.5cm 4cm 3cm -style s_ghost

# Seite 2: Schatten + Transparenzverlauf (0.19)
$d defineGraphicStyle s_shadow -fill solid -fill-color #cfe8ff -stroke solid \
    -stroke-color #336699 -stroke-width 0.04cm \
    -shadow 1 -shadow-offset-x 0.18cm -shadow-offset-y 0.18cm -shadow-color #999999 -shadow-opacity 50
$d defineTransparencyGradient fade -style linear -start 0 -end 100 -angle 90
$d defineGraphicStyle s_fade -fill solid -fill-color #e8453c -opacity-name fade \
    -stroke solid -stroke-color #000000
set p2 [$d addPage "Effekte"]
$d addRect $p2 1cm 2cm 6cm 4cm -style s_shadow -text "shadow"
$d addRect $p2 9cm 2cm 6cm 4cm -style s_fade   -text "transparency"

$d flush
set dst [file join $out draw-fills-demo.odg]
$pkg save $dst
puts "geschrieben: $dst  (hatches=[$d hatches], fillImages=[$d fillImages])"
$d destroy; $pkg destroy
