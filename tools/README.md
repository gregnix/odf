# tools/

Helper scripts for visual and conformance verification of generated ODF files.
The batch tools default to the repository's `out/` directory, resolved
**relative to the script** (not the current working directory), so they work
from any cwd.

## odftwopdf.tcl
Renders each ODF document in a directory to PDF and PNG (via `soffice` and
`pdftocairo`) for visual inspection. Two PNG variants are produced on purpose:
`<base>.png` (soffice direct) and `<base>-N.png` (from the PDF via pdftocairo,
the reliable route for multi-page Writer output).

    tclsh odftwopdf.tcl ?inDir? ?pdfDir? ?pngDir? ?timeoutSeconds?

Hardened against the LibreOffice headless hang: every `soffice` call runs under
`timeout --kill-after` and gets its own throwaway user profile in `$TMPDIR`
(removed after each call), so a stuck `.odc`/non-page document can neither
block the batch nor poison later calls via the single-instance lock.

## odfvalidate.tcl
Validates each ODF document in a directory against its declared ODF version
using the ODF Toolkit **odfvalidator** (`java -jar`). Prints a PASS/FAIL line
per file plus a summary, and exits non-zero if any file is non-conformant
(CI-friendly).

    tclsh odfvalidate.tcl ?inDir? ?jarPath?

## tclodfval.tcl
Validates **one** file and writes the full report beside it. Designed to live
on the PATH (script + jar copied together): the jar is located relative to the
script itself, resolving symlinks, so it works from any directory.

    tclodfval.tcl <odffile> ?outfile?

## inspect/odf-inspect.tcl
Dumps the structure (styles, blocks, runs, tables, images) of an `.odt` using
the public `odf` API only -- no `soffice`, no jar.

    tclsh inspect/odf-inspect.tcl file.odt

## validator-jar.tcl
Shared helpers (`vjar::find`, `vjar::scriptDir`, `vjar::java`) sourced by
`odfvalidate.tcl`. `tclodfval.tcl` deliberately keeps its own inline copy so it
stays a single self-contained PATH command.

The validator jar is located in this order: an explicit argument, the
`ODFVALIDATOR_JAR` environment variable, or `odfvalidator-*-jar-with-dependencies.jar`
found beside the script, in `tools/validator/`, or in the repo root. The jar is
**not** shipped with the repo (third-party, ODF Toolkit / Apache-2.0); download
it and either set `ODFVALIDATOR_JAR` or drop it in `tools/validator/`.

Validate only self-created, conformant documents (the `out/` directory). The
ODF 1.0 read fixtures under `tests/fixtures/sdk/` are intentionally
non-conformant (legacy OOo namespace) and should not be validated as products.
