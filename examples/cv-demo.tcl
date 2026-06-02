## examples/cv-demo.tcl  --  ODS content validation (data validation) demo
##
## ODS slice 2: defines table:content-validation entries (a list dropdown and
## a numeric range) and attaches them to cells via table:content-validation-name.
## Open in LibreOffice Calc: clicking a validated cell shows the input help,
## the dropdown offers the list, and an out-of-range entry triggers the error.
## Also passes the OASIS odfvalidator.
##
## Usage:  tclsh cv-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out cv-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

# 1) A dropdown list validation (unsorted, no empty cell allowed).
$sh addContentValidation Status \
    -condition {of:cell-content-is-in-list("offen";"in Arbeit";"erledigt")} \
    -allow-empty false -display-list unsorted \
    -help-title "Status wählen" -help-text "Bitte einen der Werte aus der Liste wählen." \
    -error-title "Ungültiger Status" -error-type stop \
    -error-text "Erlaubt sind nur: offen, in Arbeit, erledigt."

# 2) A numeric range validation (1..100), warning only.
$sh addContentValidation Prozent \
    -condition {of:cell-content-is-whole-number() and of:cell-content() >= 0 and of:cell-content() <= 100} \
    -help-title "Fortschritt" -help-text "Ganze Zahl zwischen 0 und 100." \
    -error-title "Außerhalb 0..100" -error-type warning \
    -error-text "Bitte einen Wert zwischen 0 und 100 eingeben."

# Build a small table and attach the validations to the data cells.
set t [$sh addTable "Aufgaben"]
$sh addColumns $t 3
$sh addStringRow $t {Aufgabe Status Fortschritt}      ;# header row

foreach {task status pct} {
    "Konzept"   "erledigt"  100
    "Umsetzung" "in Arbeit"  60
    "Test"      "offen"       0
} {
    set row [$sh addRow $t [list [list string $task] [list string $status] [list float $pct]]]
    set cells [$sh cells $row]
    $sh setCellValidation [lindex $cells 1] Status     ;# Status column
    $sh setCellValidation [lindex $cells 2] Prozent    ;# Fortschritt column
}

$pkg save $outPath
puts "wrote $outPath"
puts "validations: [dict keys [$sh contentValidations]]"
$sh destroy; $pkg destroy
