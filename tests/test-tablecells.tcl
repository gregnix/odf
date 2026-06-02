set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }
proc cell {t tab r c} { return [lindex [$t rowCells [lindex [$t tableRows $tab] $r]] $c] }

# ---- A) define cell styles via named options, apply at build + via setCellStyle ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t defineAutoColumn C {style:column-width 4cm}
$t defineAutoCellStyle Head -border "0.5pt solid #000000" -background #305080 \
   -color #FFFFFF -bold true -valign middle -padding 0.1cm -align center
$t defineAutoCellStyle Body -border "0.5pt solid #888888" -padding 0.1cm -valign top
set tab [$t appendTableCols {C C C}]
$t addHeaderRow $tab {A B C} {Head Head Head}
set r [$t addRow $tab {1 2 3}]
foreach c [$t rowCells $r] { $t setCellStyle $c Body }   ;# style existing cells
ok {[$t cellStyle [cell $t $tab 0 0]] eq "Head"}                 "A: header cell style set at build"
ok {[$t cellStyle [cell $t $tab 1 0]] eq "Body"}                 "A: body cell style via setCellStyle"
set hc [cell $t $tab 0 0]
ok {[$t effectiveProp $hc style:table-cell-properties fo:border] eq "0.5pt solid #000000"} "A: header border"
ok {[$t effectiveProp $hc style:table-cell-properties fo:background-color] eq "#305080"}   "A: header background"
ok {[$t effectiveProp $hc style:table-cell-properties style:vertical-align] eq "middle"}   "A: header valign"
ok {[$t effectiveProp $hc style:text-properties fo:font-weight] eq "bold"}                 "A: header bold"
ok {[$t effectiveProp $hc style:paragraph-properties fo:text-align] eq "center"}           "A: header align"
$t flush; $t destroy
$pkg save [file join $out tablecells.odt]; $pkg destroy

# ---- B) reload: cell styles + properties persist ----
set pkg2 [odf::Package new [file join $out tablecells.odt]]
set t2   [odf::Text new $pkg2]
set tb   [lindex [$t2 find table] 0]
ok {[$t2 cellStyle [cell $t2 $tb 0 1]] eq "Head"}                "B: header style persisted"
ok {[$t2 cellStyle [cell $t2 $tb 1 1]] eq "Body"}                "B: body style persisted"
set bc [cell $t2 $tb 1 0]
ok {[$t2 effectiveProp $bc style:table-cell-properties fo:border] eq "0.5pt solid #888888"} "B: body border persisted"
ok {[$t2 effectiveProp $bc style:table-cell-properties style:vertical-align] eq "top"}      "B: body valign persisted"
$t2 destroy; $pkg2 destroy

# ---- C) setCellStyle remove + reassign ----
set pkg3 [odf::newTextDoc]; set t3 [odf::Text new $pkg3]
set tab3 [$t3 appendTable 2]
set r3 [$t3 addRow $tab3 {x y} {Head ""}]
set c0 [lindex [$t3 rowCells $r3] 0]
ok {[$t3 cellStyle $c0] eq "Head"}                               "C: built-in cellStyles arg"
$t3 setCellStyle $c0 ""
ok {[$t3 cellStyle $c0] eq ""}                                   "C: setCellStyle \"\" removes"
$t3 setCellStyle $c0 Body
ok {[$t3 cellStyle $c0] eq "Body"}                               "C: setCellStyle reassigns"
$t3 destroy; $pkg3 destroy

# ---- D) error case ----
set pkg4 [odf::newTextDoc]; set t4 [odf::Text new $pkg4]
ok {[catch {$t4 defineAutoCellStyle X -bogus 1}]}                "D: unknown option -> error"
$t4 destroy; $pkg4 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
