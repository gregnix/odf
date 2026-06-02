set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) build a mixed paragraph: text + link + break + tab + span ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
set p   [$t appendParagraph "Start "]
$t addLink  $p "Tcl" https://www.tcl.tk/
$t addBreak $p
$t addTab   $p
$t addSpan  $p "fett" SomeStyle
set kinds {}; foreach r [$t runs $p] { lappend kinds [$t runKind $r] }
puts "Run-Arten: $kinds"
ok {$kinds eq {text link linebreak tab span}}        "A: run order/kinds correct"
$t flush
$pkg save [file join $out inline.odt]
$t destroy; $pkg destroy

# ---- B) reload: link href + break/tab preserved, order stable ----
set p2 [odf::Package new [file join $out inline.odt]]
set t2 [odf::Text new $p2]
set q [lindex [$t2 find paragraph] 0]
set runs [$t2 runs $q]
set kinds2 {}; foreach r $runs { lappend kinds2 [$t2 runKind $r] }
ok {$kinds2 eq {text link linebreak tab span}}        "B: order/kinds after reload"
set lr [lindex $runs 1]
ok {[$t2 runKind $lr] eq "link"}                       "B: second run is link"
ok {[$t2 linkHref $lr] eq "https://www.tcl.tk/"}       "B: link href preserved"
ok {[$t2 runText $lr] eq "Tcl"}                        "B: link text preserved"
$t2 destroy; $p2 destroy

# ---- C) read a real link in an existing document ----
set p3 [odf::Package new [file join [file dirname [file normalize [info script]]] fixtures odt-tcltk-erweitert-testdokument.odt]]
set t3 [odf::Text new $p3]
set href ""
foreach n [$t3 blocks] {
    foreach r [$t3 runs $n] { if {[$t3 runKind $r] eq "link"} { set href [$t3 linkHref $r]; break } }
    if {$href ne ""} break
}
ok {$href eq "https://www.tcl.tk/"}                    "C: real link read"
$t3 destroy; $p3 destroy

# ---- D) footnotes / endnotes (text 0.24) ----
set pkgD [odf::newTextDoc]; set tD [odf::Text new $pkgD]
set para [$tD appendParagraph "Main text"]
$tD addText $para " with a note"
set fn [$tD addFootnote $para "This is the footnote."]
$tD addText $para " and more"
set en [$tD addEndnote  $para "This is an endnote."]
set fn2 [$tD addFootnote $para "Second footnote." -citation "*"]
ok {[$tD noteClass $fn] eq "footnote"}                 "D: footnote class"
ok {[$tD noteClass $en] eq "endnote"}                  "D: endnote class"
ok {[$tD noteCitation $fn] eq "1"}                     "D: first footnote citation = 1"
ok {[$tD noteText $fn] eq "This is the footnote."}     "D: footnote text"
ok {[$tD noteCitation $fn2] eq "*"}                    "D: explicit citation"
ok {[$fn getAttribute text:id ""] ne [$en getAttribute text:id ""]} "D: distinct note ids"
ok {[catch {$tD addFootnote $para "x" -class sidenote}]} "D: bad note class rejected"
$tD flush
set odt [file join $out notes.odt]; $pkgD save $odt
$tD destroy; $pkgD destroy

# reload: note runs are read back inline
set pkgD2 [odf::Package new $odt]; set tD2 [odf::Text new $pkgD2]
set blocks [$tD2 blocks]
set pnode ""
foreach b $blocks { if {[$tD2 kind $b] eq "paragraph"} { set pnode $b; break } }
set notes {}
foreach r [$tD2 runs $pnode] { if {[$tD2 runKind $r] eq "note"} { lappend notes $r } }
ok {[llength $notes] == 3}                              "D: 3 notes read back inline"
ok {[$tD2 noteText [lindex $notes 0]] eq "This is the footnote."} "D: footnote text persisted"
ok {[$tD2 noteClass [lindex $notes 1]] eq "endnote"}   "D: endnote persisted"
# strict parse
foreach part {content.xml META-INF/manifest.xml} {
    ok {![catch {dom parse [encoding convertfrom utf-8 [$pkgD2 part $part]] dd}]} "D: $part well-formed"
    catch {dd delete}
}
$tD2 destroy; $pkgD2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
