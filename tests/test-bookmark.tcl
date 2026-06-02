set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# ---- A) bookmarks (point + range) and reference marks ----
set p1 [$t appendHeading "Introduction" 1]
$t addBookmark $p1 ch1
$t addReferenceMark $p1 mark_intro
set p2 [$t appendParagraph "Before "]
$t addBookmarkStart $p2 range1
$t addText $p2 "highlighted"
$t addBookmarkEnd $p2 range1
ok {[lsort [$t bookmarks]] eq {ch1 range1}}            "A: point + range bookmark names"
ok {[$t referenceMarks] eq {mark_intro}}               "A: reference mark name"
# range markers are present as inline runs of the right kind
set kinds {}
foreach r [$t runs $p2] { lappend kinds [$t runKind $r] }
ok {"bookmark-start" in $kinds && "bookmark-end" in $kinds} "A: range markers are inline runs"

# ---- B) cross-references with format ----
set p3 [$t appendParagraph "See "]
$t addBookmarkRef  $p3 ch1        -format page    -text "page 1"
$t addText $p3 " or "
$t addReferenceRef $p3 mark_intro -format chapter -text "chapter"
set refs {}
foreach r [$t runs $p3] {
    set k [$t runKind $r]
    if {$k in {bookmark-ref reference-ref}} { lappend refs [list $k [$t refName $r] [$t refFormat $r] [$t runText $r]] }
}
ok {[lindex $refs 0] eq {bookmark-ref ch1 page {page 1}}}        "B: bookmark-ref name/format/text"
ok {[lindex $refs 1] eq {reference-ref mark_intro chapter chapter}} "B: reference-ref name/format/text"
# default display text = ref-name when -text omitted
set r4 [$t addBookmarkRef $p3 ch1]
ok {[$t runText $r4] eq "ch1"}                         "B: ref display defaults to name"

# ---- C) validation ----
ok {[catch {$t addBookmarkRef $p3 ch1 -format bogus}]} "C: invalid reference-format rejected"
ok {[catch {$t addBookmarkRef $p3 ch1 -nope x}]}       "C: unknown option rejected"

$t flush
$pkg save [file join $out bookmarks.odt]
$t destroy; $pkg destroy

# ---- D) round-trip ----
set p [odf::Package new [file join $out bookmarks.odt]]
set t2 [odf::Text new $p]
ok {[lsort [$t2 bookmarks]] eq {ch1 range1}}           "D: bookmarks survive reload"
ok {[$t2 referenceMarks] eq {mark_intro}}              "D: reference mark survives reload"
$t2 destroy; $p destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
