# tests/fixtures/sdk — Herkunft der Real-World-Fixtures

Diese ODF-Dokumente sind **Beispieldateien aus dem LibreOffice/OpenOffice.org SDK**
(„api.libreoffice.org" Developer Guide & Basic-Beispiele). Sie werden hier
ausschließlich als **Lese-/Pass-through-Test-Fixtures** verwendet — die `odf`-
Bibliothek erzeugt sie nicht und verändert sie nicht.

## Eigenschaften

| Datei | Typ | Feature-Schwerpunkt |
|-------|-----|---------------------|
| `index.odt` | Text | Inhaltsverzeichnis/Index, Überschriften, `office:forms` (Pass-through) |
| `inserting_bookmarks.odt` | Text | Lesezeichen |
| `burger_factory.odt` | Text | Formulare/Controls (`office:forms`), viele Absätze |
| `TextTemplateWithUserFields.odt` | Text | Benutzerfelder |
| `ToDo.ods` | Spreadsheet | Calc-Lesen |
| `importexportofasciifiles.odg` | Drawing | Draw-Container |
| `SimplePresentation.odp` | Presentation | Container ohne Presentation-Modell (Pass-through) |

- **Generator:** StarOffice 8 Beta (OpenOffice.org 680m66 / 680m73, ~2005).
- **ODF-Version:** **1.0** (alle). Damit testen sie **Lesen, Pass-through und
  Versions-Erkennung** an echten Alt-Dokumenten quer über die vier Dokumenttypen —
  *nicht* ODF-1.3-Konformität (dafür sind die selbst erzeugten Dokumente da).
- **Konformität:** Diese Dateien benutzen den **alten OOo-Manifest-Namespace**
  (`http://openoffice.org/2001/manifest`) + alten DTD-Doctype und enthalten
  Alt-Inhalts-Quirks (`form:delay-for-repeat`, `style:table-properties` an Stelle,
  `dc:date`-Platzierung). Sie sind daher **nicht konform zu einem strikten ODF-
  Validator** — das ist Eigenschaft der Quelle, nicht von `odf`. `odf` reicht alles
  **byte-getreu** durch (verifiziert: Manifest original ↔ gespeichert identisch).
  Deshalb schreibt der Lesetest seine Round-Trip-Kopien in ein **Wegwerf-Temp-
  Verzeichnis** und *nicht* nach `out/` — damit diese Fremd-Kopien nicht als
  vermeintliche `odf`-Produkte validiert werden.

## Lizenz / Weitergabe

Die Dateien stammen aus den **LibreOffice SDK-Beispielen** und unterliegen deren
Lizenzbedingungen (LibreOffice SDK / api.libreoffice.org, MPL-2.0 / Apache-2.0-nahe
Beispiel-Lizenz). Sie liegen hier nur als Testdaten. Vor einer **Weitergabe** des
Repos sollte die Lizenzlage der SDK-Beispiele geprüft werden; alternativ lassen sich
die Fixtures jederzeit durch selbst mit `odf` erzeugte Dokumente ersetzen.

## Test

`tests/test-readsamples.tcl` lädt jede Datei, prüft Versions-Lesen, Block-
Klassifikation (Textdokumente) und einen Save/Reload-Round-Trip (Pass-through:
unmodellierte Knoten wie `office:forms` bleiben erhalten).
