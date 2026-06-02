## examples/demo-draw.tcl  --  build a small .odg drawing
##
## A tiny flow diagram: three boxes joined by connector lines, plus a status
## ellipse. Shows odf::draw pages, graphic styles (fill/stroke), rect/ellipse/
## line shapes with text labels. Open in LibreOffice Draw / run odfvalidator.
##
## Usage:  tclsh demo-draw.tcl ?out.odg?

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::draw

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out draw.odg]}]
file mkdir [file dirname $outPath]

set pkg [odf::newDrawDoc]
set d   [odf::Draw new $pkg]

# graphic styles
$d defineGraphicStyle node   -fill solid -fill-color #cfe8ff -stroke solid \
                             -stroke-color #336699 -stroke-width 0.06cm -text-align center
$d defineGraphicStyle accent -fill solid -fill-color #ffe0b2 -stroke solid \
                             -stroke-color #e69500 -stroke-width 0.06cm -text-align center
$d defineGraphicStyle conn   -stroke solid -stroke-color #666666 -stroke-width 0.04cm
# an arrowhead marker + a connector style that uses it
$d defineMarker Arrow "0 0 20 30" "M10 0 L0 30 L20 30 Z" -display-name "Arrow"
$d defineGraphicStyle edge -stroke solid -stroke-color #336699 -stroke-width 0.05cm \
                           -marker-end Arrow -marker-end-width 0.35cm
$d defineGradient    sky  -style linear -start-color #cfe8ff -end-color #336699 -angle 45 -border 5
$d defineGraphicStyle grad -gradient sky -stroke solid -stroke-color #224466
$d defineStrokeDash   dash1 -dots1 1 -dots1-length 0.3cm -distance 0.2cm
$d defineGraphicStyle dashbox -fill none -stroke dash -stroke-dash dash1 \
                              -stroke-color #cc0000 -stroke-width 0.05cm

set p [$d addPage "Flow"]
# three stages in a row
set inp  [$d addRect $p  2cm 3cm 6cm 2.5cm -style node   -text "Eingabe"]
set proz [$d addRect $p 11cm 3cm 6cm 2.5cm -style node   -text "Verarbeitung"]
set outp [$d addRect $p 20cm 3cm 6cm 2.5cm -style accent -text "Ausgabe"]
# a status node below, linked to the middle stage
set stat [$d addEllipse $p 11cm 8cm 6cm 3cm -style node -text "Status"]
# connectors bound to the shapes (stay attached when moved)
$d connectShapes $p $inp  $proz -style edge
$d connectShapes $p $proz $outp -style edge
$d connectShapes $p $proz $stat -style edge
$d setTitle $proz "Processing step"
$d setDesc  $proz "Central node of the flow"

# a caption text box and an embedded image (frame > image)
$d addTextBox $p 2cm 13cm 12cm 2cm "odf::draw \u2014 ODG Demo" -style node
set img [file join $base tests fixtures test640.jpg]
if {[file exists $img]} { $d addImageFile $p 18cm 12cm 8cm 5cm $img -name foto }

# second page: point/path shapes
$d defineGraphicStyle fillg -fill solid -fill-color #d6f5d6 -stroke solid \
                            -stroke-color #2e7d32 -stroke-width 0.05cm
set p2 [$d addPage "Shapes"]
$d addPolygon  $p2 {3 3 8 3 5.5 8} -style fillg                 ;# triangle
$d addPolyline $p2 {11 3 13 7 15 3 17 7 19 3} -style conn       ;# zigzag
$d addPath     $p2 3cm 10cm 8cm 4cm "0 0 8000 4000" \
                   "M0 4000 C0 0 8000 0 8000 4000" -style conn  ;# arc
$d addCircle   $p2 23cm 4cm 2cm -style fillg                    ;# circle by centre+radius
$d addRect     $p2 14cm 13cm 6cm 3cm -style grad -corner-radius 0.4cm -text "gradient"
$d addRect     $p2 14cm 17cm 6cm 2.5cm -style dashbox -text "dashed"

# a group of two boxes joined by a bound connector
set grp [$d addGroup $p2 -name "mini"]
set gx [$d addRect $grp 14cm 9cm 4cm 2cm -style node -text "X"]
set gy [$d addRect $grp 22cm 9cm 4cm 2cm -style node -text "Y"]
$d connectShapes $grp $gx $gy -style conn
$d defineLayer  diagram
$d setLayerAll  $grp diagram      ;# layer belongs on the members, not the group

# a rotated rectangle (ODF rotate is CCW about the origin; translate places it)
set rr [$d addRect $p2 0cm 0cm 5cm 2cm -style accent -text "30\u00b0"]
$d setTransform $rr {{rotate 30} {translate 3cm 16cm}}

# a third page on a custom A4-portrait master with a page background
$d definePageLayout PMportrait -format A4 -orientation portrait
$d defineDrawingPageStyle bg -fill solid -fill-color #f5f5dc
$d defineMasterPage Portrait -pagelayout PMportrait -style bg
set p3 [$d addPage "Portrait" -master Portrait]
$d setPageStyle $p3 bg
$d addRect $p3 2cm 2cm 6cm 3cm -style node -text "A4 portrait"

$d flush
$d destroy
$pkg save $outPath
$pkg destroy
puts "geschrieben: $outPath"
