# odf — native OpenDocument library for Tcl

A small, native Tcl library for reading, editing and building OpenDocument
files. It targets Tcl 8.6 and 9.x and depends only on `tdom` and the built-in
`zlib`.

The guiding idea is **pass-through**: the library keeps the underlying tdom
tree and models only what you actually edit. Everything it does not model is
preserved verbatim, so round-trips do not silently lose content. This gives
"complete access" without "complete modelling" of the (very large) ODF schema.

## Layout

```
odf/
├── odf-0.9.tm          package odf        — container (ZIP/manifest/parts) + metadata + version
├── odf/
│   ├── text-0.57.tm    package odf::text  — content model + builder (.odt): headings/lists/tables/images, bookmarks/refs/indexes/captions/fields, notes, TOC, tracking, annotations, admonitions, master docs (.odm), embedded objects/charts, **fillable forms** (text/textarea/password/number/date/time/checkbox/radio/listbox/combobox/label/button/hidden) with **database binding** (form-level datasource/command, control-level data-field, listbox/combobox source binding) and **number-format data styles** (date/time/number)
│   ├── style-0.20.tm   package odf::style — page layout, header/footer, styles, notes/line/biblio-config, list styles
│   ├── sheet-0.24.tm   package odf::sheet — spreadsheets (.ods): cells/types, number/date/time/currency/percentage/boolean styles, formulas (stored), merges, column widths, per-sheet page setup, freeze panes/print ranges, **named ranges/expressions**, **data validation**, **conditional formatting** (`style:map`), **database ranges/AutoFilter**, **subtotals**, **pivot/data-pilot (MVP)**, **calculation settings**
│   ├── draw-0.27.tm    package odf::draw  — drawings (.odg): pages, shapes, paths, connectors, groups, layers, master pages, gradients/hatches/bitmap-fills, transparency gradients, shadows, image embedding, transforms
│   ├── chart-0.4.tm    package odf::chart — embedded charts (.odc)
│   └── base-0.1.tm     package odf::base  — database front-end (.odb)
├── tests/              48 test modules, 1641 assertions
│   ├── run-all.tcl     collecting test runner
│   ├── test-forms.tcl  forms slice (controls, DB binding, properties, data styles)
│   ├── test-draw.tcl   ODG slice (shapes, fills, effects)
│   └── fixtures/       sample .odt and .png files
├── README.md
├── CHANGES.md
└── ROADMAP.md
```

## Install / use

> New here? Start with the **[getting-started guide](docs/getting-started.md)** for copy-paste examples (.odt/.ods/.odg + reading), or see the one-page **[features overview](docs/features.md)**.

Put the repo directory on the Tcl module path; `odf::text` pulls in `odf`:

```tcl
::tcl::tm::path add /path/to/odf
package require odf::text
```

## Container — `odf::Package`

Reads an ODF ZIP into parts, lets you edit them, and writes a valid ODF back
(`mimetype` first and STORED, the rest deflate). A single pure-Tcl reader is
used on all versions — no `zipfs` — so behaviour is identical on 8.6 and 9.x
and independent of `zipfs` API changes between Tcl releases.

```tcl
set pkg [odf::Package new report.odt]
$pkg parts                       ;# part names (mimetype first)
$pkg part content.xml            ;# bytes
$pkg has styles.xml
$pkg setpart content.xml $bytes  ;# in place
set doc [$pkg tree content.xml]  ;# part as a tdom document
$pkg settree content.xml $doc
$pkg manifest                    ;# dict full-path -> media-type
$pkg addpart Pictures/x.png $bytes image/png   ;# part + manifest entry
$pkg dropfile Pictures/x.png
$pkg save out.odt
$pkg destroy
```

## Content model — `odf::Text`

A thin, editable view over `content.xml` (the `office:text` body). Editing one
node leaves its siblings untouched (pass-through).

```tcl
set t [odf::Text new $pkg]
foreach n [$t blocks] { puts "[$t kind $n] [$t level $n]: [$t text $n]" }
$t find heading                  ;# nodes of one kind: heading|paragraph|list|table|image

# inline runs (text:span etc.) — change one run, keep the rest
foreach r [$t runs $node] { puts "[$t runKind $r] [$t runStyle $r]: [$t runText $r]" }
$t setRunText $run "..." ; $t addText $node " ..." ; $t addSpan $node "fett" BoldStyle
$t addLink $node "Tcl" https://www.tcl.tk/   ;# text:a   (runKind: link, linkHref)
$t addBreak $node ; $t addTab $node          ;# text:line-break / text:tab

# lists
$t listItems $list ; $t itemText $item ; $t itemSublist $item
$t setItemText $item "..." ; $t addListItem $list "..."
$t addSublist $item        ;# nested text:list inside the item -> fill with addListItem

# absolut positionierter Textrahmen (z.B. Fensterkuvert-Anschriftfeld)
$t defineAutoGraphic FrameClear {draw:stroke none fo:border none style:vertical-rel page style:horizontal-rel page ...}
$t addTextFrame Anschriftfeld 2.0cm 4.5cm 8.5cm {{"Firma GmbH" Anschrift} {"Frau X" Anschrift}} -style FrameClear
$t textFrames ; $t frameInfo Anschriftfeld
$t addLine Falz1 0.5cm 8.7cm 1.0cm 8.7cm -style FaltLinie   ;# draw:line (e.g. a fold mark)
$t drawLines ; $t lineInfo Falz1

# style resolution (read): effective properties incl. inheritance
set reg [$t styleRegistry]                         ;# name -> {family parent props{...}}
$t effectiveProps $node $reg                       ;# {style:text-properties {fo:font-size 11pt ...} ...}
$t effectiveProp  $node style:text-properties fo:color $reg
$t resolveStyle "BodyText" $reg

# tables
$t tableRows $table ; $t rowCells $row ; $t cellText $cell ; $t cellStyle $cell
$t setCellText $cell "..." ; $t addRow $table {a b c}

# footnotes/endnotes, captioned image, multi-column section
$t addFootnote $p "see appendix"            ;# inline text:note (auto id + citation)
$t appendCaptionedImage logo.png 4cm 3cm "Figure 1: logo"
$t defineSectionStyle TwoCol -columns 2
$t appendSection Intro -style TwoCol -protected 1
# images sniff PNG/JPEG/GIF/WebP/TIFF/BMP + SVG (place SVG with explicit size)
$t appendImage chart.svg 8cm 5cm

$t flush                         ;# write changes back into the package

# document-local automatic styles (in content.xml, not styles.xml)
$t defineAutoParagraph P_center -paragraph {fo:text-align center} -text {fo:font-size 14pt}
$t defineAutoText      T_red    {fo:color #CC0000 fo:font-weight bold}
$t appendParagraph "x" P_center ; $t addSpan $p "y" T_red
$t destroy
```

## Styles — `odf::Styles`

Defines reusable named styles in `styles.xml` (so referenced style names
actually render). Properties are passed as real ODF attributes; the caller
also chooses the property group.

```tcl
set s [odf::Styles new $pkg]
$s defineText      GreenBold {fo:color #008844 fo:font-weight bold}
$s defineParagraph Centered  -paragraph {fo:text-align center} -text {fo:font-size 14pt}
$s defineCell      Warn      -cell {fo:background-color #FFE5E5}
# Explicit footnote/endnote numbering (else LO uses its defaults: footnote "1", endnote roman "i")
$s defineNotesConfiguration -class endnote  -num-format 1 -position document
$s defineNotesConfiguration -class footnote -num-format 1 -position page
$s defineLineNumbering -number-lines true -num-format 1 -increment 5 -position left
$s defineBibliographyConfiguration -numbered-entries true -sort-keys {{author 1} {year 1}}

# Page layout (A4 + DIN margins) -> styles.xml
$s defineStandardPage {fo:page-width 21cm fo:page-height 29.7cm \
      fo:margin-left 2.5cm fo:margin-right 2cm fo:margin-top 2cm fo:margin-bottom 2cm}
# or individually: $s definePageLayout PM {...} ; $s defineMasterPage Standard -pagelayout PM
# read: $s pageLayouts ; $s masterPages ; $s pageLayoutProps PM ; $s masterPageLayout Standard

# Page-format presets (paper size + orientation): A3/A4/A5/A6/Letter/Legal
$s defineStandardFormat A4                                  ;# PMstandard, 2cm margins
$s definePageFormat PMa3 A3 -orientation landscape -margin 1.5cm
$s definePageFormat PMle Letter -margins {9.5cm 2cm 2cm 2.5cm} -extra {style:num-format 1}
set props [$s pageFormat A4 -orientation landscape]         ;# pure helper -> prop dict
# read: $s pageFormats

# Extra properties on a layout: numbering, columns, border, background, padding
$s pageProperties PMstandard -num-format i -columns 2 -column-gap 0.7cm \
      -border "0.5pt solid #000000" -background-color #F8F8F8
# read: $s pageColumns PMstandard            ;# -> {count 2 gap 0.7cm}

# Multi-page: first page different (master chaining) + mirrored pages
$s defineMasterPage First -pagelayout PMfirst
$s defineMasterPage Rest  -pagelayout PMrest
$s setNextPage First Rest                   ;# page 1 = First, then Rest
$s defineMasterPageStyle FirstStart First   ;# apply to the first body paragraph
$s setPageUsage PMbook mirrored             ;# all|left|right|mirrored
# read: $s nextPage First ; $s pageUsage PMbook ; $s masterPageOfStyle FirstStart

# Tables: automatic table/column/cell styles live in content.xml (odf::Text) --
# body tables need automatic styles; LibreOffice ignores common table styles.
$t defineAutoTable  T1 {style:width 15cm table:align center}
$t defineAutoColumn Cw {style:column-width 8cm}
$t defineAutoColumn Cn {style:column-width 3.5cm}
$t defineAutoCellStyle Head -border "0.5pt solid #000" -background #305080 \
      -color #FFFFFF -bold true -valign middle -align center -padding 0.1cm
set tab [$t appendTableCols {Cw Cn Cn} T1]
$t addHeaderRow $tab {Product Qty Price} {Head Head Head}
$t addRow $tab {Apple 12 1.20}
# apply a style to an existing cell: $t setCellStyle $cell Head
# merge cells: $t spanCell $tab $row $col -columns N -rows M
#   covered positions become <table:covered-table-cell/>; read via
#   $t cellSpan $tab $row $col -> {columns N rows M}
# read: $t tableColumns $tab ; $t isHeaderRow $row

# header/footer (in the master-page); %page%/%pages% -> page-number fields
$s setHeader Standard {{"Example Ltd" Centered}}
# three-part header/footer (center+right tab stops) + fields:
# $s setHeaderParts Standard -left "%title%" -center "%date%" -right "Page %page%"
# fields: %page% %pages% %date% %time% %title% %author% %subject% %file% (%% = literal %)
# read: $s headerParts Standard -> {left .. center .. right ..}
# different left/right pages (needs mirrored page-usage):
# $s setPageUsage PMstandard mirrored ; $s setHeaderParts Standard -side left -left "..."
# style the header/footer box:
# $s setHeaderFooterProps Standard -which header -min-height 1cm -border-bottom "0.5pt solid #000" -background #EEE
$s setFooter Standard {{"Page %page% of %pages%" Centered}}
# read: $s headerLines Standard ; $s footerLines Standard

# font registration (office:font-face-decls); also on odf::Text for content.xml
$s registerFont Arial -family Arial -generic swiss -pitch variable
# then in a style: ... -text {style:font-name Arial}
# read: $s fonts
$s flush
# then in odf::Text: $t appendParagraph "x" Centered ; $t addSpan $p "y" GreenBold
```

## Spreadsheets — `odf::Sheet`

Read and build `.ods` (the `office:spreadsheet` body), reusing `odf::Package`
and `odf::Styles`. Cell types are explicit on write (no number guessing).

```tcl
package require odf::sheet

# read a real Calc file
set pkg [odf::Package new book.ods]
set s   [odf::Sheet new $pkg]
foreach t [$s tables] {
    puts "[$s tableName $t]: [llength [$s rows $t]] x [$s width $t]"
    foreach r [$s rows $t] {
        foreach c [$s cells $r] {
            # type/value/text, merges and formulas:
            # $s cellType $c ; $s cellValue $c ; $s cellText $c
            # $s cellSpan $c ; $s cellCovered $c ; $s cellFormula $c
        }
    }
}

# build one from scratch
set pkg [odf::newSheetDoc]
set s   [odf::Sheet new $pkg]
$s definePercentageStyle Pct -decimals 1
$s defineCurrencyStyle   Eur -symbol "€"
$s defineCellFormat cePct Pct ; $s defineCellFormat ceEur Eur
set t [$s addTable "Sales"]
$s addColumnWidths $t {3cm 2cm 2cm}
$s addStringRow $t {Item Share Price}
$s addRow $t {{string Bolt} {percentage 0.2} {currency 0.05 EUR}} {{} cePct ceEur}
$s addRow $t [list {string Sum} {percentage 1.0} \
              [list formula {of:=SUM([.C2:.C2])} currency 0.05 EUR]] {{} cePct ceEur}
$s mergeCells   $t 0 0 1 1          ;# spans on the anchor + covered cells
$s setPrintRange $t "Sales.A1:C3"   ;# table:print-ranges
$s freezePanes  $t 0 1              ;# freeze header row -> settings.xml (needs xmlns:ooo)
$s flush                            ;# also ensures the table:table-column structure
$pkg save sales.ods
```

Page setup / header / footer are defined on `styles.xml` with `odf::Styles`
(`definePageFormat`, `defineMasterPage`, `setHeader`/`setFooter`) and bound to a
sheet via `defineTableStyle -master`:

```tcl
set st [odf::Styles new $pkg]
$st definePageFormat PM A4 -orientation landscape
$st defineMasterPage MP -pagelayout PM
$st setHeader MP {{"Report"}} ; $st setFooter MP {{"Page %page% / %pages%"}}
$st flush
set ta [$s defineTableStyle ta -master MP]
set t  [$s addTable "Report" $ta]
```

## Drawings — `odf::Draw`

Read and build `.odg` (the `office:drawing` body: `draw:page` with shapes),
reusing `odf::Package` and `odf::Styles`. Geometry is explicit.

```tcl
package require odf::draw

set pkg [odf::newDrawDoc]
set d   [odf::Draw new $pkg]
set box [$d defineGraphicStyle box -fill solid -fill-color "#cfe8ff" \
                                   -stroke solid -stroke-color "#336699"]
$d defineMarker Arrow "0 0 20 30" "M10 0 L0 30 L20 30 Z"
set edge [$d defineGraphicStyle edge -stroke solid -marker-end Arrow -marker-end-width 0.3cm]

set p [$d addPage "Page 1"]
set a [$d addRect    $p 2cm 2cm 6cm 3cm -style box -text "A"]
set b [$d addRect    $p 12cm 2cm 6cm 3cm -style box -text "B"]
$d connectShapes $p $a $b -style edge          ;# bound connector with arrowhead
$d addEllipse  $p 2cm 7cm 5cm 3cm -style box
$d addPolygon  $p {2 12 6 12 4 16}             ;# points in cm -> viewBox/points
$d addImageFile $p 12cm 8cm 6cm 4cm photo.png  ;# embed into Pictures/
set g [$d addGroup $p -name grp]               ;# returns a parent for nesting
$d addRect $g 12cm 13cm 3cm 2cm
$d setTransform $a {{rotate 15} {translate 2cm 0cm}}
$d setZIndex $b 3
$d flush
$pkg save drawing.odg
```

Shapes covered: rect (optionally rounded via `-corner-radius`), circle, ellipse,
line, polyline, polygon, path (bezier),
text-box and image frames, groups, connectors (free or shape-bound). Plus
graphic styles (fill/stroke/markers), transforms, z-order, layers and arrow
markers. Readers mirror each (`shapes`, `shapeType`, `shapeRect`, `shapeText`,
`connectorEnds`, `markers`, ...). Page layouts and master pages are managed by
`odf::Draw` itself on the styles.xml tree — `definePageLayout` (`-format`/`-width`/
`-height`/`-orientation`/`-margins`), `defineDrawingPageStyle` (page background),
`defineMasterPage` and `setPageStyle`, with `addPage -master` to bind a page.
Do not mix this with a separate `odf::Styles` instance on the same drawing (both
would write styles.xml and clobber each other).

Fills and strokes: `defineGradient` (linear/radial/…) used via `-gradient`,
`defineStrokeDash` used via `-dashed`, and arrow `defineMarker` used via
`-marker-start`/`-marker-end`. `defineGraphicStyle -parent` enables style
inheritance, and `resolveStyle`/`shapeFill`/`shapeStroke`/… read the *effective*
properties of a shape — the basis for importing/interpreting a drawing.
Accessibility text is `setTitle`/`setDesc` (read with `shapeTitle`/`shapeDesc`).
On read, LibreOffice `draw:custom-shape` is enumerated like any shape, and
`customShapeKind`/`customShapePath`/`customShapeViewBox` expose its geometry.

## Builder — new documents from scratch

```tcl
set pkg [odf::newTextDoc]        ;# minimal valid ODT skeleton
set t   [odf::Text new $pkg]
$t appendHeading "Title" 1
$t appendParagraph "Body"
set l  [$t appendList];   $t addListItem $l "Item"
set tb [$t appendTable 2]; $t addRow $tb {Name Value}
$pkg addpart Pictures/b.png $bytes image/png
$t appendImageFit Pictures/b.png -name Img1        ;# size from PNG/JPEG, page-wide (default 17cm)
$t appendImage    Pictures/b.png 26.46cm 7.94cm Img1  ;# oder explizite cm
$t flush
$pkg save new.odt
```

## Scope and limits

- Text documents (ODT), spreadsheets (ODS) and drawings (ODG). Presentations
  (ODP) are out of scope; for `.xlsx` use a dedicated OOXML library.
- `setText` (block level) flattens inline runs; use `setRunText`/`addSpan` to
  edit while preserving formatting.
- Adding/removing whole parts updates the manifest; styles are read but not
  yet generated (planned).

## Tests

```
tclsh   tests/run-all.tcl
tclsh9.0 tests/run-all.tcl
```

The runner executes each test against the relevant fixtures and prints a
combined PASS/FAIL summary (currently 48 test files, 1641 assertions, passing on
Tcl 8.6 and 9). Generated `.odt` outputs are written to a
repo-relative `out/` directory (git-ignored) -- portable across OSes and
kept in one place. Individual tests are standalone:

```
tclsh tests/test-listtable.tcl tests/fixtures/odt-tcltk-erweitert-testdokument.odt
```

## Requirements

Tcl 8.6 or 9.x, `tdom`.

## examples/

- `generate-din5008.tcl` — builds a DIN-5008 business letter (`din5008.odt`):
  A4 with DIN margins via the page-layout, return-address line, recipient block,
  right-aligned date, bold subject, body, closing. Run from the repo root:
  `tclsh examples/generate-din5008.tcl`.
- `demo-pageformats.tcl` — demonstrates the page-format presets. Optional args
  `?format? ?orientation?` (default `A5 landscape`); writes
  `out/pageformat-<format>-<orientation>.odt`, e.g.
  `tclsh examples/demo-pageformats.tcl A3 portrait`.
- `demo-columns.tcl` — multi-column page via `pageProperties -columns`. Optional
  args `?columns? ?gap?` (default `2 0.7cm`); writes `out/columns.odt` with
  enough running text to show the column break, e.g. `tclsh examples/demo-columns.tcl 3 1cm`.
- `demo-multipage.tcl` — first page different: page 1 uses a tall-top-margin
  master, following pages a normal one (via `setNextPage`); writes
  `out/multipage.odt` (multiple pages, page number in the footer).
- `demo-table.tcl` — styled table: column widths, table width + centered
  alignment, shaded/bold header row; writes `out/table.odt`.
- `demo-sheet.tcl` — a small `.ods`: a data sheet (string/float) plus a "Typen"
  sheet with number formats and a "Bericht" sheet (merged title + SUM formula);
  writes `out/sheet.ods`.
- `demo-sheet-komplex.tcl` — a richer multi-sheet workbook: every value type with
  formats, a sales block with SUM formulas and totals, merge variants, column
  widths, and a landscape page with header/footer on one sheet; writes
  `out/komplex.ods`. Optional arg `?out.ods?`.
- `read-sheet.tcl` — dump any `.ods` (sheets, dimensions, per-cell type/value/
  formula, merges) to the terminal: `tclsh examples/read-sheet.tcl file.ods ?maxrows?`.
- `demo-draw.tcl` — a small `.odg`: a flow diagram (boxes joined by arrow
  connectors, a status ellipse, a caption box and an embedded image) plus a
  second page of point/path shapes, a group and a rotated shape; writes
  `out/draw.odg`. Optional arg `?out.odg?`.
