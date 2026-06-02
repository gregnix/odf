## examples/demo-sheet.tcl  --  Demo: write an ODS spreadsheet (odf::sheet)
##
## Usage:  tclsh demo-sheet.tcl
##   ->  out/sheet.ods   (in LibreOffice Calc oeffnen)

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::sheet

set pkg [odf::newSheetDoc]
set sh  [odf::Sheet new $pkg]

set t [$sh addTable "Verkauf"]
$sh addColumns $t 3
$sh addStringRow $t {Artikel Stueck Preis}
$sh addRow $t {{string Schrauben} {float 250} {float 0.05}}
$sh addRow $t {{string Muttern}   {float 250} {float 0.04}}
$sh addRow $t {{string Bretter}   {float 12}  {float 3.20}}

# second sheet: typed cells with number formats (renders 23,7% / 9,50 € / ...)
set t2 [$sh addTable "Typen"]
$sh addColumns $t2 2
$sh definePercentageStyle fPct -decimals 1
$sh defineCurrencyStyle  fCur -decimals 2 -symbol "\u20ac"
$sh defineDateStyle      fDat -order dmy -sep .
$sh defineTimeStyle      fTim
$sh defineBooleanStyle   fBoo
$sh defineCellFormat cePct fPct
$sh defineCellFormat ceCur fCur
$sh defineCellFormat ceDat fDat
$sh defineCellFormat ceTim fTim
$sh defineCellFormat ceBoo fBoo
$sh addStringRow $t2 {Typ Wert}
$sh addRow $t2 {{string Prozent}  {percentage 0.237}}      {{} cePct}
$sh addRow $t2 {{string Betrag}   {currency 9.50 EUR}}     {{} ceCur}
$sh addRow $t2 {{string Datum}    {date 2026-06-02}}       {{} ceDat}
$sh addRow $t2 {{string Zeit}     {time PT1H30M}}          {{} ceTim}
$sh addRow $t2 {{string Wahrheit} {boolean true}}          {{} ceBoo}

# third sheet: a merged title across the table + a SUM formula
set t3 [$sh addTable "Bericht"]
$sh addColumns $t3 3
$sh addRow $t3 {{string "Quartalsbericht Nord"} {string {}} {string {}}}
$sh addRow $t3 {{string Posten} {string Q1} {string Q2}}
$sh addRow $t3 {{string Umsatz} {float 100} {float 120}}
$sh addRow $t3 [list {string Summe} {float 100} [list formula {of:=SUM([.B3:.C3])} float 220]]
$sh mergeCells $t3 0 0 3 1

$sh flush
$sh destroy
set path [file join $out sheet.ods]
$pkg save $path
$pkg destroy
puts "geschrieben: $path"
