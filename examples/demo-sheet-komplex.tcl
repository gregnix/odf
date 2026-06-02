## examples/demo-sheet-komplex.tcl  --  build a rich multi-sheet ODS
##
## Exercises the whole odf::sheet writer: several sheets, every value type,
## number formats (data styles + cell formats), merges (horizontal / vertical /
## 2x2) and formulas with cached results. Counterpart to the comprehensive read
## fixture -- but generated. Open the result in LibreOffice / run odfvalidator.
##
## Usage:  tclsh demo-sheet-komplex.tcl ?out.ods?

fconfigure stdout -encoding utf-8
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet
package require odf::style

set outPath [expr {[llength $argv] >= 1 ? [lindex $argv 0] \
                   : [file join [file dirname [info script]] .. out komplex.ods]}]
file mkdir [file dirname $outPath]

set pkg [odf::newSheetDoc]

# page setup + header/footer (styles.xml) -- bound to the Umsatz sheet below.
set sty [odf::Styles new $pkg]
$sty definePageFormat PMquer A4 -orientation landscape -margins {2cm 1.5cm 2cm 1.5cm}
$sty defineMasterPage MPbericht -pagelayout PMquer
$sty setHeader MPbericht {{"odf::sheet \u2014 Gesch\u00e4ftsbericht 2026"}}
$sty setFooter MPbericht {{"Seite %page% / %pages%"}}
$sty flush
$sty destroy

set sh  [odf::Sheet new $pkg]

# -------- shared number formats (data styles) + table-cell formats --------
$sh definePercentageStyle nPct -decimals 1
$sh defineCurrencyStyle   nEur -decimals 2 -symbol "\u20ac" -grouping 1
$sh defineDateStyle       nDat -order dmy -sep .
$sh defineNumberStyle     nNum -decimals 0 -grouping 1
$sh defineBooleanStyle    nBoo
$sh defineCellFormat cePct nPct
$sh defineCellFormat ceEur nEur
$sh defineCellFormat ceDat nDat
$sh defineCellFormat ceNum nNum
$sh defineCellFormat ceBoo nBoo
# header cells: light blue background (shows the -cell properties option)
$sh defineCellFormat ceHdr "" -cell {fo:background-color #d0e0ff}

# ============ Sheet 1: Übersicht (merged title + key/value) ============
set t1 [$sh addTable "\u00dcbersicht"]
$sh addColumns $t1 4
$sh addRow $t1 {{string "Gesch\u00e4ftsbericht 2026 \u2014 odf::sheet Demo"} {string {}} {string {}} {string {}}}
$sh addRow $t1 {{string Erstellt}  {date 2026-05-25} {string Autor}  {string odf::sheet}} {{} ceDat {} {}}
$sh addRow $t1 {{string Freigabe}  {boolean true}    {string Bl\u00e4tter} {float 4}}     {{} ceBoo {} ceNum}
$sh mergeCells $t1 0 0 4 1   ;# title spans all 4 columns

# ============ Sheet 2: Datentypen (every value type, formatted) ============
set t2 [$sh addTable "Datentypen"]
$sh addColumns $t2 3
$sh addRow $t2 {{string Typ} {string Wert} {string Hinweis}} {ceHdr ceHdr ceHdr}
$sh addRow $t2 {{string Text}     {string "M\u00fcller & S\u00f6hne"} {string "Unicode, Ampersand"}}
$sh addRow $t2 {{string Ganzzahl} {float 1234567}            {string "number, grouping"}} {{} ceNum {}}
$sh addRow $t2 {{string Prozent}  {percentage 0.237}         {string percentage}}        {{} cePct {}}
$sh addRow $t2 {{string Betrag}   {currency 1999.9 EUR}      {string currency}}          {{} ceEur {}}
$sh addRow $t2 {{string Datum}    {date 2026-06-02}          {string date}}              {{} ceDat {}}
$sh addRow $t2 {{string Zeit}     {time PT9H30M}             {string time}}
$sh addRow $t2 {{string Wahrheit} {boolean false}           {string boolean}}           {{} ceBoo {}}

# ============ Sheet 3: Umsatz (data block, SUM formulas, totals) ============
# bound to the landscape master page (header/footer) and given column widths.
set taBericht [$sh defineTableStyle taBericht -master MPbericht]
set t3 [$sh addTable "Umsatz" $taBericht]
$sh addColumnWidths $t3 {3cm 2.2cm 2.2cm 2.2cm 2.2cm 2.6cm}
$sh addRow $t3 {{string "Umsatz nach Region (in \u20ac)"} {string {}} {string {}} {string {}} {string {}} {string {}}}
$sh addRow $t3 {{string Region} {string Q1} {string Q2} {string Q3} {string Q4} {string Summe}} \
              {ceHdr ceHdr ceHdr ceHdr ceHdr ceHdr}

set regions {Nord S\u00fcd West Ost}
set vals {{100 120 110 140} {200 250 200 280} {300 370 290 420} {400 490 380 560}}
set colsum {0 0 0 0}
set rownum 3   ;# 1-based spreadsheet row of the first data row (title=1, header=2)
foreach r $regions v $vals {
    lassign $v q1 q2 q3 q4
    set rowsum [expr {$q1 + $q2 + $q3 + $q4}]
    set f [format {of:=SUM([.B%d:.E%d])} $rownum $rownum]
    set cells [list [list string $r] \
                    [list currency $q1 EUR] [list currency $q2 EUR] \
                    [list currency $q3 EUR] [list currency $q4 EUR] \
                    [list formula $f currency $rowsum EUR]]
    $sh addRow $t3 $cells {{} ceEur ceEur ceEur ceEur ceEur}
    for {set i 0} {$i < 4} {incr i} { lset colsum $i [expr {[lindex $colsum $i] + [lindex $v $i]}] }
    incr rownum
}
# totals row: column sums + grand total, as formulas with correct cached values
set last [expr {$rownum - 1}]
set grand [expr {[lindex $colsum 0] + [lindex $colsum 1] + [lindex $colsum 2] + [lindex $colsum 3]}]
set tot [list {string Gesamt}]
foreach col {B C D E} cs $colsum {
    lappend tot [list formula [format {of:=SUM([.%s3:.%s%d])} $col $col $last] currency $cs EUR]
}
lappend tot [list formula [format {of:=SUM([.F3:.F%d])} $last] currency $grand EUR]
$sh addRow $t3 $tot {ceHdr ceEur ceEur ceEur ceEur ceEur}
$sh mergeCells $t3 0 0 6 1   ;# title spans all 6 columns

# ============ Sheet 4: Merges (horizontal, vertical, 2x2) ============
set t4 [$sh addTable "Merges"]
$sh addColumns $t4 4
$sh addRow $t4 {{string "Horizontal 1\u00d73"} {string {}} {string {}} {string Rand}}
$sh addRow $t4 {{string "Vertikal 2\u00d71"} {string b1} {string c1} {string d1}}
$sh addRow $t4 {{string {}}            {string b2} {string c2} {string d2}}
$sh addRow $t4 {{string "Block 2\u00d72"} {string {}} {string x1} {string y1}}
$sh addRow $t4 {{string {}}            {string {}} {string x2} {string y2}}
$sh mergeCells $t4 0 0 3 1   ;# horizontal across 3 columns
$sh mergeCells $t4 1 0 1 2   ;# vertical across 2 rows
$sh mergeCells $t4 3 0 2 2   ;# 2x2 block

$sh flush
$sh destroy
$pkg save $outPath
$pkg destroy
puts "geschrieben: $outPath"
