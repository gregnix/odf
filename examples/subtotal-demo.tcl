## examples/subtotal-demo.tcl  --  ODS subtotals (table:subtotal-rules) demo
##
## ODS slice 5: a database range over sales data with subtotal rules -- grouped
## by Region, summing Umsatz and averaging Menge. Open in LibreOffice Calc and
## use Data > Subtotals (the rules are stored on the range); grouped subtotal
## rows are inserted on apply. Uses the same aggregation functions as data
## pilots. Passes the OASIS odfvalidator.
##
## Usage:  tclsh subtotal-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out subtotal-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

set t [$sh addTable "Verkauf"]
$sh addColumns $t 4
$sh addStringRow $t {Region Monat Umsatz Menge}
foreach {region monat umsatz menge} {
    Ost   Jan  120  6
    West  Jan   95  4
    Ost   Feb  140  7
    West  Feb  110  5
    Ost   Mär  160  8
    West  Mär   88  3
} {
    $sh addRow $t [list [list string $region] [list string $monat] \
                        [list float $umsatz] [list float $menge]]
}

# Database range A1:D7 grouped by Region (field 0): sum Umsatz (field 2),
# average Menge (field 3), sorted by Region ascending first.
$sh addDatabaseRange Auswertung "Verkauf.A1:Verkauf.D7" \
    -header true -filter-buttons true \
    -sort {{0 -order asc -type text}} \
    -subtotals {{0 {2 sum} {3 average}}}

$pkg save $outPath
puts "wrote $outPath"
puts "subtotals: [dict get [$sh databaseRanges] Auswertung subtotals]"
$sh destroy; $pkg destroy
