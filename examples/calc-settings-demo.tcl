## examples/calc-settings-demo.tcl  --  ODS calculation settings demo
##
## ODS slice 7: sets table:calculation-settings -- how a consumer recalculates
## the sheet. Here: case-insensitive text comparison, wildcards (not regex) in
## formula criteria, the classic 1899-12-30 null date, and iterative calculation
## enabled (for circular references). These influence how LibreOffice evaluates,
## so the effect shows on recalculation rather than in static cell content.
## Passes the OASIS odfvalidator.
##
## Usage:  tclsh calc-settings-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out calc-settings-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

# Recalculation behaviour for the whole document.
$sh setCalculationSettings \
    -case-sensitive false \
    -use-wildcards true \
    -precision-as-shown false \
    -null-date 1899-12-30 \
    -null-year 1930 \
    -iteration {enable -steps 100 -max-difference 0.001}

set t [$sh addTable "Daten"]
$sh addColumns $t 2
$sh addStringRow $t {Posten Betrag}
$sh addRow $t {{string Summe} {float 0}}

$pkg save $outPath
puts "wrote $outPath"
puts "calculation settings: [$sh calculationSettings]"
$sh destroy; $pkg destroy
