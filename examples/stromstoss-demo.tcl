#!/usr/bin/env tclsh
# stromstoss-demo.tcl -- reproduce the LibreSymbols "Stromstossschaltung"
# example (a German installation-plan classic: bistable relay + 3 illuminated
# push-buttons + 3 lamps) using only odf::draw primitives -- no binary
# gallery symbols, just lines, circles, paths, customs, and a title block.

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out

package require odf::draw

set pkg [odf::newDrawDoc]
set d   [odf::Draw new $pkg]

# Graphic style for all wires (thin black lines)
$d defineGraphicStyle gWire   -stroke solid -stroke-color #000000 -stroke-width 0.02cm
$d defineGraphicStyle gFrame  -stroke solid -stroke-color #000000 -stroke-width 0.02cm \
                              -fill solid -fill-color #ffffff
$d defineGraphicStyle gText   -stroke none -fill none
# Title-block style: minimal, schwarze Linien
$d defineGraphicStyle gBlock  -stroke solid -stroke-color #000000 -stroke-width 0.02cm
$d defineGraphicStyle gTbFrm  -stroke none

# A4 landscape with full title block (0.27: no -shape-style override --
# addTitleBlock supplies internal styles that LO can resolve, since they
# live in styles.xml next to the master-page shapes that reference them).
set mp [$d addMasterPage Main -size A4 -orientation landscape]
$d addTitleBlock $mp -size A4 -orientation landscape \
    -title    "Stromstoßschaltung" \
    -subtitle "Beispiel für einen Installationsplan" \
    -author   "ssc" \
    -date     "2026-05-27" \
    -page-number "1"

set page [$d addPage "Schaltplan" -master Main]

# ---- helpers --------------------------------------------------------------
# Concentric two-circle lamp symbol (used for S1..S3) at center (cx, cy).
proc drawLamp {d page cx cy} {
    set r1 0.35cm; set r2 0.55cm
    foreach {r} [list $r1 $r2] {
        # bounding box around (cx, cy) with width=2r
        set x [expr {[string trim $cx cm] - [string trim $r cm]}]cm
        set y [expr {[string trim $cy cm] - [string trim $r cm]}]cm
        set wh [expr {2 * [string trim $r cm]}]cm
        $d addEllipse $page $x $y $wh $wh -style gFrame
    }
}
# Diagonal-cross "X" consumer/fuse symbol around (cx, cy)
proc drawCross {d page cx cy} {
    set s 0.45cm
    set cn [string trim $cx cm]; set cm [string trim $cy cm]
    set ss [string trim $s cm]
    set x1 [expr {$cn - $ss}]cm; set y1 [expr {$cm - $ss}]cm
    set x2 [expr {$cn + $ss}]cm; set y2 [expr {$cm + $ss}]cm
    $d addLine $page $x1 $y1 $x2 $y2 -style gWire
    $d addLine $page $x1 $y2 $x2 $y1 -style gWire
}
# Triple slash on a wire (cable marker) -- three short diagonal strokes
proc drawCableMarks {d page cx cy} {
    set step 0.13cm; set len 0.45cm
    set cn [string trim $cx cm]; set cm [string trim $cy cm]
    set ss [string trim $step cm]; set ll [string trim $len cm]
    for {set i -1} {$i <= 1} {incr i} {
        set x1 [expr {$cn + $i*$ss - $ll/2.0}]cm
        set y1 [expr {$cm + $ll/2.0}]cm
        set x2 [expr {$cn + $i*$ss + $ll/2.0}]cm
        set y2 [expr {$cm - $ll/2.0}]cm
        $d addLine $page $x1 $y1 $x2 $y2 -style gWire
    }
}
# Small filled dot at (cx, cy) -- the conductor "tap" marker
proc drawDot {d page cx cy} {
    set r 0.10cm
    set cn [string trim $cx cm]; set cm [string trim $cy cm]
    set rr [string trim $r cm]
    set x [expr {$cn - $rr}]cm; set y [expr {$cm - $rr}]cm
    set wh [expr {2 * $rr}]cm
    set st [$d defineGraphicStyle gDot -fill solid -fill-color #000000 -stroke none]
    $d addEllipse $page $x $y $wh $wh -style gDot
}
# Stromstossrelais K1: small rectangle (1cm wide x 0.8cm tall) with a Z-path inside
proc drawRelay {d page x y label} {
    set w 1.0cm; set h 0.8cm
    set xn [string trim $x cm]; set yn [string trim $y cm]
    $d addRect $page $x $y $w $h -style gFrame
    # Z-shape inside (svg:d in the rect's own viewBox)
    set zx1 [expr {$xn + 0.2}]cm; set zy1 [expr {$yn + 0.2}]cm
    set zx2 [expr {$xn + 0.8}]cm; set zy2 [expr {$yn + 0.2}]cm
    set zx3 [expr {$xn + 0.2}]cm; set zy3 [expr {$yn + 0.6}]cm
    set zx4 [expr {$xn + 0.8}]cm; set zy4 [expr {$yn + 0.6}]cm
    $d addLine $page $zx1 $zy1 $zx2 $zy2 -style gWire
    $d addLine $page $zx2 $zy2 $zx3 $zy3 -style gWire
    $d addLine $page $zx3 $zy3 $zx4 $zy4 -style gWire
    # Label below
    set lblY [expr {$yn + 0.95}]cm
    $d addRect $page $xn[set _ {cm}] $lblY 1cm 0.5cm -style gText -text $label
}
# Text-label next to a symbol (right side of the shape)
proc drawLabel {d page x y text} {
    $d addRect $page $x $y 1cm 0.5cm -style gText -text $text
}

# ---- circuit layout -------------------------------------------------------
# Main horizontal wire at y = 11cm
set mainY 11cm
$d addLine $page 4cm $mainY 24cm $mainY -style gWire

# Relay K1 at the left -- horizontal line goes through it
drawRelay $d $page 6.5cm [expr {[string trim $mainY cm] - 0.4}]cm K1

# Three vertical branches at x = 11cm, 16cm, 21cm
foreach {x lblTop lblBot} {11cm E1 S1   16cm E2 S2   21cm E3 S3} {
    # Vertical wire from top consumer (5cm) down to lamp (16cm)
    $d addLine $page $x 5cm $x 16cm -style gWire
    # Top consumer cross at y=4.5cm
    drawCross $d $page $x 4.5cm
    # Label E_n to the right of the cross
    set lblX [expr {[string trim $x cm] + 0.6}]cm
    drawLabel $d $page $lblX 4.2cm $lblTop
    # Lamp at y=16.5cm
    drawLamp $d $page $x 16.5cm
    # Label S_n to the right of the lamp
    drawLabel $d $page $lblX 16.2cm $lblBot
    # Cable-marks above middle wire and below
    drawCableMarks $d $page $x 7.5cm
    drawCableMarks $d $page $x 14cm
    # Tap dot where vertical hits horizontal
    drawDot $d $page $x $mainY
}

# Cable marks on the horizontal wire (between branches)
foreach mx {8.5cm 13.5cm 18.5cm} {
    drawCableMarks $d $page $mx $mainY
}
# Tap dot where K1 right-end meets horizontal main
drawDot $d $page 8cm $mainY

# Save and present. Since odf 0.9 the Package auto-flushes registered helpers
# before saving, so explicit $d flush is no longer required.
$pkg save [file join $out stromstoss-demo.odg]
puts "wrote: [file join $out stromstoss-demo.odg]"
$d destroy; $pkg destroy
