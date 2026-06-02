set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }
proc slurp {f} { set h [open $f rb]; set d [read $h]; close $h; return $d }
proc cm {px} { return [format %.2fcm [expr {$px/96.0*2.54}]] }
proc pngdim {b} { binary scan [string range $b 16 23] II w h; return [list $w $h] }

set dir [expr {$argc ? [lindex $argv 0] : "."}]   ;# Verzeichnis mit den PNGs
foreach f {odt-lib-volltest-bild1.png odt-lib-volltest-bild2.png} {
    if {![file exists [file join $dir $f]]} { puts stderr "fehlt: [file join $dir $f] (Verzeichnis als Argument angeben)"; exit 2 }
}
set b1 [slurp [file join $dir odt-lib-volltest-bild1.png]]
set b2 [slurp [file join $dir odt-lib-volltest-bild2.png]]
set built [file join $out built.odt]

# ---- A) build a document from scratch ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t appendHeading "Aufgebautes Dokument" 1
$t appendParagraph "Von Grund auf mit odf::text erzeugt."
set p [$t appendParagraph "Mit "]
$t addSpan $p "fettem" CommonBoldText
$t addText $p " Anteil."
set lst [$t appendList]
$t addListItem $lst "Erster Punkt"
$t addListItem $lst "Zweiter Punkt"
set tab [$t appendTable 2]
$t addRow $tab {Name Wert}
$t addRow $tab {Alpha 1}
$t addRow $tab {Beta 2}
$pkg addpart Pictures/b1.png $b1 image/png
$pkg addpart Pictures/b2.png $b2 image/png
$t appendImageFit Pictures/b1.png -name image1
$t appendImageFit Pictures/b2.png -name image2
$t flush
$pkg save $built
$t destroy; $pkg destroy
ok {[file exists $built]} "A: file created"

# ---- B) Wieder oeffnen (Beweis: gueltiges, parsbares ODT) ----
set p2 [odf::Package new $built]
set t2 [odf::Text new $p2]
array set c {heading 0 paragraph 0 list 0 table 0 image 0 unknown 0}
foreach n [$t2 blocks] { incr c([$t2 kind $n]) }
puts "Bloecke: [array get c]"
ok {$c(heading)   >= 1} "B: heading present"
ok {$c(paragraph) >= 2} "B: paragraphs present"
ok {$c(list)      == 1} "B: list present"
ok {$c(table)     == 1} "B: table present"
ok {$c(image)     == 2} "B: 2 images present"

# Inhalte stichprobenartig
set h1n [lindex [$t2 find heading] 0]
ok {[$t2 text $h1n] eq "Aufgebautes Dokument" && [$t2 level $h1n] eq "1"} "B: heading text+level"
set tb [lindex [$t2 find table] 0]
ok {[llength [$t2 tableRows $tb]] == 3}                              "B: table 3 rows"
ok {[$t2 cellText [lindex [$t2 rowCells [lindex [$t2 tableRows $tb] 1]] 0]] eq "Alpha"} "B: cell Alpha"
set ls [lindex [$t2 find list] 0]
ok {[llength [$t2 listItems $ls]] == 2}                              "B: list 2 items"

# ---- C) images + Manifest korrekt eingebettet ----
ok {[$p2 part Pictures/b1.png] eq $b1}                  "C: image1 byte-identical"
ok {[$p2 part Pictures/b2.png] eq $b2}                  "C: image2 byte-identical"
ok {[dict get [$p2 manifest] Pictures/b1.png] eq "image/png"} "C: manifest image1"
ok {[dict get [$p2 manifest] Pictures/b2.png] eq "image/png"} "C: manifest image2"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
