## test-liststyle.tcl -- odf::Styles defineListStyle / listStyleKind (0.20)
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# style-name of a text:list node
proc listStyleName {node} { return [$node getAttribute text:style-name ""] }

# ---- A) build a doc: one ordered list, one bullet list ----
set pkg [odf::newTextDoc]
set sty [odf::Styles new $pkg]
$sty defineListStyle Num1    -kind ordered
$sty defineListStyle Bullet1 -kind bullet
set t [odf::Text new $pkg]
set lo [$t appendList Num1]
$t addListItem $lo "first"
$t addListItem $lo "second"
set lb [$t appendList Bullet1]
$t addListItem $lb "alpha"
$t addListItem $lb "beta"

# ---- B) in-memory classification (before save) ----
ok {[$sty listStyleKind Num1]    eq "ordered"} "B: Num1 -> ordered (in memory)"
ok {[$sty listStyleKind Bullet1] eq "bullet"}  "B: Bullet1 -> bullet (in memory)"
ok {[$sty listStyleKind Nope]    eq ""}        "B: unknown -> \"\""

$t flush; $sty flush
$pkg save [file join $out liststyle.odt]
$t destroy; $sty destroy; $pkg destroy

# ---- C) reopen: classification survives save/round-trip ----
set p2  [odf::Package new [file join $out liststyle.odt]]
set st2 [odf::Styles new $p2]
ok {[$st2 listStyleKind Num1]    eq "ordered"} "C: Num1 -> ordered (after reopen)"
ok {[$st2 listStyleKind Bullet1] eq "bullet"}  "C: Bullet1 -> bullet (after reopen)"

# ---- D) the lists reference the styles + items intact ----
set t2 [odf::Text new $p2]
set byName [dict create]
foreach l [$t2 find list] { dict set byName [listStyleName $l] $l }
ok {[dict exists $byName Num1]}    "D: a list references Num1"
ok {[dict exists $byName Bullet1]} "D: a list references Bullet1"
set lo2 [dict get $byName Num1]
set items [$t2 listItems $lo2]
ok {[llength $items] == 2}                          "D: ordered list has 2 items"
ok {[$t2 itemText [lindex $items 0]] eq "first"}    "D: item0 = first"
ok {[$t2 itemText [lindex $items 1]] eq "second"}   "D: item1 = second"
$t2 destroy; $st2 destroy; $p2 destroy

# ---- E) idempotent: redefining the same name replaces (kind can change) ----
set pkg3 [odf::newTextDoc]
set sty3 [odf::Styles new $pkg3]
$sty3 defineListStyle X -kind ordered
$sty3 defineListStyle X -kind bullet      ;# replace
ok {[$sty3 listStyleKind X] eq "bullet"}  "E: redefine X -> now bullet"
$sty3 flush
set doc [$pkg3 tree styles.xml]
set n 0
foreach ls [[$doc documentElement] getElementsByTagName text:list-style] {
    if {[$ls getAttribute style:name ""] eq "X"} { incr n }
}
$doc delete
ok {$n == 1}                              "E: exactly one text:list-style named X"

# ---- F) bad option / kind errors ----
ok {[catch {$sty3 defineListStyle Y -kind weird}]}  "F: invalid -kind errors"
ok {[catch {$sty3 defineListStyle Z -bogus 1}]}     "F: unknown option errors"
$sty3 destroy; $pkg3 destroy

# ---- G) generated XML is well-formed and has the expected level elements ----
set p4 [odf::Package new [file join $out liststyle.odt]]
set sdoc [$p4 tree styles.xml]   ;# dom parse -> throws if not well-formed
set numLevels 0; set bulLevels 0
foreach ls [[$sdoc documentElement] getElementsByTagName text:list-style] {
    set nm [$ls getAttribute style:name ""]
    foreach c [$ls childNodes] {
        if {[$c nodeType] ne "ELEMENT_NODE"} continue
        if {$nm eq "Num1"    && [$c localName] eq "list-level-style-number"} { incr numLevels }
        if {$nm eq "Bullet1" && [$c localName] eq "list-level-style-bullet"} { incr bulLevels }
    }
}
$sdoc delete; $p4 destroy
ok {$numLevels == 10} "G: ordered style has 10 number levels"
ok {$bulLevels == 10} "G: bullet style has 10 bullet levels"

puts "----"
puts "liststyle: PASS $pass  FAIL $fail"
exit [expr {$fail > 0 ? 1 : 0}]
