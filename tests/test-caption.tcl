set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# ---- A) captions with auto sequence numbering ----
$t appendParagraph "Document with figures and tables."
set c1 [$t appendCaption Illustration "Figure" "System overview"]
set c2 [$t appendCaption Illustration "Figure" "Data flow"]
set c3 [$t appendCaption Table "Table" "Benchmark results"]
ok {[$t captions] eq {{Illustration 1} {Illustration 2} {Table 1}}} "A: per-sequence auto numbering"
# the sequence run is inside the caption paragraph
set seqs {}
foreach r [$t runs $c1] { if {[$t runKind $r] eq "sequence"} { lappend seqs [$r getAttribute text:name] } }
ok {$seqs eq {Illustration}}                           "A: caption holds a sequence field"

# ---- B) prelude: sequence-decls created once, before body content ----
$t flush
set doc [$pkg tree content.xml]; set xml [$doc asXML]; $doc delete
ok {[regexp -all {<text:sequence-decl } $xml] == 2}    "B: one decl per used sequence"
ok {[regexp {<text:sequence-decls>} $xml]}             "B: sequence-decls element present"
ok {[string first "sequence-decls" $xml] < [string first "Document with figures" $xml]} "B: decls in prelude before content"

# ---- C) figure + table indexes ----
set fi [$t appendIllustrationIndex -title "List of Figures" -name "LoF"]
set ti [$t appendTableIndex -title "List of Tables" -name "LoT"]
ok {[$t illustrationIndexes] eq {LoF}}                 "C: illustration index name"
ok {[$t tableIndexes] eq {LoT}}                        "C: table index name"
ok {[$t kind $fi] eq "illustration-index"}             "C: kind illustration-index"
ok {[$t kind $ti] eq "table-index"}                    "C: kind table-index"
$t flush
set doc [$pkg tree content.xml]; set xml [$doc asXML]; $doc delete
ok {[regexp {<text:illustration-index-source>} $xml]}  "C: illustration source present"
ok {[regexp {<text:table-index-source>} $xml]}         "C: table source present"

# ---- D) validation ----
ok {[catch {$t appendCaption Illustration F x -nope y}]} "D: unknown caption option rejected"
ok {[catch {$t appendIllustrationIndex -nope y}]}      "D: unknown index option rejected"

$t flush
$pkg save [file join $out figtab.odt]
$t destroy; $pkg destroy

# ---- E) round-trip ----
set p2 [odf::Package new [file join $out figtab.odt]]
set t2 [odf::Text new $p2]
ok {[$t2 captions] eq {{Illustration 1} {Illustration 2} {Table 1}}} "E: captions survive reload"
ok {[$t2 illustrationIndexes] eq {LoF} && [$t2 tableIndexes] eq {LoT}} "E: indexes survive reload"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
