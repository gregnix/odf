## examples/ods-niches-demo.tcl  --  ODS completeness niches
##
## ODS slice 0.24 (sheet 0.24): demonstrates three small but useful
## ODS structures shipped together:
##
##   addLabelRange LABEL-RANGE DATA-RANGE ?-orientation column|row?
##       Header-area-to-data-area association so formulas can use
##       label references (`=Region` instead of `=A2:A5`).
##
##   setTableScenario TABLE -ranges {R...} ?options?
##       Singleton table:scenario child of a table:table -- marks a
##       cell area as a what-if scenario with border / copy semantics.
##
##   addDDELink NAME -application APP -topic T -item I
##                  ?-auto-update BOOL? ?-conversion-mode V?
##       Defines a DDE (Dynamic Data Exchange) connection so external
##       sources can be referenced. Legacy but standard ODF.
##
## All three are body-level structures; scenario is per-table. The
## demo applies all three to a single sales-data sheet so a single
## file shows the round-trip.
##
## Usage:  tclsh ods-niches-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out ods-niches-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

# --- Source data table -----------------------------------------------
set t [$sh addTable "Verkauf"]
$sh addColumns $t 3
$sh addStringRow $t {Region Q1 Q2}
$sh addRow $t {{string Nord}  {float 12500} {float 13800}}
$sh addRow $t {{string Sued}  {float 18200} {float 19500}}
$sh addRow $t {{string Ost}   {float 15800} {float 14900}}
$sh addRow $t {{string West}  {float 21000} {float 22100}}

# --- 1) Label-Ranges -------------------------------------------------
# A1:C1 are headers (column labels). A2:A5 are row labels (regions).
# After this, formulas could reference labels by name.
$sh addLabelRange "Verkauf.A1:Verkauf.C1" "Verkauf.A2:Verkauf.C5" -orientation column
$sh addLabelRange "Verkauf.A2:Verkauf.A5" "Verkauf.B2:Verkauf.C5" -orientation row

# --- 2) Scenario -----------------------------------------------------
# Mark the data area as a "Baseline" what-if scenario, with red border,
# copy-back semantics (so user-edits propagate to the source area).
$sh setTableScenario $t \
    -ranges [list "Verkauf.B2:Verkauf.C5"] \
    -active true \
    -display-border true \
    -border-color "#cc0000" \
    -copy-back true \
    -copy-styles true

# --- 3) DDE-Links ----------------------------------------------------
# Two DDE references: one auto-updating from a market-data feed,
# one with explicit conversion-mode for text-typed values.
$sh addDDELink "MarketFeed" \
    -application excel -topic "RealtimeData" -item "EUR/USD" \
    -auto-update true
$sh addDDELink "LegacyImport" \
    -application soffice -topic "spread" -item "Sheet1.A1:B10" \
    -conversion-mode keep-text

# --- Verification via the read-back APIs -----------------------------
puts "Label ranges:"
foreach lr [$sh labelRanges] {
    lassign $lr label data orientation
    puts "  label=$label  data=$data  orientation=$orientation"
}

puts "\nTable scenario on 'Verkauf':"
dict for {k v} [$sh tableScenario $t] {
    if {$v ne ""} { puts "  $k = $v" }
}

puts "\nDDE links:"
dict for {name dd} [$sh ddeLinks] {
    puts "  '$name':"
    dict for {k v} $dd {
        if {$v ne ""} { puts "    $k = $v" }
    }
}

$pkg save $outPath
puts "\nwrote $outPath"
$sh destroy; $pkg destroy
