set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# ---- A) point annotation: attributes + readers ----
set p1 [$t appendParagraph "Ein Absatz mit Anmerkung."]
set a1 [$t addAnnotation $p1 "Bitte pruefen." -author "Max Mustermann" -initials "MM" -display true -name ann1]
ok {[llength [$t annotations]] == 1}                 "A: one annotation present"
set a0 [lindex [$t annotations] 0]
ok {[$t annotationAuthor $a0] eq "Max Mustermann"}           "A: author read back"
ok {[$t annotationName   $a0] eq "ann1"}             "A: name read back"
ok {[$t annotationText   $a0] eq "Bitte pruefen."}   "A: body text read back"
ok {[$t annotationDate   $a0] ne ""}                 "A: date defaulted (non-empty)"
ok {[$t runKind $a0] eq "annotation"}                "A: runKind = annotation"

# ---- B) ranged annotation: start name + matching end ----
set p2 [$t appendParagraph "Vorher "]
$t addAnnotation    $p2 "Markierter Bereich." -author "MM" -name range1
$t addText          $p2 "hervorgehoben"
$t addAnnotationEnd $p2 range1
set kinds {}; foreach r [$t runs $p2] { lappend kinds [$t runKind $r] }
ok {"annotation" in $kinds && "annotation-end" in $kinds} "B: annotation + annotation-end are inline runs"

# ---- C) boolean office:display is literal true/false, never 1/0 ----
$t flush
set xml [[$pkg tree content.xml] asXML]
ok {[string match {*office:display="true"*} $xml]}   "C: display serialized as true"
ok {![string match {*office:display="1"*} $xml]}     "C: display NOT serialized as 1"
ok {[string match {*<dc:creator>Max Mustermann</dc:creator>*} $xml]} "C: dc:creator in content.xml"
ok {[string match {*<office:annotation-end office:name="range1"*} $xml]} "C: annotation-end with name"
ok {[string match {*xmlns:dc=*} $xml] && [string match {*xmlns:meta=*} $xml]} "C: content.xml declares dc + meta NS"

# ---- D) validation ----
ok {[catch {$t addAnnotation $p1 "x" -nope y}]}      "D: unknown option rejected"

# ---- E) save + reload round-trip (NS + content survive a real ODF save) ----
$pkg save [file join $out annotation.odt]
set p2pkg [odf::Package new [file join $out annotation.odt]]
set t2 [odf::Text new $p2pkg]
set anns2 [$t2 annotations]
ok {[llength $anns2] == 2}                            "E: two annotations survive reload"
set r0 [lindex $anns2 0]
ok {[$t2 annotationAuthor $r0] eq "Max Mustermann"}          "E: author survives reload"
ok {[$t2 annotationText   $r0] eq "Bitte pruefen."}  "E: body survives reload"
$t2 destroy; $p2pkg destroy
$t destroy; $pkg destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
