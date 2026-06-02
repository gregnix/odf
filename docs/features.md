# odf — Features at a glance

A native OpenDocument library for Tcl. **Reads and writes** ODF; the
pass-through design preserves anything it does not model. Pure Tcl, depends only
on `tdom` + `zlib`, runs on Tcl 8.6 and 9.x.

| Package | File | What you can do |
|---------|------|-----------------|
| `odf` | — | Container: read/write the ODF ZIP (parts, `manifest`, metadata); `mimetype` handled correctly. |
| `odf::text` | `.odt` | Headings, paragraphs, lists, tables, images; bookmarks, references, captions, fields; foot/endnotes, table of contents; change tracking, annotations, admonitions; master documents (`.odm`); embedded objects/charts; fillable forms with database binding. |
| `odf::style` | — | Page layout, page-format presets (A3–A6/Letter/Legal), headers/footers (3-part, fields, mirrored pages), paragraph/text/note styles, columns. |
| `odf::sheet` | `.ods` | Typed cells; number/date/time/currency/percentage/boolean formats; stored formulas; merges; column widths; per-sheet page setup; freeze panes & print ranges; named ranges; data validation; conditional formatting; database ranges / AutoFilter; subtotals; pivot/data-pilot (MVP); calculation settings. |
| `odf::draw` | `.odg` | Pages, shapes, paths, connectors, groups, layers, master pages; gradients/hatches/bitmap fills, transparency, shadows; image embedding; transforms. |
| `odf::chart` | `.odc` | Embedded charts. |
| `odf::base` | `.odb` | Database front-end. |

## Notes

- **Pass-through:** editing one node leaves its siblings untouched, so opening a
  real LibreOffice document, changing one thing and saving does not drop the
  rest.
- **Units** are written as you pass them (e.g. `2cm`, `8cm`, `0.5pt`).
- **Validation:** the test suite checks generated files; the interactive ODS
  features (validation, conditional formatting, pivot) are validator-clean —
  final rendering still depends on the consuming application.

See [`getting-started.md`](getting-started.md) for examples and
[`README.md`](../README.md) for the complete API.
