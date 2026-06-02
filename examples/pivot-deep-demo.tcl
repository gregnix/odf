## examples/pivot-deep-demo.tcl  --  ODS pivot depth tier 1 demo
##
## ODS slice 0.22 (sheet 0.22): demonstrates the extended field spec
## for `addDataPilotTable` with the new tokens:
##
##   -show-empty BOOL       table:data-pilot-field/@show-empty
##   -subtotals {fn1 fn2}   table:data-pilot-subtotals child
##   -members {{name ?display?} ...}   explicit member list
##
## These produce a `table:data-pilot-level` wrapper inside the pivot
## field, so consumers can render subtotals and selectively show/hide
## members. Compare with the basic pivot-demo.tcl which uses only the
## flat orientation/function form (slice 0.18 MVP).
##
## The pivot result itself is not computed by odf -- LibreOffice
## recomputes when opening the file. This demo shows the *definition*
## of the deeper pivot structure, which the validator and LO accept.
##
## Usage:  tclsh pivot-deep-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out pivot-deep-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

# Source data: sales by region and product, 12 rows
set src [$sh addTable "Verkaeufe"]
$sh addColumns $src 3
$sh addStringRow $src {Region Produkt Umsatz}
foreach {region produkt umsatz} {
    Nord Buch    1200
    Nord Stift    340
    Nord DVD      560
    Sued Buch    1800
    Sued Stift    220
    Sued DVD      810
    Ost  Buch     900
    Ost  Stift    180
    Ost  DVD      450
    West Buch    1500
    West Stift    400
    West DVD      670
} {
    $sh addRow $src [list [list string $region] [list string $produkt] [list float $umsatz]]
}

# Target table for the pivot output (LO writes the computed result here)
# Needs at least one row to satisfy the schema -- LO will overwrite it
# when it recomputes the pivot on open.
set tgt [$sh addTable "Pivot"]
$sh addColumns $tgt 5
$sh addRow $tgt {{string ""}}

# Pivot with depth tier 1:
#   - Region as row dimension WITH subtotals (sum, count) and explicit members
#   - Produkt as column dimension with show-empty + member display flags
#   - Umsatz as data field with sum
$sh addDataPilotTable Umsatzpivot \
    -source "Verkaeufe.A1:Verkaeufe.C13" \
    -target "Pivot.A1:Pivot.E20" \
    -field [list Region row \
             -subtotals {sum count} \
             -members {{Nord} {Sued} {Ost} {West}}] \
    -field [list Produkt column \
             -show-empty true \
             -members {{Buch true} {Stift true} {DVD true}}] \
    -field [list Umsatz data -function sum]

# Reader: verify the level wrapper is preserved
puts "DataPilot tables in document:"
dict for {pivotName pivotDict} [$sh dataPilotTables] {
    puts "  name: $pivotName"
    puts "    source: [dict get $pivotDict source]"
    foreach f [dict get $pivotDict fields] {
        puts "    field:"
        dict for {k v} $f { puts "      $k = $v" }
    }
}

$pkg save $outPath
puts "wrote $outPath"
$sh destroy; $pkg destroy
