set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }
proc cols {t tab} {
    set r {}
    foreach c [$tab childNodes] {
        if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:table-column"} { lappend r $c }
    }
    return $r
}

# ---- A) build a styled table structure ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t defineAutoTable  T1 {style:width 12cm table:align center}
$t defineAutoColumn C1 {style:column-width 3cm}
$t defineAutoColumn C2 {style:column-width 6cm}
$t defineAutoColumn C3 {style:column-width 3cm}
$t defineAutoCellStyle Head -background #DDDDDD -bold true
set tab [$t appendTableCols {C1 C2 C3} T1]
$t addHeaderRow $tab {Name Description Price} {Head Head Head}
$t addRow $tab {Apple {Fresh apples} 1.20}
$t addRow $tab {Pear  {Sweet pears}  1.50}
ok {[$t tableColumns $tab] eq {C1 C2 C3}}                       "A: three column styles"
set rows [$t tableRows $tab]
ok {[llength $rows] == 3}                                       "A: header + 2 body rows"
ok {[$t isHeaderRow [lindex $rows 0]]}                          "A: row 0 is header"
ok {![$t isHeaderRow [lindex $rows 1]]}                         "A: row 1 is body"
ok {[$t cellStyle [lindex [$t rowCells [lindex $rows 0]] 0]] eq "Head"} "A: header cell style"
$t flush; $t destroy
$pkg save [file join $out tablestruct.odt]; $pkg destroy

# ---- B) reload: structure, widths, table style persist ----
set pkg2 [odf::Package new [file join $out tablestruct.odt]]
set t2   [odf::Text new $pkg2]
set tb   [lindex [$t2 find table] 0]
ok {[$t2 tableColumns $tb] eq {C1 C2 C3}}                       "B: columns persisted"
ok {[llength [$t2 tableRows $tb]] == 3}                         "B: rows persisted"
ok {[$t2 isHeaderRow [lindex [$t2 tableRows $tb] 0]]}           "B: header row persisted"
set cl [cols $t2 $tb]
ok {[$t2 effectiveProp [lindex $cl 1] style:table-column-properties style:column-width] eq "6cm"} "B: column width via style"
ok {[$t2 effectiveProp $tb style:table-properties style:width] eq "12cm"}    "B: table width via style"
ok {[$t2 effectiveProp $tb style:table-properties table:align] eq "center"}  "B: table align via style"
ok {[$t2 cellText [lindex [$t2 rowCells [lindex [$t2 tableRows $tb] 1]] 1]] eq "Fresh apples"} "B: body cell text"
$t2 destroy; $pkg2 destroy

# ---- C) legacy appendTable + addRow stay backward-compatible ----
set pkg3 [odf::newTextDoc]; set t3 [odf::Text new $pkg3]
set tb3 [$t3 appendTable 2]
$t3 addRow $tb3 {a b}
ok {[llength [$t3 tableRows $tb3]] == 1}                        "C: legacy appendTable+addRow"
ok {[$t3 cellStyle [lindex [$t3 rowCells [lindex [$t3 tableRows $tb3] 0]] 0]] eq ""} "C: no style when none given"
$t3 destroy; $pkg3 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
