# CHANGES — odf

## Unreleased

- `odf::style` 0.20 — `defineListStyle` (named `text:list-style`, ordered
  numbers or bullets) and `listStyleKind` (classify a list style by name →
  `ordered` / `bullet`, searching styles.xml then content.xml automatic
  styles). Lists referenced via `text:style-name` can now carry real
  numbering instead of only the default bullet. Test: `tests/test-liststyle.tcl`.
  List levels also emit `style:list-level-properties` (label-alignment) for a
  proper hanging indent per level.

## 0.9

Initial public release.

Native OpenDocument library for Tcl (8.6 and 9.x), depends only on `tdom` and
the built-in `zlib`. The design is **pass-through**: the underlying tdom tree is
kept and only what you actually edit is modelled, so round-trips never silently
lose content.

Packages and what they cover:

- `odf` (0.9) — container (ZIP / manifest / parts), metadata, version.
- `odf::text` (0.57) — `.odt` content model + builder: headings, lists, tables,
  images, bookmarks/refs/indexes/captions/fields, notes, TOC, change tracking,
  annotations, admonitions, master documents (`.odm`), embedded objects/charts,
  fillable forms with database binding, and number-format data styles.
- `odf::style` (0.20) — page layout, header/footer, styles, notes/line/biblio
  configuration, and list styles (ordered/bullet).
- `odf::sheet` (0.24) — `.ods` spreadsheets: cells/types, number/date/time/
  currency/percentage/boolean styles, stored formulas, merges, column widths,
  per-sheet page setup, freeze panes/print ranges, named ranges/expressions,
  data validation, conditional formatting, database ranges/AutoFilter,
  subtotals, pivot/data-pilot (MVP), calculation settings.
- `odf::draw` (0.27) — `.odg` drawings: pages, shapes, paths, connectors,
  groups, layers, master pages, gradients/hatches/bitmap fills, transparency
  gradients, shadows, image embedding, transforms.
- `odf::chart` (0.4) — embedded charts (`.odc`).
- `odf::base` (0.1) — database front-end (`.odb`).

Errors follow the `{ODF ...}` error-code convention. Ships with a test suite
(1641 assertions, all passing) and runnable demos under `examples/`.
