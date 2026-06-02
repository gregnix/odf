set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }
proc slurp {f} { set h [open $f rb]; set d [read $h]; close $h; return $d }
proc frameDims {t node} {
    set fr [lindex [$node getElementsByTagName draw:frame] 0]
    return [list [$fr getAttribute svg:width ""] [$fr getAttribute svg:height ""]]
}

set png [slurp [file join [file dirname [file normalize [info script]]] fixtures odt-lib-volltest-bild1.png]]   ;# 1000x300

# ---- A) seitengerecht (Standard 17cm): 1000x300 -> 17.00 x 5.10 ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$pkg addpart Pictures/b.png $png image/png
set p [$t appendImageFit Pictures/b.png -name image]
lassign [frameDims $t $p] w h
puts "fit (17cm): $w x $h"
ok {$w eq "17.00cm"}                         "A: width capped at 17cm"
ok {$h eq "5.10cm"}                          "A: height proportional (300/1000*17)"

# ---- B) ohne Begrenzung: native 1000x300 @96dpi = 26.46 x 7.94 ----
set p2 [$t appendImageFit Pictures/b.png -maxwidth 0]
lassign [frameDims $t $p2] w2 h2
puts "nativ:     $w2 x $h2"
ok {$w2 eq "26.46cm"}                        "B: native width 26.46cm"
ok {$h2 eq "7.94cm"}                         "B: native height 7.94cm"
$t flush
$pkg save [file join $out imgfit.odt]
$t destroy; $pkg destroy

# ---- C) reload: sizes persistent ----
set r [odf::Package new [file join $out imgfit.odt]]
set tr [odf::Text new $r]
set imgs [$tr find image]
lassign [frameDims $tr [lindex $imgs 0]] rw rh
ok {$rw eq "17.00cm" && $rh eq "5.10cm"}     "C: first image 17x5.10 after reload"
$tr destroy; $r destroy

# ---- D) Fehlerfaelle (no magic: zeigen sich) ----
set pkg [odf::newTextDoc]; set t [odf::Text new $pkg]
ok {[catch {$t appendImageFit Pictures/fehlt.png}]}                 "D: missing part -> error"
$pkg addpart Pictures/x.bin "keinpng" application/octet-stream
ok {[catch {$t appendImageFit Pictures/x.bin}]}                     "D: not a PNG -> error"
$t destroy; $pkg destroy

# ---- JPEG size (640x480 @96dpi = 16.93 x 12.70) ----
set jpg [slurp [file join [file dirname [file normalize [info script]]] fixtures test640.jpg]]
set pkg [odf::newTextDoc]; set t [odf::Text new $pkg]
$pkg addpart Pictures/j.jpg $jpg image/jpeg
set pj [$t appendImageFit Pictures/j.jpg -maxwidth 0 -name J]
lassign [frameDims $t $pj] jw jh
puts "jpeg nativ: $jw x $jh"
ok {$jw eq "16.93cm" && $jh eq "12.70cm"}    "JPEG 640x480 detected"
$t destroy; $pkg destroy


puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
