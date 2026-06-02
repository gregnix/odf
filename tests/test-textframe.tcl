set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }
proc slurp {f} { set h [open $f rb]; set d [read $h]; close $h; return $d }

# ---- A) build the address block as a page-anchored text frame ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t defineAutoGraphic FrameClear {draw:stroke none draw:fill none fo:padding 0cm \
        fo:border none style:wrap run-through style:run-through foreground \
        style:vertical-pos from-top style:vertical-rel page \
        style:horizontal-pos from-left style:horizontal-rel page}
$t addTextFrame Anschriftfeld 2.0cm 4.5cm 8.5cm {
    {"Max Mustermann \u00b7 Musterstra\u00dfe 1 \u00b7 12345 Musterstadt" Absender}
    {"Firma Beispiel GmbH" Anschrift}
    {"Frau Erika Beispiel" Anschrift}
    {"Beispielweg 12" Anschrift}
    {"12345 Musterstadt" Anschrift}
} -height 4.0cm -style FrameClear
# normal flowing text as well (must not disturb the frame)
$t appendParagraph "Betreff: Test" 
$t flush
$pkg save [file join $out frame.odt]
$t destroy; $pkg destroy

# ---- B) reload: frame, position, lines, anchor ----
set p2 [odf::Package new [file join $out frame.odt]]
set t2 [odf::Text new $p2]
ok {[$t2 textFrames] eq "Anschriftfeld"}                       "B: text frame detected"
set fi [$t2 frameInfo Anschriftfeld]
ok {[dict get $fi x] eq "2.0cm"}                               "B: x=2.0cm"
ok {[dict get $fi y] eq "4.5cm"}                               "B: y=4.5cm (DIN ~45mm)"
ok {[dict get $fi width] eq "8.5cm"}                           "B: width=8.5cm (85mm)"
ok {[dict get $fi height] eq "4.0cm"}                          "B: height=4.0cm"
ok {[dict get $fi anchor] eq "page"}                           "B: page-anchored"
set lines [dict get $fi lines]
ok {[llength $lines] == 5}                                     "B: 5 lines"
ok {[string match "Max Mustermann*" [lindex $lines 0]]}        "B: first line return address"
ok {[lindex $lines end] eq "12345 Musterstadt"}               "B: last line city"
$t2 destroy; $p2 destroy

# ---- C) no clash with image frames ----
set p3 [odf::Package new [file join $out frame.odt]]
set t3 [odf::Text new $p3]
$p3 addpart Pictures/x.png [slurp [file join [file dirname [file normalize [info script]]] fixtures odt-lib-volltest-bild1.png]] image/png
$t3 appendImageFit Pictures/x.png -name Bild
ok {[$t3 textFrames] eq "Anschriftfeld"}                       "C: image frame not counted as text frame"
ok {[llength [$t3 find image]] == 1}                           "C: image still detected as image"
$t3 destroy; $p3 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
