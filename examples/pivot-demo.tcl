## examples/pivot-demo.tcl  --  ODS pivot table / data pilot demo
##
## ODS slice 6: a table:data-pilot-table over sales data -- Region as row field,
## Monat as column field, Umsatz as a summed data field, into a target range.
##
## NOTE: a data pilot stores the *definition* only. LibreOffice computes and
## lays out the actual pivot in the target range when the document is opened
## and the pilot is refreshed (Data > Pivot Table > Refresh). A headless
## --convert-to render will usually leave the target range empty -- this is by
## design (ODF defines the format + function semantics, the consumer computes
## the result). The OASIS odfvalidator confirms the definition is conformant.
##
## Usage:  tclsh pivot-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out pivot-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

set t [$sh addTable "Verkauf"]
$sh addColumns $t 3
$sh addStringRow $t {Region Monat Umsatz}
foreach {region monat umsatz} {
    Ost   Jan  120   West  Jan   95
    Ost   Feb  140   West  Feb  110
    Ost   Mär  160   West  Mär   88
} {
    $sh addRow $t [list [list string $region] [list string $monat] [list float $umsatz]]
}

# Pivot definition: rows = Region, columns = Monat, data = sum(Umsatz),
# grand totals on both axes. LibreOffice fills the target range on refresh.
$sh addDataPilotTable Umsatzpivot \
    -source "Verkauf.A1:Verkauf.C7" \
    -target "Verkauf.E1:Verkauf.I12" \
    -grand-total both -show-filter-button true \
    -field {Region row} \
    -field {Monat  column} \
    -field {Umsatz data -function sum}

$pkg save $outPath
puts "wrote $outPath"
puts "pivot fields: [dict get [$sh dataPilotTables] Umsatzpivot fields]"
$sh destroy; $pkg destroy
