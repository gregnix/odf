## test-gaps.tcl -- "expected missing" tests.
##
## These pin down the DELIBERATE gaps in odf so they show up in the test run
## instead of being silently absent ("missing things show themselves", made
## testable). Each test is GREEN while the gap still exists.
##
## IMPORTANT: if a test here turns RED (FAIL), that is NOT a bug -- it means the
## gap has been CLOSED. The correct response is to update this test AND record
## the new feature in ODF-1.3-FEATURES.md + nogit/docs/08-priority-backlog.md.
##
## Covers the large gaps from the priority backlog: no formula engine, pivot
## depth, rich-text cell writing, signatures/encryption, presentations (.odp),
## .odb app tier, and the consumer-evaluated nature of interactive ODS features.

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf
package require odf::sheet
package require odf::base

set pass 0; set fail 0
proc ok {b m} {
    if {[uplevel 1 [list expr $b]]} {
        incr ::pass; puts "ok   $m"
    } else {
        incr ::fail; puts "FAIL $m   <-- gap closed? update test + FEATURES/backlog"
    }
}
# public method matching a glob present on a class? (false if class absent)
proc hasMethod {cls pat} {
    if {![llength [info commands $cls]]} { return 0 }
    foreach m [info class methods $cls -all] { if {[string match $pat $m]} { return 1 } }
    return 0
}
# any proc in the odf namespace matching a glob?
proc hasProc {pat} { expr {[llength [info procs ::odf::$pat]] > 0} }

puts "-- expected-missing / gap tests --"

# === GAP 1: OpenFormula is stored, never evaluated (no engine) ===========
# A formula cell stores table:formula plus a caller-supplied cached value. We
# hand it a deliberately WRONG cached value (99 for 2+3) to prove odf does not
# compute anything: it takes the value verbatim.
set pkg [odf::newSheetDoc]; set sh [odf::Sheet new $pkg]
set t [$sh addTable T]; $sh addColumns $t 1
set rows [$sh rows $t]
$sh addRow $t {{formula of:=2+3 float 99}}
set cell [lindex [$sh cells [lindex [$sh rows $t] end]] 0]
ok {[$sh cellFormula $cell] eq "of:=2+3"}            "GAP: formula stored verbatim (of:=2+3)"
ok {[$sh cellValue $cell] eq "99"}                   "GAP: cached value taken as-is, NOT evaluated (99, not 5)"
ok {![hasMethod odf::Sheet evaluate]}                "GAP: no formula engine (no 'evaluate')"
ok {![hasMethod odf::Sheet recalc] && ![hasMethod odf::Sheet compute]} \
                                                     "GAP: no recalc/compute on Sheet"
$sh destroy; $pkg destroy

# === GAP 2: Pivot/DataPilot is an MVP -- definition only, no deep tier =====
ok {[hasMethod odf::Sheet addDataPilotTable]}        "pivot MVP present (addDataPilotTable)"
ok {![hasMethod odf::Sheet *evel*] && ![hasMethod odf::Sheet *ember*] && ![hasMethod odf::Sheet *roupField*]} \
                                                     "GAP: no data-pilot-groups (level/members/subtotals available since 0.22)"

# === GAP 3: rich-text cell writing is closed since 0.23 ====================
# (removed -- setCellRichText is available; cellText already read rich content.)
# Structural reader for run-by-run access is still cross-module (odf::text::runs
# on the cell's text:p children); a sheet-side convenience would be a future
# slice but is not a behavioural gap.

# === GAP 4: no digital signatures, no encryption (security) ===============
ok {![hasMethod odf::Package sign] && ![hasMethod odf::Package *ignature*]} \
                                                     "GAP: no digital signatures (dsig)"
ok {![hasMethod odf::Package encrypt] && ![hasMethod odf::Package *ncrypt*]} \
                                                     "GAP: no encryption"

# === GAP 5: no presentation (.odp) document type ==========================
ok {![hasProc newPresentationDoc] && ![hasProc newImpressDoc]} \
                                                     "GAP: no .odp presentation builder"

# === GAP 6: .odb is a connector only (no query/report/form app) ===========
ok {[hasProc newBaseDoc]}                            ".odb connector present (newBaseDoc)"
ok {![llength [info commands ::odf::Base]] && ![hasProc *uery*] && ![hasProc *eport*]} \
                                                     "GAP: .odb has no query/report/form app tier"

# === GAP 7: interactive ODS features are consumer-evaluated ===============
# CF / subtotals / pivot / AutoFilter are written and valid, but the *result*
# (colours, summary rows, filled pivot, filtered view) is produced by the
# consumer, not by odf. Pinned via the pivot: the target range is declared but
# odf emits no computed cells into it.
set pkg2 [odf::newSheetDoc]; set sh2 [odf::Sheet new $pkg2]
set s [$sh2 addTable Src]; $sh2 addColumns $s 2
$sh2 addStringRow $s {Region Wert}; $sh2 addRow $s {{string Ost} {float 1}}
$sh2 addDataPilotTable P -source "Src.A1:Src.B2" -target "Out.A1:Out.C12" -field {Region row}
ok {[dict size [$sh2 dataPilotTables]] == 1}         "pivot definition stored"
ok {![hasMethod odf::Sheet computePivot] && ![hasMethod odf::Sheet *illPivot*]} \
                                                     "GAP: pivot result not computed by odf (consumer-evaluated)"
$sh2 destroy; $pkg2 destroy

# === GAP 8: ODS niche structures (label-ranges/dde-links/scenarios) closed since 0.24
# (removed -- addLabelRange, addDDELink, setTableScenario are available.)

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
