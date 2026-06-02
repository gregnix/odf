set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# ---- A) register three change regions ----
set p1 [$t appendParagraph "Hallo "]
$t addInsertion c1 -author "Max Mustermann" -comment "neu"
$t addChangeStart $p1 c1
$t addText        $p1 "eingefuegt"
$t addChangeEnd   $p1 c1

set p2 [$t appendParagraph "Rest "]
$t addDeletion c2 -author "MM" -content "geloeschter Satz."
$t addChange   $p2 c2

$t appendParagraph "x"
$t addFormatChange c3 -author "Max Mustermann"

set regs [$t changedRegions]
ok {[llength $regs] == 3}                             "A: three changed regions"
# index by id
array set byId {}
foreach r $regs { set byId([$t changeId $r]) $r }
ok {[$t changeType $byId(c1)] eq "insertion"}         "A: c1 is insertion"
ok {[$t changeType $byId(c2)] eq "deletion"}          "A: c2 is deletion"
ok {[$t changeType $byId(c3)] eq "format-change"}     "A: c3 is format-change"
ok {[$t changeAuthor $byId(c1)] eq "Max Mustermann"}          "A: author read back"
ok {[$t changeComment $byId(c1)] eq "neu"}            "A: comment read back"
ok {[$t changeDate $byId(c1)] ne ""}                  "A: date defaulted"

# ---- B) inline markers are runs of the right kind ----
set k1 {}; foreach r [$t runs $p1] { lappend k1 [$t runKind $r] }
ok {"change-start" in $k1 && "change-end" in $k1}     "B: ranged change markers inline"
set k2 {}; foreach r [$t runs $p2] { lappend k2 [$t runKind $r] }
ok {"change" in $k2}                                  "B: point change marker inline"

# ---- C) structure: prelude placement + deletion content + block kind ----
$t flush
set xml [[$pkg tree content.xml] asXML]
ok {[string match {*<text:tracked-changes*} $xml]}    "C: tracked-changes container present"
regexp {<office:text>(.*?)<text:p} $xml -> pre
ok {[string match {*tracked-changes*} $pre]}          "C: container sits before first paragraph (prelude)"
ok {[string match {*geloeschter Satz.*} $xml]}        "C: deletion carries deleted content"
ok {[string match {*xml:id="c1"*} $xml]}              "C: changed-region has xml:id"
set tc [lindex [$t find tracked-changes] 0]
ok {$tc ne "" && [$t kind $tc] eq "tracked-changes"}  "C: block kind = tracked-changes"

# ---- D) validation ----
ok {[catch {$t addInsertion c9 -nope x}]}             "D: unknown option rejected"

# ---- E) save + reload round-trip ----
$pkg save [file join $out tracking.odt]
$t destroy; $pkg destroy
set p2pkg [odf::Package new [file join $out tracking.odt]]
set t2 [odf::Text new $p2pkg]
ok {[llength [$t2 changedRegions]] == 3}              "E: regions survive reload"
set r0 ""; foreach r [$t2 changedRegions] { if {[$t2 changeId $r] eq "c2"} { set r0 $r } }
ok {$r0 ne "" && [$t2 changeType $r0] eq "deletion"}  "E: deletion type survives reload"
$t2 destroy; $p2pkg destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
