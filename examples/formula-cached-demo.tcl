## examples/formula-cached-demo.tcl  --  ODS formula API with cached values
##
## ODS slice 0.21 (sheet 0.21): demonstrates `setFormula cell formula
## ?value-spec?` -- the cell receives an OpenFormula expression AND a
## cached value in one step. The cached value is what LibreOffice (and
## other ODS consumers) display before they recompute the formula. A
## file with formulas but no cached values shows empty cells in many
## readers; with cached values it displays correctly even before recalc.
##
## Compare to the basic formula-demo.tcl which sets only the formula
## via addRow {formula ...} (no cached value).
##
## Usage:  tclsh formula-cached-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out formula-cached-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]
set t   [$sh addTable "Umsatz"]
$sh addColumns $t 3
$sh addStringRow $t {Quartal Umsatz Anteil}

# Plain numeric data rows
$sh addRow $t {{string Q1} {float 12500} {string ""}}
$sh addRow $t {{string Q2} {float 18200} {string ""}}
$sh addRow $t {{string Q3} {float 15800} {string ""}}
$sh addRow $t {{string Q4} {float 21000} {string ""}}

# Sum row: empty placeholder, then setFormula with cached value
$sh addRow $t {{string "Summe"} {string ""} {string ""}}

set rows [$sh rows $t]
set sumRow [lindex $rows end]
set sumCell [lindex [$sh cells $sumRow] 1]

# slice 0.21: combined formula + cached value in one call.
# OpenFormula prefix `of:=` is added by setFormula automatically.
# Note: braces {...} around formula -- [.B2:.B5] would be Tcl command-sub.
$sh setFormula $sumCell {SUM([.B2:.B5])} {float 67500}

# Percentage column with formula + cached value per row
for {set i 0} {$i < 4} {incr i} {
    set row [lindex $rows [expr {$i + 1}]]
    set cell [lindex [$sh cells $row] 2]
    set rowNum [expr {$i + 2}]
    set values {18.52 26.96 23.41 31.11}
    set cached [lindex $values $i]
    $sh setFormula $cell "\[.B$rowNum\]/\[.B6\]*100" \
                   [list percentage [expr {$cached / 100.0}]]
}

# Verify via reader API
puts "Sum cell has formula:    [$sh cellHasFormula $sumCell]"
puts "Sum cell formula:        [$sh cellFormula $sumCell]"
puts "Sum cell type:           [$sh cellType $sumCell]"
puts "Sum cell value (cached): [$sh cellValue $sumCell]"

$pkg save $outPath
puts "wrote $outPath"
$sh destroy; $pkg destroy
