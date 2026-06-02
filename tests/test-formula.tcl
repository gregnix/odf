set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# A) body MathML gets wrapped in a namespaced math:math
set p1 [$t appendParagraph "E = "]
set f1 [$t addFormula $p1 {<mrow><mi>m</mi><msup><mi>c</mi><mn>2</mn></msup></mrow>}]
ok {[$f1 nodeName] eq "draw:frame"}                          "A: returns a draw:frame"
ok {[llength [$f1 getElementsByTagName draw:object]] == 1}   "A: frame holds one draw:object"
set m1 [$t formulaMathML [lindex [$f1 getElementsByTagName draw:object] 0]]
ok {[string match {<math:math*} $m1]}                        "A: body wrapped in math:math"
ok {[string match {*xmlns:math=*Math/MathML*} $m1]}          "A: MathML namespace declared"
ok {[string match {*msup*} $m1]}                             "A: MathML body preserved"

# B) a complete math:math is used as-is (not double-wrapped)
set p2 [$t appendParagraph ""]
set ns "http://www.w3.org/1998/Math/MathML"
$t addFormula $p2 "<math:math xmlns:math=\"$ns\"><math:mi>x</math:mi></math:math>"
set obj2 [lindex [[lindex [$t formulas] end] getElementsByTagName draw:object] 0]
set inner [lindex [$t formulas] end]
set ml2 [$t formulaMathML $inner]
ok {[regexp -all {<math:math} $ml2] == 1}                    "B: complete math:math not double-wrapped"

# C) options
set p3 [$t appendParagraph ""]
set f3 [$t addFormula $p3 {<mi>y</mi>} -anchor paragraph -width 3cm -height 2cm]
ok {[$f3 getAttribute text:anchor-type ""] eq "paragraph"}   "C: -anchor applied"
ok {[$f3 getAttribute svg:width ""] eq "3cm"}                "C: -width applied"
ok {[$f3 getAttribute svg:height ""] eq "2cm"}               "C: -height applied"
ok {[catch {$t addFormula $p3 {<mi>z</mi>} -nope x}]}        "C: unknown option rejected"

# D) classification
ok {[llength [$t formulas]] == 3}                            "D: three formula objects"
set fr ""; foreach r [$t runs $p1] { if {[$t runKind $r] eq "formula"} { set fr 1 } }
ok {$fr eq 1}                                                "D: runKind reports formula"
ok {[$t kind $p1] eq "paragraph"}                            "D: host block stays paragraph (not image)"

# E) save + reload round-trip
$t flush
$pkg save [file join $out formula.odt]
$t destroy; $pkg destroy
set p [odf::Package new [file join $out formula.odt]]
set t2 [odf::Text new $p]
ok {[llength [$t2 formulas]] == 3}                           "E: formulas survive reload"
ok {[string match {*msup*} [$t2 formulaMathML [lindex [$t2 formulas] 0]]]} "E: MathML content survives reload"
$t2 destroy; $p destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
