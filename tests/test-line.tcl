set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) fold marks as draw:line ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t defineAutoGraphic FaltLinie {draw:stroke solid svg:stroke-width 0.02cm svg:stroke-color #000000 \
        style:vertical-rel page style:horizontal-rel page}
$t appendParagraph "Inhalt"
$t addLine Falz1 0.5cm 8.7cm  1.0cm 8.7cm  -style FaltLinie
$t addLine Loch  0.5cm 14.85cm 1.2cm 14.85cm -style FaltLinie
$t addLine Falz2 0.5cm 19.2cm 1.0cm 19.2cm  -style FaltLinie
# plus a text frame to show there is no clash
$t addTextFrame Box 2cm 4cm 8cm {{"x"}} -style FaltLinie
$t flush
$pkg save [file join $out lines.odt]
$t destroy; $pkg destroy

# ---- B) reload: lines, coordinates, anchor ----
set p2 [odf::Package new [file join $out lines.odt]]
set t2 [odf::Text new $p2]
set ln [$t2 drawLines]
ok {[llength $ln] == 3}                                  "B: 3 lines"
ok {"Falz1" in $ln && "Loch" in $ln && "Falz2" in $ln}   "B: all marks named"
set i [$t2 lineInfo Loch]
ok {[dict get $i y1] eq "14.85cm"}                       "B: punch mark y=14.85cm"
ok {[dict get $i x2] eq "1.2cm"}                         "B: punch mark longer (x2=1.2cm)"
ok {[dict get $i anchor] eq "page"}                      "B: page-anchored"
set f [$t2 lineInfo Falz1]
ok {[dict get $f y1] eq "8.7cm" && [dict get $f y2] eq "8.7cm"} "B: Fold1 horizontal at 8.7cm"
# no clash
ok {[$t2 textFrames] eq "Box"}                           "B: text frame detected independently"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
