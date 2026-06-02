## tests/test-draw.tcl  --  ODG drawing (odf::draw), slice 1
## Build a drawing from scratch, save, reload and verify pages + shapes
## (geometry / text / style). No fixture needed.

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::draw
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) build from scratch ----
set pkg [odf::newDrawDoc]
ok {[$pkg mimetype] eq "application/vnd.oasis.opendocument.graphics"} "A: graphics mimetype"
set d [odf::Draw new $pkg]
$d defineGraphicStyle box -fill solid -fill-color #cfe8ff -stroke solid -stroke-color #336699 -stroke-width 0.05cm
set p1 [$d addPage "Page 1"]
$d addRect    $p1 2cm 2cm 6cm 3cm -style box -text "Hello ODG"
$d addEllipse $p1 10cm 2cm 5cm 3cm -style box
$d addLine    $p1 2cm 7cm 27cm 7cm
set p2 [$d addPage "Page 2"]
$d addRect    $p2 1cm 1cm 4cm 4cm
ok {[catch {$d defineGraphicStyle bad -nope x}] == 1} "A: unknown graphic option rejected"
ok {[catch {$d addRect $p1 0 0 1cm 1cm -bad x}] == 1} "A: unknown shape option rejected"
$d flush
$d destroy
set path [file join $out draw-test.odg]
$pkg save $path
$pkg destroy

# ---- B) reload + structure ----
set p [odf::Package new $path]
ok {[lindex [$p parts] 0] eq "mimetype"} "B: mimetype is first ZIP entry"
set d [odf::Draw new $p]
ok {[$d pageCount] == 2}                 "B: two pages"
set pages [$d pages]
ok {[$d pageName [lindex $pages 0]] eq "Page 1"} "B: page 1 name"
ok {[$d pageName [lindex $pages 1]] eq "Page 2"} "B: page 2 name"

set sh [$d shapes [lindex $pages 0]]
ok {[llength $sh] == 3}                   "B: page 1 has 3 shapes"
ok {[$d shapeType [lindex $sh 0]] eq "rect"}    "B: shape0 is rect"
ok {[$d shapeRect [lindex $sh 0]] eq {2cm 2cm 6cm 3cm}} "B: rect geometry"
ok {[$d shapeText [lindex $sh 0]] eq "Hello ODG"}       "B: rect text"
ok {[$d shapeStyleName [lindex $sh 0]] eq "box"}        "B: rect style"
ok {[$d shapeType [lindex $sh 1]] eq "ellipse"} "B: shape1 is ellipse"
ok {[$d shapeRect [lindex $sh 1]] eq {10cm 2cm 5cm 3cm}} "B: ellipse geometry"
ok {[$d shapeType [lindex $sh 2]] eq "line"}    "B: shape2 is line"
ok {[$d shapeLine [lindex $sh 2]] eq {2cm 7cm 27cm 7cm}} "B: line endpoints"

ok {[llength [$d shapes [lindex $pages 1]]] == 1} "B: page 2 has 1 shape"

# ---- C) parts well-formed ----
foreach part {content.xml styles.xml META-INF/manifest.xml meta.xml} {
    if {[catch {dom parse [encoding convertfrom utf-8 [$p part $part]] dd}]} {
        ok {0} "C: $part well-formed"
    } else { $dd delete; ok {1} "C: $part well-formed" }
}

# ---- D) graphic style + default page geometry ----
set doc [$p tree content.xml]
proc gprops {doc name} {
    foreach st [[$doc documentElement] getElementsByTagName style:style] {
        if {[$st getAttribute style:name ""] eq $name} {
            return [lindex [$st getElementsByTagName style:graphic-properties] 0]
        }
    }
    return ""
}
set gp [gprops $doc box]
ok {$gp ne ""}                                       "D: graphic style box present"
ok {[$gp getAttribute draw:fill ""] eq "solid"}      "D: fill solid"
ok {[$gp getAttribute draw:fill-color ""] eq "#cfe8ff"} "D: fill color"
ok {[$gp getAttribute svg:stroke-color ""] eq "#336699"} "D: stroke color"
$doc delete

# the draw:page references the shipped default master-page (so it is valid)
set cdoc [$p tree content.xml]
set pg [lindex [[$cdoc documentElement] getElementsByTagName draw:page] 0]
ok {[$pg getAttribute draw:master-page-name ""] eq "Default"} "D: page uses Default master"
$cdoc delete
set sdoc [$p tree styles.xml]
set mp ""
foreach e [[$sdoc documentElement] getElementsByTagName style:master-page] {
    if {[$e getAttribute style:name ""] eq "Default"} { set mp $e }
}
ok {$mp ne "" && [$mp getAttribute style:page-layout-name ""] eq "PMdraw"} "D: Default master -> PMdraw layout"
$sdoc delete

$d destroy
$p destroy

# ---- E) frames: text box + embedded image (slice 2) ----
set pkgE [odf::newDrawDoc]
set dE [odf::Draw new $pkgE]
set pgE [$dE addPage "Frames"]
$dE addTextBox $pgE 2cm 2cm 8cm 3cm "Box text"
set imgFile [file join $base tests fixtures test640.jpg]
$dE addImageFile $pgE 2cm 6cm 6cm 4cm $imgFile -name pic
ok {[catch {$dE embedImage [info script]}] == 1} "E: non-image rejected"
$dE flush
$dE destroy
set ePath [file join $out frames.odg]
$pkgE save $ePath
$pkgE destroy

set pE [odf::Package new $ePath]
set dEr [odf::Draw new $pE]
set shE [$dEr shapes [lindex [$dEr pages] 0]]
ok {[llength $shE] == 2}                          "E: two frames"
ok {[$dEr shapeType [lindex $shE 0]] eq "frame"}  "E: shape0 is frame"
ok {[$dEr frameKind [lindex $shE 0]] eq "text"}   "E: frame0 kind text"
ok {[$dEr shapeText [lindex $shE 0]] eq "Box text"} "E: frame0 text read"
ok {[$dEr frameKind [lindex $shE 1]] eq "image"}  "E: frame1 kind image"
ok {[$dEr shapeImage [lindex $shE 1]] eq "Pictures/pic.jpg"} "E: image href"
ok {[$pE has Pictures/pic.jpg]}                   "E: image part embedded"
ok {[dict get [$pE manifest] Pictures/pic.jpg] eq "image/jpeg"} "E: manifest media type"
$dEr destroy
$pE destroy

# ---- F) point/path shapes (slice 3) ----
set pkgF [odf::newDrawDoc]
set dF [odf::Draw new $pkgF]
set pgF [$dF addPage "Shapes"]
$dF addPolyline $pgF {0 0 2 1 4 0} -style {}
$dF addPolygon  $pgF {0 0 2 3 4 0}
$dF addPath     $pgF 1cm 1cm 3cm 2cm "0 0 3000 2000" "M0 0 L3000 0 L1500 2000 Z"
ok {[catch {$dF addPolyline $pgF {0 0}}] == 1}        "F: too few points rejected"
ok {[catch {$dF addPolyline $pgF {0 0 1 1} -unit km}] == 1} "F: bad unit rejected"
$dF flush
$dF destroy
set fPath [file join $out shapes.odg]
$pkgF save $fPath
$pkgF destroy

set pF [odf::Package new $fPath]
set dFr [odf::Draw new $pF]
set shF [$dFr shapes [lindex [$dFr pages] 0]]
ok {[$dFr shapeType [lindex $shF 0]] eq "polyline"}            "F: shape0 polyline"
ok {[$dFr shapeRect [lindex $shF 0]] eq {0cm 0cm 4cm 1cm}}     "F: polyline bbox"
ok {[$dFr shapeViewBox [lindex $shF 0]] eq "0 0 4000 1000"}    "F: polyline viewBox (1/100mm)"
ok {[$dFr shapePoints [lindex $shF 0]] eq "0,0 2000,1000 4000,0"} "F: polyline points mapped"
ok {[$dFr shapeType [lindex $shF 1]] eq "polygon"}             "F: shape1 polygon"
ok {[$dFr shapePoints [lindex $shF 1]] eq "0,0 2000,3000 4000,0"} "F: polygon points"
ok {[$dFr shapeType [lindex $shF 2]] eq "path"}                "F: shape2 path"
ok {[$dFr shapeViewBox [lindex $shF 2]] eq "0 0 3000 2000"}    "F: path viewBox"
ok {[$dFr shapePathData [lindex $shF 2]] eq "M0 0 L3000 0 L1500 2000 Z"} "F: path data"
$dFr destroy
$pF destroy

# ---- G) groups + connectors (slice 4) ----
set pkgG [odf::newDrawDoc]
set dG [odf::Draw new $pkgG]
set pgG [$dG addPage "GC"]
# a group with two member shapes
set grp [$dG addGroup $pgG -name g1]
$dG addRect    $grp 1cm 1cm 3cm 2cm
$dG addEllipse $grp 5cm 1cm 3cm 2cm
# two boxes + a bound connector + a free connector
set a [$dG addRect $pgG 2cm 8cm 6cm 3cm -text A]
set b [$dG addRect $pgG 14cm 8cm 6cm 3cm -text B]
$dG connectShapes $pgG $a $b -type standard
$dG addConnector  $pgG 2cm 14cm 20cm 14cm -type line
$dG flush
$dG destroy
set gPath [file join $out gc.odg]
$pkgG save $gPath
$pkgG destroy

set pG [odf::Package new $gPath]
set dGr [odf::Draw new $pG]
set top [$dGr shapes [lindex [$dGr pages] 0]]
# top-level: group, rect A, rect B, bound connector, free connector
ok {[$dGr shapeType [lindex $top 0]] eq "g"}          "G: shape0 is a group"
ok {[llength [$dGr shapes [lindex $top 0]]] == 2}     "G: group has 2 members"
ok {[$dGr shapeType [lindex [$dGr shapes [lindex $top 0]] 1]] eq "ellipse"} "G: group member1 ellipse"
ok {[$dGr shapeType [lindex $top 3]] eq "connector"}  "G: bound connector present"
ok {[$dGr shapeType [lindex $top 4]] eq "connector"}  "G: free connector present"
# bound connector references both shape ids; ends are the box centers
set bc [lindex $top 3]
lassign [$dGr connectorShapes $bc] sid eid
ok {$sid ne "" && $eid ne "" && $sid ne $eid}         "G: connector binds two distinct shape ids"
ok {[$dGr connectorEnds $bc] eq {5.0cm 9.5cm 17.0cm 9.5cm}} "G: connector ends = box centers"
# the referenced ids actually exist on rect A and rect B (reload order preserved)
ok {[[lindex $top 1] getAttribute draw:id ""] eq $sid} "G: start id is on rect A"
ok {[[lindex $top 2] getAttribute draw:id ""] eq $eid} "G: end id is on rect B"
# both ids are also xml:id (the canonical ID the IDREF resolves against)
ok {[[lindex $top 1] getAttribute xml:id ""] eq $sid} "G: rect A has xml:id (validator)"
ok {[[lindex $top 2] getAttribute xml:id ""] eq $eid} "G: rect B has xml:id (validator)"
# free connector has explicit ends and no shape binding
set fc [lindex $top 4]
ok {[$dGr connectorEnds $fc] eq {2cm 14cm 20cm 14cm}}  "G: free connector ends"
ok {[$dGr connectorShapes $fc] eq {{} {}}}             "G: free connector unbound"
# draw:connector requires svg:viewBox (4 ints); we also emit svg:d
ok {[regexp {^-?\d+ -?\d+ \d+ \d+$} [$bc getAttribute svg:viewBox ""]]} "G: bound connector has viewBox (4 ints)"
ok {[$bc getAttribute svg:viewBox ""] eq "0 0 12000 1"}    "G: bound connector viewBox from centers"
ok {[$bc getAttribute svg:d ""] eq "M0 0 L12000 0"}        "G: bound connector path data"
ok {[$fc getAttribute svg:viewBox ""] eq "0 0 18000 1"}    "G: free connector viewBox"
$dGr destroy
$pG destroy

# ---- H) transforms (slice 5, completes Phase 1) ----
set pkgH [odf::newDrawDoc]
set dH [odf::Draw new $pkgH]
set pgH [$dH addPage "T"]
set r1 [$dH addRect $pgH 2cm 2cm 4cm 2cm -text rot]
$dH setTransform $r1 {{rotate 30} {translate 2cm 1cm}}
set r2 [$dH addRect $pgH 8cm 2cm 4cm 2cm]
$dH setTransform $r2 {{scale 1.5 2}}
set r3 [$dH addEllipse $pgH 2cm 8cm 4cm 2cm]
$dH setTransform $r3 {{skewx 15}}
ok {[catch {$dH setTransform $r1 {{flip 1}}}] == 1} "H: unknown transform op rejected"
$dH flush
$dH destroy
set hPath [file join $out transform.odg]
$pkgH save $hPath
$pkgH destroy

set pH [odf::Package new $hPath]
set dHr [odf::Draw new $pH]
set shH [$dHr shapes [lindex [$dHr pages] 0]]
ok {[$dHr shapeTransform [lindex $shH 0]] eq "rotate (0.52360) translate (2cm 1cm)"} "H: rotate+translate serialized (deg->rad)"
ok {[$dHr shapeTransform [lindex $shH 1]] eq "scale (1.5 2)"}    "H: scale serialized"
ok {[$dHr shapeTransform [lindex $shH 2]] eq "skewX (0.26180)"}  "H: skewx serialized (deg->rad)"
ok {[$dHr shapeTransform [lindex $shH 1]] ne "" && [$dHr shapeText [lindex $shH 0]] eq "rot"} "H: transform coexists with geometry/text"
$dHr destroy
$pH destroy

# ---- I) z-order + layers (slice 7, Phase 2) ----
set pkgI [odf::newDrawDoc]
set dI [odf::Draw new $pkgI]
$dI defineLayer background -display screen
$dI defineLayer foreground
set pgI [$dI addPage "Z"]
set z1 [$dI addRect $pgI 1cm 1cm 4cm 4cm]
$dI setZIndex $z1 0
$dI setLayer  $z1 background
set z2 [$dI addRect $pgI 2cm 2cm 4cm 4cm]
$dI setZIndex $z2 5
$dI setLayer  $z2 foreground
ok {[catch {$dI setZIndex $z1 -1}] == 1}      "I: negative z-index rejected"
$dI flush
$dI destroy
set iPath [file join $out zlayer.odg]
$pkgI save $iPath
$pkgI destroy

set pI [odf::Package new $iPath]
set dIr [odf::Draw new $pI]
ok {[$dIr layers] eq {background foreground}}  "I: layers defined in styles.xml"
set shI [$dIr shapes [lindex [$dIr pages] 0]]
ok {[$dIr shapeZIndex [lindex $shI 0]] eq "0"} "I: shape0 z-index 0"
ok {[$dIr shapeZIndex [lindex $shI 1]] eq "5"} "I: shape1 z-index 5"
ok {[$dIr shapeLayer  [lindex $shI 0]] eq "background"} "I: shape0 layer"
ok {[$dIr shapeLayer  [lindex $shI 1]] eq "foreground"} "I: shape1 layer"
# layer-set lives in office:master-styles, layer has draw:display
set sdoc [$pI tree styles.xml]
set ls [lindex [[$sdoc documentElement] getElementsByTagName draw:layer-set] 0]
ok {$ls ne ""}                                 "I: draw:layer-set present in styles.xml"
set bg ""
foreach l [$ls getElementsByTagName draw:layer] { if {[$l getAttribute draw:name ""] eq "background"} { set bg $l } }
ok {[$bg getAttribute draw:display ""] eq "screen"} "I: layer display attr"
$sdoc delete
$dIr destroy
$pI destroy

# ---- J) arrows / markers (slice 8, Phase 3) ----
set pkgJ [odf::newDrawDoc]
set dJ [odf::Draw new $pkgJ]
$dJ defineMarker Arrow "0 0 20 30" "M10 0 L0 30 L20 30 Z" -display-name "Arrow"
$dJ defineGraphicStyle edge -stroke solid -stroke-color #333333 -stroke-width 0.05cm \
                            -marker-end Arrow -marker-end-width 0.3cm -marker-end-center 0
set pgJ [$dJ addPage "Arrows"]
set la [$dJ addLine $pgJ 2cm 2cm 12cm 2cm -style edge]
$dJ flush
$dJ destroy
set jPath [file join $out arrows.odg]
$pkgJ save $jPath
$pkgJ destroy

set pJ [odf::Package new $jPath]
set dJr [odf::Draw new $pJ]
ok {[$dJr markers] eq {Arrow}}  "J: marker defined in office:styles"
# the marker carries viewBox + path
set sd [$pJ tree styles.xml]
set mk ""
foreach m [[$sd documentElement] getElementsByTagName draw:marker] { if {[$m getAttribute draw:name ""] eq "Arrow"} { set mk $m } }
ok {[$mk getAttribute svg:viewBox ""] eq "0 0 20 30"}        "J: marker viewBox"
ok {[$mk getAttribute svg:d ""] eq "M10 0 L0 30 L20 30 Z"}   "J: marker path data"
$sd delete
# the graphic style references the marker
set cd [$pJ tree content.xml]
set gp ""
foreach st [[$cd documentElement] getElementsByTagName style:style] {
    if {[$st getAttribute style:name ""] eq "edge"} { set gp [lindex [$st getElementsByTagName style:graphic-properties] 0] }
}
ok {[$gp getAttribute draw:marker-end ""] eq "Arrow"}        "J: graphic style references marker"
ok {[$gp getAttribute draw:marker-end-width ""] eq "0.3cm"}  "J: marker-end-width set"
$cd delete
# the line uses the arrow style
set ln [lindex [$dJr shapes [lindex [$dJr pages] 0]] 0]
ok {[$dJr shapeStyleName $ln] eq "edge"}                     "J: line uses arrow style"
ok {[catch {$dJr defineMarker M "0 0 1 1" "M0 0" -bad x}] == 1} "J: unknown marker option rejected"
$dJr destroy
$pJ destroy

# ---- K) master pages / page layouts (slice 9, Phase 3) ----
set pkgK [odf::newDrawDoc]
set dK [odf::Draw new $pkgK]
$dK definePageLayout PMportrait -format A4 -orientation portrait
$dK definePageLayout PMwide -width 30cm -height 20cm   ;# orientation auto -> landscape
$dK defineDrawingPageStyle bg -fill solid -fill-color #f5f5dc
$dK defineMasterPage Portrait -pagelayout PMportrait -style bg -display-name "Portrait page"
set pK1 [$dK addPage "P1" -master Portrait]
set pK2 [$dK addPage "P2"]                              ;# Default master
$dK setPageStyle $pK2 bg
# give the pages visible content so the master/page styling actually shows
$dK defineGraphicStyle box -fill solid -fill-color #4477aa
$dK addRect    $pK1 3cm 3cm 8cm 3cm -style box
$dK addTextBox $pK1 3cm 7cm 8cm 1cm "Portrait master page"
$dK addCircle  $pK2 8cm 6cm 2cm -style box
ok {[catch {$dK definePageLayout X -format A9}] == 1}   "K: unknown format rejected"
ok {[catch {$dK definePageLayout X}] == 1}              "K: missing size rejected"
$dK flush
$dK destroy
set kPath [file join $out master.odg]
$pkgK save $kPath
$pkgK destroy

set pK [odf::Package new $kPath]
set dKr [odf::Draw new $pK]
ok {[lsort [$dKr masterPages]] eq {Default Portrait}}    "K: master pages (default + custom)"
ok {[$dKr masterPageLayout Portrait] eq "PMportrait"}    "K: master -> page layout"
ok {[$dKr masterPageStyle Portrait] eq "bg"}             "K: master -> background style"
set pgs [$dKr pages]
ok {[$dKr pageMaster [lindex $pgs 0]] eq "Portrait"}     "K: page1 uses Portrait master"
ok {[$dKr pageMaster [lindex $pgs 1]] eq "Default"}      "K: page2 uses Default master"
ok {[$dKr pageStyle  [lindex $pgs 1]] eq "bg"}           "K: page2 background style set"
# page-layout geometry written correctly (A4 portrait => width<height)
set sd [$pK tree styles.xml]
set pp ""
foreach pl [[$sd documentElement] getElementsByTagName style:page-layout] {
    if {[$pl getAttribute style:name ""] eq "PMportrait"} { set pp [lindex [$pl getElementsByTagName style:page-layout-properties] 0] }
}
ok {[$pp getAttribute fo:page-width ""] eq "21cm" && [$pp getAttribute fo:page-height ""] eq "29.7cm"} "K: A4 portrait geometry"
ok {[$pp getAttribute style:print-orientation ""] eq "portrait"} "K: portrait orientation"
set ppw ""
foreach pl [[$sd documentElement] getElementsByTagName style:page-layout] {
    if {[$pl getAttribute style:name ""] eq "PMwide"} { set ppw [lindex [$pl getElementsByTagName style:page-layout-properties] 0] }
}
ok {[$ppw getAttribute style:print-orientation ""] eq "landscape"} "K: 30x20 auto-detected landscape"
$sd delete
$dKr destroy
$pK destroy

# ---- L) graphic-style resolution (slice 11, Phase 4 read) ----
set pkgL [odf::newDrawDoc]
set dL [odf::Draw new $pkgL]
# a base style (stroke) and a child that inherits and overrides the fill
$dL defineGraphicStyle base -stroke solid -stroke-color #333333 -stroke-width 0.05cm
$dL defineGraphicStyle box -parent base -fill solid -fill-color #cfe8ff
set pgL [$dL addPage "S"]
set r [$dL addRect $pgL 2cm 2cm 6cm 3cm -style box -text "X"]
set r2 [$dL addRect $pgL 10cm 2cm 6cm 3cm]    ;# no style
$dL flush
$dL destroy
set lPath [file join $out resolve.odg]
$pkgL save $lPath
$pkgL destroy

set pL [odf::Package new $lPath]
set dLr [odf::Draw new $pL]
set shL [$dLr shapes [lindex [$dLr pages] 0]]
set s0 [lindex $shL 0]
# direct properties from "box"
ok {[$dLr shapeFillColor $s0] eq "#cfe8ff"}              "L: resolved fill-color (own)"
ok {[$dLr shapeFill $s0] eq "solid"}                     "L: resolved fill"
# inherited from parent "base"
ok {[$dLr shapeStrokeColor $s0] eq "#333333"}            "L: resolved stroke-color (inherited)"
ok {[$dLr shapeStrokeWidth $s0] eq "0.05cm"}             "L: resolved stroke-width (inherited)"
# full dict has merged keys
set d [$dLr shapeStyle $s0]
ok {[dict get $d draw:fill-color] eq "#cfe8ff" && [dict get $d svg:stroke-color] eq "#333333"} "L: merged style dict"
ok {[$dLr resolveStyle base] eq [dict create draw:stroke solid svg:stroke-color #333333 svg:stroke-width 0.05cm]} "L: resolveStyle by name (base)"
# child overrides parent: give child its own stroke-color too
$dLr destroy
$pL destroy

# override precedence (child wins over parent)
set pkgL2 [odf::newDrawDoc]; set dL2 [odf::Draw new $pkgL2]
$dL2 defineGraphicStyle p -stroke-color #000000 -stroke-width 0.1cm
$dL2 defineGraphicStyle c -parent p -stroke-color #ff0000
ok {[dict get [$dL2 resolveStyle c] svg:stroke-color] eq "#ff0000"} "L: child overrides parent"
ok {[dict get [$dL2 resolveStyle c] svg:stroke-width] eq "0.1cm"}   "L: parent value kept when not overridden"
# shape without style resolves to empty
set pg2 [$dL2 addPage P]; set rn [$dL2 addRect $pg2 1cm 1cm 2cm 2cm]
ok {[$dL2 shapeStyle $rn] eq {} && [$dL2 shapeFill $rn] eq ""}       "L: unstyled shape -> empty"
$dL2 destroy; $pkgL2 destroy

# ---- M) draw:circle + svg:title/desc (slice 12) ----
set pkgM [odf::newDrawDoc]
set dM [odf::Draw new $pkgM]
set pgM [$dM addPage "CT"]
set c [$dM addCircle $pgM 5cm 5cm 3cm -style {}]
set rT [$dM addRect $pgM 10cm 2cm 6cm 3cm -text "hi"]   ;# has a text:p child
$dM setTitle $rT "My rectangle"
$dM setDesc  $rT "A longer description"
$dM setTitle $c "A circle"
# child order on rT must be title, desc, then text:p (schema order)
set order {}
foreach ch [$rT childNodes] { if {[$ch nodeType] eq "ELEMENT_NODE"} { lappend order [$ch nodeName] } }
ok {$order eq {svg:title svg:desc text:p}}             "M: title/desc precede draw:text"
$dM flush
$dM destroy
set mPath [file join $out circletitle.odg]
$pkgM save $mPath
$pkgM destroy

set pM [odf::Package new $mPath]
set dMr [odf::Draw new $pM]
set shM [$dMr shapes [lindex [$dMr pages] 0]]
ok {[$dMr shapeType [lindex $shM 0]] eq "circle"}       "M: shape0 is circle"
ok {[$dMr shapeCircle [lindex $shM 0]] eq {5cm 5cm 3cm}} "M: circle cx/cy/r"
ok {[$dMr shapeTitle [lindex $shM 0]] eq "A circle"}     "M: circle title"
ok {[$dMr shapeTitle [lindex $shM 1]] eq "My rectangle"} "M: rect title"
ok {[$dMr shapeDesc  [lindex $shM 1]] eq "A longer description"} "M: rect desc"
ok {[$dMr shapeText  [lindex $shM 1]] eq "hi"}           "M: rect text still read"
ok {[$dMr shapeTitle [lindex $shM 1]] ne "" && [$dMr shapeDesc [lindex $shM 0]] eq ""} "M: desc empty when unset"
# setTitle replaces, not duplicates
$dMr destroy
$pM destroy
set pkgM2 [odf::newDrawDoc]; set dM2 [odf::Draw new $pkgM2]
set pg [$dM2 addPage P]; set rr [$dM2 addRect $pg 1cm 1cm 2cm 2cm]
$dM2 setTitle $rr "first"; $dM2 setTitle $rr "second"
set n 0; foreach ch [$rr childNodes] { if {[$ch nodeName] eq "svg:title"} { incr n } }
ok {$n == 1 && [$dM2 shapeTitle $rr] eq "second"}        "M: setTitle replaces (no duplicate)"
$dM2 destroy; $pkgM2 destroy

# ---- N) reading a LibreOffice-style draw:custom-shape (slice 13, import) ----
# We don't write custom-shapes; build one by hand (as LO would) and read it back.
set pkgN [odf::newDrawDoc]
set dN [odf::Draw new $pkgN]
$dN defineGraphicStyle box -fill solid -fill-color #ffe0b2 -stroke solid -stroke-color #884400
set pgN [$dN addPage "Imp"]
set doc [$pgN ownerDocument]
set cs [$doc createElement draw:custom-shape]
$cs setAttribute svg:x 3cm; $cs setAttribute svg:y 3cm
$cs setAttribute svg:width 5cm; $cs setAttribute svg:height 4cm
$cs setAttribute draw:style-name box
set tp [$doc createElement text:p]
$tp appendChild [$doc createTextNode "Custom"]
$cs appendChild $tp
set eg [$doc createElement draw:enhanced-geometry]
$eg setAttribute draw:type ellipse
$eg setAttribute svg:viewBox "0 0 21600 21600"
$eg setAttribute draw:enhanced-path "U 10800 10800 10800 10800 0 360 Z N"
$cs appendChild $eg
$pgN appendChild $cs
$dN flush
$dN destroy
set nPath [file join $out customshape.odg]
$pkgN save $nPath
$pkgN destroy

set pN [odf::Package new $nPath]
set dNr [odf::Draw new $pN]
set s [lindex [$dNr shapes [lindex [$dNr pages] 0]] 0]
ok {[$dNr shapeType $s] eq "custom-shape"}              "N: enumerated as custom-shape"
ok {[$dNr shapeRect $s] eq {3cm 3cm 5cm 4cm}}           "N: bbox read"
ok {[$dNr shapeText $s] eq "Custom"}                    "N: text read"
ok {[$dNr customShapeKind $s] eq "ellipse"}             "N: enhanced-geometry kind"
ok {[$dNr customShapeViewBox $s] eq "0 0 21600 21600"}  "N: enhanced-geometry viewBox"
ok {[string match "U 10800*" [$dNr customShapePath $s]]} "N: enhanced-path read"
ok {[$dNr shapeFillColor $s] eq "#ffe0b2"}              "N: resolved fill on imported shape"
ok {[$dNr customShapeKind [lindex [$dNr shapes [lindex [$dNr pages] 0]] 0]] ne ""} "N: kind non-empty"
$dNr destroy
$pN destroy

# ---- O) rounded rects + gradient fills (slice 14) ----
set pkgO [odf::newDrawDoc]
set dO [odf::Draw new $pkgO]
$dO defineGradient sky -style linear -start-color #cfe8ff -end-color #336699 -angle 45 -border 5
$dO defineGraphicStyle grad -gradient sky -stroke solid -stroke-color #224466
set pgO [$dO addPage "RG"]
set rr [$dO addRect $pgO 2cm 2cm 6cm 3cm -style grad -corner-radius 0.5cm -text "rounded"]
ok {[catch {$dO defineGradient bad -start-color #fff}] == 1}  "O: gradient needs both colors"
$dO flush
$dO destroy
set oPath [file join $out gradient.odg]
$pkgO save $oPath
$pkgO destroy

set pO [odf::Package new $oPath]
set dOr [odf::Draw new $pO]
ok {[$dOr gradients] eq {sky}}                          "O: gradient defined in office:styles"
set s [lindex [$dOr shapes [lindex [$dOr pages] 0]] 0]
ok {[$dOr shapeCornerRadius $s] eq "0.5cm"}             "O: rect corner-radius"
ok {[$dOr shapeFill $s] eq "gradient"}                  "O: resolved fill = gradient"
# the gradient carries colors/angle/border
set sd [$pO tree styles.xml]
set g ""
foreach el [[$sd documentElement] getElementsByTagName draw:gradient] { if {[$el getAttribute draw:name ""] eq "sky"} { set g $el } }
ok {[$g getAttribute draw:start-color ""] eq "#cfe8ff" && [$g getAttribute draw:end-color ""] eq "#336699"} "O: gradient colors"
ok {[$g getAttribute draw:angle ""] eq "45deg"}         "O: gradient angle (deg)"
ok {[$g getAttribute draw:border ""] eq "5%"}           "O: gradient border (%)"
ok {[$g getAttribute draw:style ""] eq "linear"}        "O: gradient style"
$sd delete
$dOr destroy
$pO destroy

# ---- P) dashed/dotted strokes (slice 15) ----
set pkgP [odf::newDrawDoc]
set dP [odf::Draw new $pkgP]
$dP defineStrokeDash dash1 -dots1 1 -dots1-length 0.3cm -distance 0.2cm
$dP defineGraphicStyle dl  -stroke dash -stroke-dash dash1 -stroke-color #cc0000 -stroke-width 0.05cm
$dP defineGraphicStyle dl2 -dashed dash1 -stroke-color #00aa00     ;# convenience
set pgP [$dP addPage "D"]
set r1 [$dP addRect $pgP 2cm 2cm 6cm 3cm -style dl]
set r2 [$dP addRect $pgP 2cm 7cm 6cm 3cm -style dl2]
ok {[catch {$dP defineStrokeDash x -bad 1}] == 1}        "P: unknown dash option rejected"
$dP flush
$dP destroy
set pPath [file join $out dashed.odg]
$pkgP save $pPath
$pkgP destroy

set pP [odf::Package new $pPath]
set dPr [odf::Draw new $pP]
ok {[$dPr strokeDashes] eq {dash1}}                      "P: stroke-dash defined in office:styles"
set sh [$dPr shapes [lindex [$dPr pages] 0]]
set d [$dPr shapeStyle [lindex $sh 0]]
ok {[dict get $d draw:stroke] eq "dash"}                 "P: resolved stroke = dash"
ok {[dict get $d draw:stroke-dash] eq "dash1"}           "P: resolved stroke-dash ref"
set d2 [$dPr shapeStyle [lindex $sh 1]]
ok {[dict get $d2 draw:stroke] eq "dash" && [dict get $d2 draw:stroke-dash] eq "dash1"} "P: -dashed convenience"
# the dash element carries the pattern
set sd [$pP tree styles.xml]
set e ""
foreach el [[$sd documentElement] getElementsByTagName draw:stroke-dash] { if {[$el getAttribute draw:name ""] eq "dash1"} { set e $el } }
ok {[$e getAttribute draw:dots1-length ""] eq "0.3cm" && [$e getAttribute draw:distance ""] eq "0.2cm"} "P: dash pattern lengths"
ok {[$e getAttribute draw:style ""] eq "round"}          "P: dash style default round"
$sd delete
$dPr destroy
$pP destroy

# ---- Q) group conformance: layer/transform belong on members (slice 16) ----
set pkgQ [odf::newDrawDoc]
set dQ [odf::Draw new $pkgQ]
$dQ defineLayer L1
set pgQ [$dQ addPage "G"]
set grp [$dQ addGroup $pgQ -name outer]
set a [$dQ addRect $grp 1cm 1cm 3cm 2cm]
set b [$dQ addRect $grp 5cm 1cm 3cm 2cm]
set inner [$dQ addGroup $grp -name inner]
set c [$dQ addEllipse $inner 9cm 1cm 3cm 2cm]
# a group must NOT take draw:layer / draw:transform
ok {[catch {$dQ setLayer $grp L1}] == 1}              "Q: setLayer on group rejected"
ok {[catch {$dQ setTransform $grp {{rotate 10}}}] == 1} "Q: setTransform on group rejected"
# but z-index / title are fine on a group
$dQ setZIndex $grp 2
$dQ setTitle  $grp "the group"
# apply layer/transform to the members instead (recurses into nested group)
$dQ setLayerAll     $grp L1
$dQ setTransformAll $grp {{rotate 10}}
$dQ flush
$dQ destroy
set qPath [file join $out groups.odg]
$pkgQ save $qPath
$pkgQ destroy

set pQ [odf::Package new $qPath]
set dQr [odf::Draw new $pQ]
set g [lindex [$dQr shapes [lindex [$dQr pages] 0]] 0]
ok {[$dQr shapeType $g] eq "g"}                       "Q: group present"
ok {[$dQr shapeZIndex $g] eq "2"}                     "Q: group keeps z-index (valid)"
ok {[$dQr shapeTitle $g] eq "the group"}              "Q: group keeps title (valid)"
ok {[$g getAttribute draw:layer ""] eq ""}            "Q: group has NO draw:layer"
ok {[$g getAttribute draw:transform ""] eq ""}        "Q: group has NO draw:transform"
# every leaf (incl. the one in the nested group) got layer + transform
set leaves {}
proc collectLeaves {dr node varName} {
    upvar 1 $varName acc
    foreach c [$dr shapes $node] {
        if {[$dr shapeType $c] eq "g"} { collectLeaves $dr $c acc } else { lappend acc $c }
    }
}
collectLeaves $dQr $g leaves
ok {[llength $leaves] == 3}                            "Q: 3 leaf shapes (2 + 1 nested)"
set okLayer 1; set okTf 1
foreach lf $leaves {
    if {[$dQr shapeLayer $lf] ne "L1"} { set okLayer 0 }
    if {[$dQr shapeTransform $lf] ne "rotate (0.17453)"} { set okTf 0 }
}
ok {$okLayer}                                          "Q: all leaves on layer L1"
ok {$okTf}                                             "Q: all leaves transformed (incl. nested)"
$dQr destroy
$pQ destroy

# ---- R) fill/appearance family: hatch + fill-image + opacity (slice 17) ----
set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]
$d defineHatch diag -style single -color #336699 -distance 0.1cm -rotation 45
ok {[lsearch -exact [$d hatches] diag] >= 0}                "R: hatch defined / listed"
$d defineGraphicStyle hatched -hatch diag -fill-hatch-solid 1 -stroke solid -stroke-color #000000
set png [binary decode base64 iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNgAAIAAAUAAen63NgAAAAASUVORK5CYII=]
set fh [open [file join $out _px.png] wb]; fconfigure $fh -translation binary; puts -nonewline $fh $png; close $fh
$d defineFillImage tile -path [file join $out _px.png]
ok {[lsearch -exact [$d fillImages] tile] >= 0}            "R: fill-image defined / listed"
$d defineGraphicStyle tiled -bitmap tile -repeat repeat -fill-image-width 0.5cm -fill-image-height 0.5cm
$d defineGraphicStyle ghost -fill solid -fill-color #ff0000 -opacity 40 -stroke solid -stroke-color #000000 -stroke-opacity 60
set pR [$d addPage "Fills"]
$d addRect $pR 1cm  1cm 4cm 3cm -style hatched
$d addRect $pR 6cm  1cm 4cm 3cm -style tiled
$d addRect $pR 11cm 1cm 4cm 3cm -style ghost
$d flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[string match {*draw:fill="hatch"*draw:fill-hatch-name="diag"*} $xml]}   "R: hatched -> fill=hatch + hatch-name"
ok {[string match {*draw:fill-hatch-solid="true"*} $xml]}                    "R: fill-hatch-solid=true"
ok {[string match {*draw:fill="bitmap"*draw:fill-image-name="tile"*} $xml]}  "R: tiled -> fill=bitmap + image-name"
ok {[string match {*style:repeat="repeat"*} $xml]}                           "R: style:repeat"
ok {[string match {*draw:opacity="40%"*} $xml]}                              "R: draw:opacity percentage"
ok {[string match {*svg:stroke-opacity="60%"*} $xml]}                        "R: svg:stroke-opacity percentage"
set sxml [encoding convertfrom utf-8 [$pkg part styles.xml]]
ok {[string match {*<draw:hatch *draw:name="diag"*draw:style="single"*} $sxml]}        "R: draw:hatch in office:styles"
ok {[string match {*<draw:fill-image *draw:name="tile"*xlink:href="Pictures/*} $sxml]} "R: draw:fill-image in office:styles"
$pkg save [file join $out draw-fills.odg]
$d destroy; $pkg destroy

# ---- S) shadow + transparency gradient (slice 18) ----
set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]
$d defineGraphicStyle s_shadow -fill solid -fill-color #cfe8ff -stroke solid -stroke-color #336699 \
    -shadow 1 -shadow-offset-x 0.15cm -shadow-offset-y 0.15cm -shadow-color #808080 -shadow-opacity 50
$d defineTransparencyGradient fade -style linear -start 0 -end 100 -angle 90
ok {[lsearch -exact [$d transparencyGradients] fade] >= 0}    "S: transparency gradient defined / listed"
$d defineGraphicStyle s_fade -fill solid -fill-color #e8453c -opacity-name fade
set pS [$d addPage "FX"]
$d addRect $pS 1cm 1cm 5cm 3cm -style s_shadow -text "shadow"
$d addRect $pS 7cm 1cm 5cm 3cm -style s_fade   -text "fade"
$d flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[string match {*draw:shadow="visible"*} $xml]}              "S: draw:shadow=visible"
ok {[string match {*draw:shadow-offset-x="0.15cm"*} $xml]}      "S: shadow offset-x"
ok {[string match {*draw:shadow-color="#808080"*} $xml]}        "S: shadow color"
ok {[string match {*draw:shadow-opacity="50%"*} $xml]}          "S: shadow opacity %"
ok {[string match {*draw:opacity-name="fade"*} $xml]}           "S: style references transparency gradient"
set sxml [encoding convertfrom utf-8 [$pkg part styles.xml]]
ok {[string match {*<draw:opacity *draw:name="fade"*draw:start="0%"*draw:end="100%"*} $sxml]} "S: draw:opacity element in office:styles"
$pkg save [file join $out draw-fx.odg]
$d destroy; $pkg destroy

# ---- T) native shapes: measure, caption, regular-polygon (slice 17) ----
set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]
$d defineGraphicStyle gr1 -stroke solid -stroke-color #336699 -stroke-width 0.02cm
$d defineGraphicStyle gMeasure -parent gr1 \
        -measure-start-guide 0cm -measure-end-guide 0cm -measure-line-distance 0.3cm
set pT [$d addPage "Shapes"]

# Measure line from (1,1) to (6,1) -- the guide/distance properties live on the style
set m [$d addMeasure $pT 1cm 1cm 6cm 1cm -style gMeasure -name measure -text "5 cm"]
ok {[$m getAttribute svg:x1 ""]             eq "1cm"}                "T: measure x1"
ok {[$m getAttribute svg:x2 ""]             eq "6cm"}                "T: measure x2"
ok {[$m getAttribute draw:style-name ""]    eq "gMeasure"}           "T: measure references gMeasure style"
ok {[$m getAttribute draw:name ""]          eq "measure"}            "T: -name on draw:measure (via ApplyOpts)"

# Caption with a tail tip at (caption-point-x, caption-point-y)
set c [$d addCaption $pT 1cm 2cm 5cm 2cm 6.5cm 4cm \
        -style gr1 -text-style txt -name caption -text "draw:caption"]
ok {[$c getAttribute draw:caption-point-x ""] eq "6.5cm"}            "T: caption-point-x"
ok {[$c getAttribute draw:caption-point-y ""] eq "4cm"}              "T: caption-point-y"
ok {[$c getAttribute draw:text-style-name ""] eq "txt"}              "T: caption draw:text-style-name"

# Regular polygon (hexagon) -- convex
set hex [$d addRegularPolygon $pT 7cm 1cm 3cm 3cm 6 -style gr1 -name polygon6 -text "polygon"]
ok {[$hex getAttribute draw:corners ""] eq "6"}                      "T: hexagon corners=6"
ok {[$hex getAttribute draw:concave ""] eq "false"}                  "T: hexagon concave=false"

# 5-pointed star -- concave with sharpness
set star [$d addRegularPolygon $pT 11cm 1cm 3cm 3cm 5 \
        -concave 1 -sharpness 30% -style gr1 -name star5 -text "star"]
ok {[$star getAttribute draw:corners ""]   eq "5"}                   "T: star corners=5"
ok {[$star getAttribute draw:concave ""]   eq "true"}                "T: star concave=true"
ok {[$star getAttribute draw:sharpness ""] eq "30%"}                 "T: star sharpness=30%"

$d flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[string match {*<draw:measure*svg:x1="1cm"*5 cm*</draw:measure>*} $xml]} \
                                                                       "T: measure serialized with label text"
set sxml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[regexp {<style:graphic-properties[^/>]*draw:line-distance="0.3cm"[^/>]*draw:start-guide="0cm"} $sxml] \
   || [regexp {<style:graphic-properties[^/>]*draw:start-guide="0cm"[^/>]*draw:line-distance="0.3cm"} $sxml]} \
                                                                       "T: measure props on style:graphic-properties"
ok {[string match {*<draw:caption*draw:caption-point-x="6.5cm"*draw:caption-point-y="4cm"*} $xml]} \
                                                                       "T: caption serialized with tail"
ok {[regexp -all {<draw:regular-polygon} $xml] == 2}                  "T: two regular polygons"
$pkg save [file join $out draw-natives.odg]
$d destroy; $pkg destroy

# ---- U) Layers: defineLayer + -layer on shapes (slice 0.21) ----
set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]
$d defineLayer constructions -display printer
$d defineLayer notes         -protected 1
ok {[lsort [$d layers]] eq {constructions notes}}                      "U: layers reader sees both"

set pU [$d addPage "Layered"]
# Shapes pinned to layers via -layer
$d addRect    $pU 1cm 1cm 4cm 2cm -layer constructions -text "constr"
$d addEllipse $pU 6cm 1cm 4cm 2cm -layer notes         -text "notes"
$d addLine    $pU 1cm 4cm 10cm 4cm                -layer measurelines
$d flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[string match {*<draw:rect*draw:layer="constructions"*} $xml]}     "U: -layer on draw:rect"
ok {[string match {*<draw:ellipse*draw:layer="notes"*} $xml]}          "U: -layer on draw:ellipse"
ok {[string match {*<draw:line*draw:layer="measurelines"*} $xml]}      "U: -layer on draw:line (implicit LO layer, no defineLayer needed)"
set sxml [encoding convertfrom utf-8 [$pkg part styles.xml]]
ok {[regexp {<draw:layer-set>.*<draw:layer[^/>]*draw:name="constructions"[^/>]*draw:display="printer"} $sxml]} \
                                                                       "U: layer-set in styles.xml with -display=printer"
ok {[regexp {<draw:layer[^/>]*draw:name="notes"[^/>]*draw:protected="true"} $sxml]} \
                                                                       "U: -protected serialized"
$pkg save [file join $out draw-layers.odg]
$d destroy; $pkg destroy

# ---- V) Custom-Shape Registry: 10 real LO types (slice 0.22) ----
set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]
set known [$d customShapeTypes]
ok {[llength $known] == 10}                                            "V: registry holds 10 types"
foreach t {rectangle ellipse round-rectangle trapezoid right-triangle isosceles-triangle parallelogram block-arc octagon diamond} {
    ok {[lsearch -exact $known $t] >= 0}                               "V: type $t in registry"
}
set pV [$d addPage "Gallery"]
# Drop one of each, in a grid 2 cols x 5 rows, each 4cm x 3cm
set i 0
foreach t $known {
    set col [expr {$i % 2}]; set row [expr {$i / 2}]
    set xcm [expr {1 + $col * 6}]; set ycm [expr {1 + $row * 4}]
    $d addCustomShape $pV $t ${xcm}cm ${ycm}cm 4cm 3cm -text $t -name $t
    incr i
}
$d flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[regexp -all {<draw:custom-shape } $xml] == 10}                    "V: 10 custom-shapes in initial gallery"
# Each must have its enhanced-geometry with the right draw:type
foreach t $known {
    ok {[regexp "<draw:enhanced-geometry\[^/>\]*draw:type=\"$t\"" $xml]} \
                                                                       "V: enhanced-geometry for $t"
}
# Types that have equations must serialize their draw:equation children
ok {[regexp {<draw:enhanced-geometry[^>]*draw:type="trapezoid"[^>]*>.*?<draw:equation} $xml]} \
                                                                       "V: trapezoid carries its draw:equation children"
ok {[regexp {draw:modifiers="5400"} $xml]}                            "V: trapezoid default modifiers preserved (5400)"
ok {[regexp {draw:modifiers="3600"} $xml]}                            "V: round-rectangle default modifiers preserved"
# Modifier override
$d addCustomShape $pV round-rectangle 13cm 1cm 4cm 3cm -modifiers 6500 -name rr_custom
$d flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[regexp {draw:name="rr_custom"[^/>]*/>?\s*<draw:enhanced-geometry[^>]*draw:modifiers="6500"} $xml] \
   || [regexp {<draw:enhanced-geometry[^>]*draw:modifiers="6500"} $xml]} \
                                                                       "V: -modifiers override emitted"
$pkg save [file join $out draw-gallery.odg]
$d destroy; $pkg destroy

# ---- W) dr3d 3D scene (slice 0.23) ----
set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]
set pW [$d addPage "3D"]
set sc [$d add3DScene $pW 2cm 2cm 8cm 8cm]
$d add3DSphere $sc
set sc2 [$d add3DScene $pW 12cm 2cm 8cm 8cm]
$d add3DCube $sc2
$d flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[regexp -all {<dr3d:scene } $xml] == 2}                           "W: two dr3d:scenes"
ok {[regexp -all {<dr3d:light } $xml] == 16}                          "W: 8 default lights x 2 scenes = 16"
ok {[regexp {<dr3d:scene[^>]*dr3d:vrp="\(0 0 16885} $xml]}            "W: dr3d:vrp serialized"
ok {[regexp {<dr3d:scene[^>]*dr3d:projection="perspective"} $xml]}    "W: perspective projection"
ok {[regexp {<dr3d:light[^/>]*dr3d:enabled="true"} $xml]}             "W: first light enabled"
ok {[regexp -all {<dr3d:light[^/>]*dr3d:enabled="false"} $xml] == 14} "W: 7 disabled lights x 2 = 14"
ok {[regexp {<dr3d:sphere[ />]} $xml]}                                "W: dr3d:sphere"
ok {[regexp {<dr3d:cube[ />]} $xml]}                                  "W: dr3d:cube"
$pkg save [file join $out draw-3d.odg]
$d destroy; $pkg destroy

# ---- X) Tutorial annotation pattern (slice 0.24) ----
set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]
$d defineGraphicStyle gShape -fill solid -fill-color #e8f0ff -stroke solid -stroke-color #336699
$d defineGraphicStyle gMeasure -stroke solid -stroke-color #888888 \
        -measure-start-guide 0cm -measure-end-guide 0cm -measure-line-distance 0.3cm
set pX [$d addPage "Quadrat"]
set cs [$d addAnnotatedRectangle $pX 8cm 6cm 4cm 4cm "a = 4 cm" \
        -shape-style gShape -measure-style gMeasure]
ok {[$cs nodeName] eq "draw:custom-shape"}                            "X: returns the central custom-shape"
ok {[$cs getAttribute draw:layer ""] eq "layout"}                     "X: shape pinned to layout layer"
$d flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[regexp {<draw:custom-shape[^>]*svg:x="8cm"[^>]*draw:layer="layout"} $xml]} \
                                                                       "X: central shape on layout layer at correct x"
ok {[regexp -all {<draw:measure[^>]*draw:layer="measurelines"} $xml] == 4} \
                                                                       "X: 4 dimension lines on measurelines layer"
ok {[regexp {<draw:measure[^>]*svg:x1="8cm"[^>]*svg:x2="12cm"} $xml]}  "X: top/bottom horizontal measure spans x1-x2"
ok {[regexp {<draw:measure[^>]*svg:y1="6cm"[^>]*svg:y2="10cm"} $xml]}  "X: left/right vertical measure spans y1-y2"
$pkg save [file join $out draw-annotated-quadrat.odg]
$d destroy; $pkg destroy

# ---- Y) technical-drawing template bundle (slice 0.25) ----
set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]
# (A) addMasterPage convenience builder
set mp [$d addMasterPage A4Querformat -size A4 -orientation landscape \
        -display-name "A4 Querformat" -margins {2.5cm 1cm 1cm 1cm}]
ok {[$mp nodeName] eq "style:master-page"}                            "Y: addMasterPage returns master-page element"
ok {[$mp getAttribute style:name ""] eq "A4Querformat"}               "Y: master-page has the given name"
ok {[$mp getAttribute style:display-name ""] eq "A4 Querformat"}      "Y: display-name set"
ok {[$mp getAttribute style:page-layout-name ""] eq "PM_A4Querformat"} "Y: page-layout-name is wired"
ok {[lsearch -exact [$d masterPages] A4Querformat] >= 0}              "Y: masterPages reader sees it"
ok {[[$d masterPageEl A4Querformat] getAttribute style:name ""] eq "A4Querformat"} \
                                                                       "Y: masterPageEl reader works"

# (D) setPageFormat overrides the page-layout
$d setPageFormat $mp -format A3 -orientation landscape -margins {2cm 1cm 1cm 1cm}
$d flush
set sxml [encoding convertfrom utf-8 [$pkg part styles.xml]]
ok {[regexp {<style:page-layout-properties[^/>]*fo:page-width="42cm"} $sxml]} \
                                                                       "Y: setPageFormat switched to A3 (42cm width)"

# Reset back to A4 for the title-block demo
$d setPageFormat $mp -format A4 -orientation landscape -margins {2.5cm 1cm 1cm 1cm}

# Define styles for the title block
$d defineGraphicStyle gBlock -stroke solid -stroke-color #000000 -stroke-width 0.02cm
$d defineGraphicStyle gFrame -stroke none

# (B) Auto-field methods, smoke-test in content.xml first
set pY [$d addPage "TestPage" -master A4Querformat]
set r1 [$d addRect $pY 5cm 5cm 6cm 1cm -style gFrame]
# We don't have addTextInRect in this module -- create a text:p inside the
# rect manually and add a date field to it
set p [[$pY ownerDocument] createElement text:p]
$d addDateField $p -value 2026-05-27 -fixed 1 -text "27.05.2026"
$r1 appendChild $p
$d flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[regexp {<text:date[^/>]*text:date-value="2026-05-27"[^/>]*text:fixed="true"[^>]*>27.05.2026</text:date>} $xml]} \
                                                                       "Y: addDateField on content.xml text:p"
ok {[regexp {xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"} $xml]} \
                                                                       "Y: xmlns:text bound on content root"

# (C) Full title block on the master page
$d addTitleBlock $mp \
    -title    "Stromstoßschaltung" \
    -subtitle "Beispiel für einen Installationsplan" \
    -author   "ssc" \
    -date     "2026-05-27" \
    -page-number "1" \
    -shape-style gBlock \
    -frame-style gFrame
$d flush
set sxml [encoding convertfrom utf-8 [$pkg part styles.xml]]

# Border rect on backgroundobjects layer
ok {[regexp {<draw:rect[^>]*draw:layer="backgroundobjects"[^>]*svg:width="27.7cm"} $sxml]} \
                                                                       "Y: border rect on backgroundobjects layer"
# Separator line
ok {[regexp {<draw:line[^>]*draw:layer="backgroundobjects"[^>]*svg:x1="1cm"[^>]*svg:x2="28.7cm"} $sxml]} \
                                                                       "Y: separator line between drawing area and title"
# Title frame with title + subtitle. Frame y shifts up + height doubles when
# subtitle is present (0.27 behaviour so LO does not clip the second line),
# so only check the x position and that both lines are in the frame.
ok {[regexp {<draw:frame[^>]*svg:x="1cm"[^>]*?>.*?Stromstoßschaltung.*?Beispiel für einen Installationsplan} $sxml]} \
                                                                       "Y: title frame contains title + subtitle"
# Author frame with author field
ok {[regexp {<draw:frame[^>]*svg:x="14.454cm"[^>]*svg:y="18.8cm".*?<text:author-name[^>]*text:fixed="true">ssc</text:author-name>} $sxml]} \
                                                                       "Y: author frame with text:author-name field"
# Date frame
ok {[regexp {<draw:frame[^>]*svg:x="21.577cm"[^>]*svg:y="18.8cm".*?<text:date[^>]*text:date-value="2026-05-27"} $sxml]} \
                                                                       "Y: date frame with text:date field"
# Page-number frame
ok {[regexp {<draw:frame[^>]*svg:x="21.577cm"[^>]*svg:y="19.36cm".*?<text:page-number} $sxml]} \
                                                                       "Y: page-number frame with text:page-number field"
ok {[regexp {xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"} $sxml]} \
                                                                       "Y: xmlns:text bound on styles.xml root"
$pkg save [file join $out draw-titleblock.odg]
$d destroy; $pkg destroy

# ---- Z) multi-format title block (slice 0.26) ----
set pkg [odf::newDrawDoc]
set d [odf::Draw new $pkg]
# Reader: alle 6 verfügbaren Formate
set fmts [$d titleBlockFormats]
ok {[llength $fmts] == 6}                                              "Z: 6 title-block formats registered"
foreach k {A0-landscape A1-landscape A2-landscape A3-landscape A4-landscape A4-portrait} {
    ok {[lsearch -exact $fmts $k] >= 0}                                "Z: format $k registered"
}

# Eine Master-Page pro Format + Schriftfeld
$d defineGraphicStyle gBlock -stroke solid -stroke-color #000000 -stroke-width 0.02cm
$d defineGraphicStyle gFrame -stroke none

foreach fmt {A0 A1 A2 A3 A4} {
    set mp [$d addMasterPage Master_${fmt}_L -size $fmt -orientation landscape]
    # 0.27: no -shape-style / -frame-style -- let addTitleBlock supply its
    # internal styles__tb_default_outline / __tb_default_frame which are
    # written into styles.xml so LO can actually resolve them.
    $d addTitleBlock $mp -size $fmt -orientation landscape \
        -title "Format $fmt landscape" -subtitle "Multi-Format Demo" \
        -author "lib" -date "2026-05-27" -page-number "1"
    $d addPage "Page_$fmt" -master Master_${fmt}_L
}
# A4-Hochformat zusätzlich
set mpP [$d addMasterPage Master_A4_P -size A4 -orientation portrait]
$d addTitleBlock $mpP -size A4 -orientation portrait \
    -title "A4 Hochformat" -author "lib" -date "2026-05-27" -page-number "1"
$d addPage "Page_A4_P" -master Master_A4_P

$d flush
set sxml [encoding convertfrom utf-8 [$pkg part styles.xml]]

# A0-landscape: Border bei 1cm,2.5cm mit width=116.9cm
ok {[regexp {<draw:rect[^>]*svg:x="1cm"[^>]*svg:y="2.5cm"[^>]*svg:width="116.9cm"[^>]*svg:height="80.6cm"} $sxml]} \
                                                                       "Z: A0 border 116.9 x 80.6cm"
# A0 Titel bei x=77.9cm. Mit Subtitle verschiebt sich y nach oben (81.303 - 1.797 = 79.506)
ok {[regexp {<draw:frame[^>]*svg:x="77.9cm"[^>]*svg:y="79.506cm"[^>]*svg:width="19.428cm"} $sxml]} \
                                                                       "Z: A0 title frame at correct position/size (with subtitle)"

# A3-landscape: Border width=40cm
ok {[regexp {<draw:rect[^>]*svg:width="40cm"[^>]*svg:height="26.2cm"} $sxml]} \
                                                                       "Z: A3 border 40 x 26.2cm"
# A3 Titel mit Subtitle: y=26.903 - 1.797 = 25.106
ok {[regexp {<draw:frame[^>]*svg:x="1cm"[^>]*svg:y="25.106cm"[^>]*svg:width="19.428cm"} $sxml]} \
                                                                       "Z: A3 title at correct position (with subtitle)"

# A4-landscape (existing behaviour)
ok {[regexp {<draw:rect[^>]*svg:width="27.7cm"[^>]*svg:height="17.5cm"} $sxml]} \
                                                                       "Z: A4-landscape border (unchanged default)"
# A4 Titel mit Subtitle: y=18.8 - 1.2 = 17.6
ok {[regexp {<draw:frame[^>]*svg:x="1cm"[^>]*svg:y="17.6cm"[^>]*svg:width="13.454cm"} $sxml]} \
                                                                       "Z: A4-landscape title position (subtitle-aware)"

# A4-portrait
ok {[regexp {<draw:rect[^>]*svg:x="2.5cm"[^>]*svg:y="1cm"[^>]*svg:width="17.5cm"[^>]*svg:height="27.7cm"} $sxml]} \
                                                                       "Z: A4-portrait border with swapped margins"
ok {[regexp {<draw:frame[^>]*svg:x="2.5cm"[^>]*svg:y="27.5cm"[^>]*svg:width="8.5cm"} $sxml]} \
                                                                       "Z: A4-portrait title frame at bottom"

# Page-format A0 -- check the page-layout in styles.xml
ok {[regexp {<style:page-layout-properties[^/>]*fo:page-width="118.9cm"} $sxml]} \
                                                                       "Z: A0 page-layout width 118.9cm"

# Unknown format → klare Fehlermeldung
set err ""
catch {[$d addTitleBlock $mpP -size A5 -orientation landscape -title X]} err
ok {[string match {*no title-block geometry for A5-landscape*} $err]}  "Z: clear error for unknown format"

$pkg save [file join $out draw-titleblock-multi.odg]
$d destroy; $pkg destroy

puts "\nPASS $pass   FAIL $fail"
