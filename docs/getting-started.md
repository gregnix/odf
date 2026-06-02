# odf — Getting Started

A short, task-oriented guide with complete, copy-paste examples. The full API
reference is in [`README.md`](../README.md); runnable programs live in
[`examples/`](../examples/); a one-page capability list is in
[`features.md`](features.md).

`odf` is **pass-through**: it keeps the underlying tdom tree and models only what
you actually edit — everything else is preserved verbatim, so round-trips never
silently lose content. Dependencies: only `tdom` and the built-in `zlib`. Runs
on Tcl 8.6 and 9.x.

## Install

Put the odf directory on the Tcl module path, then require the part you need
(it pulls in `odf` automatically):

```tcl
::tcl::tm::path add /path/to/odf
package require odf::text     ;# or odf::sheet / odf::draw
```

## Build a text document (.odt)

```tcl
package require odf::text
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]

$t appendHeading   "Report" 1            ;# text, level (1..n)
$t appendParagraph "Hello, world. This is a paragraph."
set tab [$t appendTable 2 2]             ;# 2 rows, 2 columns

$t flush                                 ;# write changes into content.xml
$t destroy
$pkg save report.odt
$pkg destroy
```

## Build a spreadsheet (.ods)

Cells are **typed**: `{string ...}`, `{float ...}`, etc. `addStringRow` is the
shorthand for a row of plain text.

```tcl
package require odf::sheet
set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

set s [$sh addTable "Sales"]
$sh addColumns   $s 3
$sh addStringRow $s {Item Qty Price}
$sh addRow       $s {{string Screws} {float 250} {float 0.05}}
$sh addRow       $s {{string Nuts}   {float 250} {float 0.04}}

$sh flush
$sh destroy
$pkg save sales.ods
$pkg destroy
```

## Build a drawing (.odg)

```tcl
package require odf::draw
set pkg [odf::newDrawDoc]
set d   [odf::Draw new $pkg]

$d defineGraphicStyle box -fill solid -fill-color #cfe8ff \
                          -stroke solid -stroke-color #336699
set p [$d addPage "Page 1"]
$d addRect $p 2cm 2cm 6cm 3cm -style box -text "Hello"

$d flush
$d destroy
$pkg save sketch.odg
$pkg destroy
```

## Read an existing file

```tcl
package require odf::text
set pkg [odf::Package new report.odt]
set t   [odf::Text new $pkg]
foreach n [$t blocks] {
    puts "[$t kind $n]: [$t text $n]"     ;# kind: heading|paragraph|list|table|image
}
$pkg destroy
```

## Things to keep in mind

- **Order:** build content → `flush` → `save` → `destroy`.
- **Saving** always goes through the package (`$pkg save file.odt`); `odf` writes
  `mimetype` first and uncompressed and deflates the rest, so the result is a
  valid ODF file.
- **Edit instead of rewrite:** open an existing file with
  `odf::Package new file.odt`, change what you need, then `save` — the rest is
  left untouched.

## Next steps

- Full per-package method list: [`README.md`](../README.md).
- One-page capability overview: [`features.md`](features.md).
- ODF 1.3 coverage detail: [`ODF-1.3-FEATURES.md`](../ODF-1.3-FEATURES.md).
- Runnable examples (tables, formulas, forms, charts, mail merge, DIN 5008, …):
  [`examples/`](../examples/).
