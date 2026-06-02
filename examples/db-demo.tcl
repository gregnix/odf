## examples/db-demo.tcl  --  ODS database range / AutoFilter demo
##
## ODS slice 4: marks a data range as a table:database-range with AutoFilter
## buttons, a filter (city = Berlin AND value > 100) and a descending sort.
## Open in LibreOffice Calc: the range carries filter dropdowns; Data > More
## Filters shows the stored criteria. Passes the OASIS odfvalidator.
##
## Usage:  tclsh db-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out db-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

set t [$sh addTable "Umsatz"]
$sh addColumns $t 3
$sh addStringRow $t {Stadt Region Wert}
foreach {stadt region wert} {
    Berlin   Ost   142
    Hamburg  Nord   88
    Berlin   Ost   205
    München  Süd   117
    Köln     West   64
    Berlin   Ost    95
} {
    $sh addRow $t [list [list string $stadt] [list string $region] [list float $wert]]
}

# Mark A1:C7 as a filterable database range: AutoFilter dropdowns, a header
# row, filter (Stadt=Berlin AND Wert>100), sorted by Wert descending.
$sh addDatabaseRange Auswertung "Umsatz.A1:Umsatz.C7" \
    -filter-buttons true -header true -orientation column \
    -filter {{0 = Berlin -type text} {2 > 100 -type number}} \
    -sort {{2 -order desc -type number}}

$pkg save $outPath
puts "wrote $outPath"
puts "database ranges: [dict keys [$sh databaseRanges]]"
$sh destroy; $pkg destroy
