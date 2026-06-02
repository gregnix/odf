set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::style
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# ---- A) inline citations (bibliography marks) ----
set p [$t appendParagraph "As shown by "]
set m1 [$t addBibliographyMark $p -type book -author "Smith, J." -title "ODF Internals" \
    -year 2020 -identifier "SMITH2020" -publisher "TechPress"]
$t addText $p " and "
set m2 [$t addBibliographyMark $p -type article -author "Doe" -title "Tcl and XML" \
    -year 2019 -identifier "DOE2019" -text "\[2\]"]
ok {[$t bibliographyMarks] eq {{book SMITH2020} {article DOE2019}}} "A: marks type+identifier"
ok {[$t runKind $m1] eq "bibliography-mark"}           "A: mark is an inline run"
ok {[$t markField $m1 author] eq "Smith, J."}          "A: field author"
ok {[$t markField $m1 publisher] eq "TechPress"}       "A: field publisher"
ok {[$t runText $m1] eq "SMITH2020"}                   "A: display defaults to identifier"
ok {[$t runText $m2] eq "\[2\]"}                        "A: explicit display text"

# ---- B) bibliography index ----
set bib [$t appendBibliography -title "References" -name "Bib1"]
ok {[$t bibliographies] eq {Bib1}}                     "B: bibliography index name"
ok {[$t kind $bib] eq "bibliography"}                  "B: block kind is bibliography"
$t flush
set doc [$pkg tree content.xml]; set xml [$doc asXML]; $doc delete
ok {[regexp {<text:bibliography-source>} $xml]}        "B: source present"
ok {[regexp {<text:index-body/?>} $xml]}               "B: index-body present (filled by consumer)"
ok {[regexp {text:bibliography-type="book"} $xml]}     "B: mark type serialized"

# ---- C) validation ----
ok {[catch {$t addBibliographyMark $p -type bogus}]}   "C: invalid bibliography-type rejected"
ok {[catch {$t addBibliographyMark $p -type book -nope x}]} "C: unknown field rejected"
ok {[catch {$t appendBibliography -nope x}]}           "C: unknown index option rejected"

# combine with the styles-side configuration in one document
set s [odf::Styles new $pkg]
$s defineBibliographyConfiguration -numbered-entries true -prefix "\[" -suffix "\]" \
    -sort-keys {{author 1} {year 1}}
$s flush
$pkg save [file join $out bibfull.odt]
$t destroy; $s destroy; $pkg destroy

# ---- D) round-trip ----
set p2 [odf::Package new [file join $out bibfull.odt]]
set t2 [odf::Text new $p2]
ok {[$t2 bibliographyMarks] eq {{book SMITH2020} {article DOE2019}}} "D: marks survive reload"
ok {[$t2 bibliographies] eq {Bib1}}                    "D: index survives reload"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
