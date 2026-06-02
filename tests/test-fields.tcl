set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# ---- A) page number / count (the footer classic) ----
set f [$t appendParagraph "Page "]
set pn [$t addPageNumber $f -format 1]
$t addText $f " of "
set pc [$t addPageCount $f -format 1]
ok {[$t runKind $pn] eq "page-number"}                 "A: page-number field"
ok {[$t runKind $pc] eq "page-count"}                  "A: page-count field"
ok {[$pn getAttribute style:num-format] eq "1"}        "A: num-format on page number"
ok {[$t addPageNumber $f -select current] ne ""}       "A: select current accepted"
ok {[catch {$t addPageNumber $f -select sideways}]}    "A: invalid select rejected"

# ---- B) metadata fields ----
set p [$t appendParagraph "Meta: "]
$t addTitle  $p -text "My Doc"
$t addAuthor $p -text "Max Mustermann"
$t addDate   $p -value "2026-05-26" -fixed false -text "2026-05-26"
set ch [$t addChapter $p -display number -level 2 -text "2"]
$t addFileName $p -display name -text "doc.odt"
ok {[$ch getAttribute text:display] eq "number"}       "B: chapter display"
ok {[$ch getAttribute text:outline-level] eq "2"}      "B: chapter level"
set fl [$t fields]
ok {[lsearch -index 0 $fl title] >= 0}                 "B: title field present"
ok {[lsearch -index 0 $fl author-name] >= 0}           "B: author-name field present"
ok {[lsearch -index 0 $fl date] >= 0}                  "B: date field present"
ok {[lsearch -index 0 $fl file-name] >= 0}             "B: file-name field present"

# ---- C) validation ----
ok {[catch {$t addChapter $p -display bogus}]}         "C: invalid chapter display rejected"
ok {[catch {$t addFileName $p -display weird}]}        "C: invalid file-name display rejected"
ok {[catch {$t addTitle $p -nope x}]}                  "C: unknown option rejected"

# ---- D) boolean fixed coerced ----
$t flush
set doc [$pkg tree content.xml]; set xml [$doc asXML]; $doc delete
ok {![regexp {text:fixed="[01]"} $xml]}                "D: text:fixed never 1/0"

$t flush
$pkg save [file join $out fields.odt]
$t destroy; $pkg destroy

# ---- E) round-trip ----
set p2 [odf::Package new [file join $out fields.odt]]
set t2 [odf::Text new $p2]
set fl2 [$t2 fields]
ok {[lsearch -index 0 $fl2 page-number] >= 0 && [lsearch -index 0 $fl2 page-count] >= 0} "E: page fields survive reload"
ok {[lsearch -index 0 $fl2 chapter] >= 0}              "E: chapter survives reload"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
