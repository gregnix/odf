set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set src [lindex $argv 0]
if {$src eq "" || ![file isfile $src]} { puts stderr "Usage: tclsh test-text3.tcl <file.odt>"; exit 2 }
set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# choose a list: prefer one with a sublist, else the first; returns {list edittarget}
proc pickList {t} {
    set first ""
    foreach l [$t find list] {
        if {$first eq ""} { set first $l }
        foreach it [$t listItems $l] {
            set sub [$t itemSublist $it]
            if {$sub ne ""} { return [list $l $sub] }
        }
    }
    if {$first eq ""} { return {} }
    return [list $first $first]   ;# flat: edit target = the list itself
}

set pkg [odf::Package new $src]
set t   [odf::Text new $pkg]

# ---- A) read lists ----
lassign [pickList $t] L editL
set haveList [expr {$L ne ""}]
if {$haveList} {
    set items [$t listItems $L]
    puts "list: [llength $items] items, edit target [expr {$editL eq $L ? {flat} : {sublist}}]"
    ok {[llength [$t listItems $editL]] >= 2}   "A: edit target has >=2 items"
} else {
    puts "list: none -> list tests skipped"
}

# ---- B) read table ----
set tab [lindex [$t find table] 0]
set rows [$t tableRows $tab]
puts "table: [llength $rows] lines, [llength [$t rowCells [lindex $rows 0]]] Spalten"
ok {[llength $rows] >= 2}                    "B: >=2 lines"
set hdr [$t rowCells [lindex $rows 0]]
ok {[llength $hdr] >= 2}                      "B: header has cells"
set kopf0 [$t cellText [lindex $hdr 0]]

# ---- C) bearbeiten ----
set stylesBefore [$pkg part styles.xml]
if {$haveList} {
    $t setItemText [lindex [$t listItems $editL] 0] "SUB-GEAENDERT"
    $t addListItem $editL "NEU-ITEM"
}
$t setCellText [lindex [$t rowCells [lindex $rows 1]] 0] "ZELLE-GEAENDERT"
$t addRow $tab {n1 n2 n3 n4}
$t flush
$pkg save [file join $out mod-lt.odt]
$t destroy; $pkg destroy

# ---- D) reload + check ----
set p2 [odf::Package new [file join $out mod-lt.odt]]
set t2 [odf::Text new $p2]
if {$haveList} {
    lassign [pickList $t2] L2 editL2
    set its2 [$t2 listItems $editL2]
    ok {[$t2 itemText [lindex $its2 0]] eq "SUB-GEAENDERT"}    "D: item changed"
    ok {[$t2 itemText [lindex $its2 end]] eq "NEU-ITEM"}       "D: item appended"
}
set tab2 [lindex [$t2 find table] 0]
set rows2 [$t2 tableRows $tab2]
ok {[llength $rows2] == [expr {[llength $rows]+1}]}        "D: row appended"
ok {[$t2 cellText [lindex [$t2 rowCells [lindex $rows2 1]] 0]] eq "ZELLE-GEAENDERT"} "D: cell changed"
ok {[$t2 cellText [lindex [$t2 rowCells [lindex $rows2 0]] 0]] eq $kopf0}            "D: header unchanged (pass-through)"
ok {[$p2 part styles.xml] eq $stylesBefore}                "D: styles.xml byte-identical"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
