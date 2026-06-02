## draw-0.19.tm --  ODG (OpenDocument Graphics / Drawing), slice 1..18
## 0.27: addTitleBlock LO-render fixes after first round of evidence.
##       Two real bugs visible in LO renders of draw-titleblock-multi.odg:
##       (1) The border rect rendered solid-blue (LO's default rect fill)
##       because the shape -style reference resolved to nothing: the
##       referenced style lives in content.xml (defineGraphicStyle target),
##       but addTitleBlock writes its shapes into styles.xml (master-page),
##       and styles must be in the SAME document as their referents. Fix:
##       addTitleBlock now creates an internal default border/separator
##       style '__tb_default_outline' INSIDE styles.xml on first use --
##       black 0.02cm stroke, fill=none, idempotent. Any user-supplied
##       -shape-style still overrides it but the user is responsible for
##       making sure the style exists in styles.xml in that case.
##       (2) text:date rendered as 'DD.MM.YY' (LO default short format)
##       because no number:date-style was supplied. Fix: an internal
##       '__tb_default_dateformat' is registered in styles.xml (DD.MM.YYYY)
##       and the date field automatically references it through a chart-
##       family style. Same idempotent-on-first-use pattern.
## 0.26: multi-format title block. addTitleBlock grows -size and
##       -orientation; geometries for A0..A4 landscape and A4 portrait
##       (the formats the LibreSymbols pack ships, all _03 layout pattern)
##       extracted verbatim from templates/Technische Zeichnungen/. Default
##       stays A4-landscape -- no breaking change to existing callers. A new
##       reader, titleBlockFormats, lists what is supported. The actual
##       geometry table lives in a per-instance array (TbGeom) initialised
##       in the constructor next to the custom-shape Registry.
## 0.25: technical-drawing template bundle (slices A+B+C+D), grounded
##       against the LibreSymbols extension templates (templates/Technische
##       Zeichnungen/*.otg). The pack contains 18 LO-UI A0..A4 portrait/
##       landscape templates whose master pages carry complete title blocks.
##       Five additions compose into a one-call workflow:
##       (A) addMasterPage NAME ?-size A4? ?-orientation landscape? ?-display-
##       name DN? ?-margins MS? -- convenience builder: page-layout +
##       master-page in one call. Returns the master-page DOM element so
##       further content can be appended directly. masterPageEl NAME exposes
##       lookup as a public reader.
##       (B) Auto-field helpers (addAuthorField, addDateField, addPageNumber-
##       Field, addPageCountField). Operate on any text:p, regardless of host
##       document (via [\$textP ownerDocument]), so they work both inside
##       content.xml shapes AND inside styles.xml master-page frames. Bind
##       xmlns:text on the host document root idempotently.
##       (C) addTitleBlock \$masterPage ?-title T? ?-subtitle S? ?-author A?
##       ?-date YYYY-MM-DD? ?-page-number N? ?-border 1|0? + style options.
##       Writes the LO-template title-block pattern: border rect + separator
##       line + four frames (title, author, date, page number), all on the
##       backgroundobjects layer. Reproduces the A4_Querformat_03 template
##       structure 1:1. Geometry is currently A4-landscape only -- explicit
##       intent for slice 0.25; multi-size title blocks can come later.
##       (D) setPageFormat \$masterPage ?args? -- adjusts the page-layout the
##       master-page points to (LO templates ship one page-layout per master-
##       page); simply delegates to definePageLayout under the master-page's
##       layout name.
## 0.21..0.24: four-slice batch grounded against real LO-UI Draw outputs
##       (lll pack -- handbook chapter set + geometric tutorials + installation
##       diagrams). All slices come from the same corpus, so they fit together.
## 0.21: layers (draw:layer + draw:layer-set in office:master-styles).
##       defineLayer NAME ?-protected 0|1? ?-display always|screen|printer|none?
##       creates the entry; ApplyOpts grows -layer LAYER_NAME so every shape
##       method that flows through it inherits layer support uniformly. New
##       reader: layers. The standard LO layers (layout, controls, measurelines,
##       backgroundobjects) are implicit -- no defineLayer needed, just pass
##       -layer measurelines on shapes.
## 0.22: pragmatic custom-shape registry. Across the entire lll pack only 10
##       distinct draw:type values appear in real LO-UI output -- rectangle,
##       ellipse, round-rectangle, isosceles-triangle, trapezoid, right-
##       triangle, block-arc, octagon, diamond, parallelogram. The registry
##       carries each type's actual LO enhanced-path, viewBox, draw:modifiers
##       defaults, and draw:equation children verbatim (extracted from the
##       pack). addCustomShape $page $type $x $y $w $h emits a complete LO-
##       compatible custom-shape (validator-clean, schema-correct, and shaped
##       like LO's own output). New reader: customShapeTypes.
## 0.23: dr3d 3D scene. add3DScene wraps a <dr3d:scene> with the default LO
##       8-light setup (1 enabled + 7 disabled, matching Kugel.odg / Wuerfel.
##       odg / etc.). add3DCube and add3DSphere drop the geometry into the
##       scene; both are very small in LO output (just style + layer + sane
##       defaults). Mirrors the LO Draw 'insert 3D object' UI.
## 0.24: tutorial annotation pattern. addAnnotatedRectangle reproduces the
##       LO geometry-handbook layout: central custom-shape on the layout
##       layer + four edge dimension lines on the measurelines layer + a
##       text label. Composes existing primitives (addCustomShape, addMeasure,
##       layers); ships as a usable helper plus reference for users assembling
##       their own annotated diagrams.
## 0.20: native draw shapes from the draw-ref-shapes.odg reference set.
##       New methods: addMeasure (svg:x/y/width/height + draw:start-guide /
##       end-guide / line-distance + text:p), addCaption (svg geometry + draw:
##       caption-point-x/y + draw:text-style-name + text:p), addRegularPolygon
##       (draw:corners N, draw:concave true|false, draw:sharpness PCT for
##       stars). ApplyOpts extended with -name (draw:name attribute) so all
##       shapes that go through it inherit naming uniformly. No behaviour
##       change for existing methods.
## 0.19: shadow + transparency gradient (round out appearance). defineGraphicStyle
##       gains -shadow 0|1 (draw:shadow visible|hidden), -shadow-offset-x/-y (len),
##       -shadow-color, -shadow-opacity PCT, and -opacity-name (reference a
##       transparency gradient). defineTransparencyGradient creates a draw:opacity
##       element in office:styles (-style linear|axial|radial|ellipsoid|square|
##       rectangular, -start/-end PCT opacity, -angle DEG, -border PCT, -cx/-cy).
##       Reader: transparencyGradients.
## 0.18: complete the fill/appearance family. defineHatch creates a draw:hatch
##       in office:styles (-style single|double|triple, -color, -distance,
##       -rotation DEG, -display-name); defineFillImage creates a draw:fill-image
##       (-path embeds via embedImage, or -href to an existing Pictures/ part).
##       defineGraphicStyle gains -fill-hatch-name / -hatch, -fill-hatch-solid,
##       -fill-image-name / -bitmap, -fill-image-width/-height, -repeat
##       (stretch|repeat|no-repeat), -opacity PCT (draw:opacity) and
##       -stroke-opacity PCT (svg:stroke-opacity). Readers: hatches, fillImages.
## 0.17: newDrawTemplate -- create a .otg drawing template (setMimetype).
##
## A drawing branch alongside odf::text / odf::sheet, reusing the format-neutral
## odf::Package (container) and odf::Styles (styles.xml). odf::newDrawDoc builds
## an empty drawing; class odf::Draw works on content.xml (office:drawing >
## draw:page > shapes). Independent of any consumer; odf never depends back.
##
##   set pkg [odf::newDrawDoc]
##   set d   [odf::Draw new $pkg]
##   set g   [$d defineGraphicStyle box -fill solid -fill-color #cfe8ff \
##                                       -stroke solid -stroke-color #336699]
##   set p   [$d addPage "Page 1"]
##   $d addRect    $p 2cm 2cm 6cm 3cm -style box -text "Hello"
##   $d addEllipse $p 10cm 2cm 5cm 3cm -style box
##   $d addLine    $p 2cm 7cm 15cm 7cm
##   $d flush
##   $pkg save drawing.odg
##
## Slice 1 (write): pages (addPage, default master-page valid out of the box),
## basic shapes rect/ellipse/line with svg geometry + optional graphic style +
## text label; defineGraphicStyle (fill / stroke) as a family=graphic automatic
## style in content.xml. Slice 1 (read): pages/pageName/pageCount, shapes,
## shapeType, shapeRect, shapeLine, shapeText, shapeStyleName.
## Slice 16 (conformance): a draw:g (group) does NOT carry draw:layer or
## draw:transform in ODF 1.3 (unlike normal shapes). setLayer/setTransform now
## refuse a group with a clear error; setLayerAll/setTransformAll apply to the
## member shapes (recursing through nested groups). z-index/style/title/desc
## remain valid on groups. Slice 15 (write): dashed/dotted strokes. defineStrokeDash creates a
## draw:stroke-dash in office:styles (-style rect|round, -dots1/-dots1-length,
## -dots2/-dots2-length, -distance). defineGraphicStyle gains -stroke-dash and a
## -dashed convenience (sets draw:stroke=dash). Reader: strokeDashes.
## Slice 14 (write): richer fills + rounded rects. addRect gains -corner-radius
## (draw:corner-radius). defineGradient creates a draw:gradient in office:styles
## (-style linear|axial|radial|ellipsoid|square|rectangular, -start-color,
## -end-color, -angle DEG, -border PCT, -cx/-cy PCT); defineGraphicStyle gains
## -fill-gradient-name and a -gradient convenience (sets draw:fill=gradient).
## Readers: shapeCornerRadius, gradients.
## Slice 13 (read, Phase 4 interop): expose a draw:custom-shape's geometry kind.
## LibreOffice stores most shapes as draw:custom-shape (with draw:enhanced-geometry).
## They already enumerate via shapes/shapeType ("custom-shape") with bbox/text/
## style; customShapeKind/customShapePath/customShapeViewBox now expose the
## enhanced-geometry (draw:type, draw:enhanced-path, svg:viewBox).
## Slice 12 (write+read): draw:circle (svg:cx/cy/r) and svg:title/svg:desc
## (accessibility text). Title/desc are inserted in schema order (title, then
## desc, before any draw:text). Readers: shapeCircle, shapeTitle, shapeDesc.
## Slice 11 (read, Phase 4): graphic-style resolution. defineGraphicStyle gains
## -parent (style:parent-style-name). resolveStyle merges a style's
## style:graphic-properties along the parent chain (child wins) into a dict of
## raw attribute names; shapeStyle resolves a shape's style, and shapeFill/
## shapeFillColor/shapeStroke/shapeStrokeColor/shapeStrokeWidth are conveniences.
## This is the basis for understanding drawings on read (import / interop).
## Slice 10 (fix): draw:connector requires svg:viewBox (the schema references
## common-draw-viewbox-attlist without <optional>). Both addConnector and
## connectShapes now also emit svg:viewBox (4 ints, 1/100 mm bbox of the
## endpoints) and svg:d (the routed line in viewBox coords); the editor reroutes.
## Slice 9 (write, Phase 3): master-page management, all on the styles.xml tree
## (single tree/flush -- do NOT mix with a separate odf::Styles instance).
## definePageLayout (style:page-layout in office:automatic-styles, -format/-width/
## -height/-orientation/-margins), defineDrawingPageStyle (family drawing-page for
## page background fill), defineMasterPage (style:master-page -> page-layout +
## optional background style), setPageStyle (draw:page draw:style-name). Readers:
## masterPages, masterPageLayout, masterPageStyle, pageMaster, pageStyle.
## Slice 8 (write, Phase 3): arrows (markers). defineMarker creates a draw:marker
## (name + svg:viewBox + svg:d) in office:styles; defineGraphicStyle gains
## -marker-start/-end (reference a marker), -marker-start/-end-width (length),
## -marker-start/-end-center (bool) on style:graphic-properties. Reader: markers.
## Slice 7 (write, Phase 2): z-order + layers. setZIndex sets draw:z-index
## (nonNegativeInteger); defineLayer adds a draw:layer to the draw:layer-set in
## office:master-styles (styles.xml), setLayer assigns a shape's draw:layer.
## Readers: shapeZIndex, shapeLayer, layers. Slice 6 (fix): connector targets carry xml:id AND draw:id (same value).
## ODF binds IDREF (draw:start-shape/end-shape) to the canonical xml:id; a bare
## draw:id is not an ID type, so the validator rejected the reference. LibreOffice
## writes both -- we now do too. Slice 5 (write): transforms (completes "Phase 1"). setTransform serializes
## a list of clauses into draw:transform -- {rotate DEG} {skewx DEG} {skewy DEG}
## (degrees -> radians), {translate X Y}, {scale SX SY}, {matrix a b c d e f}.
## ODF rotate is counter-clockwise about the parent origin; combine with a
## translate to place in situ. Reading: shapeTransform. Slice 4 (write): groups + connectors. addGroup returns a draw:g usable as
## the parent for further shapes (nest by passing it where a page goes).
## addConnector draws a free connector (svg:x1/y1/x2/y2); connectShapes binds a
## connector to two shapes (assigns draw:id, center-to-center fallback coords).
## Reading: connectorEnds, connectorShapes. Slice 3 (write): point/path shapes. addPolyline/addPolygon take points as
## bare numbers in -unit (default cm); the bounding box, svg:viewBox and
## draw:points (1/100 mm grid) are computed. addPath is explicit (caller gives
## the bbox + svg:viewBox + svg:d). Reading: shapePoints, shapeViewBox,
## shapePathData. Slice 2 (write): frames -- addTextBox (draw:frame > draw:text-box > text:p)
## and images (embedImage stores bytes under Pictures/ with the media type from
## the bytes; addImage places a draw:frame > draw:image; addImageFile does both).
## Reading: frameKind, shapeImage, and shapeText now also reads frame text.
## "No magic": geometry is explicit; image media type is sniffed from bytes.

package require Tcl 8.6 9
package require tdom
package require odf

namespace eval odf {}

## Empty drawing document skeleton (mirrors odf::newSheetDoc). styles.xml ships
## a default page-layout + master-page "Default" so every draw:page is valid.
proc odf::newDrawDoc {} {
    set NS_O urn:oasis:names:tc:opendocument:xmlns:office:1.0
    set mimetype "application/vnd.oasis.opendocument.graphics"
    set manifest "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<manifest:manifest xmlns:manifest=\"urn:oasis:names:tc:opendocument:xmlns:manifest:1.0\" manifest:version=\"1.3\"><manifest:file-entry manifest:full-path=\"/\" manifest:media-type=\"$mimetype\"/><manifest:file-entry manifest:full-path=\"content.xml\" manifest:media-type=\"text/xml\"/><manifest:file-entry manifest:full-path=\"styles.xml\" manifest:media-type=\"text/xml\"/><manifest:file-entry manifest:full-path=\"meta.xml\" manifest:media-type=\"text/xml\"/></manifest:manifest>"
    set content "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-content xmlns:office=\"$NS_O\" xmlns:style=\"urn:oasis:names:tc:opendocument:xmlns:style:1.0\" xmlns:text=\"urn:oasis:names:tc:opendocument:xmlns:text:1.0\" xmlns:draw=\"urn:oasis:names:tc:opendocument:xmlns:drawing:1.0\" xmlns:fo=\"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0\" xmlns:svg=\"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" office:version=\"1.3\"><office:body><office:drawing/></office:body></office:document-content>"
    set styles "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-styles xmlns:office=\"$NS_O\" xmlns:style=\"urn:oasis:names:tc:opendocument:xmlns:style:1.0\" xmlns:fo=\"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0\" xmlns:draw=\"urn:oasis:names:tc:opendocument:xmlns:drawing:1.0\" xmlns:svg=\"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0\" office:version=\"1.3\"><office:styles/><office:automatic-styles><style:page-layout style:name=\"PMdraw\"><style:page-layout-properties fo:page-width=\"29.7cm\" fo:page-height=\"21cm\" fo:margin-top=\"1cm\" fo:margin-bottom=\"1cm\" fo:margin-left=\"1cm\" fo:margin-right=\"1cm\" style:print-orientation=\"landscape\"/></style:page-layout></office:automatic-styles><office:master-styles><style:master-page style:name=\"Default\" style:page-layout-name=\"PMdraw\"/></office:master-styles></office:document-styles>"
    set meta "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-meta xmlns:office=\"$NS_O\" xmlns:meta=\"urn:oasis:names:tc:opendocument:xmlns:meta:1.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" office:version=\"1.3\"><office:meta><meta:generator>odf-tcl</meta:generator></office:meta></office:document-meta>"

    set pkg [odf::Package new]
    $pkg setpart mimetype $mimetype
    $pkg setpart META-INF/manifest.xml [encoding convertto utf-8 $manifest]
    $pkg setpart content.xml [encoding convertto utf-8 $content]
    $pkg setpart styles.xml  [encoding convertto utf-8 $styles]
    $pkg setpart meta.xml    [encoding convertto utf-8 $meta]
    return $pkg
}

oo::class create odf::Draw {
    variable Pkg Doc Body StylesDoc

    constructor {pkg} {
        set Pkg $pkg
        set Doc [$pkg tree content.xml]
        set Body [lindex [[$Doc documentElement] getElementsByTagName office:drawing] 0]
        if {$Body eq ""} { error "no office:drawing in content.xml" }
        my InitRegistry
        my InitTitleBlockGeoms
        # 0.9: auto-flush on save via Package hook registry
        $Pkg registerFlushHook [list [self] flush]
    }
    destructor {
        if {[info exists Doc] && $Doc ne ""} { $Doc delete }
        if {[info exists StylesDoc] && $StylesDoc ne ""} { $StylesDoc delete }
    }

    # ---- write ----

    # office:automatic-styles in content.xml (created before office:body).
    method AutoStylesEl {} {
        set root [$Doc documentElement]
        set el [lindex [$root getElementsByTagName office:automatic-styles] 0]
        if {$el eq ""} {
            set el [$Doc createElement office:automatic-styles]
            set body [lindex [$root getElementsByTagName office:body] 0]
            $root insertBefore $el $body
        }
        return $el
    }

    # A drawing page. -master <master-page-name> (default "Default", which the
    # skeleton ships valid). Returns the draw:page node.
    method addPage {name args} {
        set master Default
        foreach {k v} $args { switch -- $k {-master {set master $v} default {error "unknown option: $k"}} }
        set p [$Doc createElement draw:page]
        $p setAttribute draw:name $name
        $p setAttribute draw:master-page-name $master
        $Body appendChild $p
        return $p
    }

    # A family=graphic automatic style. Options:
    #   -fill none|solid        -fill-color #rrggbb
    #   -stroke none|solid      -stroke-color #rrggbb   -stroke-width <len>
    #   -text-align start|center|end|justify  (horizontal align of shape text)
    method defineHatch {name args} {
        set style single; set color ""; set distance 0.2cm; set rot 0; set dn ""
        foreach {k v} $args {
            switch -- $k {
                -style        { set style $v }
                -color        { set color $v }
                -distance     { set distance $v }
                -rotation     { set rot $v }
                -display-name { set dn $v }
                default       { error "unknown option: $k" }
            }
        }
        if {$color eq ""} { error "defineHatch needs -color" }
        set sd [my StylesDoc]; set os [my OfficeStylesEl]
        foreach h [$os getElementsByTagName draw:hatch] {
            if {[$h getAttribute draw:name ""] eq $name} { $h delete }
        }
        set h [$sd createElement draw:hatch]
        $h setAttribute draw:name $name
        if {$dn ne ""} { $h setAttribute draw:display-name $dn }
        $h setAttribute draw:style $style
        $h setAttribute draw:color $color
        $h setAttribute draw:distance $distance
        $h setAttribute draw:rotation ${rot}deg
        $os appendChild $h
        return $name
    }
    method defineFillImage {name args} {
        set path ""; set href ""; set dn ""
        foreach {k v} $args {
            switch -- $k {
                -path         { set path $v }
                -href         { set href $v }
                -display-name { set dn $v }
                default       { error "unknown option: $k" }
            }
        }
        if {$path ne ""} { set href [my embedImage $path] }
        if {$href eq ""} { error "defineFillImage needs -path or -href" }
        set sd [my StylesDoc]; set os [my OfficeStylesEl]
        # draw:fill-image uses xlink:href; styles.xml root does not bind xlink by
        # default (content.xml does) -- bind it here (idempotent).
        [$sd documentElement] setAttribute xmlns:xlink http://www.w3.org/1999/xlink
        foreach fi [$os getElementsByTagName draw:fill-image] {
            if {[$fi getAttribute draw:name ""] eq $name} { $fi delete }
        }
        set fi [$sd createElement draw:fill-image]
        $fi setAttribute draw:name $name
        if {$dn ne ""} { $fi setAttribute draw:display-name $dn }
        $fi setAttribute xlink:href $href
        $fi setAttribute xlink:type simple
        $fi setAttribute xlink:show embed
        $fi setAttribute xlink:actuate onLoad
        $os appendChild $fi
        return $name
    }
    method defineTransparencyGradient {name args} {
        set style linear; set start 0; set end 100; set angle 0; set border 0
        set cx ""; set cy ""; set dn ""
        foreach {k v} $args {
            switch -- $k {
                -style        { set style $v }
                -start        { set start $v }
                -end          { set end $v }
                -angle        { set angle $v }
                -border       { set border $v }
                -cx           { set cx $v }
                -cy           { set cy $v }
                -display-name { set dn $v }
                default       { error "unknown option: $k" }
            }
        }
        set sd [my StylesDoc]; set os [my OfficeStylesEl]
        foreach o [$os getElementsByTagName draw:opacity] {
            if {[$o getAttribute draw:name ""] eq $name} { $o delete }
        }
        set o [$sd createElement draw:opacity]
        $o setAttribute draw:name $name
        if {$dn ne ""} { $o setAttribute draw:display-name $dn }
        $o setAttribute draw:style $style
        $o setAttribute draw:start ${start}%
        $o setAttribute draw:end ${end}%
        $o setAttribute draw:angle ${angle}deg
        $o setAttribute draw:border ${border}%
        if {$cx ne ""} { $o setAttribute draw:cx ${cx}% }
        if {$cy ne ""} { $o setAttribute draw:cy ${cy}% }
        $os appendChild $o
        return $name
    }
    method defineGraphicStyle {name args} {
        set props {}; set parent ""
        foreach {k v} $args {
            switch -- $k {
                -parent      { set parent $v }
                -fill        { lappend props draw:fill $v }
                -fill-gradient-name { lappend props draw:fill-gradient-name $v }
                -gradient    { lappend props draw:fill gradient; lappend props draw:fill-gradient-name $v }
                -fill-color  { lappend props draw:fill-color $v }
                -stroke      { lappend props draw:stroke $v }
                -stroke-dash { lappend props draw:stroke-dash $v }
                -dashed      { lappend props draw:stroke dash; lappend props draw:stroke-dash $v }
                -stroke-color { lappend props svg:stroke-color $v }
                -stroke-width { lappend props svg:stroke-width $v }
                -text-align  { lappend props draw:textarea-horizontal-align $v }
                -marker-start { lappend props draw:marker-start $v }
                -marker-end   { lappend props draw:marker-end $v }
                -marker-start-width { lappend props draw:marker-start-width $v }
                -marker-end-width   { lappend props draw:marker-end-width $v }
                -marker-start-center { lappend props draw:marker-start-center [expr {$v ? "true" : "false"}] }
                -marker-end-center   { lappend props draw:marker-end-center   [expr {$v ? "true" : "false"}] }
                -fill-hatch-name   { lappend props draw:fill-hatch-name $v }
                -hatch             { lappend props draw:fill hatch; lappend props draw:fill-hatch-name $v }
                -fill-hatch-solid  { lappend props draw:fill-hatch-solid [expr {$v ? "true" : "false"}] }
                -fill-image-name   { lappend props draw:fill-image-name $v }
                -bitmap            { lappend props draw:fill bitmap; lappend props draw:fill-image-name $v }
                -fill-image-width  { lappend props draw:fill-image-width $v }
                -fill-image-height { lappend props draw:fill-image-height $v }
                -repeat            { lappend props style:repeat $v }
                -opacity           { lappend props draw:opacity ${v}% }
                -stroke-opacity    { lappend props svg:stroke-opacity ${v}% }
                -shadow            { lappend props draw:shadow [expr {$v ? "visible" : "hidden"}] }
                -shadow-offset-x   { lappend props draw:shadow-offset-x $v }
                -shadow-offset-y   { lappend props draw:shadow-offset-y $v }
                -shadow-color      { lappend props draw:shadow-color $v }
                -shadow-opacity    { lappend props draw:shadow-opacity ${v}% }
                -opacity-name      { lappend props draw:opacity-name $v }
                -measure-start-guide   { lappend props draw:start-guide   $v }
                -measure-end-guide     { lappend props draw:end-guide     $v }
                -measure-line-distance { lappend props draw:line-distance $v }
                default      { error "unknown option: $k" }
            }
        }
        set st [$Doc createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family graphic
        if {$parent ne ""} { $st setAttribute style:parent-style-name $parent }
        if {[llength $props]} {
            set pe [$Doc createElement style:graphic-properties]
            foreach {a val} $props { $pe setAttribute $a $val }
            $st appendChild $pe
        }
        [my AutoStylesEl] appendChild $st
        return $name
    }

    method Geom {el x y w h} {
        $el setAttribute svg:x $x
        $el setAttribute svg:y $y
        $el setAttribute svg:width $w
        $el setAttribute svg:height $h
    }
    method Label {el text} {
        if {$text eq ""} return
        set p [$Doc createElement text:p]
        $p appendChild [$Doc createTextNode $text]
        $el appendChild $p
    }
    method ApplyOpts {el args} {
        set style ""; set text ""; set name ""; set layer ""
        foreach {k v} $args {
            switch -- $k {
                -style { set style $v }
                -text  { set text  $v }
                -name  { set name  $v }
                -layer { set layer $v }
                default { error "unknown option: $k" }
            }
        }
        if {$style ne ""} { $el setAttribute draw:style-name $style }
        if {$name  ne ""} { $el setAttribute draw:name       $name }
        if {$layer ne ""} { $el setAttribute draw:layer      $layer }
        my Label $el $text
    }

    # draw:rect at (x,y) size w x h. ?-style S? ?-text T?
    method addRect {page x y w h args} {
        set el [$Doc createElement draw:rect]
        my Geom $el $x $y $w $h
        set rest {}
        foreach {k v} $args {
            if {$k eq "-corner-radius"} { $el setAttribute draw:corner-radius $v } else { lappend rest $k $v }
        }
        my ApplyOpts $el {*}$rest
        $page appendChild $el
        return $el
    }
    # draw:ellipse with bounding box (x,y,w,h). ?-style S? ?-text T?
    # A circle by centre + radius (svg:cx/cy/r). ?-style? ?-text?
    method addCircle {page cx cy r args} {
        set el [$Doc createElement draw:circle]
        $el setAttribute svg:cx $cx
        $el setAttribute svg:cy $cy
        $el setAttribute svg:r $r
        my ApplyOpts $el {*}$args
        $page appendChild $el
        return $el
    }
    method addEllipse {page x y w h args} {
        set el [$Doc createElement draw:ellipse]
        my Geom $el $x $y $w $h
        my ApplyOpts $el {*}$args
        $page appendChild $el
        return $el
    }
    # draw:line from (x1,y1) to (x2,y2). ?-style S?
    method addLine {page x1 y1 x2 y2 args} {
        set el [$Doc createElement draw:line]
        $el setAttribute svg:x1 $x1
        $el setAttribute svg:y1 $y1
        $el setAttribute svg:x2 $x2
        $el setAttribute svg:y2 $y2
        my ApplyOpts $el {*}$args
        $page appendChild $el
        return $el
    }

    # Compute bbox + viewBox + points (1/100 mm grid) from bare-number points
    # {x1 y1 x2 y2 ...} in <unit>. Returns a dict x/y/width/height/viewBox/points.
    method PointsGeom {points unit} {
        if {[llength $points] < 4 || [llength $points] % 2 != 0} {
            error "points need at least two x y pairs of numbers"
        }
        set scale {cm 1000 mm 100 in 2540 pt 35.28}
        if {![dict exists $scale $unit]} { error "unit must be cm/mm/in/pt: $unit" }
        set sc [dict get $scale $unit]
        set minx ""; set miny ""; set maxx ""; set maxy ""
        foreach {x y} $points {
            if {$minx eq "" || $x < $minx} { set minx $x }
            if {$maxx eq "" || $x > $maxx} { set maxx $x }
            if {$miny eq "" || $y < $miny} { set miny $y }
            if {$maxy eq "" || $y > $maxy} { set maxy $y }
        }
        set w [expr {$maxx - $minx}]; set h [expr {$maxy - $miny}]
        set vw [expr {int(round($w * $sc))}]; if {$vw < 1} { set vw 1 }
        set vh [expr {int(round($h * $sc))}]; if {$vh < 1} { set vh 1 }
        set pts {}
        foreach {x y} $points {
            lappend pts "[expr {int(round(($x - $minx) * $sc))}],[expr {int(round(($y - $miny) * $sc))}]"
        }
        return [dict create x $minx$unit y $miny$unit width $w$unit height $h$unit \
                            viewBox "0 0 $vw $vh" points [join $pts " "]]
    }
    method Poly {page tag points args} {
        set unit cm; set rest {}
        foreach {k v} $args {
            switch -- $k {
                -unit  { set unit $v }
                -style { lappend rest -style $v }
                -text  { lappend rest -text $v }
                default { error "unknown option: $k" }
            }
        }
        set g [my PointsGeom $points $unit]
        set el [$Doc createElement $tag]
        $el setAttribute svg:x [dict get $g x]
        $el setAttribute svg:y [dict get $g y]
        $el setAttribute svg:width [dict get $g width]
        $el setAttribute svg:height [dict get $g height]
        $el setAttribute svg:viewBox [dict get $g viewBox]
        $el setAttribute draw:points [dict get $g points]
        my ApplyOpts $el {*}$rest
        $page appendChild $el
        return $el
    }
    # Open point shape. points = {x1 y1 x2 y2 ...} bare numbers in -unit (cm).
    method addPolyline {page points args} { return [my Poly $page draw:polyline $points {*}$args] }
    # Closed point shape (same args as addPolyline).
    method addPolygon  {page points args} { return [my Poly $page draw:polygon  $points {*}$args] }
    # Explicit path: bounding box (x,y,w,h), svg:viewBox and svg:d (path data in
    # the viewBox coordinate system). ?-style S? ?-text T?
    method addPath {page x y w h viewBox d args} {
        set el [$Doc createElement draw:path]
        my Geom $el $x $y $w $h
        $el setAttribute svg:viewBox $viewBox
        $el setAttribute svg:d $d
        my ApplyOpts $el {*}$args
        $page appendChild $el
        return $el
    }

    # draw:frame holding a text-box. ?-style S?
    method addTextBox {page x y w h text args} {
        set el [$Doc createElement draw:frame]
        my Geom $el $x $y $w $h
        my ApplyOpts $el {*}$args
        set tb [$Doc createElement draw:text-box]
        set p [$Doc createElement text:p]
        $p appendChild [$Doc createTextNode $text]
        $tb appendChild $p
        $el appendChild $tb
        $page appendChild $el
        return $el
    }
    # Detect image kind from the leading bytes -> {ext mediatype}.
    method SniffImage {bytes} {
        binary scan $bytes H16 sig
        if {[string match 89504e47* $sig]} { return {png image/png} }
        if {[string match ffd8* $sig]}     { return {jpg image/jpeg} }
        if {[string match 47494638* $sig]} { return {gif image/gif} }
        error "unrecognized image (not PNG/JPEG/GIF)"
    }
    # Embed an image FILE under Pictures/<name>.<ext> (media type from the
    # bytes) and return its href. ?-name <base>? (default the file root name).
    method embedImage {path args} {
        set name ""
        foreach {k v} $args { switch -- $k {-name {set name $v} default {error "unknown option: $k"}} }
        set fh [open $path rb]; set bytes [read $fh]; close $fh
        lassign [my SniffImage $bytes] ext mt
        if {$name eq ""} { set name [file rootname [file tail $path]] }
        set href "Pictures/$name.$ext"
        $Pkg addpart $href $bytes $mt
        return $href
    }
    # Place an already-embedded image (href) as a draw:frame > draw:image. ?-style S?
    method addImage {page x y w h href args} {
        set el [$Doc createElement draw:frame]
        my Geom $el $x $y $w $h
        my ApplyOpts $el {*}$args
        set img [$Doc createElement draw:image]
        $img setAttribute xlink:href $href
        $img setAttribute xlink:type simple
        $img setAttribute xlink:show embed
        $img setAttribute xlink:actuate onLoad
        $el appendChild $img
        $page appendChild $el
        return $el
    }
    # Embed an image file and place it in one call. ?-name N? ?-style S?
    method addImageFile {page x y w h path args} {
        set name ""; set rest {}
        foreach {k v} $args {
            switch -- $k {
                -name  { set name $v }
                -style { lappend rest -style $v }
                default { error "unknown option: $k" }
            }
        }
        set ev {}
        if {$name ne ""} { lappend ev -name $name }
        set href [my embedImage $path {*}$ev]
        return [my addImage $page $x $y $w $h $href {*}$rest]
    }

    # A group (draw:g): returns a node usable as the parent for further shapes
    # (pass it where a page goes to nest). ?-name N?
    method addGroup {parent args} {
        set name ""
        foreach {k v} $args { switch -- $k {-name {set name $v} default {error "unknown option: $k"}} }
        set el [$Doc createElement draw:g]
        if {$name ne ""} { $el setAttribute draw:name $name }
        $parent appendChild $el
        return $el
    }

    # Split a length like "6cm" -> {6 cm}.
    method LenSplit {v} {
        if {![regexp {^(-?[0-9]*\.?[0-9]+)([a-z]*)$} $v -> num unit]} { error "bad length: $v" }
        return [list $num $unit]
    }
    # Center point {cx<unit> cy<unit>} of a box shape (svg:x/y/width/height).
    method ShapeCenter {shape} {
        foreach a {svg:x svg:y svg:width svg:height} {
            if {[$shape getAttribute $a ""] eq ""} { error "shape has no bounding box for a connector" }
        }
        lassign [my LenSplit [$shape getAttribute svg:x ""]]      x u
        lassign [my LenSplit [$shape getAttribute svg:y ""]]      y _
        lassign [my LenSplit [$shape getAttribute svg:width ""]]  w _
        lassign [my LenSplit [$shape getAttribute svg:height ""]] h _
        return [list [expr {$x + $w / 2.0}]$u [expr {$y + $h / 2.0}]$u]
    }
    # Collect existing shape IDs (xml:id and draw:id) in the document (recursive).
    method CollectIds {node varName} {
        upvar 1 $varName ids
        if {[$node nodeType] ne "ELEMENT_NODE"} return
        foreach a {xml:id draw:id} {
            set id [$node getAttribute $a ""]
            if {$id ne "" && $id ni $ids} { lappend ids $id }
        }
        foreach c [$node childNodes] { my CollectIds $c ids }
    }
    # Existing or freshly assigned unique shape ID. Sets BOTH xml:id (the
    # canonical ID the IDREF resolves against) and draw:id (LibreOffice compat).
    method ShapeId {shape} {
        set ex [$shape getAttribute xml:id ""]
        if {$ex eq ""} { set ex [$shape getAttribute draw:id ""] }
        if {$ex eq ""} {
            set ids {}; my CollectIds [$Doc documentElement] ids
            set i 1; while {"id$i" in $ids} { incr i }
            set ex "id$i"
        }
        $shape setAttribute xml:id $ex
        $shape setAttribute draw:id $ex
        return $ex
    }

    # Length -> millimetres (number).
    method ToMM {v} {
        lassign [my LenSplit $v] n u
        set f [dict get {cm 10 mm 1 in 25.4 pt 0.3528} $u]
        return [expr {$n * $f}]
    }
    # viewBox (0 0 W H, 1/100 mm) + svg:d line for a connector between two points.
    method InitRegistry {} {
        variable Registry; array set Registry {}
        set Registry(rectangle-viewBox)   {0 0 21600 21600}
        set Registry(rectangle-path)      {M 0 0 L 21600 0 21600 21600 0 21600 0 0 Z N}
        set Registry(rectangle-modifiers) {}
        set Registry(rectangle-equations) [list ]
        set Registry(ellipse-viewBox)   {0 0 21600 21600}
        set Registry(ellipse-path)      {U 10800 10800 10800 10800 0 360 Z N}
        set Registry(ellipse-modifiers) {}
        set Registry(ellipse-equations) [list ]
        set Registry(trapezoid-viewBox)   {0 0 21600 21600}
        set Registry(trapezoid-path)      {M 0 0 L 21600 0 ?f0 21600 ?f1 21600 Z N}
        set Registry(trapezoid-modifiers) {5400}
        set Registry(trapezoid-equations) [list {<draw:equation draw:name="f0" draw:formula="21600-$0 "/>} {<draw:equation draw:name="f1" draw:formula="$0 "/>} {<draw:equation draw:name="f3" draw:formula="?f2 +1750"/>} {<draw:equation draw:name="f4" draw:formula="21600-?f3 "/>} {<draw:equation draw:name="f6" draw:formula="21600-?f5 "/>}]
        set Registry(parallelogram-viewBox)   {0 0 21600 21600}
        set Registry(parallelogram-path)      {M ?f0 0 L 21600 0 ?f1 21600 0 21600 Z N}
        set Registry(parallelogram-modifiers) {7192.00088879014}
        set Registry(parallelogram-equations) [list {<draw:equation draw:name="f0" draw:formula="$0 "/>} {<draw:equation draw:name="f1" draw:formula="21600-$0 "/>} {<draw:equation draw:name="f3" draw:formula="?f2 +1750"/>} {<draw:equation draw:name="f4" draw:formula="21600-?f3 "/>} {<draw:equation draw:name="f6" draw:formula="10800+?f5 "/>} {<draw:equation draw:name="f7" draw:formula="?f0 -10800"/>} {<draw:equation draw:name="f8" draw:formula="if(?f7 ,?f13 ,0)"/>} {<draw:equation draw:name="f9" draw:formula="10800-?f5 "/>} {<draw:equation draw:name="f10" draw:formula="if(?f7 ,?f12 ,21600)"/>} {<draw:equation draw:name="f11" draw:formula="21600-?f5 "/>} {<draw:equation draw:name="f13" draw:formula="21600-?f12 "/>}]
        set Registry(right-triangle-viewBox)   {0 0 21600 21600}
        set Registry(right-triangle-path)      {M 0 0 L 21600 21600 0 21600 0 0 Z N}
        set Registry(right-triangle-modifiers) {}
        set Registry(right-triangle-equations) [list ]
        set Registry(round-rectangle-viewBox)   {0 0 21600 21600}
        set Registry(round-rectangle-path)      {M ?f7 0 X 0 ?f8 L 0 ?f9 Y ?f7 21600 L ?f10 21600 X 21600 ?f9 L 21600 ?f8 Y ?f10 0 Z N}
        set Registry(round-rectangle-modifiers) {3600}
        set Registry(round-rectangle-equations) [list {<draw:equation draw:name="f0" draw:formula="45"/>} {<draw:equation draw:name="f3" draw:formula="left+?f2 "/>} {<draw:equation draw:name="f4" draw:formula="top+?f2 "/>} {<draw:equation draw:name="f5" draw:formula="right-?f2 "/>} {<draw:equation draw:name="f6" draw:formula="bottom-?f2 "/>} {<draw:equation draw:name="f7" draw:formula="left+$0 "/>} {<draw:equation draw:name="f8" draw:formula="top+$0 "/>} {<draw:equation draw:name="f9" draw:formula="bottom-$0 "/>} {<draw:equation draw:name="f10" draw:formula="right-$0 "/>}]
        set Registry(isosceles-triangle-viewBox)   {0 0 21600 21600}
        set Registry(isosceles-triangle-path)      {M ?f0 0 L 21600 21600 0 21600 Z N}
        set Registry(isosceles-triangle-modifiers) {10800}
        set Registry(isosceles-triangle-equations) [list {<draw:equation draw:name="f0" draw:formula="$0 "/>} {<draw:equation draw:name="f2" draw:formula="?f1 +10800"/>} {<draw:equation draw:name="f4" draw:formula="?f3 +7200"/>} {<draw:equation draw:name="f5" draw:formula="21600-?f0 "/>} {<draw:equation draw:name="f7" draw:formula="21600-?f6 "/>}]
        set Registry(block-arc-viewBox)   {0 0 21600 21600}
        set Registry(block-arc-path)      {B 0 0 21600 21600 ?f4 ?f3 ?f2 ?f3 W ?f5 ?f5 ?f6 ?f6 ?f2 ?f3 ?f4 ?f3 Z N}
        set Registry(block-arc-modifiers) {180 5400}
        set Registry(block-arc-equations) [list {<draw:equation draw:name="f2" draw:formula="?f0 +10800"/>} {<draw:equation draw:name="f3" draw:formula="?f1 +10800"/>} {<draw:equation draw:name="f4" draw:formula="21600-?f2 "/>} {<draw:equation draw:name="f5" draw:formula="10800-$1 "/>} {<draw:equation draw:name="f6" draw:formula="10800+$1 "/>}]
        set Registry(octagon-viewBox)   {0 0 21600 21600}
        set Registry(octagon-path)      {M ?f0 0 L ?f2 0 21600 ?f1 21600 ?f3 ?f2 21600 ?f0 21600 0 ?f3 0 ?f1 Z N}
        set Registry(octagon-modifiers) {6326}
        set Registry(octagon-equations) [list {<draw:equation draw:name="f0" draw:formula="left+$0 "/>} {<draw:equation draw:name="f1" draw:formula="top+$0 "/>} {<draw:equation draw:name="f2" draw:formula="right-$0 "/>} {<draw:equation draw:name="f3" draw:formula="bottom-$0 "/>} {<draw:equation draw:name="f5" draw:formula="left+?f4 "/>} {<draw:equation draw:name="f6" draw:formula="top+?f4 "/>} {<draw:equation draw:name="f7" draw:formula="right-?f4 "/>} {<draw:equation draw:name="f8" draw:formula="bottom-?f4 "/>}]
        set Registry(diamond-viewBox)   {0 0 21600 21600}
        set Registry(diamond-path)      {M 10800 0 L 21600 10800 10800 21600 0 10800 10800 0 Z N}
        set Registry(diamond-modifiers) {}
        set Registry(diamond-equations) [list ]
    }

    # ---- 0.21 LAYERS ------------------------------------------------------
    # draw:layer-set lives in office:master-styles (styles.xml). Returns the
    # layer-set element, creating it on first call.
    method LayerSetEl {} {
        set ms [my MasterStylesElS]
        set ls [lindex [$ms getElementsByTagName draw:layer-set] 0]
        if {$ls eq ""} {
            set sd [my StylesDoc]
            set ls [$sd createElement draw:layer-set]
            $ms appendChild $ls
        }
        return $ls
    }
    # Define a custom layer. Schema attlist: draw:name (required), draw:protected
    # (boolean, optional), draw:display (always|screen|printer|none, optional).
    # The standard LO layers (layout, controls, measurelines, backgroundobjects)
    # are implicit and need NO defineLayer call -- they just work as -layer
    # values on shapes.
    method defineLayer {name args} {
        set protected ""; set display ""
        foreach {k v} $args {
            switch -- $k {
                -protected { set protected [expr {$v ? "true" : "false"}] }
                -display   { set display $v }
                default { error "unknown option: $k" }
            }
        }
        if {$display ne ""} {
            switch -- $display {always - screen - printer - none {}
                default { error "bad -display: $display (always|screen|printer|none)" }
            }
        }
        set sd [my StylesDoc]
        set el [$sd createElement draw:layer]
        $el setAttribute draw:name $name
        if {$protected ne ""} { $el setAttribute draw:protected $protected }
        if {$display   ne ""} { $el setAttribute draw:display   $display }
        [my LayerSetEl] appendChild $el
        return $name
    }
    method layers {} {
        set res {}
        set ms [my MasterStylesElS]
        set ls [lindex [$ms getElementsByTagName draw:layer-set] 0]
        if {$ls eq ""} { return $res }
        foreach l [$ls childNodes] {
            if {[$l nodeType] eq "ELEMENT_NODE" && [$l nodeName] eq "draw:layer"} {
                lappend res [$l getAttribute draw:name ""]
            }
        }
        return $res
    }

    # ---- 0.22 CUSTOM-SHAPE REGISTRY ---------------------------------------
    # The 10 draw:type values that real LO Draw output uses, each with the
    # actual enhanced-path/viewBox/modifiers/equation children that LO writes.
    # Pure replay of LO output -- shapes look identical to LO's own gallery
    # versions and are fully adjustable in LO Draw via their modifiers.
    method customShapeTypes {} {
        variable Registry
        set seen {}; set res {}
        foreach k [array names Registry *-path] {
            set t [string range $k 0 end-5]
            if {[lsearch -exact $seen $t] < 0} { lappend seen $t; lappend res $t }
        }
        return [lsort $res]
    }
    # addCustomShape $page $type $x $y $w $h ?-modifiers MODS? ?-style? ?-text?
    # ?-name? ?-layer?. -modifiers overrides the registry default (for adjusting
    # rounded-corner radius, trapezoid skew, etc.).
    method addCustomShape {page type x y w h args} {
        variable Registry
        if {![info exists Registry($type-path)]} {
            error "unknown custom-shape type: $type (have: [my customShapeTypes])"
        }
        set modsOverride ""; set rest {}
        foreach {k v} $args {
            switch -- $k {
                -modifiers { set modsOverride $v }
                -style - -text - -name - -layer { lappend rest $k $v }
                default { error "unknown option: $k" }
            }
        }
        set cs [$Doc createElement draw:custom-shape]
        my Geom $cs $x $y $w $h
        my ApplyOpts $cs {*}$rest
        # enhanced-geometry as child
        set eg [$Doc createElement draw:enhanced-geometry]
        $eg setAttribute svg:viewBox     $Registry($type-viewBox)
        $eg setAttribute draw:type       $type
        $eg setAttribute draw:enhanced-path $Registry($type-path)
        set mods $Registry($type-modifiers)
        if {$modsOverride ne ""} { set mods $modsOverride }
        if {$mods ne ""} { $eg setAttribute draw:modifiers $mods }
        # equations as further children (raw XML strings -- parse and append)
        foreach eqXml $Registry($type-equations) {
            set fragDoc [dom parse "<root xmlns:draw='urn:oasis:names:tc:opendocument:xmlns:drawing:1.0'>$eqXml</root>"]
            set eq [lindex [[$fragDoc documentElement] childNodes] 0]
            set imp [$Doc importNode $eq 1]
            $eg appendChild $imp
            $fragDoc delete
        }
        $cs appendChild $eg
        $page appendChild $cs
        return $cs
    }

    # ---- 0.23 3D SCENE ----------------------------------------------------
    # Default LO 8-light setup as observed in Kugel.odg/Wuerfel.odg/etc.:
    # one enabled diagonal light + seven disabled placeholders. Users can
    # mutate via DOM if they need a custom rig.
    method DefaultLights {scene} {
        # Light 0: enabled, diagonal #cccccc
        set ld [list \
            {#cccccc {(0.57735026918963 0.57735026918963 0.57735026918963)} true true} \
            {#000000 {(0 0 1)} false false} \
            {#000000 {(0 0 1)} false false} \
            {#000000 {(0 0 1)} false false} \
            {#000000 {(0 0 1)} false false} \
            {#000000 {(0 0 1)} false false} \
            {#000000 {(0 0 1)} false false} \
            {#000000 {(0 0 1)} false false}]
        foreach spec $ld {
            lassign $spec color dir enabled specular
            set l [$Doc createElement dr3d:light]
            $l setAttribute dr3d:diffuse-color $color
            $l setAttribute dr3d:direction     $dir
            $l setAttribute dr3d:enabled       $enabled
            $l setAttribute dr3d:specular      $specular
            $scene appendChild $l
        }
    }
    # add3DScene $page x y w h ?-style? ?-layer?
    # Creates a <dr3d:scene> with svg geometry + LO-standard projection /
    # camera / ambient settings and adds 8 default lights.
    # NOTE: dr3d:scene's attlist does NOT include common-draw-name-attlist,
    # so -name is not accepted here (schema-strict; LO does the same).
    method add3DScene {page x y w h args} {
        # Validate args before letting them through ApplyOpts.
        foreach {k v} $args {
            if {$k eq "-name"} { error "dr3d:scene does not accept draw:name (schema-strict)" }
        }
        # Bind xmlns:dr3d on the content root (idempotent -- repeated sets fine).
        [$Doc documentElement] setAttribute xmlns:dr3d \
            "urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"
        set sc [$Doc createElement dr3d:scene]
        my Geom $sc $x $y $w $h
        $sc setAttribute dr3d:vrp           "(0 0 16885.7142857143)"
        $sc setAttribute dr3d:vpn           "(0 0 14285.7142857143)"
        $sc setAttribute dr3d:projection    perspective
        $sc setAttribute dr3d:distance      2.6cm
        $sc setAttribute dr3d:focal-length  10cm
        $sc setAttribute dr3d:shadow-slant  0
        $sc setAttribute dr3d:shade-mode    gouraud
        $sc setAttribute dr3d:ambient-color "#666666"
        $sc setAttribute dr3d:lighting-mode false
        my DefaultLights $sc
        my ApplyOpts $sc {*}$args
        $page appendChild $sc
        return $sc
    }
    # Cube and sphere live INSIDE a scene. Both are essentially empty in LO --
    # they default to a unit volume centered at the origin. Pass -style for
    # a graphic style controlling fill / material.
    method add3DCube {scene args} {
        set el [$Doc createElement dr3d:cube]
        my ApplyOpts $el {*}$args
        $scene appendChild $el
        return $el
    }
    method add3DSphere {scene args} {
        set el [$Doc createElement dr3d:sphere]
        my ApplyOpts $el {*}$args
        $scene appendChild $el
        return $el
    }

    # ---- 0.24 ANNOTATIONS PATTERN -----------------------------------------
    # Tutorial-style annotated rectangle: the central shape on the layout
    # layer + four dimension lines on the measurelines layer + a centered
    # text label. Reproduces the layout pattern of the LO geometry handbook
    # (Quadrat.odg, Rechteck.odg, ...). Returns the central custom-shape.
    # Requires a graphic style usable for the measure (with measure-*-guide
    # / measure-line-distance properties) -- pass via -measure-style.
    method addAnnotatedRectangle {page x y w h label args} {
        set shapeStyle ""; set measureStyle ""
        foreach {k v} $args {
            switch -- $k {
                -shape-style   { set shapeStyle   $v }
                -measure-style { set measureStyle $v }
                default { error "unknown option: $k" }
            }
        }
        # central shape -- rectangle on layout layer
        set sopts [list -layer layout -text $label]
        if {$shapeStyle ne ""} { lappend sopts -style $shapeStyle }
        set cs [my addCustomShape $page rectangle $x $y $w $h {*}$sopts]
        # 4 dimension lines on the measurelines layer. Geometry: top/bottom
        # horizontal, left/right vertical, each offset 0.2cm outside the box.
        set off 0.2cm
        # Convert "Ncm" etc. to numeric cm by quick scan -- we keep the user
        # values as-is and rely on string concat for measure coordinates; this
        # works because the measure positions are computed via dom-only ops.
        # Use the same coordinate strings so units are preserved.
        # For the offsets: we drop measures placed directly at the box edges
        # (simplest correct layout); a real LO render moves them slightly out.
        set mopts {-layer measurelines}
        if {$measureStyle ne ""} { lappend mopts -style $measureStyle }
        # x1=x  y1=y  -> x2=x+w  y2=y  (top edge)
        # we let the user position graphically; numerics-as-strings cannot
        # be added safely without a unit parser. For the helper we just
        # place the measures co-linear with the edges (zero guide length).
        set X [my AddUnit $x  0];  set Y  [my AddUnit $y  0]
        set XR [my AddUnit $x $w]; set YB [my AddUnit $y $h]
        my addMeasure $page $X  $Y  $XR $Y  {*}$mopts
        my addMeasure $page $X  $YB $XR $YB {*}$mopts
        my addMeasure $page $X  $Y  $X  $YB {*}$mopts
        my addMeasure $page $XR $Y  $XR $YB {*}$mopts
        return $cs
    }
    # Helper: add a number to a coordinate string (e.g. "8.55cm" + "4cm" ->
    # "12.55cm"). Both inputs must use the same unit; if not, returns first
    # input unchanged. The unit is whatever non-digit suffix the first input
    # carries.
    method AddUnit {a b} {
        if {![regexp {^([0-9.]+)([a-zA-Z%]*)$} $a -> an au]} { return $a }
        if {![regexp {^([0-9.]+)([a-zA-Z%]*)$} $b -> bn bu]} { return $a }
        if {$au ne $bu && $bu ne ""} { return $a }
        set sum [expr {$an + $bn}]
        return "${sum}${au}"
    }

    method ConnectorGeom {x1 y1 x2 y2} {
        set ax [my ToMM $x1]; set ay [my ToMM $y1]
        set bx [my ToMM $x2]; set by [my ToMM $y2]
        set minx [expr {min($ax,$bx)}]; set miny [expr {min($ay,$by)}]
        set vw [expr {int(round((max($ax,$bx) - $minx) * 100))}]; if {$vw < 1} { set vw 1 }
        set vh [expr {int(round((max($ay,$by) - $miny) * 100))}]; if {$vh < 1} { set vh 1 }
        set sx [expr {int(round(($ax - $minx) * 100))}]; set sy [expr {int(round(($ay - $miny) * 100))}]
        set ex [expr {int(round(($bx - $minx) * 100))}]; set ey [expr {int(round(($by - $miny) * 100))}]
        return [list "0 0 $vw $vh" "M$sx $sy L$ex $ey"]
    }

    # Free connector between two explicit points. ?-type standard|lines|line|curve?
    # (default standard) ?-style S?
    # Linear measurement line from (x1,y1) to (x2,y2). Schema: svg:x1/y1/x2/y2
    # only on the element; the visual aspects (extension guides, line distance)
    # live on the referenced graphic style as style:graphic-properties (see
    # defineGraphicStyle -measure-start-guide / -measure-end-guide /
    # -measure-line-distance). Element body is text:p (the measured-value label).
    # ?-style S? ?-text T? ?-name N?
    method addMeasure {page x1 y1 x2 y2 args} {
        set el [$Doc createElement draw:measure]
        $el setAttribute svg:x1 $x1; $el setAttribute svg:y1 $y1
        $el setAttribute svg:x2 $x2; $el setAttribute svg:y2 $y2
        my ApplyOpts $el {*}$args
        $page appendChild $el
        return $el
    }

    # Speech-bubble / callout: bounding box + tail tip at (captionX, captionY).
    # Schema: svg:x/y/width/height + draw:caption-point-x/y + optional draw:text-
    # style-name (paragraph style for the body). ?-style S? ?-text T? ?-text-style P?
    # ?-name N?
    method addCaption {page x y w h captionX captionY args} {
        set textStyle ""; set rest {}
        foreach {k v} $args {
            switch -- $k {
                -text-style { set textStyle $v }
                -style - -text - -name { lappend rest $k $v }
                default { error "unknown option: $k" }
            }
        }
        set el [$Doc createElement draw:caption]
        my Geom $el $x $y $w $h
        $el setAttribute draw:caption-point-x $captionX
        $el setAttribute draw:caption-point-y $captionY
        if {$textStyle ne ""} { $el setAttribute draw:text-style-name $textStyle }
        my ApplyOpts $el {*}$rest
        $page appendChild $el
        return $el
    }

    # Regular polygon or star inscribed in the bounding box. corners is the
    # number of vertices (N>=3). -concave 1 makes it a star with the given
    # -sharpness (a percentage; the inner radius factor). Schema attributes:
    # draw:corners, draw:concave (boolean), draw:sharpness (percent).
    # ?-style S? ?-text T? ?-name N?
    method addRegularPolygon {page x y w h corners args} {
        set concave 0; set sharpness ""; set rest {}
        foreach {k v} $args {
            switch -- $k {
                -concave   { set concave   $v }
                -sharpness { set sharpness $v }
                -style - -text - -name { lappend rest $k $v }
                default { error "unknown option: $k" }
            }
        }
        set el [$Doc createElement draw:regular-polygon]
        my Geom $el $x $y $w $h
        $el setAttribute draw:corners $corners
        $el setAttribute draw:concave [expr {$concave ? "true" : "false"}]
        if {$sharpness ne ""} { $el setAttribute draw:sharpness $sharpness }
        my ApplyOpts $el {*}$rest
        $page appendChild $el
        return $el
    }

    method addConnector {page x1 y1 x2 y2 args} {
        set type standard; set rest {}
        foreach {k v} $args {
            switch -- $k {
                -type  { set type $v }
                -style { lappend rest -style $v }
                default { error "unknown option: $k" }
            }
        }
        set el [$Doc createElement draw:connector]
        $el setAttribute draw:type $type
        $el setAttribute svg:x1 $x1; $el setAttribute svg:y1 $y1
        $el setAttribute svg:x2 $x2; $el setAttribute svg:y2 $y2
        lassign [my ConnectorGeom $x1 $y1 $x2 $y2] vb d
        $el setAttribute svg:viewBox $vb; $el setAttribute svg:d $d
        my ApplyOpts $el {*}$rest
        $page appendChild $el
        return $el
    }
    # Connector bound to two shapes: assigns draw:id to each (if needed), sets
    # draw:start-shape/end-shape, and center-to-center fallback coordinates that
    # the editor reroutes. ?-type? ?-style? ?-start-glue G? ?-end-glue G?
    method connectShapes {page start end args} {
        set type standard; set rest {}; set sg ""; set eg ""
        foreach {k v} $args {
            switch -- $k {
                -type       { set type $v }
                -style      { lappend rest -style $v }
                -start-glue { set sg $v }
                -end-glue   { set eg $v }
                default     { error "unknown option: $k" }
            }
        }
        set sid [my ShapeId $start]; set eid [my ShapeId $end]
        lassign [my ShapeCenter $start] sx sy
        lassign [my ShapeCenter $end]   ex ey
        set el [$Doc createElement draw:connector]
        $el setAttribute draw:type $type
        $el setAttribute draw:start-shape $sid
        $el setAttribute draw:end-shape $eid
        if {$sg ne ""} { $el setAttribute draw:start-glue-point $sg }
        if {$eg ne ""} { $el setAttribute draw:end-glue-point $eg }
        $el setAttribute svg:x1 $sx; $el setAttribute svg:y1 $sy
        $el setAttribute svg:x2 $ex; $el setAttribute svg:y2 $ey
        lassign [my ConnectorGeom $sx $sy $ex $ey] vb d
        $el setAttribute svg:viewBox $vb; $el setAttribute svg:d $d
        my ApplyOpts $el {*}$rest
        $page appendChild $el
        return $el
    }

    # ---- transforms ----
    method IsGroup {shape} { return [expr {[$shape nodeName] eq "draw:g"}] }
    method Deg2Rad {deg} { return [format %.5f [expr {$deg * acos(-1) / 180.0}]] }
    method TransformClause {clause} {
        set op [lindex $clause 0]; set a [lrange $clause 1 end]
        switch -- $op {
            rotate    { return "rotate ([my Deg2Rad [lindex $a 0]])" }
            skewx     { return "skewX ([my Deg2Rad [lindex $a 0]])" }
            skewy     { return "skewY ([my Deg2Rad [lindex $a 0]])" }
            translate { return "translate ([lindex $a 0] [lindex $a 1])" }
            scale     { return "scale ([lindex $a 0] [lindex $a 1])" }
            matrix    { return "matrix ([join $a { }])" }
            default   { error "unknown transform op: $op (rotate/translate/scale/skewx/skewy/matrix)" }
        }
    }
    # Set draw:transform from a list of clauses, applied in the given order.
    # Angles in degrees (rotate/skewx/skewy) are converted to radians.
    method setTransform {shape ops} {
        if {[my IsGroup $shape]} { error "a draw:g (group) cannot carry draw:transform in ODF 1.3; transform the member shapes instead (setTransformAll)" }
        set parts {}
        foreach c $ops { lappend parts [my TransformClause $c] }
        $shape setAttribute draw:transform [join $parts " "]
        return $shape
    }

    # ---- z-order ----
    method setZIndex {shape n} {
        if {![string is integer -strict $n] || $n < 0} { error "z-index must be a non-negative integer: $n" }
        $shape setAttribute draw:z-index $n
        return $shape
    }

    # ---- layers (draw:layer-set in office:master-styles, styles.xml) ----
    method StylesDoc {} {
        if {![info exists StylesDoc] || $StylesDoc eq ""} { set StylesDoc [$Pkg tree styles.xml] }
        return $StylesDoc
    }
    method LayerSetEl {} {
        set sd [my StylesDoc]
        set ms [lindex [[$sd documentElement] getElementsByTagName office:master-styles] 0]
        if {$ms eq ""} { error "no office:master-styles in styles.xml" }
        set ls [lindex [$ms getElementsByTagName draw:layer-set] 0]
        if {$ls eq ""} { set ls [$sd createElement draw:layer-set]; $ms appendChild $ls }
        return $ls
    }
    # Define a drawing layer. ?-display always|screen|printer|none? ?-protected 0/1?
    method defineLayer {name args} {
        set display ""; set protected ""
        foreach {k v} $args {
            switch -- $k {
                -display   { set display $v }
                -protected { set protected $v }
                default    { error "unknown option: $k" }
            }
        }
        set sd [my StylesDoc]
        set ls [my LayerSetEl]
        foreach l [$ls getElementsByTagName draw:layer] {
            if {[$l getAttribute draw:name ""] eq $name} { $l delete }
        }
        set l [$sd createElement draw:layer]
        $l setAttribute draw:name $name
        if {$protected ne ""} { $l setAttribute draw:protected [expr {$protected ? "true" : "false"}] }
        if {$display ne ""}   { $l setAttribute draw:display $display }
        $ls appendChild $l
        return $name
    }
    # Assign a shape to a layer (by name).
    method setLayer {shape name} {
        if {[my IsGroup $shape]} { error "a draw:g (group) cannot carry draw:layer; apply it to the member shapes instead (setLayerAll)" }
        $shape setAttribute draw:layer $name; return $shape
    }
    # All non-group shapes inside a group (recurses through nested groups).
    method GroupLeaves {node} {
        set r {}
        foreach c [$node childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE"} continue
            if {![string match draw:* [$c nodeName]]} continue
            if {[my IsGroup $c]} { lappend r {*}[my GroupLeaves $c] } else { lappend r $c }
        }
        return $r
    }
    # Assign a layer to every member shape of a group (groups can't carry one).
    method setLayerAll {group name} {
        foreach s [my GroupLeaves $group] { my setLayer $s $name }
        return $group
    }
    # Apply a transform to every member shape of a group (overwrites each one's).
    method setTransformAll {group ops} {
        foreach s [my GroupLeaves $group] { my setTransform $s $ops }
        return $group
    }

    # ---- markers (arrowheads), in office:styles of styles.xml ----
    method OfficeStylesEl {} {
        set sd [my StylesDoc]
        set os [lindex [[$sd documentElement] getElementsByTagName office:styles] 0]
        if {$os eq ""} { error "no office:styles in styles.xml" }
        return $os
    }
    # A draw:marker (arrowhead): name + svg:viewBox + svg:d (path in the viewBox).
    # Referenced from a graphic style via -marker-start/-end. ?-display-name DN?
    method defineMarker {name viewBox d args} {
        set dn ""
        foreach {k v} $args { switch -- $k {-display-name {set dn $v} default {error "unknown option: $k"}} }
        set sd [my StylesDoc]
        set os [my OfficeStylesEl]
        foreach m [$os getElementsByTagName draw:marker] {
            if {[$m getAttribute draw:name ""] eq $name} { $m delete }
        }
        set m [$sd createElement draw:marker]
        $m setAttribute draw:name $name
        if {$dn ne ""} { $m setAttribute draw:display-name $dn }
        $m setAttribute svg:viewBox $viewBox
        $m setAttribute svg:d $d
        $os appendChild $m
        return $name
    }

    # A draw:gradient in office:styles (styles.xml). Referenced by a graphic
    # style via -gradient/-fill-gradient-name. Required: -start-color/-end-color.
    # -style linear|axial|radial|ellipsoid|square|rectangular (default linear);
    # -angle DEG (default 0); -border PCT int (default 0); -cx/-cy PCT int.
    method defineGradient {name args} {
        set style linear; set sc ""; set ec ""; set angle 0; set border 0
        set cx ""; set cy ""; set dn ""; set si 100; set ei 100
        foreach {k v} $args {
            switch -- $k {
                -style          { set style $v }
                -start-color    { set sc $v }
                -end-color      { set ec $v }
                -angle          { set angle $v }
                -border         { set border $v }
                -cx             { set cx $v }
                -cy             { set cy $v }
                -start-intensity { set si $v }
                -end-intensity   { set ei $v }
                -display-name   { set dn $v }
                default         { error "unknown option: $k" }
            }
        }
        if {$sc eq "" || $ec eq ""} { error "defineGradient needs -start-color and -end-color" }
        set sd [my StylesDoc]; set os [my OfficeStylesEl]
        foreach g [$os getElementsByTagName draw:gradient] {
            if {[$g getAttribute draw:name ""] eq $name} { $g delete }
        }
        set g [$sd createElement draw:gradient]
        $g setAttribute draw:name $name
        if {$dn ne ""} { $g setAttribute draw:display-name $dn }
        $g setAttribute draw:style $style
        $g setAttribute draw:start-color $sc
        $g setAttribute draw:end-color $ec
        $g setAttribute draw:start-intensity ${si}%
        $g setAttribute draw:end-intensity ${ei}%
        $g setAttribute draw:angle ${angle}deg
        $g setAttribute draw:border ${border}%
        if {$cx ne ""} { $g setAttribute draw:cx ${cx}% }
        if {$cy ne ""} { $g setAttribute draw:cy ${cy}% }
        $os appendChild $g
        return $name
    }

    # A draw:stroke-dash in office:styles (dash/dot pattern). -style rect|round
    # (default round); -dots1 N (count, default 1) with optional -dots1-length L;
    # optional -dots2 N / -dots2-length L; -distance L (gap, default 0.2cm).
    method defineStrokeDash {name args} {
        set style round; set dots1 1; set d1len ""; set dots2 ""; set d2len ""
        set distance 0.2cm; set dn ""
        foreach {k v} $args {
            switch -- $k {
                -style        { set style $v }
                -dots1        { set dots1 $v }
                -dots1-length { set d1len $v }
                -dots2        { set dots2 $v }
                -dots2-length { set d2len $v }
                -distance     { set distance $v }
                -display-name { set dn $v }
                default       { error "unknown option: $k" }
            }
        }
        set sd [my StylesDoc]; set os [my OfficeStylesEl]
        foreach e [$os getElementsByTagName draw:stroke-dash] {
            if {[$e getAttribute draw:name ""] eq $name} { $e delete }
        }
        set e [$sd createElement draw:stroke-dash]
        $e setAttribute draw:name $name
        if {$dn ne ""} { $e setAttribute draw:display-name $dn }
        $e setAttribute draw:style $style
        $e setAttribute draw:dots1 $dots1
        if {$d1len ne ""} { $e setAttribute draw:dots1-length $d1len }
        if {$dots2 ne ""} { $e setAttribute draw:dots2 $dots2 }
        if {$d2len ne ""} { $e setAttribute draw:dots2-length $d2len }
        $e setAttribute draw:distance $distance
        $os appendChild $e
        return $name
    }

    # ---- master pages / page layouts (all on styles.xml) ----
    method AutoStylesElS {} {
        set sd [my StylesDoc]
        set el [lindex [[$sd documentElement] getElementsByTagName office:automatic-styles] 0]
        if {$el eq ""} { error "no office:automatic-styles in styles.xml" }
        return $el
    }
    method MasterStylesElS {} {
        set sd [my StylesDoc]
        set el [lindex [[$sd documentElement] getElementsByTagName office:master-styles] 0]
        if {$el eq ""} { error "no office:master-styles in styles.xml" }
        return $el
    }
    method PaperSize {fmt} {
        set t {A0 {84.1cm 118.9cm} A1 {59.4cm 84.1cm} A2 {42cm 59.4cm} \
               A3 {29.7cm 42cm} A4 {21cm 29.7cm} A5 {14.8cm 21cm} \
               Letter {21.59cm 27.94cm} Legal {21.59cm 35.56cm}}
        if {![dict exists $t $fmt]} { error "unknown format: $fmt (A0/A1/A2/A3/A4/A5/Letter/Legal)" }
        return [dict get $t $fmt]
    }
    method Orient {w h orient} {
        lassign [my LenSplit $w] wn _u1
        lassign [my LenSplit $h] hn _u2
        if {$orient eq ""} {
            set orient [expr {$wn >= $hn ? "landscape" : "portrait"}]
        } else {
            if {$orient eq "landscape" && $wn < $hn} { set t $w; set w $h; set h $t }
            if {$orient eq "portrait"  && $wn > $hn} { set t $w; set w $h; set h $t }
        }
        return [list $w $h $orient]
    }
    # Define a page layout. -format A4/A3/A5/Letter/Legal OR -width L -height L;
    # -orientation portrait|landscape; -margin L or -margins {top right bottom left}.
    method definePageLayout {name args} {
        set width ""; set height ""; set fmt ""; set orient ""; set margins {1cm 1cm 1cm 1cm}
        foreach {k v} $args {
            switch -- $k {
                -format      { set fmt $v }
                -width       { set width $v }
                -height      { set height $v }
                -orientation { set orient $v }
                -margin      { set margins [list $v $v $v $v] }
                -margins     { set margins $v }
                default      { error "unknown option: $k" }
            }
        }
        if {$fmt ne ""} { lassign [my PaperSize $fmt] width height }
        if {$width eq "" || $height eq ""} { error "definePageLayout needs -format or -width/-height" }
        lassign [my Orient $width $height $orient] width height orient
        set sd [my StylesDoc]; set as [my AutoStylesElS]
        foreach pl [$as getElementsByTagName style:page-layout] {
            if {[$pl getAttribute style:name ""] eq $name} { $pl delete }
        }
        set pl [$sd createElement style:page-layout]
        $pl setAttribute style:name $name
        set pp [$sd createElement style:page-layout-properties]
        $pp setAttribute fo:page-width $width
        $pp setAttribute fo:page-height $height
        lassign $margins mt mr mb ml
        $pp setAttribute fo:margin-top $mt
        $pp setAttribute fo:margin-right $mr
        $pp setAttribute fo:margin-bottom $mb
        $pp setAttribute fo:margin-left $ml
        $pp setAttribute style:print-orientation $orient
        $pl appendChild $pp
        $as appendChild $pl
        return $name
    }
    # Define a drawing-page style (page background). -fill none|solid, -fill-color C.
    method defineDrawingPageStyle {name args} {
        set fill none; set fillcolor ""
        foreach {k v} $args {
            switch -- $k {
                -fill       { set fill $v }
                -fill-color { set fillcolor $v }
                default     { error "unknown option: $k" }
            }
        }
        set sd [my StylesDoc]; set os [my OfficeStylesEl]
        foreach st [$os getElementsByTagName style:style] {
            if {[$st getAttribute style:name ""] eq $name && [$st getAttribute style:family ""] eq "drawing-page"} { $st delete }
        }
        set st [$sd createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family drawing-page
        set pr [$sd createElement style:drawing-page-properties]
        $pr setAttribute draw:fill $fill
        if {$fillcolor ne ""} { $pr setAttribute draw:fill-color $fillcolor }
        $st appendChild $pr
        $os appendChild $st
        return $name
    }
    # Define a master page. -pagelayout L (default PMdraw), -style S (drawing-page
    # background style), -display-name DN.
    method defineMasterPage {name args} {
        set pagelayout PMdraw; set style ""; set dn ""
        foreach {k v} $args {
            switch -- $k {
                -pagelayout   { set pagelayout $v }
                -style        { set style $v }
                -display-name { set dn $v }
                default       { error "unknown option: $k" }
            }
        }
        set sd [my StylesDoc]; set ms [my MasterStylesElS]
        foreach mp [$ms getElementsByTagName style:master-page] {
            if {[$mp getAttribute style:name ""] eq $name} { $mp delete }
        }
        set mp [$sd createElement style:master-page]
        $mp setAttribute style:name $name
        $mp setAttribute style:page-layout-name $pagelayout
        if {$style ne ""} { $mp setAttribute draw:style-name $style }
        if {$dn ne ""}    { $mp setAttribute style:display-name $dn }
        $ms appendChild $mp
        return $name
    }
    # Set a draw:page background (drawing-page style by name).
    method setPageStyle {page name} { $page setAttribute draw:style-name $name; return $page }

    # ---- graphic-style resolution (read) ----
    # Find a family="graphic" style:style by name, in content automatic-styles
    # first, then styles.xml (office:styles / automatic-styles).
    method GraphicStyleEl {name} {
        foreach root [list $Doc [my StylesDoc]] {
            foreach st [[$root documentElement] getElementsByTagName style:style] {
                if {[$st getAttribute style:name ""] eq $name &&
                    [$st getAttribute style:family ""] eq "graphic"} { return $st }
            }
        }
        return ""
    }
    # Raw style:graphic-properties attributes of one style:style node, as a dict.
    method GraphicProps {st} {
        set gp [lindex [$st getElementsByTagName style:graphic-properties] 0]
        set d {}
        if {$gp eq ""} { return $d }
        foreach a [$gp attributes] {
            if {[llength $a] == 3} {
                lassign $a ln px uri
                if {$uri eq ""} continue   ;# xmlns declaration, skip
                set full "$px:$ln"
            } else { set full $a }
            dict set d $full [$gp getAttribute $full ""]
        }
        return $d
    }
    # Resolve a graphic style by name into a merged property dict, following
    # style:parent-style-name (child overrides parent). {} if not found.
    method resolveStyle {name} {
        set merged {}; set seen {}
        while {$name ne "" && $name ni $seen} {
            lappend seen $name
            set st [my GraphicStyleEl $name]
            if {$st eq ""} break
            # parent first, so child (set later) wins
            set parentProps {}
            set parent [$st getAttribute style:parent-style-name ""]
            set here [my GraphicProps $st]
            # walk up: collect this node, then continue loop with parent
            set merged [dict merge $here $merged]
            set name $parent
        }
        return $merged
    }
    # Resolved property dict of a shape's own draw:style-name ({} if none).
    method shapeStyle {shape} {
        set n [$shape getAttribute draw:style-name ""]
        if {$n eq ""} { return {} }
        return [my resolveStyle $n]
    }
    method ShapeProp {shape key} {
        set d [my shapeStyle $shape]
        return [expr {[dict exists $d $key] ? [dict get $d $key] : ""}]
    }
    method shapeFill        {shape} { return [my ShapeProp $shape draw:fill] }
    method shapeFillColor   {shape} { return [my ShapeProp $shape draw:fill-color] }
    method shapeStroke      {shape} { return [my ShapeProp $shape draw:stroke] }
    method shapeStrokeColor {shape} { return [my ShapeProp $shape svg:stroke-color] }
    method shapeStrokeWidth {shape} { return [my ShapeProp $shape svg:stroke-width] }

    # ---- title / description (svg:title, svg:desc) ----
    method DirectChild {parent tag} {
        foreach c [$parent childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq $tag} { return $c }
        }
        return ""
    }
    # Set svg:title (accessibility name). Inserted as the first child so the
    # schema order title -> desc -> ... -> draw:text holds.
    method setTitle {shape text} {
        set ex [my DirectChild $shape svg:title]
        if {$ex ne ""} { $ex delete }
        set el [$Doc createElement svg:title]
        $el appendChild [$Doc createTextNode $text]
        set first [lindex [$shape childNodes] 0]
        if {$first eq ""} { $shape appendChild $el } else { $shape insertBefore $el $first }
        return $shape
    }
    # Set svg:desc (long description). Inserted right after svg:title if present.
    method setDesc {shape text} {
        set ex [my DirectChild $shape svg:desc]
        if {$ex ne ""} { $ex delete }
        set el [$Doc createElement svg:desc]
        $el appendChild [$Doc createTextNode $text]
        set title [my DirectChild $shape svg:title]
        if {$title ne ""} {
            set next [$title nextSibling]
            if {$next eq ""} { $shape appendChild $el } else { $shape insertBefore $el $next }
        } else {
            set first [lindex [$shape childNodes] 0]
            if {$first eq ""} { $shape appendChild $el } else { $shape insertBefore $el $first }
        }
        return $shape
    }

    # ---- read ----

    method pages {} {
        set r {}
        foreach p [$Body childNodes] {
            if {[$p nodeType] eq "ELEMENT_NODE" && [$p nodeName] eq "draw:page"} { lappend r $p }
        }
        return $r
    }
    method pageName {page} { return [$page getAttribute draw:name ""] }
    method pageCount {} { return [llength [my pages]] }

    # Shape nodes of a page: child elements in the draw: namespace.
    method shapes {page} {
        set r {}
        foreach s [$page childNodes] {
            if {[$s nodeType] eq "ELEMENT_NODE" && [string match draw:* [$s nodeName]]} { lappend r $s }
        }
        return $r
    }
    # Local shape name without the draw: prefix (rect/ellipse/line/...).
    method shapeType {shape} { return [string range [$shape nodeName] 5 end] }
    method shapeStyleName {shape} { return [$shape getAttribute draw:style-name ""] }
    # {x y width height} from the svg geometry; "" attrs stay "".
    method shapeRect {shape} {
        return [list [$shape getAttribute svg:x ""] [$shape getAttribute svg:y ""] \
                     [$shape getAttribute svg:width ""] [$shape getAttribute svg:height ""]]
    }
    method shapeCornerRadius {shape} { return [$shape getAttribute draw:corner-radius ""] }
    # {x1 y1 x2 y2} for a line.
    # {cx cy r} of a draw:circle.
    method shapeCircle {shape} {
        return [list [$shape getAttribute svg:cx ""] [$shape getAttribute svg:cy ""] [$shape getAttribute svg:r ""]]
    }
    # svg:title / svg:desc text of a shape ("" if none).
    method shapeTitle {shape} { set t [my DirectChild $shape svg:title]; expr {$t eq "" ? "" : [$t text]} }
    method shapeDesc  {shape} { set d [my DirectChild $shape svg:desc];  expr {$d eq "" ? "" : [$d text]} }
    # draw:custom-shape geometry (LibreOffice import): the draw:enhanced-geometry
    # child holds draw:type (e.g. rectangle/ellipse/round-rectangle/non-primitive),
    # draw:enhanced-path and its own svg:viewBox. "" if not a custom-shape.
    method EnhancedGeometryEl {shape} { return [my DirectChild $shape draw:enhanced-geometry] }
    method customShapeKind    {shape} { set e [my EnhancedGeometryEl $shape]; expr {$e eq "" ? "" : [$e getAttribute draw:type ""]} }
    method customShapePath    {shape} { set e [my EnhancedGeometryEl $shape]; expr {$e eq "" ? "" : [$e getAttribute draw:enhanced-path ""]} }
    method customShapeViewBox {shape} { set e [my EnhancedGeometryEl $shape]; expr {$e eq "" ? "" : [$e getAttribute svg:viewBox ""]} }
    method shapeLine {shape} {
        return [list [$shape getAttribute svg:x1 ""] [$shape getAttribute svg:y1 ""] \
                     [$shape getAttribute svg:x2 ""] [$shape getAttribute svg:y2 ""]]
    }
    # Point list (draw:points) of a polyline/polygon; svg:viewBox; svg:d of a path.
    method shapePoints {shape}   { return [$shape getAttribute draw:points ""] }
    method shapeViewBox {shape}  { return [$shape getAttribute svg:viewBox ""] }
    method shapePathData {shape} { return [$shape getAttribute svg:d ""] }
    # Raw draw:transform string of a shape; "" if none.
    method shapeTransform {shape} { return [$shape getAttribute draw:transform ""] }
    method shapeZIndex {shape} { return [$shape getAttribute draw:z-index ""] }
    method shapeLayer {shape}  { return [$shape getAttribute draw:layer ""] }
    # Defined layer names (from draw:layer-set in styles.xml), in document order.
    method layers {} {
        set sd [my StylesDoc]
        set ms [lindex [[$sd documentElement] getElementsByTagName office:master-styles] 0]
        if {$ms eq ""} { return {} }
        set ls [lindex [$ms getElementsByTagName draw:layer-set] 0]
        if {$ls eq ""} { return {} }
        set r {}
        foreach l [$ls getElementsByTagName draw:layer] { lappend r [$l getAttribute draw:name ""] }
        return $r
    }
    # Defined marker (arrowhead) names from office:styles, in document order.
    method markers {} {
        set os [lindex [[[my StylesDoc] documentElement] getElementsByTagName office:styles] 0]
        if {$os eq ""} { return {} }
        set r {}
        foreach m [$os getElementsByTagName draw:marker] { lappend r [$m getAttribute draw:name ""] }
        return $r
    }
    # Defined gradient names from office:styles, in document order.
    method transparencyGradients {} {
        set os [lindex [[[my StylesDoc] documentElement] getElementsByTagName office:styles] 0]
        if {$os eq ""} { return {} }
        set r {}
        foreach o [$os getElementsByTagName draw:opacity] { lappend r [$o getAttribute draw:name ""] }
        return $r
    }
    method hatches {} {
        set os [lindex [[[my StylesDoc] documentElement] getElementsByTagName office:styles] 0]
        if {$os eq ""} { return {} }
        set r {}
        foreach h [$os getElementsByTagName draw:hatch] { lappend r [$h getAttribute draw:name ""] }
        return $r
    }
    method fillImages {} {
        set os [lindex [[[my StylesDoc] documentElement] getElementsByTagName office:styles] 0]
        if {$os eq ""} { return {} }
        set r {}
        foreach fi [$os getElementsByTagName draw:fill-image] { lappend r [$fi getAttribute draw:name ""] }
        return $r
    }
    method gradients {} {
        set os [lindex [[[my StylesDoc] documentElement] getElementsByTagName office:styles] 0]
        if {$os eq ""} { return {} }
        set r {}
        foreach g [$os getElementsByTagName draw:gradient] { lappend r [$g getAttribute draw:name ""] }
        return $r
    }
    # Defined stroke-dash names from office:styles, in document order.
    method strokeDashes {} {
        set os [lindex [[[my StylesDoc] documentElement] getElementsByTagName office:styles] 0]
        if {$os eq ""} { return {} }
        set r {}
        foreach e [$os getElementsByTagName draw:stroke-dash] { lappend r [$e getAttribute draw:name ""] }
        return $r
    }
    # Master-page names (office:master-styles), in document order.
    method masterPages {} {
        set ms [lindex [[[my StylesDoc] documentElement] getElementsByTagName office:master-styles] 0]
        if {$ms eq ""} { return {} }
        set r {}
        foreach mp [$ms getElementsByTagName style:master-page] { lappend r [$mp getAttribute style:name ""] }
        return $r
    }
    method MasterPageEl {name} {
        set ms [lindex [[[my StylesDoc] documentElement] getElementsByTagName office:master-styles] 0]
        if {$ms eq ""} { return "" }
        foreach mp [$ms getElementsByTagName style:master-page] {
            if {[$mp getAttribute style:name ""] eq $name} { return $mp }
        }
        return ""
    }
    method masterPageLayout {name} { set mp [my MasterPageEl $name]; expr {$mp eq "" ? "" : [$mp getAttribute style:page-layout-name ""]} }
    method masterPageStyle  {name} { set mp [my MasterPageEl $name]; expr {$mp eq "" ? "" : [$mp getAttribute draw:style-name ""]} }
    method pageMaster {page} { return [$page getAttribute draw:master-page-name ""] }
    method pageStyle  {page} { return [$page getAttribute draw:style-name ""] }
    # {x1 y1 x2 y2} of a connector (svg endpoints).
    method connectorEnds {shape} {
        return [list [$shape getAttribute svg:x1 ""] [$shape getAttribute svg:y1 ""] \
                     [$shape getAttribute svg:x2 ""] [$shape getAttribute svg:y2 ""]]
    }
    # {startId endId} of a bound connector (draw:start-shape/end-shape); "" if free.
    method connectorShapes {shape} {
        return [list [$shape getAttribute draw:start-shape ""] [$shape getAttribute draw:end-shape ""]]
    }
    # Text label: direct text:p (rect/ellipse) or, for a draw:frame, the text:p
    # inside its draw:text-box. Joined by newline.
    method shapeText {shape} {
        set node $shape
        if {[$shape nodeName] eq "draw:frame"} {
            set tb [lindex [$shape getElementsByTagName draw:text-box] 0]
            if {$tb eq ""} { return "" }
            set node $tb
        }
        set ps {}
        foreach c [$node childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:p"} { lappend ps [$c asText] }
        }
        return [join $ps "\n"]
    }
    # For a draw:frame: image | text | other; "" for non-frames.
    method frameKind {shape} {
        if {[$shape nodeName] ne "draw:frame"} { return "" }
        if {[llength [$shape getElementsByTagName draw:image]]}    { return image }
        if {[llength [$shape getElementsByTagName draw:text-box]]} { return text }
        return other
    }
    # xlink:href of the image inside a frame; "" if none.
    method shapeImage {shape} {
        set img [lindex [$shape getElementsByTagName draw:image] 0]
        if {$img eq ""} { return "" }
        return [$img getAttribute xlink:href ""]
    }

    # ---- 0.25 TECHNICAL-DRAWING TEMPLATE BUNDLE -------------------------

    # (A) Convenience builder: creates a style:page-layout and a style:master-
    # page in one call, wires them together, and returns the master-page DOM
    # element so further content (title block, frames, etc.) can be added.
    # Delegates the heavy lifting to definePageLayout / defineMasterPage so all
    # the existing format/orientation/margin handling is reused.
    method addMasterPage {name args} {
        set size A4; set orient landscape; set dn ""
        set margins {1cm 1cm 1cm 1cm}; set explicitMargin 0
        foreach {k v} $args {
            switch -- $k {
                -size         { set size $v }
                -orientation  { set orient $v }
                -display-name { set dn $v }
                -margins      { set margins $v; set explicitMargin 1 }
                -margin       { set margins [list $v $v $v $v]; set explicitMargin 1 }
                default { error "unknown option: $k" }
            }
        }
        set plName "PM_$name"
        set plArgs [list -format $size -orientation $orient]
        if {$explicitMargin} { lappend plArgs -margins $margins }
        my definePageLayout $plName {*}$plArgs
        set mpArgs [list -pagelayout $plName]
        if {$dn ne ""} { lappend mpArgs -display-name $dn }
        my defineMasterPage $name {*}$mpArgs
        return [my MasterPageEl $name]
    }

    # Public reader: returns the master-page DOM element for NAME (or "" if
    # absent). Wraps the internal MasterPageEl helper.
    method masterPageEl {name} { return [my MasterPageEl $name] }

    # (D) Re-set the page format of an existing master-page by overwriting
    # the page-layout it references. Args pass through to definePageLayout.
    method setPageFormat {masterPage args} {
        set plName [$masterPage getAttribute style:page-layout-name ""]
        if {$plName eq ""} { error "master-page has no style:page-layout-name" }
        my definePageLayout $plName {*}$args
        return $masterPage
    }

    # (B) Auto-field helpers. Operate on any text:p and figure out the host
    # document from the element -- this lets them work both in content.xml
    # shapes and in styles.xml master-page frames. xmlns:text is bound on the
    # host root idempotently.
    method EnsureXmlnsText {doc} {
        [$doc documentElement] setAttribute xmlns:text \
            "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    }
    method addAuthorField {textP args} {
        set fixed ""; set display ""
        foreach {k v} $args {
            switch -- $k {
                -fixed { set fixed [expr {$v ? "true" : "false"}] }
                -text  { set display $v }
                default { error "unknown option: $k" }
            }
        }
        set doc [$textP ownerDocument]
        my EnsureXmlnsText $doc
        set el [$doc createElement text:author-name]
        if {$fixed   ne ""} { $el setAttribute text:fixed $fixed }
        if {$display ne ""} { $el appendChild [$doc createTextNode $display] }
        $textP appendChild $el
        return $el
    }
    method addDateField {textP args} {
        set value ""; set styleName ""; set fixed ""; set display ""
        foreach {k v} $args {
            switch -- $k {
                -value { set value $v }
                -style { set styleName $v }
                -fixed { set fixed [expr {$v ? "true" : "false"}] }
                -text  { set display $v }
                default { error "unknown option: $k" }
            }
        }
        set doc [$textP ownerDocument]
        my EnsureXmlnsText $doc
        set el [$doc createElement text:date]
        if {$value     ne ""} { $el setAttribute text:date-value $value }
        if {$styleName ne ""} { $el setAttribute style:data-style-name $styleName }
        if {$fixed     ne ""} { $el setAttribute text:fixed $fixed }
        if {$display   ne ""} { $el appendChild [$doc createTextNode $display] }
        $textP appendChild $el
        return $el
    }
    method addPageNumberField {textP args} {
        set select ""; set adjust ""; set display ""
        foreach {k v} $args {
            switch -- $k {
                -select { set select $v }
                -adjust { set adjust $v }
                -text   { set display $v }
                default { error "unknown option: $k" }
            }
        }
        if {$select ne ""} {
            switch -- $select {previous - current - next {}
                default { error "bad -select: $select (previous|current|next)" }
            }
        }
        set doc [$textP ownerDocument]
        my EnsureXmlnsText $doc
        set el [$doc createElement text:page-number]
        if {$select  ne ""} { $el setAttribute text:select-page $select }
        if {$adjust  ne ""} { $el setAttribute text:page-adjust $adjust }
        if {$display ne ""} { $el appendChild [$doc createTextNode $display] }
        $textP appendChild $el
        return $el
    }
    method addPageCountField {textP args} {
        set display ""
        foreach {k v} $args {
            switch -- $k {
                -text { set display $v }
                default { error "unknown option: $k" }
            }
        }
        set doc [$textP ownerDocument]
        my EnsureXmlnsText $doc
        set el [$doc createElement text:page-count]
        if {$display ne ""} { $el appendChild [$doc createTextNode $display] }
        $textP appendChild $el
        return $el
    }

    # (C) Title-block writer -- reproduces the LO A4_Querformat_03 template
    # pattern (border rect + separator line + 4 frames) on the given master-
    # page. Geometry is hard-coded for A4 landscape in 0.25; other formats can
    # be supported later by parametrising the offsets.
    # ---- 0.26 MULTI-FORMAT TITLE-BLOCK GEOMETRIES -----------------------
    # Geometry table for the _03 LibreSymbols title-block pattern. Six formats:
    # A0..A4 landscape + A4 portrait (the orientations the pack actually
    # ships). Each entry is a list of five frames in order:
    #   border  title  author  date  page
    # Each frame is {x y w h} -- coordinates and sizes verbatim from the
    # corresponding LO-UI template. The separator line is derived from the
    # title-frame y position and the border's horizontal extent.
    method InitTitleBlockGeoms {} {
        variable TbGeom; array set TbGeom {}
        set TbGeom(A0-landscape) [list \
            {1cm 2.5cm 116.9cm 80.6cm} \
            {77.9cm 81.303cm 19.428cm 1.797cm} \
            {97.328cm 81.303cm 10.286cm 0.959cm} \
            {107.614cm 81.303cm 10.286cm 0.959cm} \
            {107.614cm 82.142cm 10.286cm 0.958cm}]
        set TbGeom(A1-landscape) [list \
            {1cm 2.5cm 82.1cm 55.9cm} \
            {43.1cm 56.603cm 19.428cm 1.797cm} \
            {62.528cm 56.603cm 10.286cm 0.959cm} \
            {72.814cm 56.603cm 10.286cm 0.959cm} \
            {72.814cm 57.442cm 10.286cm 0.958cm}]
        set TbGeom(A2-landscape) [list \
            {1cm 2.5cm 57.4cm 38.5cm} \
            {18.4cm 39.203cm 19.428cm 1.797cm} \
            {37.828cm 39.203cm 10.286cm 0.959cm} \
            {48.114cm 39.203cm 10.286cm 0.959cm} \
            {48.114cm 40.042cm 10.286cm 0.958cm}]
        set TbGeom(A3-landscape) [list \
            {1cm 2.5cm 40cm 26.2cm} \
            {1cm 26.903cm 19.428cm 1.797cm} \
            {20.428cm 26.903cm 10.286cm 0.959cm} \
            {30.714cm 26.903cm 10.286cm 0.959cm} \
            {30.714cm 27.742cm 10.286cm 0.958cm}]
        set TbGeom(A4-landscape) [list \
            {1cm 2.5cm 27.7cm 17.5cm} \
            {1cm 18.8cm 13.454cm 1.2cm} \
            {14.454cm 18.8cm 7.123cm 0.64cm} \
            {21.577cm 18.8cm 7.123cm 0.64cm} \
            {21.577cm 19.36cm 7.123cm 0.64cm}]
        set TbGeom(A4-portrait) [list \
            {2.5cm 1cm 17.5cm 27.7cm} \
            {2.5cm 27.5cm 8.5cm 1.2cm} \
            {11cm 27.5cm 4.5cm 0.64cm} \
            {15.5cm 27.5cm 4.5cm 0.64cm} \
            {15.5cm 28.06cm 4.5cm 0.64cm}]
    }
    # Reader: which {format-orientation} keys does addTitleBlock support?
    method titleBlockFormats {} {
        variable TbGeom
        return [lsort [array names TbGeom]]
    }

    method addTitleBlock {masterPage args} {
        variable TbGeom
        set size A4; set orient landscape
        set title ""; set subtitle ""; set author ""; set dateVal ""; set pageNo ""
        set border 1
        set shapeStyle ""; set frameStyle ""; set textStyle ""; set dateStyle ""
        foreach {k v} $args {
            switch -- $k {
                -size        { set size $v }
                -orientation { set orient $v }
                -title       { set title $v }
                -subtitle    { set subtitle $v }
                -author      { set author $v }
                -date        { set dateVal $v }
                -page-number { set pageNo $v }
                -border      { set border $v }
                -shape-style { set shapeStyle $v }
                -frame-style { set frameStyle $v }
                -text-style  { set textStyle $v }
                -date-style  { set dateStyle $v }
                default { error "unknown option: $k" }
            }
        }
        set key "$size-$orient"
        if {![info exists TbGeom($key)]} {
            error "no title-block geometry for $key (have: [my titleBlockFormats])"
        }
        # 0.27: ensure default styles exist in styles.xml; use them whenever
        # the caller did not override.
        my EnsureTbStyles
        if {$shapeStyle eq ""} { set shapeStyle __tb_default_outline }
        if {$frameStyle eq ""} { set frameStyle __tb_default_frame }
        if {$dateStyle  eq ""} { set dateStyle  __tb_date_DDMMYYYY }
        lassign $TbGeom($key) borderGeo titleGeo authorGeo dateGeo pageGeo
        lassign $borderGeo  bX bY bW bH
        lassign $titleGeo   tX tY tW tH
        lassign $authorGeo  aX aY aW aH
        lassign $dateGeo    dX dY dW dH
        lassign $pageGeo    pX pY pW pH
        set sd [my StylesDoc]
        # Border rect
        if {$border} {
            set r [$sd createElement draw:rect]
            $r setAttribute draw:layer backgroundobjects
            $r setAttribute svg:x $bX; $r setAttribute svg:y $bY
            $r setAttribute svg:width $bW; $r setAttribute svg:height $bH
            $r setAttribute draw:style-name $shapeStyle
            $masterPage appendChild $r
        }
        # Separator line at title-frame y, spanning the border's horizontal extent
        set ln [$sd createElement draw:line]
        $ln setAttribute draw:layer backgroundobjects
        $ln setAttribute svg:x1 $bX;                  $ln setAttribute svg:y1 $tY
        $ln setAttribute svg:x2 [my AddUnit $bX $bW]; $ln setAttribute svg:y2 $tY
        $ln setAttribute draw:style-name $shapeStyle
        $masterPage appendChild $ln
        # Title (with optional subtitle). When a subtitle is present, the
        # title frame needs to hold two text:p lines -- LO clips at the frame
        # height so 1.2cm (single-line default) cuts the subtitle off. Double
        # the height and shift the frame's y upward by that delta so the
        # bottom edge stays where the geometry table says.
        if {$title ne ""} {
            set tH2 $tH; set tY2 $tY
            if {$subtitle ne ""} {
                set tHnum [string trim $tH cm]
                set tYnum [string trim $tY cm]
                set tH2 "[format %g [expr {$tHnum + $tHnum}]]cm"
                set tY2 "[format %g [expr {$tYnum - $tHnum}]]cm"
            }
            set tb [my TbTextBox $masterPage $tX $tY2 $tW $tH2 $frameStyle]
            my TbPara $tb $textStyle $title
            if {$subtitle ne ""} { my TbPara $tb $textStyle $subtitle }
        }
        # Author
        if {$author ne ""} {
            set tb [my TbTextBox $masterPage $aX $aY $aW $aH $frameStyle]
            set p [my TbPara $tb $textStyle ""]
            my addAuthorField $p -text $author -fixed 1
        }
        # Date -- use the data-style so LO renders DD.MM.YYYY rather than its
        # default short DD.MM.YY format.
        if {$dateVal ne ""} {
            set tb [my TbTextBox $masterPage $dX $dY $dW $dH $frameStyle]
            set p [my TbPara $tb $textStyle ""]
            my addDateField $p -value $dateVal -fixed 1 -text $dateVal -style $dateStyle
        }
        # Page number
        if {$pageNo ne ""} {
            set tb [my TbTextBox $masterPage $pX $pY $pW $pH $frameStyle]
            set p [my TbPara $tb $textStyle ""]
            my addPageNumberField $p -text $pageNo
        }
        return $masterPage
    }
    # Title-block internal helpers -- frame + paragraph builders in styles.xml.
    # TbTextBox returns the draw:text-box (not the frame) so the caller can
    # directly append paragraphs.
    method TbTextBox {masterPage x y w h style} {
        set sd [my StylesDoc]
        set f [$sd createElement draw:frame]
        $f setAttribute draw:layer backgroundobjects
        $f setAttribute svg:x $x; $f setAttribute svg:y $y
        $f setAttribute svg:width $w; $f setAttribute svg:height $h
        if {$style ne ""} { $f setAttribute draw:style-name $style }
        set tb [$sd createElement draw:text-box]
        $f appendChild $tb
        $masterPage appendChild $f
        return $tb
    }
    method TbPara {textBox style content} {
        set sd [$textBox ownerDocument]
        set p [$sd createElement text:p]
        if {$style ne ""} { $p setAttribute text:style-name $style }
        if {$content ne ""} { $p appendChild [$sd createTextNode $content] }
        $textBox appendChild $p
        return $p
    }

    # ---- 0.27: title-block default styles (in styles.xml) ----------------
    # Registers, idempotently, the styles addTitleBlock falls back to when no
    # -shape-style / -date-style is supplied. Names start with "__tb_" so
    # they don't collide with user styles. All three live in styles.xml's
    # office:automatic-styles so master-page shapes can resolve them.
    method EnsureTbStyles {} {
        set sd [my StylesDoc]
        set autoEl [my AutoStylesElS]
        # (1) Default outline graphic style: black 0.02cm stroke, no fill.
        if {[my StyleByName $autoEl style:style __tb_default_outline] eq ""} {
            set st [$sd createElement style:style]
            $st setAttribute style:name __tb_default_outline
            $st setAttribute style:family graphic
            set gp [$sd createElement style:graphic-properties]
            $gp setAttribute draw:stroke solid
            $gp setAttribute svg:stroke-color "#000000"
            $gp setAttribute svg:stroke-width 0.02cm
            $gp setAttribute draw:fill none
            $st appendChild $gp
            $autoEl appendChild $st
        }
        # (2) Default frame graphic style: no stroke, no fill (text frame).
        if {[my StyleByName $autoEl style:style __tb_default_frame] eq ""} {
            set st [$sd createElement style:style]
            $st setAttribute style:name __tb_default_frame
            $st setAttribute style:family graphic
            set gp [$sd createElement style:graphic-properties]
            $gp setAttribute draw:stroke none
            $gp setAttribute draw:fill none
            $st appendChild $gp
            $autoEl appendChild $st
        }
        # (3) Date format DD.MM.YYYY + a chart-family style referencing it.
        if {[my StyleByName $autoEl number:date-style __tb_date_DDMMYYYY] eq ""} {
            set NS_N urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0
            [$sd documentElement] setAttribute xmlns:number $NS_N
            set ds [$sd createElement number:date-style]
            $ds setAttribute style:name __tb_date_DDMMYYYY
            foreach {tag attrs txt} {
                number:day        {number:style long} ""
                _literal          {} .
                number:month      {number:style long} ""
                _literal          {} .
                number:year       {number:style long} ""
            } {
                if {$tag eq "_literal"} {
                    set el [$sd createElement number:text]
                    $el appendChild [$sd createTextNode $txt]
                } else {
                    set el [$sd createElement $tag]
                    foreach {a v} $attrs { $el setAttribute $a $v }
                }
                $ds appendChild $el
            }
            $autoEl appendChild $ds
        }
        if {[my StyleByName $autoEl style:style __tb_default_date] eq ""} {
            set st [$sd createElement style:style]
            $st setAttribute style:name __tb_default_date
            $st setAttribute style:family text
            $st setAttribute style:data-style-name __tb_date_DDMMYYYY
            $autoEl appendChild $st
        }
    }
    # Generic lookup: first child element of parent with given nodeName and
    # style:name (or "" if not found).
    method StyleByName {parent tagName styleName} {
        foreach c [$parent childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq $tagName \
                && [$c getAttribute style:name ""] eq $styleName} { return $c }
        }
        return ""
    }

    method flush {} {
        $Pkg settree content.xml $Doc
        if {[info exists StylesDoc] && $StylesDoc ne ""} { $Pkg settree styles.xml $StylesDoc }
        return
    }
}

# A drawing template (.otg): same content model as a drawing document, only the
# media type differs (application/vnd.oasis.opendocument.graphics-template).
proc odf::newDrawTemplate {} {
    set pkg [odf::newDrawDoc]
    $pkg setMimetype "application/vnd.oasis.opendocument.graphics-template"
    return $pkg
}

package provide odf::draw 0.27
