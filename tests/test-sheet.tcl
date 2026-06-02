## tests/test-sheet.tcl  --  ODS spreadsheet (odf::sheet), slice 1
## Build a spreadsheet from scratch, save, reload and verify structure +
## cell types/values. No fixture needed.

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::sheet
package require odf::style
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) build from scratch ----
set pkg [odf::newSheetDoc]
ok {[$pkg mimetype] eq "application/vnd.oasis.opendocument.spreadsheet"} "A: spreadsheet mimetype"
set sh [odf::Sheet new $pkg]
set t  [$sh addTable "Daten"]
$sh addColumns $t 3
$sh addStringRow $t {Name Menge Notiz}
$sh addRow $t {{string Bob}   {float 42}  {string ok}}
$sh addRow $t {{string Alice} {float 3.5} {string {Umlaut äöü}}}
ok {[catch {$sh addRow $t {{float xx}}}] == 1} "A: non-numeric float rejected"
$sh flush
$sh destroy
set odsPath [file join $out sheet.ods]
$pkg save $odsPath
$pkg destroy

# ---- B) reload + verify ----
set p2 [odf::Package new $odsPath]
ok {[lindex [$p2 parts] 0] eq "mimetype"} "B: mimetype is first ZIP entry"
set s2 [odf::Sheet new $p2]
set tabs [$s2 tables]
ok {[llength $tabs] == 1}                       "B: one table"
set tt [lindex $tabs 0]
ok {[$s2 tableName $tt] eq "Daten"}             "B: table name"
ok {[llength [$s2 columns $tt]] == 3}           "B: three columns"
set rows [$s2 rows $tt]
ok {[llength $rows] == 3}                        "B: three rows"

# header row: three string cells
set h [$s2 cells [lindex $rows 0]]
ok {[llength $h] == 3}                           "B: header has 3 cells"
ok {[$s2 cellType [lindex $h 0]] eq "string"}   "B: header cell is string"
ok {[$s2 cellText [lindex $h 1]] eq "Menge"}    "B: header text"

# data row 1: string / float / string
set r1 [$s2 cells [lindex $rows 1]]
ok {[$s2 cellType  [lindex $r1 0]] eq "string"} "B: r1c0 type string"
ok {[$s2 cellValue [lindex $r1 0]] eq "Bob"}    "B: r1c0 value"
ok {[$s2 cellType  [lindex $r1 1]] eq "float"}  "B: r1c1 type float"
ok {[$s2 cellValue [lindex $r1 1]] eq "42"}     "B: r1c1 office:value"
ok {[$s2 cellText  [lindex $r1 1]] eq "42"}     "B: r1c1 display text"

# data row 2: float 3.5 + umlauts preserved
set r2 [$s2 cells [lindex $rows 2]]
ok {[$s2 cellValue [lindex $r2 1]] eq "3.5"}        "B: r2c1 float 3.5"
ok {[$s2 cellText  [lindex $r2 2]] eq "Umlaut äöü"} "B: r2c2 umlauts preserved"
$s2 destroy

# ---- C) every part well-formed (namespace-clean) ----
foreach part {content.xml styles.xml META-INF/manifest.xml meta.xml} {
    set wf [expr {![catch {dom parse [encoding convertfrom utf-8 [$p2 part $part]] d}]}]
    if {$wf} { $d delete }
    ok {$wf} "C: $part well-formed"
}
$p2 destroy

# ---- D) repeat expansion + trailing-fill trimming (slice 2, read) ----
# Hand-crafted content.xml as a real Calc file would emit it: repeated cells,
# a repeated data row, and huge trailing fill on cells AND rows.
set craft {<?xml version="1.0" encoding="UTF-8"?>
<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" office:version="1.3"><office:body><office:spreadsheet>
<table:table table:name="T">
 <table:table-column table:number-columns-repeated="3"/>
 <table:table-row>
  <table:table-cell office:value-type="string"><text:p>A</text:p></table:table-cell>
  <table:table-cell office:value-type="string"><text:p>B</text:p></table:table-cell>
  <table:table-cell office:value-type="string"><text:p>C</text:p></table:table-cell>
  <table:table-cell table:number-columns-repeated="16381"/>
 </table:table-row>
 <table:table-row table:number-rows-repeated="2">
  <table:table-cell office:value-type="float" office:value="7"><text:p>7</text:p></table:table-cell>
  <table:table-cell table:number-columns-repeated="2"/>
  <table:table-cell office:value-type="string"><text:p>end</text:p></table:table-cell>
  <table:table-cell table:number-columns-repeated="16380"/>
 </table:table-row>
 <table:table-row table:number-rows-repeated="1048573">
  <table:table-cell table:number-columns-repeated="16384"/>
 </table:table-row>
</table:table>
</office:spreadsheet></office:body></office:document-content>}

set pkg3 [odf::newSheetDoc]
$pkg3 setpart content.xml [encoding convertto utf-8 $craft]
set s3 [odf::Sheet new $pkg3]
set tt3 [lindex [$s3 tables] 0]
set R [$s3 rows $tt3]
ok {[llength $R] == 3}                                 "D: 3 logical rows (header + 2x repeated data; trailing fill dropped)"
# header: trailing fill cell trimmed -> 3 cells
set hc [$s3 cells [lindex $R 0]]
ok {[llength $hc] == 3}                                "D: header expands to 3 cells (16381-fill trimmed)"
ok {[$s3 cellText [lindex $hc 2]] eq "C"}              "D: header last cell C"
# data row: 7, gap(2 empty), end ; trailing fill trimmed -> 4 cells
set dc [$s3 cells [lindex $R 1]]
ok {[llength $dc] == 4}                                "D: data row expands to 4 cells (gap kept, fill trimmed)"
ok {[$s3 cellType  [lindex $dc 0]] eq "float"}         "D: data c0 float"
ok {[$s3 cellValue [lindex $dc 0]] eq "7"}             "D: data c0 value 7"
ok {[$s3 cellType  [lindex $dc 1]] eq ""}              "D: data c1 is an empty gap cell"
ok {[$s3 cellText  [lindex $dc 3]] eq "end"}           "D: data c3 = end"
# the repeated data row yields an identical second row
set dc2 [$s3 cells [lindex $R 2]]
ok {[llength $dc2] == 4 && [$s3 cellText [lindex $dc2 3]] eq "end"} "D: repeated row identical"
# width = widest logical row, columns bounded by it
ok {[$s3 width $tt3] == 4}                             "D: width 4"
ok {[llength [$s3 columns $tt3]] == 3}                 "D: 3 columns (col-repeat=3, bounded by width)"
$s3 destroy
$pkg3 destroy

# ---- E) typed values, rich/multi-paragraph text, merges (slice 3, read) ----
set craftE {<?xml version="1.0" encoding="UTF-8"?>
<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" office:version="1.3"><office:body><office:spreadsheet>
<table:table table:name="V">
 <table:table-row>
  <table:table-cell office:value-type="float" office:value="3.5"><text:p>3,5</text:p></table:table-cell>
  <table:table-cell office:value-type="percentage" office:value="0.237"><text:p>23,7%</text:p></table:table-cell>
  <table:table-cell office:value-type="currency" office:currency="EUR" office:value="2.87"><text:p>2,87 €</text:p></table:table-cell>
  <table:table-cell office:value-type="date" office:date-value="2026-06-02"><text:p>02.06.2026</text:p></table:table-cell>
  <table:table-cell office:value-type="time" office:time-value="PT01H30M00S"><text:p>01:30</text:p></table:table-cell>
  <table:table-cell office:value-type="boolean" office:boolean-value="true"><text:p>WAHR</text:p></table:table-cell>
 </table:table-row>
 <table:table-row>
  <table:table-cell office:value-type="string"><text:p>Zeile1</text:p><text:p>Zeile2</text:p></table:table-cell>
  <table:table-cell office:value-type="string"><text:p>a<text:s text:c="3"/>b</text:p></table:table-cell>
 </table:table-row>
 <table:table-row>
  <table:table-cell office:value-type="string" table:number-columns-spanned="2" table:number-rows-spanned="1"><text:p>Titel</text:p></table:table-cell>
  <table:covered-table-cell/>
  <table:table-cell office:value-type="string"><text:p>X</text:p></table:table-cell>
 </table:table-row>
</table:table>
</office:spreadsheet></office:body></office:document-content>}

set pkgE [odf::newSheetDoc]
$pkgE setpart content.xml [encoding convertto utf-8 $craftE]
set sE [odf::Sheet new $pkgE]
set tE [lindex [$sE tables] 0]
set RE [$sE rows $tE]
ok {[llength $RE] == 3} "E: 3 rows"

# typed values per value-type
set v [$sE cells [lindex $RE 0]]
ok {[$sE cellValue [lindex $v 0]] eq "3.5"}        "E: float value"
ok {[$sE cellValue [lindex $v 1]] eq "0.237"}      "E: percentage value"
ok {[$sE cellValue [lindex $v 2]] eq "2.87"}       "E: currency value"
ok {[$sE cellCurrency [lindex $v 2]] eq "EUR"}     "E: currency code"
ok {[$sE cellValue [lindex $v 3]] eq "2026-06-02"} "E: date value (office:date-value)"
ok {[$sE cellValue [lindex $v 4]] eq "PT01H30M00S"} "E: time value (office:time-value)"
ok {[$sE cellValue [lindex $v 5]] eq "true"}       "E: boolean value"

# rich / multi-paragraph text
set v2 [$sE cells [lindex $RE 1]]
ok {[$sE cellText [lindex $v2 0]] eq "Zeile1\nZeile2"} "E: multi-paragraph joined by newline"
ok {[$sE cellText [lindex $v2 1]] eq "a   b"}          "E: text:s expands to spaces"

# merge: anchor spans 2 cols, covered placeholder kept, then X
set v3 [$sE cells [lindex $RE 2]]
ok {[llength $v3] == 3}                                "E: merge row has 3 positions (anchor, covered, X)"
ok {[$sE cellSpan [lindex $v3 0]] eq {2 1}}            "E: anchor cellSpan 2x1"
ok {![$sE cellCovered [lindex $v3 0]]}                 "E: anchor not covered"
ok {[$sE cellCovered [lindex $v3 1]]}                  "E: middle cell is covered"
ok {[$sE cellText [lindex $v3 2]] eq "X"}              "E: cell after merge = X"
$sE destroy
$pkgE destroy

# ---- F) formula read (slice 4) ----
set craftF {<?xml version="1.0" encoding="UTF-8"?>
<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" office:version="1.3"><office:body><office:spreadsheet>
<table:table table:name="F">
 <table:table-row>
  <table:table-cell office:value-type="float" office:value="3"><text:p>3</text:p></table:table-cell>
  <table:table-cell office:value-type="float" office:value="7"><text:p>7</text:p></table:table-cell>
  <table:table-cell table:formula="of:=SUM([.A1:.B1])" office:value-type="float" office:value="10"><text:p>10</text:p></table:table-cell>
 </table:table-row>
</table:table>
</office:spreadsheet></office:body></office:document-content>}

set pkgF [odf::newSheetDoc]
$pkgF setpart content.xml [encoding convertto utf-8 $craftF]
set sF [odf::Sheet new $pkgF]
set cF [$sF cells [lindex [$sF rows [lindex [$sF tables] 0]] 0]]
set sum [lindex $cF 2]
set expFormula {of:=SUM([.A1:.B1])}
ok {[$sF cellFormula $sum] eq $expFormula}          "F: cellFormula raw OpenFormula"
ok {[$sF cellValue   $sum] eq "10"}                 "F: cellValue is the computed result"
ok {[$sF cellFormula [lindex $cF 0]] eq ""}         "F: plain cell has no formula"
$sF destroy
$pkgF destroy

# ---- G) write typed cells, read back (slice 5, write) ----
set pkgG [odf::newSheetDoc]
set sG [odf::Sheet new $pkgG]
set tG [$sG addTable "Typed"]
$sG addRow $tG {{string Txt} {float 1234.567} {percentage 0.237} {currency 9.5 EUR} {date 2026-06-02} {time PT1H30M} {boolean true}}
ok {[catch {$sG addRow $tG {{boolean vielleicht}}}] == 1} "G: invalid boolean rejected"
$sG flush
$sG destroy
set gPath [file join $out typed.ods]
$pkgG save $gPath
$pkgG destroy

set p7 [odf::Package new $gPath]
set s7 [odf::Sheet new $p7]
set c7 [$s7 cells [lindex [$s7 rows [lindex [$s7 tables] 0]] 0]]
ok {[llength $c7] == 7}                              "G: 7 typed cells"
ok {[$s7 cellType  [lindex $c7 0]] eq "string"}      "G: string type"
ok {[$s7 cellType  [lindex $c7 1]] eq "float"}       "G: float type"
ok {[$s7 cellValue [lindex $c7 1]] eq "1234.567"}    "G: float value"
ok {[$s7 cellType  [lindex $c7 2]] eq "percentage"}  "G: percentage type"
ok {[$s7 cellValue [lindex $c7 2]] eq "0.237"}       "G: percentage value"
ok {[$s7 cellType  [lindex $c7 3]] eq "currency"}    "G: currency type"
ok {[$s7 cellValue [lindex $c7 3]] eq "9.5"}         "G: currency value"
ok {[$s7 cellCurrency [lindex $c7 3]] eq "EUR"}      "G: currency code"
ok {[$s7 cellType  [lindex $c7 4]] eq "date"}        "G: date type"
ok {[$s7 cellValue [lindex $c7 4]] eq "2026-06-02"}  "G: date value"
ok {[$s7 cellType  [lindex $c7 5]] eq "time"}        "G: time type"
ok {[$s7 cellValue [lindex $c7 5]] eq "PT1H30M"}     "G: time value"
ok {[$s7 cellType  [lindex $c7 6]] eq "boolean"}     "G: boolean type"
ok {[$s7 cellValue [lindex $c7 6]] eq "true"}        "G: boolean value"
# conformance: parts still well-formed
set okwf 1
foreach part {content.xml styles.xml META-INF/manifest.xml meta.xml} {
    if {[catch {dom parse [encoding convertfrom utf-8 [$p7 part $part]] dd}]} { set okwf 0 } else { $dd delete }
}
ok {$okwf} "G: all parts well-formed"
$s7 destroy
$p7 destroy

# ---- H) number formats (slice 6): define, assign, read the style chain ----
set pkgH [odf::newSheetDoc]
set sH [odf::Sheet new $pkgH]
$sH definePercentageStyle Pct -decimals 1
$sH defineCurrencyStyle  Cur -decimals 2 -symbol "EUR" -grouping 1
$sH defineDateStyle      Dat -order dmy -sep .
$sH defineTimeStyle      Tim -seconds 0
$sH defineNumberStyle    Num -decimals 2 -grouping 1
$sH defineBooleanStyle   Boo
$sH defineCellFormat cePct Pct
$sH defineCellFormat ceCur Cur
$sH defineCellFormat ceDat Dat
set tH [$sH addTable "Fmt"]
$sH addRow $tH {{percentage 0.237} {currency 9.5 EUR} {date 2026-06-02}} {cePct ceCur ceDat}
$sH flush
$sH destroy
set hPath [file join $out fmt.ods]
$pkgH save $hPath
$pkgH destroy

set p8 [odf::Package new $hPath]
set s8 [odf::Sheet new $p8]
set c8 [$s8 cells [lindex [$s8 rows [lindex [$s8 tables] 0]] 0]]
ok {[$s8 cellStyleName [lindex $c8 0]] eq "cePct"}  "H: cell0 style-name cePct"
ok {[$s8 dataStyleOf cePct] eq "Pct"}               "H: cePct -> data style Pct"
ok {[$s8 cellStyleName [lindex $c8 1]] eq "ceCur"}  "H: cell1 style-name ceCur"
ok {[$s8 dataStyleOf ceCur] eq "Cur"}               "H: ceCur -> data style Cur"
ok {[$s8 dataStyleOf ceDat] eq "Dat"}               "H: ceDat -> data style Dat"
# the value-type is still correct alongside the format
ok {[$s8 cellType [lindex $c8 0]] eq "percentage"}  "H: cell0 still percentage typed"

# data-style elements exist with the right element name in automatic-styles
set doc [$p8 tree content.xml]
proc dataStyleTag {doc name} {
    foreach tag {number:number-style number:percentage-style number:currency-style number:date-style number:time-style number:boolean-style} {
        foreach e [[$doc documentElement] getElementsByTagName $tag] {
            if {[$e getAttribute style:name ""] eq $name} { return $tag }
        }
    }
    return ""
}
ok {[dataStyleTag $doc Pct] eq "number:percentage-style"} "H: Pct is a percentage-style"
ok {[dataStyleTag $doc Cur] eq "number:currency-style"}   "H: Cur is a currency-style"
ok {[dataStyleTag $doc Dat] eq "number:date-style"}       "H: Dat is a date-style"
ok {[dataStyleTag $doc Tim] eq "number:time-style"}       "H: Tim is a time-style"
ok {[dataStyleTag $doc Boo] eq "number:boolean-style"}    "H: Boo is a boolean-style"
$doc delete
# parts well-formed
set okwf2 1
foreach part {content.xml styles.xml META-INF/manifest.xml meta.xml} {
    if {[catch {dom parse [encoding convertfrom utf-8 [$p8 part $part]] d3}]} { set okwf2 0 } else { $d3 delete }
}
ok {$okwf2} "H: all parts well-formed"
$s8 destroy
$p8 destroy

# ---- I) mandatory table:table-column structure ensured at flush (slice 7) ----
set pkgI [odf::newSheetDoc]
set sI [odf::Sheet new $pkgI]
set tI [$sI addTable "NoCols"]
$sI addStringRow $tI {A B C}
$sI addRow $tI {{string x} {float 1}}      ;# narrower row
$sI flush                                   ;# no addColumns called on purpose
$sI destroy
set iPath [file join $out nocols.ods]
$pkgI save $iPath
$pkgI destroy

set p9 [odf::Package new $iPath]
set s9 [odf::Sheet new $p9]
set t9 [lindex [$s9 tables] 0]
# columns now exist and cover the widest row (3)
ok {[llength [$s9 columns $t9]] == 3}   "I: columns auto-created to cover width 3"
ok {[$s9 width $t9] == 3}               "I: width still 3"
# columns must come before the first row in document order
set doc9 [$p9 tree content.xml]
set tbl [lindex [[$doc9 documentElement] getElementsByTagName table:table] 0]
set order {}
foreach c [$tbl childNodes] {
    if {[$c nodeType] ne "ELEMENT_NODE"} continue
    switch -- [$c nodeName] {
        table:table-column { lappend order col }
        table:table-row    { lappend order row }
    }
}
set firstRow [lsearch $order row]
set lastCol  [lsearch -all $order col]; set lastCol [lindex $lastCol end]
ok {$lastCol >= 0 && $firstRow > $lastCol} "I: all columns precede the rows"
$doc9 delete
$s9 destroy
$p9 destroy

# ---- J) merges + formulas on write (slice 8) ----
set pkgJ [odf::newSheetDoc]
set sJ [odf::Sheet new $pkgJ]
set tJ [$sJ addTable "MF"]
$sJ addRow $tJ {{string Titel} {string b} {string c}}
$sJ addRow $tJ {{string A} {string B} {string C}}
$sJ addRow $tJ {{string D} {string E} {string F}}
set expJ {of:=SUM([.A2:.B2])}
$sJ addRow $tJ [list {string sum} [list formula $expJ float 99] {string x}]
$sJ mergeCells $tJ 0 0 3 1   ;# title across 3 columns
$sJ mergeCells $tJ 1 0 2 2   ;# 2x2 block
ok {[catch {$sJ mergeCells $tJ 0 0 9 1}] == 1} "J: out-of-bounds merge rejected"
$sJ flush
$sJ destroy
set jPath [file join $out merge.ods]
$pkgJ save $jPath
$pkgJ destroy

set pA [odf::Package new $jPath]
set sA [odf::Sheet new $pA]
set tA [lindex [$sA tables] 0]
set RA [$sA rows $tA]

# row0: title merge collapses to the anchor at row end -> 1 logical cell, span 3x1
set r0 [$sA cells [lindex $RA 0]]
ok {[llength $r0] == 1}                     "J: title row = 1 logical cell (trailing covered trimmed)"
ok {[$sA cellSpan [lindex $r0 0]] eq {3 1}} "J: title span 3x1"
ok {[$sA cellText [lindex $r0 0]] eq "Titel"} "J: title text"

# row1: anchor 2x2, interior covered kept, then C
set r1 [$sA cells [lindex $RA 1]]
ok {[llength $r1] == 3}                      "J: row1 has 3 positions"
ok {[$sA cellSpan [lindex $r1 0]] eq {2 2}}  "J: row1 anchor span 2x2"
ok {![$sA cellCovered [lindex $r1 0]]}       "J: row1 anchor not covered"
ok {[$sA cellCovered [lindex $r1 1]]}        "J: row1 c1 covered"
ok {[$sA cellText [lindex $r1 2]] eq "C"}    "J: row1 c2 = C"

# row2: two covered then F
set r2 [$sA cells [lindex $RA 2]]
ok {[$sA cellCovered [lindex $r2 0]]}        "J: row2 c0 covered"
ok {[$sA cellCovered [lindex $r2 1]]}        "J: row2 c1 covered"
ok {[$sA cellText [lindex $r2 2]] eq "F"}    "J: row2 c2 = F"

# row3: formula cell carries formula + cached result
set r3 [$sA cells [lindex $RA 3]]
ok {[$sA cellFormula [lindex $r3 1]] eq $expJ} "J: formula written/read"
ok {[$sA cellType    [lindex $r3 1]] eq "float"} "J: formula cell typed float"
ok {[$sA cellValue   [lindex $r3 1]] eq "99"}  "J: cached result 99"

set okwf3 1
foreach part {content.xml styles.xml META-INF/manifest.xml meta.xml} {
    if {[catch {dom parse [encoding convertfrom utf-8 [$pA part $part]] d4}]} { set okwf3 0 } else { $d4 delete }
}
ok {$okwf3} "J: all parts well-formed"
$sA destroy
$pA destroy

# ---- K) column widths (slice 9) ----
set pkgK [odf::newSheetDoc]
set sK [odf::Sheet new $pkgK]
set tK [$sK addTable "Cols"]
set colNames [$sK addColumnWidths $tK {3cm 2cm 2cm}]
$sK addStringRow $tK {A B C}
$sK flush
$sK destroy
set kPath [file join $out cols.ods]
$pkgK save $kPath
$pkgK destroy

set pK [odf::Package new $kPath]
set sKr [odf::Sheet new $pK]
set tKr [lindex [$sKr tables] 0]
ok {[llength [$sKr columns $tKr]] == 3} "K: 3 columns"
# read the column nodes' style-names and resolve widths
set colNodes {}
foreach c [$tKr childNodes] {
    if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:table-column"} { lappend colNodes $c }
}
ok {[$sKr columnWidthOf [[lindex $colNodes 0] getAttribute table:style-name ""]] eq "3cm"} "K: col0 width 3cm"
ok {[$sKr columnWidthOf [[lindex $colNodes 1] getAttribute table:style-name ""]] eq "2cm"} "K: col1 width 2cm"
ok {[$sKr columnWidthOf [[lindex $colNodes 2] getAttribute table:style-name ""]] eq "2cm"} "K: col2 width 2cm"
$sKr destroy
$pK destroy

# ---- L) page setup + header/footer bound to a sheet (slice 9) ----
set pkgL [odf::newSheetDoc]
set stL [odf::Styles new $pkgL]
$stL definePageFormat PMland A4 -orientation landscape -margin 1.5cm
$stL defineMasterPage MPrep -pagelayout PMland
$stL setHeader MPrep {{"odf::sheet Report"}}
$stL setFooter MPrep {{"Seite %page% / %pages%"}}
$stL flush
$stL destroy
set sL [odf::Sheet new $pkgL]
set taL [$sL defineTableStyle taRep -master MPrep]
set tL [$sL addTable "Report" $taL]
$sL addColumns $tL 2
$sL addStringRow $tL {K V}
$sL flush
$sL destroy
set lPath [file join $out page.ods]
$pkgL save $lPath
$pkgL destroy

set pL [odf::Package new $lPath]
set sLr [odf::Sheet new $pL]
set tLr [lindex [$sLr tables] 0]
ok {[$sLr tableStyleName $tLr] eq "taRep"}      "L: sheet uses table style taRep"
ok {[$sLr masterPageOf taRep] eq "MPrep"}        "L: taRep binds master page MPrep"
# styles.xml structure
proc findNamedStyle {root tag name} {
    foreach e [$root getElementsByTagName $tag] { if {[$e getAttribute style:name ""] eq $name} { return $e } }
    return ""
}
set sdoc [$pL tree styles.xml]
set sroot [$sdoc documentElement]
set mp [findNamedStyle $sroot style:master-page MPrep]
ok {$mp ne ""}                                              "L: master-page MPrep present"
ok {[$mp getAttribute style:page-layout-name ""] eq "PMland"} "L: master-page uses PMland"
set hdr [lindex [$mp getElementsByTagName style:header] 0]
ok {$hdr ne "" && [string match *Report* [$hdr asText]]}    "L: header text present"
set ftr [lindex [$mp getElementsByTagName style:footer] 0]
ok {$ftr ne "" && [string match *Seite* [$ftr asText]]}     "L: footer text present"
set pl [findNamedStyle $sroot style:page-layout PMland]
ok {$pl ne ""}                                              "L: page-layout PMland present"
set plp [lindex [$pl getElementsByTagName style:page-layout-properties] 0]
ok {[string match 29.7cm* [$plp getAttribute fo:page-width ""]]} "L: landscape A4 (width 29.7cm)"
$sdoc delete
$sLr destroy
$pL destroy

# ---- print ranges + freeze panes (sheet 0.10) ----
set pkgF [odf::newSheetDoc]; set sF [odf::Sheet new $pkgF]
set tA [$sF addTable "Data"]
$sF addRow $tA {{string Name} {string Q1} {string Q2}}
$sF addRow $tA {{string Alice} {float 1} {float 2}}
set tB [$sF addTable "Notes"]
$sF addRow $tB {{string x}}
$sF setPrintRange $tA "Data.A1:Data.C2"
$sF freezePanes $tA 1 1        ;# freeze first column + header row
$sF freezePanes $tB 0 1        ;# freeze only the header row
ok {[$sF printRange $tA] eq "Data.A1:Data.C2"}     "PR: print range set"
ok {[catch {$sF freezePanes $tA -1 0}]}            "PR: negative freeze rejected"
$sF flush
set ods [file join $out freeze.ods]; $pkgF save $ods
$sF destroy; $pkgF destroy

set pkgF2 [odf::Package new $ods]; set sF2 [odf::Sheet new $pkgF2]
ok {[$pkgF2 has settings.xml]}                     "PR: settings.xml present"
set tabs {}
foreach tt [[[$pkgF2 tree content.xml] documentElement] getElementsByTagName table:table] { dict set tabs [$tt getAttribute table:name ""] $tt }
ok {[$sF2 printRange [dict get $tabs Data]] eq "Data.A1:Data.C2"} "PR: print range persisted"
ok {[$sF2 freezeOf [dict get $tabs Data]] eq {1 1}} "PR: freeze 1/1 persisted"
ok {[$sF2 freezeOf [dict get $tabs Notes]] eq {0 1}} "PR: freeze 0/1 persisted"
# settings.xml well-formed + freeze mode = 2 where frozen
set sx [encoding convertfrom utf-8 [$pkgF2 part settings.xml]]
ok {![catch {dom parse $sx ds}]}                   "PR: settings.xml well-formed"
ok {[string match "*HorizontalSplitMode*2*" $sx]}  "PR: split mode = freeze (2)"
ok {[string match "*xmlns:ooo=*" $sx]}            "PR: settings.xml declares xmlns:ooo (LO honours freeze)"
catch {ds delete}
$sF2 destroy; $pkgF2 destroy

# ---- NR) named ranges + named expressions (slice 0.13) ----
set pkgNR [odf::newSheetDoc]
set shNR  [odf::Sheet new $pkgNR]
set tNR   [$shNR addTable "Daten"]
$shNR addColumns $tNR 3
$shNR addRow $tNR {{float 10} {float 20} {float 30}}
$shNR addRow $tNR {{float 40} {float 50} {float 60}}

# Container existiert noch nicht (über öffentliche Reader geprüft)
ok {[dict size [$shNR namedRanges]] == 0 && [dict size [$shNR namedExpressions]] == 0} \
                                                                "NR: no named ranges/expressions initially"

# Named range (simple absolute address)
$shNR addNamedRange Umsatz "Daten.A1:Daten.C2"
ok {[dict get [$shNR namedRanges] Umsatz] eq "Daten.A1:Daten.C2"} "NR: addNamedRange stored + reader"

# Named range with base + usable-as
$shNR addNamedRange Druckbereich "Daten.A1:Daten.C2" -base "Daten.A1" -usable-as print-range
# Named expression (formula alias)
$shNR addNamedExpression Summe {SUM([.A1:.C2])} -base "Daten.A1"
ok {[dict get [$shNR namedExpressions] Summe] eq {SUM([.A1:.C2])}} "NR: addNamedExpression stored + reader"

# Both kinds live in the same container
ok {[dict size [$shNR namedRanges]] == 2}                        "NR: two named ranges"
ok {[dict size [$shNR namedExpressions]] == 1}                   "NR: one named expression"

# Overwrite by name
$shNR addNamedRange Umsatz "Daten.A1:Daten.C1"
ok {[dict get [$shNR namedRanges] Umsatz] eq "Daten.A1:Daten.C1"} "NR: same-name range overwrites"
ok {[dict size [$shNR namedRanges]] == 2}                        "NR: overwrite did not duplicate"

# Bad usable-as token rejected
ok {[catch {$shNR addNamedRange X "Daten.A1" -usable-as bogus}]} "NR: bad -usable-as rejected"

# Container must be the LAST child of office:spreadsheet (epilogue rule),
# even when a table is added AFTER the named ranges.
set tLate [$shNR addTable "Nachzügler"]
$shNR addColumns $tLate 1
$shNR addRow $tLate {{float 1}}
$shNR flush
set xmlNR [encoding convertfrom utf-8 [$pkgNR part content.xml]]
ok {[regexp {<table:named-expressions>.*</table:named-expressions>\s*</office:spreadsheet>} $xmlNR]} \
                                                                 "NR: container stays last after late addTable"
# Schema-shape checks
ok {[regexp {<table:named-range[^>]*table:name="Druckbereich"[^>]*table:cell-range-address="Daten.A1:Daten.C2"[^>]*table:base-cell-address="Daten.A1"[^>]*table:range-usable-as="print-range"} $xmlNR]} \
                                                                 "NR: named-range attributes serialised"
ok {[regexp {<table:named-expression[^>]*table:name="Summe"[^>]*table:expression="SUM} $xmlNR]} \
                                                                 "NR: named-expression attributes serialised"

# Save + reload roundtrip
$pkgNR save [file join $out namedranges.ods]
$shNR destroy; $pkgNR destroy
set pkgNR2 [odf::Package new [file join $out namedranges.ods]]
set shNR2  [odf::Sheet new $pkgNR2]
ok {[dict get [$shNR2 namedRanges] Druckbereich] eq "Daten.A1:Daten.C2"} "NR: named range survives save+reload"
ok {[dict get [$shNR2 namedExpressions] Summe] eq {SUM([.A1:.C2])}}    "NR: named expression survives save+reload"
$shNR2 destroy; $pkgNR2 destroy

# ---- 0.14: content validation (data validation) ------------------------
puts "\n-- content validation (slice 2) --"
set pkgCV [odf::newSheetDoc]
set shCV  [odf::Sheet new $pkgCV]

ok {[dict size [$shCV contentValidations]] == 0}                 "CV: none initially"

# A list dropdown validation with help + stop error
$shCV addContentValidation Ampel \
    -condition {of:cell-content-is-in-list("rot";"gelb";"gruen")} \
    -allow-empty false -display-list unsorted \
    -help-title "Status" -help-text "Bitte einen Status wählen" \
    -error-title "Ungültig" -error-type stop -error-text "Nur rot/gelb/gruen"
set cvs [$shCV contentValidations]
ok {[dict size $cvs] == 1}                                       "CV: one validation stored"
ok {[dict get $cvs Ampel condition] eq {of:cell-content-is-in-list("rot";"gelb";"gruen")}} \
                                                                 "CV: condition stored + reader"
ok {[dict get $cvs Ampel display-list] eq "unsorted"}            "CV: display-list stored"
ok {[dict get $cvs Ampel allow-empty] eq "false"}               "CV: allow-empty stored"
ok {[dict get $cvs Ampel help-title] eq "Status"}              "CV: help-title stored"
ok {[dict get $cvs Ampel help-text] eq "Bitte einen Status wählen"} "CV: help-text stored"
ok {[dict get $cvs Ampel error-type] eq "stop"}                "CV: error-type stored"
ok {[dict get $cvs Ampel error-text] eq "Nur rot/gelb/gruen"}  "CV: error-text stored"

# A numeric range validation, minimal (condition only)
$shCV addContentValidation Note -condition {of:cell-content() >= 1 and of:cell-content() <= 6}
ok {[dict size [$shCV contentValidations]] == 2}                "CV: two validations"

# A stable validation with help+error that is NOT overwritten later
$shCV addContentValidation Pflicht -condition {of:cell-content-is-text()} \
    -help-title "Hinweis" -help-text "Text eingeben" \
    -error-title "Fehler" -error-type warning -error-text "muss Text sein"
ok {[dict size [$shCV contentValidations]] == 3}                "CV: three validations"

# Attach to a cell and read back
set tCV [$shCV addTable "Eingabe"]
$shCV addColumns $tCV 1
set rowCV [$shCV addRow $tCV {{string ""}}]
set cellCV [lindex [$shCV cells $rowCV] 0]
$shCV setCellValidation $cellCV Ampel
ok {[$shCV cellValidation $cellCV] eq "Ampel"}                  "CV: cell references validation"

# Same-name overwrite
$shCV addContentValidation Ampel -condition {of:cell-content-is-in-list("a";"b")}
ok {[dict get [$shCV contentValidations] Ampel condition] eq {of:cell-content-is-in-list("a";"b")}} \
                                                                 "CV: same-name overwrites"
ok {[dict size [$shCV contentValidations]] == 3}                "CV: overwrite did not duplicate"

# Bad options rejected
ok {[catch {$shCV addContentValidation X -display-list bogus}]}  "CV: bad -display-list rejected"
ok {[catch {$shCV addContentValidation X -error-type bogus}]}    "CV: bad -error-type rejected"
ok {[catch {$shCV addContentValidation X -allow-empty maybe}]}   "CV: bad -allow-empty rejected"

$shCV flush
set xmlCV [encoding convertfrom utf-8 [$pkgCV part content.xml]]
# Prelude position: content-validations must precede the first table:table
ok {[regexp {<table:content-validations>.*</table:content-validations>.*<table:table} $xmlCV]} \
                                                                 "CV: container is prelude (before tables)"
# child order: help-message before error-message
ok {[regexp {<table:help-message[^>]*>.*</table:help-message>.*<table:error-message} $xmlCV]} \
                                                                 "CV: help-message before error-message"
ok {[regexp {table:content-validation-name="Ampel"} $xmlCV]}     "CV: cell carries validation-name"

# Save + reload roundtrip
$pkgCV save [file join $out cv.ods]
$shCV destroy; $pkgCV destroy
set pkgCV2 [odf::Package new [file join $out cv.ods]]
set shCV2  [odf::Sheet new $pkgCV2]
set cvs2 [$shCV2 contentValidations]
ok {[dict get $cvs2 Pflicht error-type] eq "warning"}          "CV: error-message survives save+reload"
ok {[dict get $cvs2 Ampel condition] eq {of:cell-content-is-in-list("a";"b")}} "CV: overwritten condition survives reload"
ok {[dict get $cvs2 Note condition] ne ""}                      "CV: numeric validation survives reload"
$shCV2 destroy; $pkgCV2 destroy

# ---- 0.15: conditional formatting via style:map ------------------------
puts "\n-- conditional formatting (slice 3) --"
set pkgCF [odf::newSheetDoc]
set shCF  [odf::Sheet new $pkgCF]

# target styles applied when a condition holds (red / green backgrounds)
$shCF defineCellFormat HotStyle  "" -cell {fo:background-color #ffcccc}
$shCF defineCellFormat ColdStyle "" -cell {fo:background-color #ccffcc}

# a conditional style: >100 -> Hot, <0 -> Cold
$shCF defineConditionalFormat Ampelzelle \
    -map {value()>100 HotStyle} \
    -map {value()<0   ColdStyle}
set maps [$shCF styleMaps Ampelzelle]
ok {[llength $maps] == 2}                                        "CF: two style:map stored"
ok {[lindex [lindex $maps 0] 0] eq "value()>100"}              "CF: first condition stored"
ok {[lindex [lindex $maps 0] 1] eq "HotStyle"}                 "CF: first apply-style stored"
ok {[lindex [lindex $maps 1] 1] eq "ColdStyle"}                "CF: second apply-style stored"

# base-cell-address variant
$shCF defineConditionalFormat RelZelle \
    -text {fo:font-weight bold} \
    -map {cell-content()="X" HotStyle Tab.A1}
set rm [$shCF styleMaps RelZelle]
ok {[lindex [lindex $rm 0] 2] eq "Tab.A1"}                     "CF: base-cell-address stored"

# errors
ok {[catch {$shCF defineConditionalFormat NoMaps}]}             "CF: missing -map rejected"
ok {[catch {$shCF defineConditionalFormat Bad2 -map {{} StyleX}}]}  "CF: bad -map rejected"

# attach the conditional style to data cells and serialise
set tCF [$shCF addTable "Werte"]
$shCF addColumns $tCF 1
set rowCF [$shCF addRow $tCF {{float 150}} Ampelzelle]
$shCF flush
set xmlCF [encoding convertfrom utf-8 [$pkgCF part content.xml]]
# style:map comes AFTER properties within style:style
ok {[regexp {<style:style[^>]*style:name="RelZelle".*<style:text-properties[^>]*/>.*<style:map} $xmlCF]} \
                                                                 "CF: style:map after properties"
ok {[regexp {<style:map[^>]*style:condition="value\(\)&gt;100"[^>]*style:apply-style-name="HotStyle"} $xmlCF]} \
                                                                 "CF: map attributes serialised"
ok {[regexp {table:style-name="Ampelzelle"} $xmlCF]}            "CF: conditional style attached to cell"

# Save + reload roundtrip
$pkgCF save [file join $out cf.ods]
$shCF destroy; $pkgCF destroy
set pkgCF2 [odf::Package new [file join $out cf.ods]]
set shCF2  [odf::Sheet new $pkgCF2]
set maps2 [$shCF2 styleMaps Ampelzelle]
ok {[llength $maps2] == 2}                                      "CF: style:map survive save+reload"
ok {[lindex [lindex $maps2 0] 1] eq "HotStyle"}                "CF: apply-style survives reload"
$shCF2 destroy; $pkgCF2 destroy

# ---- 0.16: database ranges + AutoFilter --------------------------------
puts "\n-- database ranges (slice 4) --"
set pkgDB [odf::newSheetDoc]
set shDB  [odf::Sheet new $pkgDB]

ok {[dict size [$shDB databaseRanges]] == 0}                    "DB: none initially"

# A filterable range with AutoFilter buttons, two AND conditions, one sort
$shDB addDatabaseRange Verkauf "Tab.A1:Tab.C100" \
    -filter-buttons true -header true -orientation column \
    -filter {{0 = Berlin -type text} {2 > 100 -type number}} \
    -sort {{2 -order desc -type number}}
set drs [$shDB databaseRanges]
ok {[dict size $drs] == 1}                                      "DB: one range stored"
ok {[dict get $drs Verkauf range] eq "Tab.A1:Tab.C100"}        "DB: target-range stored"
ok {[dict get $drs Verkauf filter-buttons] eq "true"}          "DB: display-filter-buttons stored"
ok {[dict get $drs Verkauf header] eq "true"}                  "DB: contains-header stored"
ok {[dict get $drs Verkauf orientation] eq "column"}           "DB: orientation stored"
ok {[llength [dict get $drs Verkauf filters]] == 2}            "DB: two filter conditions"
ok {[lindex [dict get $drs Verkauf filters] 0] eq {0 = Berlin text}} "DB: first condition values"
ok {[lindex [dict get $drs Verkauf sorts] 0] eq {2 descending number}} "DB: sort-by values"

# A minimal range (single filter condition -> filter-condition, not filter-and)
$shDB addDatabaseRange Mini "Tab.E1:Tab.E10" -filter {{0 != "" -type text}}
ok {[llength [dict get [$shDB databaseRanges] Mini filters]] == 1} "DB: single condition"

# A stable range with filter-and + sort, NOT overwritten, for shape checks
$shDB addDatabaseRange Stabil "Tab.G1:Tab.I40" -filter-buttons true \
    -filter {{0 = X -type text} {1 < 5 -type number}} \
    -sort {{1 -order desc -type number}}

# Same-name overwrite
$shDB addDatabaseRange Verkauf "Tab.A1:Tab.D50" -filter-buttons false
ok {[dict get [$shDB databaseRanges] Verkauf range] eq "Tab.A1:Tab.D50"} "DB: same-name overwrites"
ok {[dict size [$shDB databaseRanges]] == 3}                   "DB: overwrite did not duplicate"

# Errors
ok {[catch {$shDB addDatabaseRange X "Tab.A1" -orientation diagonal}]} "DB: bad -orientation rejected"
ok {[catch {$shDB addDatabaseRange X "Tab.A1" -filter-buttons maybe}]} "DB: bad -filter-buttons rejected"
ok {[catch {$shDB addDatabaseRange X "Tab.A1" -filter {{0}}}]}         "DB: bad filter condition rejected"

# Serialise: epilogue order + filter/sort shape
set t [$shDB addTable "Tab"]
$shDB addColumns $t 4
$shDB addRow $t {{string a} {string b} {float 1} {float 2}}
$shDB addNamedRange NR "Tab.A1:Tab.A2"
$shDB flush
set xmlDB [encoding convertfrom utf-8 [$pkgDB part content.xml]]
ok {[regexp {<table:named-expressions>.*</table:named-expressions>.*<table:database-ranges>} $xmlDB]} \
                                                                 "DB: named-expressions before database-ranges (epilogue order)"
ok {[regexp {<table:database-ranges>.*</table:database-ranges>\s*</office:spreadsheet>} $xmlDB]} \
                                                                 "DB: database-ranges is last epilogue element"
ok {[regexp {<table:filter-and>.*<table:filter-condition[^>]*table:field-number="0"} $xmlDB]} \
                                                                 "DB: filter-and with conditions serialised"
ok {[regexp {<table:sort>.*<table:sort-by[^>]*table:order="descending"} $xmlDB]} \
                                                                 "DB: sort-by serialised"

# Save + reload roundtrip
$pkgDB save [file join $out dbrange.ods]
$shDB destroy; $pkgDB destroy
set pkgDB2 [odf::Package new [file join $out dbrange.ods]]
set shDB2  [odf::Sheet new $pkgDB2]
set drs2 [$shDB2 databaseRanges]
ok {[dict get $drs2 Verkauf range] eq "Tab.A1:Tab.D50"}        "DB: range survives save+reload"
ok {[llength [dict get $drs2 Mini filters]] == 1}              "DB: filter survives save+reload"
$shDB2 destroy; $pkgDB2 destroy

# ---- 0.17: subtotals (slice 5) -----------------------------------------
puts "\n-- subtotals (slice 5) --"
set pkgST [odf::newSheetDoc]
set shST  [odf::Sheet new $pkgST]
set tST [$shST addTable "Tab"]
$shST addColumns $tST 4
$shST addStringRow $tST {Region Monat Umsatz Menge}
$shST addRow $tST {{string Ost} {string Jan} {float 100} {float 5}}

# two rules: group by field 0 (sum field 2, average field 3); group by 1 (max field 2)
$shST addDatabaseRange Auswertung "Tab.A1:Tab.D2" -header true \
    -sort {{0 -order asc}} \
    -subtotals {{0 {2 sum} {3 average}} {1 {2 max}}}
set st [dict get [$shST databaseRanges] Auswertung subtotals]
ok {[llength $st] == 2}                                        "ST: two rules stored"
ok {[lindex [lindex $st 0] 0] eq "0"}                          "ST: rule1 group-by field"
ok {[lindex [lindex $st 0] 1] eq {{2 sum} {3 average}}}        "ST: rule1 fields+functions"
ok {[lindex [lindex $st 1] 1] eq {{2 max}}}                    "ST: rule2 field+function"

# a rule that only groups (empty field list) is allowed
$shST addDatabaseRange OnlyGroup "Tab.A1:Tab.D2" -subtotals {{0}}
ok {[lindex [lindex [dict get [$shST databaseRanges] OnlyGroup subtotals] 0] 1] eq ""} \
                                                                "ST: group-only rule (no fields)"

# errors
ok {[catch {$shST addDatabaseRange E "Tab.A1" -subtotals {{0 {2 median}}}}]} "ST: bad function rejected"
ok {[catch {$shST addDatabaseRange E "Tab.A1" -subtotals {{0 {2}}}}]}        "ST: incomplete field rejected"
ok {[catch {$shST addDatabaseRange E "Tab.A1" -subtotals {{{} {2 sum}}}}]}   "ST: missing group-by rejected"

# serialise: child order filter? sort? subtotal-rules?, function values
$shST flush
set xmlST [encoding convertfrom utf-8 [$pkgST part content.xml]]
ok {[regexp {<table:sort>.*</table:sort>.*<table:subtotal-rules>} $xmlST]} \
                                                                "ST: subtotal-rules after sort"
ok {[regexp {<table:subtotal-rule[^>]*table:group-by-field-number="0".*<table:subtotal-field[^>]*table:function="sum"} $xmlST]} \
                                                                "ST: rule + field serialised"
ok {[regexp {<table:subtotal-field[^>]*table:function="average"} $xmlST]} "ST: average function serialised"

# save + reload roundtrip
$pkgST save [file join $out subtotal.ods]
$shST destroy; $pkgST destroy
set pkgST2 [odf::Package new [file join $out subtotal.ods]]
set shST2  [odf::Sheet new $pkgST2]
set st2 [dict get [$shST2 databaseRanges] Auswertung subtotals]
ok {[llength $st2] == 2}                                       "ST: rules survive save+reload"
ok {[lindex [lindex $st2 0] 1] eq {{2 sum} {3 average}}}       "ST: fields survive reload"
$shST2 destroy; $pkgST2 destroy

# ---- 0.18: pivot tables / data pilots (slice 6) ------------------------
puts "\n-- pivot tables / data pilots (slice 6) --"
set pkgDP [odf::newSheetDoc]
set shDP  [odf::Sheet new $pkgDP]
set tDP [$shDP addTable "Data"]
$shDP addColumns $tDP 3
$shDP addStringRow $tDP {Region Monat Umsatz}
$shDP addRow $tDP {{string Ost} {string Jan} {float 100}}

ok {[dict size [$shDP dataPilotTables]] == 0}                  "DP: none initially"

$shDP addDataPilotTable Pivot1 -source "Data.A1:Data.C2" -target "Data.E1:Data.H10" \
    -grand-total both -show-filter-button true \
    -field {Region row} -field {Monat column} -field {Umsatz data -function sum}
set dp [$shDP dataPilotTables]
ok {[dict size $dp] == 1}                                      "DP: one pivot stored"
ok {[dict get $dp Pivot1 target] eq "Data.E1:Data.H10"}       "DP: target-range stored"
ok {[dict get $dp Pivot1 source] eq "Data.A1:Data.C2"}        "DP: source-cell-range stored"
ok {[dict get $dp Pivot1 grand-total] eq "both"}              "DP: grand-total stored"
ok {[llength [dict get $dp Pivot1 fields]] == 3}              "DP: three fields stored"
set f0 [lindex [dict get $dp Pivot1 fields] 0]
ok {[dict get $f0 source-name] eq "Region" && [dict get $f0 orientation] eq "row" \
    && [dict get $f0 function] eq ""} "DP: row field"
set f2 [lindex [dict get $dp Pivot1 fields] 2]
ok {[dict get $f2 source-name] eq "Umsatz" && [dict get $f2 orientation] eq "data" \
    && [dict get $f2 function] eq "sum"} "DP: data field + function"

# minimal pivot (no source): target + one field
$shDP addDataPilotTable Mini -target "Data.J1" -field {Region row}
ok {[dict get [$shDP dataPilotTables] Mini source] eq ""}     "DP: source optional"

# errors
ok {[catch {$shDP addDataPilotTable E -field {R row}}]}        "DP: missing -target rejected"
ok {[catch {$shDP addDataPilotTable E -target T}]}            "DP: no field rejected"
ok {[catch {$shDP addDataPilotTable E -target T -field {R diagonal}}]} "DP: bad orientation rejected"
ok {[catch {$shDP addDataPilotTable E -target T -field {R data -function median}}]} "DP: bad function rejected"
ok {[catch {$shDP addDataPilotTable E -target T -grand-total all -field {R row}}]} "DP: bad grand-total rejected"

# same-name overwrite
$shDP addDataPilotTable Pivot1 -target "Data.E1" -field {Region row}
ok {[dict get [$shDP dataPilotTables] Pivot1 target] eq "Data.E1"} "DP: same-name overwrites"
ok {[dict size [$shDP dataPilotTables]] == 2}                 "DP: overwrite did not duplicate"

# stable pivot with full shape, NOT overwritten, for serialisation checks
$shDP addDataPilotTable Stabil -source "Data.A1:Data.C2" -target "Data.M1:Data.P9" \
    -field {Region row} -field {Umsatz data -function sum}
$shDP flush
set xmlDP [encoding convertfrom utf-8 [$pkgDP part content.xml]]
ok {[regexp {<table:data-pilot-tables>.*</table:data-pilot-tables>\s*</office:spreadsheet>} $xmlDP]} \
                                                                "DP: data-pilot-tables is last epilogue element"
ok {[regexp {<table:data-pilot-table[^>]*table:name="Stabil"[^>]*table:target-range-address="Data.M1:Data.P9"} $xmlDP]} \
                                                                "DP: table name + target serialised"
ok {[regexp {<table:source-cell-range[^>]*table:cell-range-address="Data.A1:Data.C2"} $xmlDP]} \
                                                                "DP: source-cell-range serialised"
ok {[regexp {<table:data-pilot-field[^>]*table:orientation="data"[^>]*table:function="sum"} $xmlDP]} \
                                                                "DP: data field + function serialised"

# save + reload roundtrip
$pkgDP save [file join $out pivot.ods]
$shDP destroy; $pkgDP destroy
set pkgDP2 [odf::Package new [file join $out pivot.ods]]
set shDP2  [odf::Sheet new $pkgDP2]
set dp2 [$shDP2 dataPilotTables]
ok {[dict get $dp2 Stabil target] eq "Data.M1:Data.P9"}       "DP: pivot survives save+reload"
set f1r [lindex [dict get $dp2 Stabil fields] 1]
ok {[dict get $f1r source-name] eq "Umsatz" && [dict get $f1r orientation] eq "data" \
    && [dict get $f1r function] eq "sum"} "DP: fields survive reload"
$shDP2 destroy; $pkgDP2 destroy

# ---- 0.19: calculation settings (slice 7) ------------------------------
puts "\n-- calculation settings (slice 7) --"
set pkgCS [odf::newSheetDoc]
set shCS  [odf::Sheet new $pkgCS]

ok {[dict size [$shCS calculationSettings]] == 0}             "CS: none initially"

$shCS setCalculationSettings -case-sensitive false -use-wildcards true \
    -precision-as-shown false -null-year 1930 -null-date 1899-12-30 \
    -iteration {enable -steps 100 -max-difference 0.001}
set cs [$shCS calculationSettings]
ok {[dict get $cs case-sensitive] eq "false"}                "CS: bool attr stored"
ok {[dict get $cs use-wildcards] eq "true"}                  "CS: use-wildcards stored"
ok {[dict get $cs null-year] eq "1930"}                      "CS: null-year stored"
ok {[dict get $cs null-date] eq "1899-12-30"}                "CS: null-date stored"
ok {[dict get $cs iteration] eq {enable 100 0.001}}          "CS: iteration stored"

# idempotent: a second call replaces, does not duplicate
$shCS setCalculationSettings -case-sensitive true
$shCS flush
set xmlCS [encoding convertfrom utf-8 [$pkgCS part content.xml]]
ok {[regexp -all {<table:calculation-settings} $xmlCS] == 1}  "CS: singleton (overwrite, no duplicate)"
ok {[dict get [$shCS calculationSettings] case-sensitive] eq "true"} "CS: overwrite took effect"

# prelude order: calculation-settings must precede content-validations
$shCS addContentValidation Val -condition {of:cell-content() > 0}
$shCS flush
set xmlCS [encoding convertfrom utf-8 [$pkgCS part content.xml]]
ok {[regexp {<table:calculation-settings.*<table:content-validations} $xmlCS]} \
                                                              "CS: calculation-settings before content-validations"
ok {[regexp {<office:spreadsheet>\s*<table:calculation-settings} $xmlCS]} \
                                                              "CS: calculation-settings is first prelude element"

# child order: null-date before iteration
ok {[regexp {<table:null-date.*<table:iteration} $xmlCS] || ![regexp {<table:null-date} $xmlCS]} \
                                                              "CS: null-date before iteration"

# errors
ok {[catch {$shCS setCalculationSettings -case-sensitive maybe}]}     "CS: bad boolean rejected"
ok {[catch {$shCS setCalculationSettings -null-year abc}]}           "CS: bad null-year rejected"
ok {[catch {$shCS setCalculationSettings -iteration {sometimes}}]}   "CS: bad iteration status rejected"
ok {[catch {$shCS setCalculationSettings -nonsense 1}]}              "CS: unknown option rejected"

# save + reload roundtrip (set the full state first -- set, not merge)
$shCS setCalculationSettings -case-sensitive true -use-wildcards true
set t [$shCS addTable "T"]; $shCS addColumns $t 1; $shCS addRow $t {{float 1}}
$pkgCS save [file join $out calc.ods]
$shCS destroy; $pkgCS destroy
set pkgCS2 [odf::Package new [file join $out calc.ods]]
set shCS2  [odf::Sheet new $pkgCS2]
set cs2 [$shCS2 calculationSettings]
ok {[dict get $cs2 case-sensitive] eq "true"}                "CS: survives save+reload"
ok {[dict get $cs2 use-wildcards] eq "true"}                 "CS: wildcards survive reload"
$shCS2 destroy; $pkgCS2 destroy

# ---- 0.20: CV display attribute (LO-compatible default) ----------------
puts "\n-- CV display attribute (slice 0.20) --"
set pkgCD [odf::newSheetDoc]; set shCD [odf::Sheet new $pkgCD]
set tCD [$shCD addTable T]; $shCD addColumns $tCD 1; $shCD addRow $tCD {{float 1}}

# default: any error/help-* triggers the message, display defaults to "true"
$shCD addContentValidation v1 -condition {of:cell-content()>0} -error-type stop
$shCD addContentValidation v2 -condition {of:cell-content()>0} \
    -help-title "H" -error-type warning
# explicit false
$shCD addContentValidation v3 -condition {of:cell-content()>0} \
    -error-type information -error-display false
# display alone is enough to emit the message
$shCD addContentValidation v4 -condition {of:cell-content()>0} -error-display true
$shCD flush
set xmlCD [encoding convertfrom utf-8 [$pkgCD part content.xml]]

ok {[regexp {v1.*?<table:error-message[^>]*table:display="true"} $xmlCD]} \
                                                                  "CV: v1 default error-display=true"
ok {[regexp {v2.*?<table:help-message[^>]*table:display="true"}  $xmlCD]} \
                                                                  "CV: v2 default help-display=true"
ok {[regexp {v3.*?<table:error-message[^>]*table:display="false"} $xmlCD]} \
                                                                  "CV: v3 explicit error-display=false"
ok {[regexp {v4.*?<table:error-message[^>]*table:display="true"} $xmlCD]} \
                                                                  "CV: v4 error-display alone emits message"

set vsCD [$shCD contentValidations]
ok {[dict get $vsCD v1 error-display] eq "true"}                  "CV: reader v1 error-display=true"
ok {[dict get $vsCD v2 help-display]  eq "true"}                  "CV: reader v2 help-display=true"
ok {[dict get $vsCD v3 error-display] eq "false"}                 "CV: reader v3 error-display=false"

# bad booleans rejected
ok {[catch {$shCD addContentValidation bad -condition x -error-display maybe}]} \
                                                                  "CV: bad -error-display rejected"
ok {[catch {$shCD addContentValidation bad -condition x -help-display whenever}]} \
                                                                  "CV: bad -help-display rejected"
$shCD destroy; $pkgCD destroy

# ---- 0.21: formula API (cached value retroactive + clear + hasFormula) -
puts "\n-- formula API (slice 0.21) --"
set pkgF [odf::newSheetDoc]; set shF [odf::Sheet new $pkgF]
set tF [$shF addTable T]; $shF addColumns $tF 3

# (1) addRow {formula OF type val} -- flat spec, must keep working
$shF addRow $tF {{float 1} {float 2} {formula of:=SUM([.A1:.B1]) float 3}}
# (2) Plain rows whose third cell will be turned into a formula afterwards
$shF addRow $tF {{float 10} {float 20} {float 0}}
$shF addRow $tF {{float 100} {float 200} {string ""}}
$shF addRow $tF {{float 1000} {float 2000} {float 99}}

set r1 [lindex [$shF rows $tF] 0]
set r2 [lindex [$shF rows $tF] 1]
set r3 [lindex [$shF rows $tF] 2]
set r4 [lindex [$shF rows $tF] 3]
set c1 [lindex [$shF cells $r1] 2]
set c2 [lindex [$shF cells $r2] 2]
set c3 [lindex [$shF cells $r3] 2]
set c4 [lindex [$shF cells $r4] 2]

# (1) original addRow formula path still produces formula + cached value
ok {[$shF cellFormula $c1] eq "of:=SUM(\[.A1:.B1\])"}              "formula: addRow flat spec keeps formula"
ok {[$shF cellHasFormula $c1] == 1}                                "formula: cellHasFormula true after addRow"
ok {[$shF cellType $c1] eq "float" && [$shF cellValue $c1] == 3}   "formula: addRow flat spec keeps cached value"

# (2A) setFormula with only formula -- value untouched
$shF setFormula $c2 {of:=SUM([.A2:.B2])}
ok {[$shF cellFormula $c2] eq "of:=SUM(\[.A2:.B2\])"}              "formula: setFormula sets table:formula"
ok {[$shF cellHasFormula $c2] == 1}                                "formula: hasFormula after setFormula"
ok {[$shF cellValue $c2] == 0}                                     "formula: cached value untouched by 2-arg setFormula"

# (2B) setFormula with value-spec -- value replaced
$shF setFormula $c3 {of:=SUM([.A3:.B3])} {float 300}
ok {[$shF cellFormula $c3] eq "of:=SUM(\[.A3:.B3\])"}              "formula: setFormula+value-spec sets formula"
ok {[$shF cellType $c3] eq "float" && [$shF cellValue $c3] == 300} "formula: setFormula+value-spec replaces cached value"
# string -> float: prior string-typing fully replaced (no leftover office:string-value)
ok {![regexp {office:string-value} [$c3 asXML]]}                   "formula: stale value attributes stripped"

# (2C) clear: formula="" removes table:formula, value stays
$shF setFormula $c4 {of:=SUM([.A4:.B4])} {float 3000}
ok {[$shF cellHasFormula $c4] == 1}                                "formula: pre-clear has formula"
$shF setFormula $c4 ""
ok {[$shF cellHasFormula $c4] == 0}                                "formula: setFormula \"\" clears table:formula"
ok {[$shF cellFormula $c4] eq ""}                                  "formula: cellFormula empty after clear"
ok {[$shF cellType $c4] eq "float" && [$shF cellValue $c4] == 3000} "formula: cached value survives clear"

# (3) error paths -- match the convention (lowercase, value appended, no period)
ok {[catch {$shF setFormula $c2 of:=X {formula y float 1}} e] && \
    $e eq "setFormula: value-spec must be a plain typed cell spec, not 'formula'"} \
                                                                   "formula: 'formula' as value-spec rejected"
ok {[catch {$shF setFormula $c2 of:=X {float 1} extra} e] && \
    $e eq "setFormula: too many arguments (cell formula ?value-spec?)"} \
                                                                   "formula: too many args rejected"
ok {[catch {$shF setFormula $c2 of:=X {weirdtype 1}} e] && \
    [string match "unknown cell type: weirdtype*" $e]}             "formula: unknown type rejected"

$shF destroy; $pkgF destroy

# ---- 0.22: pivot depth tier 1 (level + subtotals + members) ----------
puts "\n-- pivot depth (slice 0.22) --"
set pkgDPD [odf::newSheetDoc]; set shDPD [odf::Sheet new $pkgDPD]
set tDPD [$shDPD addTable Data]; $shDPD addColumns $tDPD 3
$shDPD addRow $tDPD {{string Region} {string Product} {string Umsatz}}
$shDPD addRow $tDPD {{string North}  {string A}       {float 100}}
$shDPD addDataPilotTable PivD -target {Out.A1:Out.E20} \
    -source {Data.A1:Data.C2} \
    -field {Region  row    -show-empty true -subtotals {sum count} -members {{North true} {South false}}} \
    -field {Product column -subtotals {sum}} \
    -field {Umsatz  data   -function sum}
$shDPD flush
set xmlDPD [encoding convertfrom utf-8 [$pkgDPD part content.xml]]

ok {[regexp {<table:data-pilot-level} $xmlDPD]}                 "DP-depth: level element emitted"
ok {[regexp {show-empty=\"true\"}    $xmlDPD]}                 "DP-depth: show-empty=true on level"
ok {[regexp {<table:data-pilot-subtotal table:function=\"sum\"/>} $xmlDPD]} \
                                                                  "DP-depth: subtotal sum emitted"
ok {[regexp {<table:data-pilot-subtotal table:function=\"count\"/>} $xmlDPD]} \
                                                                  "DP-depth: subtotal count emitted"
ok {[regexp {<table:data-pilot-member table:name=\"North\" table:display=\"true\"} $xmlDPD]} \
                                                                  "DP-depth: member North display=true"
ok {[regexp {<table:data-pilot-member table:name=\"South\" table:display=\"false\"} $xmlDPD]} \
                                                                  "DP-depth: member South display=false"

set dpD [dict get [$shDPD dataPilotTables] PivD]
set fR  [lindex [dict get $dpD fields] 0]
ok {[dict get $fR source-name] eq "Region"}                     "DP-depth: reader source-name Region"
ok {[dict get $fR show-empty]  eq "true"}                       "DP-depth: reader show-empty"
ok {[dict get $fR subtotals]   eq "sum count"}                  "DP-depth: reader subtotals list"
ok {[lindex [dict get $fR members] 0] eq {North true}}          "DP-depth: reader member North"
ok {[lindex [dict get $fR members] 1] eq {South false}}         "DP-depth: reader member South"

# Reload roundtrip
$pkgDPD save /tmp/dp-depth.ods
set pkgDPD2 [odf::Package new]; $pkgDPD2 load /tmp/dp-depth.ods
set shDPD2 [odf::Sheet new $pkgDPD2]
set dpD2 [dict get [$shDPD2 dataPilotTables] PivD]
set fR2 [lindex [dict get $dpD2 fields] 0]
ok {[dict get $fR2 subtotals] eq "sum count"}                   "DP-depth: subtotals survive reload"
ok {[lindex [dict get $fR2 members] 1] eq {South false}}        "DP-depth: members survive reload"

# Error paths -- all convention-compliant
ok {[catch {$shDPD addDataPilotTable Bad -target X -field {x row -show-empty maybe}} e] \
    && $e eq "bad field -show-empty: maybe (boolean)"} \
                                                                  "DP-depth: bad -show-empty rejected"
ok {[catch {$shDPD addDataPilotTable Bad -target X -field {x row -subtotals {}}} e] \
    && [string match "bad field -subtotals: empty list*" $e]} \
                                                                  "DP-depth: empty -subtotals rejected"
ok {[catch {$shDPD addDataPilotTable Bad -target X -field {x row -subtotals {weird}}} e] \
    && [string match "bad field subtotal function: weird*" $e]} \
                                                                  "DP-depth: unknown subtotal fn rejected"
ok {[catch {$shDPD addDataPilotTable Bad -target X -field {x row -members {}}} e] \
    && [string match "bad field -members: empty list*" $e]} \
                                                                  "DP-depth: empty -members rejected"

$shDPD destroy; $pkgDPD destroy; $shDPD2 destroy; $pkgDPD2 destroy

# ---- 0.23: rich-text cell writing -------------------------------------
puts "\n-- rich-text cells (slice 0.23) --"
set pkgRT [odf::newSheetDoc]; set shRT [odf::Sheet new $pkgRT]
set tRT [$shRT addTable T]; $shRT addColumns $tRT 1

$shRT addRow $tRT {{string "placeholder"}}
$shRT addRow $tRT {{float 99}}
$shRT addRow $tRT {{string "old"}}
$shRT addRow $tRT {{string "x"}}

set r1 [lindex [$shRT rows $tRT] 0]
set r2 [lindex [$shRT rows $tRT] 1]
set r3 [lindex [$shRT rows $tRT] 2]
set r4 [lindex [$shRT rows $tRT] 3]
set rt1 [lindex [$shRT cells $r1] 0]
set rt2 [lindex [$shRT cells $r2] 0]
set rt3 [lindex [$shRT cells $r3] 0]
set rt4 [lindex [$shRT cells $r4] 0]

# (1) Span + text mix
$shRT setCellRichText $rt1 [list {span Bold "WARNING"} {text " please verify"}]
set xml1 [$rt1 asXML]
ok {[regexp {text:style-name="Bold">WARNING} $xml1]}             "RT: span style attached"
ok {[regexp {</text:span>\s* please verify} $xml1]}              "RT: text after span"
ok {[$shRT cellText $rt1] eq "WARNING please verify"}            "RT: cellText concats span+text"
ok {[$shRT cellType $rt1] eq "string"}                            "RT: cell becomes string-typed"

# (2) Numeric -> rich-text: office:value-type wechselt, office:value weg
$shRT setCellRichText $rt2 [list {text "was 99"}]
ok {[$shRT cellType $rt2] eq "string"}                            "RT: numeric -> string after rich-text"
ok {![$rt2 hasAttribute office:value]}                            "RT: stale office:value stripped"

# (3) Multi-paragraph + lb, tab, space, link
$shRT setCellRichText $rt3 \
    [list {text "Zeile A"} lb {text "nach lb"}] \
    [list {text "tab:"} tab {span Italic "kursiv"}] \
    [list {text "spaces:"} {space 3} {text "ende"}] \
    [list {link "https://example.org" "klick" "Bold"}]
set xml3 [$rt3 asXML]
ok {[regexp {<text:line-break/>} $xml3]}                          "RT: lb token -> text:line-break"
ok {[regexp {<text:tab/>} $xml3]}                                 "RT: tab token -> text:tab"
ok {[regexp {<text:s text:c="3"/>} $xml3]}                        "RT: space N -> text:s text:c=N"
ok {[regexp {xlink:href="https://example.org"} $xml3]}            "RT: link href set"
ok {[regexp -all {<text:p>} $xml3] == 4}                          "RT: four paragraphs emitted"
set t3 [$shRT cellText $rt3]
ok {[string match "*Zeile A\nnach lb*" $t3]}                      "RT: cellText preserves lb as newline"
ok {[string match "*spaces:   ende*" $t3]}                        "RT: cellText expands text:s"
ok {[string match "*klick*" $t3]}                                 "RT: cellText includes link display"

# (4) Replace twice -- no leftover from earlier call
$shRT setCellRichText $rt4 [list {span Bold "First"}]
$shRT setCellRichText $rt4 [list {text "Second only"}]
ok {[regexp -all {<text:p>} [$rt4 asXML]] == 1}                   "RT: replace leaves only one text:p"
ok {![regexp {First} [$rt4 asXML]]}                               "RT: replace removes prior span"
ok {[$shRT cellText $rt4] eq "Second only"}                       "RT: cellText after replace"

# Error paths -- all convention-compliant (lowercase, value appended)
ok {[catch {$shRT setCellRichText $rt1} e] \
    && $e eq "setCellRichText: at least one paragraph required"} \
                                                                  "RT: no paragraph rejected"
ok {[catch {$shRT setCellRichText $rt1 {text}} e] \
    && [string match "bad rich-text run: need*text*" $e]}         "RT: bare 'text' rejected"
ok {[catch {$shRT setCellRichText $rt1 {{span Bold}}} e] \
    && [string match "bad rich-text run: need*span*" $e]}         "RT: span 2-arg rejected"
ok {[catch {$shRT setCellRichText $rt1 {{space 0}}} e] \
    && [string match "*positive integer*" $e]}                    "RT: space 0 rejected"
ok {[catch {$shRT setCellRichText $rt1 {{weirdo "x"}}} e] \
    && [string match "unknown rich-text run: weirdo*" $e]}        "RT: unknown run-type rejected"

# Persist + reload: rich-text survives roundtrip
$pkgRT save /tmp/rt-rt.ods
set pkgRT2 [odf::Package new]; $pkgRT2 load /tmp/rt-rt.ods
set shRT2 [odf::Sheet new $pkgRT2]
set tRT2 [lindex [$shRT2 tables] 0]
set rRT2 [lindex [$shRT2 rows $tRT2] 0]
set c1RT2 [lindex [$shRT2 cells $rRT2] 0]
ok {[$shRT2 cellText $c1RT2] eq "WARNING please verify"}          "RT: text survives save+reload"
ok {[regexp {text:style-name="Bold">WARNING} [$c1RT2 asXML]]}     "RT: span style survives reload"

$shRT destroy; $pkgRT destroy; $shRT2 destroy; $pkgRT2 destroy

# ---- 0.24: ODS completeness niches (label-ranges, scenario, dde-links) -
puts "\n-- ODS niches (slice 0.24) --"
set pkgNi [odf::newSheetDoc]; set shNi [odf::Sheet new $pkgNi]
set tNi [$shNi addTable Sales]; $shNi addColumns $tNi 3
$shNi addRow $tNi {{string Region} {string Q1} {string Q2}}
$shNi addRow $tNi {{string North}  {float 100}  {float 120}}

# --- label-ranges ---
$shNi addLabelRange "Sales.A1:Sales.C1" "Sales.A2:Sales.C2" -orientation column
$shNi addLabelRange "Sales.A1:Sales.A1" "Sales.A2:Sales.A2" -orientation row
$shNi addLabelRange "Sales.D1:Sales.D1" "Sales.D2:Sales.D2"   ;# default orientation

set lrs [$shNi labelRanges]
ok {[llength $lrs] == 3}                                          "niche: 3 label-ranges stored"
ok {[lindex [lindex $lrs 0] 2] eq "column"}                        "niche: first label-range orientation=column"
ok {[lindex [lindex $lrs 1] 2] eq "row"}                           "niche: second label-range orientation=row"
ok {[lindex [lindex $lrs 2] 2] eq "column"}                        "niche: default orientation is column"

# --- table scenario ---
$shNi setTableScenario $tNi \
    -ranges [list "Sales.A2:Sales.C2" "Sales.A3:Sales.C3"] \
    -active true -display-border true -border-color "#FF0000" \
    -copy-back true -copy-styles true
set sc [$shNi tableScenario $tNi]
ok {[dict get $sc ranges] eq "Sales.A2:Sales.C2 Sales.A3:Sales.C3"} "niche: scenario ranges joined w/ space"
ok {[dict get $sc active] eq "true"}                                "niche: scenario active=true"
ok {[dict get $sc border-color] eq "#FF0000"}                       "niche: scenario border-color"
ok {[dict get $sc copy-formulas] eq ""}                             "niche: scenario unset attr stays empty"

# Replace: same table, new scenario -> singleton semantics
$shNi setTableScenario $tNi -ranges [list "Sales.A5:Sales.C5"] -active false
set sc2 [$shNi tableScenario $tNi]
ok {[dict get $sc2 ranges] eq "Sales.A5:Sales.C5"}                  "niche: scenario replaces (singleton)"
ok {[dict get $sc2 active] eq "false"}                              "niche: scenario active=false"
# Verify there's still only one in the XML
$shNi flush
set xmlNi [encoding convertfrom utf-8 [$pkgNi part content.xml]]
ok {[regexp -all {<table:scenario} $xmlNi] == 1}                    "niche: only one scenario in XML"
ok {[regexp {<table:scenario[^>]*/>\s*<table:table-column} $xmlNi]} "niche: scenario before columns"

# --- dde-links ---
$shNi addDDELink "MarketFeed" -application excel -topic "RealtimeData" -item "AAPL" -auto-update true
$shNi addDDELink "Idem" -application soffice -topic spread -item {[Sales.A1]} -conversion-mode keep-text

set dd [$shNi ddeLinks]
ok {[dict size $dd] == 2}                                           "niche: two dde-links stored"
ok {[dict get $dd MarketFeed application] eq "excel"}               "niche: dde-link application"
ok {[dict get $dd MarketFeed auto-update] eq "true"}                "niche: dde-link auto-update"
ok {[dict get $dd Idem conversion-mode] eq "keep-text"}             "niche: dde-link conversion-mode"

# Same-name overwrite (idempotent on name)
$shNi addDDELink "MarketFeed" -application "newapp" -topic "newtopic" -item "newitem"
set dd2 [$shNi ddeLinks]
ok {[dict size $dd2] == 2}                                          "niche: same-name dde-link replaces"
ok {[dict get $dd2 MarketFeed application] eq "newapp"}             "niche: dde-link overwrite applied"

# Roundtrip: all three niches survive save+reload
$pkgNi save /tmp/niches-rt.ods
set pkgNi2 [odf::Package new]; $pkgNi2 load /tmp/niches-rt.ods
set shNi2 [odf::Sheet new $pkgNi2]
set tNi2 [lindex [$shNi2 tables] 0]
ok {[llength [$shNi2 labelRanges]] == 3}                            "niche: label-ranges survive reload"
ok {[dict get [$shNi2 tableScenario $tNi2] ranges] eq "Sales.A5:Sales.C5"} \
                                                                    "niche: scenario survives reload"
ok {[dict size [$shNi2 ddeLinks]] == 2}                             "niche: dde-links survive reload"

# Error paths
ok {[catch {$shNi addLabelRange "" "Sales.A1"} e] \
    && [string match "addLabelRange: label-range*" $e]}             "niche: empty label-range rejected"
ok {[catch {$shNi addLabelRange "x" "y" -orientation diag} e] \
    && [string match "bad -orientation: diag*" $e]}                 "niche: bad orientation rejected"
ok {[catch {$shNi setTableScenario $tNi -ranges {}} e] \
    && [string match "*ranges is required*" $e]}                    "niche: empty scenario ranges rejected"
ok {[catch {$shNi setTableScenario $tNi -ranges X -active maybe} e] \
    && [string match "*must be boolean*" $e]}                       "niche: scenario bad bool rejected"
ok {[catch {$shNi addDDELink "L" -application a -topic t -item i -conversion-mode wat} e] \
    && [string match "bad -conversion-mode: wat*" $e]}              "niche: dde bad conv-mode rejected"
ok {[catch {$shNi addDDELink "L" -application "" -topic t -item i} e] \
    && [string match "*application is required*" $e]}               "niche: dde empty application rejected"

$shNi destroy; $pkgNi destroy; $shNi2 destroy; $pkgNi2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
