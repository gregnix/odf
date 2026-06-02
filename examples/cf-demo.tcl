## examples/cf-demo.tcl  --  ODS conditional formatting (style:map) demo
##
## ODS slice 3: defines target cell styles (red / green) and a conditional
## style whose style:map entries apply them by value. Open in LibreOffice Calc:
## values above the threshold turn red, negative values turn green -- the
## official ODF style:map mechanism (no calcext extension needed). Passes the
## OASIS odfvalidator.
##
## Usage:  tclsh cf-demo.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out cf-demo.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

# Target styles, applied when a condition holds.
$sh defineCellFormat HighStyle "" -cell {fo:background-color #f8c9c9}
$sh defineCellFormat LowStyle  "" -cell {fo:background-color #c9e8c9}

# Conditional style: > 100 -> red bg + bold red text; < 0 -> green bg.
$sh defineConditionalFormat Wert \
    -text {fo:font-weight bold} \
    -map {value()>100 HighStyle} \
    -map {value()<0   LowStyle}

set t [$sh addTable "Messwerte"]
$sh addColumns $t 2
$sh addStringRow $t {Monat Wert}

foreach {monat wert} {Jan 42 Feb 150 Mär -8 Apr 99 Mai 220 Jun -3} {
    # apply the conditional style to the value cell (2nd column)
    $sh addRow $t [list [list string $monat] [list float $wert]] {"" Wert}
}

$pkg save $outPath
puts "wrote $outPath"
puts "style:map on 'Wert': [$sh styleMaps Wert]"
$sh destroy; $pkg destroy
