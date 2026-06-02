set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }
proc nodeName {n} { return [$n nodeName] }

# ---- A) build a 3-column grid, then span ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t defineAutoColumn C {style:column-width 4cm}
set tab [$t appendTableCols {C C C}]
$t addHeaderRow $tab {Title {} {}}            ;# title goes in cell 0, then spans
$t addRow $tab {A1 B1 C1}
$t addRow $tab {A2 B2 C2}
$t addRow $tab {A3 B3 C3}
# rows: 0 = header, 1..3 = body
$t spanCell $tab 0 0 -columns 3               ;# header title across all columns
$t spanCell $tab 1 0 -rows 2                  ;# A1 spans rows 1 and 2 (column 0)

set rows [$t tableRows $tab]
set hcells [$t rowCells [lindex $rows 0]]
ok {[llength $rows] == 4}                                          "A: 4 rows"
ok {[[lindex $hcells 0] getAttribute table:number-columns-spanned 1] == 3} "A: header columns-spanned=3"
ok {[nodeName [lindex $hcells 1]] eq "table:covered-table-cell"}   "A: header col 1 covered"
ok {[nodeName [lindex $hcells 2]] eq "table:covered-table-cell"}   "A: header col 2 covered"
ok {[llength $hcells] == 3}                                        "A: header still 3 cell slots"
set sp [$t cellSpan $tab 0 0]
ok {[dict get $sp columns] == 3 && [dict get $sp rows] == 1}       "A: cellSpan header = 3x1"

set r1c0 [lindex [$t rowCells [lindex $rows 1]] 0]
ok {[$r1c0 getAttribute table:number-rows-spanned 1] == 2}        "A: body rows-spanned=2"
ok {[nodeName [lindex [$t rowCells [lindex $rows 2]] 0]] eq "table:covered-table-cell"} "A: row 2 col 0 covered"
ok {[$t cellText [lindex [$t rowCells [lindex $rows 1]] 1]] eq "B1"} "A: neighbour cell intact"

$t flush; $t destroy
$pkg save [file join $out tablespan.odt]; $pkg destroy

# ---- B) reload: spans + covered cells persist ----
set pkg2 [odf::Package new [file join $out tablespan.odt]]
set t2   [odf::Text new $pkg2]
set tb   [lindex [$t2 find table] 0]
set sp2  [$t2 cellSpan $tb 0 0]
ok {[dict get $sp2 columns] == 3}                                 "B: header span persisted"
ok {[dict get [$t2 cellSpan $tb 1 0] rows] == 2}                  "B: row span persisted"
ok {[nodeName [lindex [$t2 rowCells [lindex [$t2 tableRows $tb] 0]] 1]] eq "table:covered-table-cell"} "B: covered cell persisted"
$t2 destroy; $pkg2 destroy

# ---- C) error cases ----
set pkg3 [odf::newTextDoc]; set t3 [odf::Text new $pkg3]
set tb3 [$t3 appendTableCols {C C C}]
$t3 addRow $tb3 {a b c}
$t3 addRow $tb3 {d e f}
ok {[catch {$t3 spanCell $tb3 0 0 -columns 4}]}                   "C: column span over width -> error"
ok {[catch {$t3 spanCell $tb3 0 0 -rows 3}]}                     "C: row span over height -> error"
ok {[catch {$t3 spanCell $tb3 0 0 -bogus 1}]}                    "C: unknown option -> error"
ok {![catch {$t3 spanCell $tb3 0 0 -columns 2 -rows 2}]}         "C: valid 2x2 span ok"
$t3 destroy; $pkg3 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
