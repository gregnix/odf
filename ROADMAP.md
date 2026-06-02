# odf — Roadmap

`odf` follows a **pass-through-first** design: it models what you edit and
preserves everything else verbatim. The current release is stable for that
scope (full test suite green), and is deliberately **not** a complete ODF model.
This roadmap lists the next sensible steps; it is not a commitment to dates.

## Near term

- Make the documented scope per subpackage (`text` / `sheet` / `draw` /
  `style` / `chart` / `base`) explicit and versioned: clearly mark what is
  **modelled/supported** vs. what is **pass-through only**.
- Keep README/docs consistent with the actual file set (this `ROADMAP.md`,
  `CHANGES.md`, feature lists).

## Medium term

- Extend LibreOffice interoperability for complex documents, staying
  **round-trip-safe** and **validator-clean**.
- Document which areas are intentionally not fully modelled (pass-through
  first), so users know where to expect raw tdom access.

## Later

- More end-to-end examples for combined workflows
  (`read → edit → save → compare`).

See [`CHANGES.md`](CHANGES.md) for released changes and
[`docs/features.md`](docs/features.md) for the current capability overview.
