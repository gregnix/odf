set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# ---- A) inline index marks ----
set p [$t appendParagraph "The quick brown fox and the lazy dog."]
set m1 [$t addIndexMark $p "fox" -key1 "animals" -main-entry true]
set m2 [$t addIndexMark $p "dog" -key1 "animals"]
ok {[$t indexMarks] eq {fox dog}}                      "A: index mark string-values"
ok {[$t runKind $m1] eq "index-mark"}                  "A: mark is an inline run"
ok {[$m1 getAttribute text:key1] eq "animals"}         "A: key1 set"
ok {[$m1 getAttribute text:main-entry ""] eq "true"}   "A: main-entry coerced to boolean true"

# ---- B) alphabetical index ----
set idx [$t appendIndex -title "Keyword Index" -name "Idx1"]
ok {[$t alphabeticalIndexes] eq {Idx1}}                "B: index name"
ok {[$t kind $idx] eq "index"}                         "B: block kind is index"
$t flush
set doc [$pkg tree content.xml]; set xml [$doc asXML]; $doc delete
ok {[regexp {<text:alphabetical-index-source} $xml]}   "B: source present"
ok {[regexp {<text:index-body/?>} $xml]}               "B: index-body present (filled by consumer)"
ok {[regexp {text:string-value="fox"} $xml]}           "B: mark serialized"
ok {![regexp {text:main-entry="[01]"} $xml]}           "B: main-entry never 1/0"

# ---- C) validation ----
ok {[catch {$t addIndexMark $p "x" -main-entry maybe}]} "C: non-boolean main-entry rejected"
ok {[catch {$t addIndexMark $p "x" -nope y}]}          "C: unknown option rejected"
ok {[catch {$t appendIndex -nope y}]}                  "C: unknown index option rejected"

$t flush
$pkg save [file join $out index.odt]
$t destroy; $pkg destroy

# ---- D) round-trip ----
set p2 [odf::Package new [file join $out index.odt]]
set t2 [odf::Text new $p2]
ok {[$t2 indexMarks] eq {fox dog}}                     "D: marks survive reload"
ok {[$t2 alphabeticalIndexes] eq {Idx1}}               "D: index survives reload"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
