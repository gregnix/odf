set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set src [lindex $argv 0]
if {$src eq "" || ![file isfile $src]} { puts stderr "Usage: tclsh test-text2.tcl <file.odt>"; exit 2 }
set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# find the formatting paragraph (with bold/italic)
proc fmtPara {t} {
    foreach n [$t find paragraph] { if {[string match {*normaler Text*} [$t text $n]]} { return $n } }
    return ""
}

set pkg [odf::Package new $src]
set t   [odf::Text new $pkg]
set p   [fmtPara $t]
if {$p eq ""} { puts "skipped: no matching paragraph (test is tailored to deinedatei.odt)"; exit 0 }
ok {$p ne ""} "formatting paragraph found"

# ---- A) read runs ----
puts "=== Runs ==="
set runs [$t runs $p]
foreach r $runs { puts [format "  %-5s %-12s '%s'" [$t runKind $r] [$t runStyle $r] [$t runText $r]] }
ok {[llength $runs] == 3}                         "A: 3 Runs"
ok {[$t runKind [lindex $runs 0]] eq "text"}      "A: run0 = text node"
ok {[$t runKind [lindex $runs 1]] eq "span"}      "A: Run1 = span"
ok {[$t runStyle [lindex $runs 1]] eq "BoldStyle"} "A: Run1 Style = BoldStyle"
ok {[$t runStyle [lindex $runs 2]] eq "ItalicStyle"} "A: Run2 Style = ItalicStyle"

# ---- B) inline-preservedd editieren ----
set stylesBefore [$pkg part styles.xml]
set bold [lindex $runs 1]
$t setRunText $bold "FETT-GEAENDERT"            ;# nur den fetten Run
$t addSpan $p " plus-neu" ItalicStyle           ;# neuen Run anhaengen
$t flush
$pkg save [file join $out mod-inline.odt]
$t destroy; $pkg destroy

# ---- C) reload + check ----
set p2 [odf::Package new [file join $out mod-inline.odt]]
set t2 [odf::Text new $p2]
set q  [fmtPara $t2]
set r2 [$t2 runs $q]
ok {[$t2 runText [lindex $r2 1]] eq "FETT-GEAENDERT"}      "C: bold run changed"
ok {[$t2 runStyle [lindex $r2 1]] eq "BoldStyle"}          "C: bold run KEEPS style (inline-preserving)"
ok {[string match *kursiver* [$t2 runText [lindex $r2 2]]]} "C: italic run unchanged (pass-through)"
ok {[$t2 runText [lindex $r2 end]] eq " plus-neu"}         "C: new span appended"
ok {[$t2 runStyle [lindex $r2 end]] eq "ItalicStyle"}      "C: new span has style"
ok {[$p2 part styles.xml] eq $stylesBefore}                "C: styles.xml byte-identical"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
