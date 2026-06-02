set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) build a nested list from scratch (3 levels) ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
set l   [$t appendList]
set gui [$t addListItem $l "GUI"]
set sub [$t addSublist $gui]
$t addListItem $sub "Tk"
set ttk [$t addListItem $sub "ttk"]
set sub3 [$t addSublist $ttk]          ;# dritte Ebene
$t addListItem $sub3 "themed"
$t addListItem $sub "canvas"
set db  [$t addListItem $l "Datenbank"]
set sub2 [$t addSublist $db]
$t addListItem $sub2 "SQLite"
$t addListItem $sub2 "PostgreSQL"
$t flush
$pkg save [file join $out sublist.odt]
$t destroy; $pkg destroy

# ---- B) reload: check nesting ----
set p2 [odf::Package new [file join $out sublist.odt]]
set t2 [odf::Text new $p2]
set top [lindex [$t2 find list] 0]
set items [$t2 listItems $top]
ok {[llength $items] == 2}                                  "B: 2 top items"
ok {[$t2 itemText [lindex $items 0]] eq "GUI"}              "B: Item0 = GUI"
ok {[$t2 itemText [lindex $items 1]] eq "Datenbank"}        "B: Item1 = Database"

set guiSub [$t2 itemSublist [lindex $items 0]]
ok {$guiSub ne ""}                                          "B: GUI has sublist"
set guiSubItems [$t2 listItems $guiSub]
ok {[llength $guiSubItems] == 3}                            "B: sublist 3 items (Tk/ttk/canvas)"
ok {[$t2 itemText [lindex $guiSubItems 0]] eq "Tk"}         "B: Sub0 = Tk"

# dritte Ebene unter ttk
set ttkSub [$t2 itemSublist [lindex $guiSubItems 1]]
ok {$ttkSub ne ""}                                          "B: ttk has 3rd level"
ok {[$t2 itemText [lindex [$t2 listItems $ttkSub] 0]] eq "themed"} "B: 3rd level = themed"

set dbSub [$t2 itemSublist [lindex $items 1]]
ok {[llength [$t2 listItems $dbSub]] == 2}                  "B: Database sublist 2 items"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
