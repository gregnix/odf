set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) wrap existing blocks into a 2-column, protected section ----
set pkg [odf::newTextDoc]; set t [odf::Text new $pkg]
$t appendHeading "Document" 1
set p1 [$t appendParagraph "First paragraph of the section."]
set p2 [$t appendParagraph "Second paragraph of the section."]
$t appendParagraph "Outside the section."
$t defineSectionStyle TwoCol -columns 2 -column-gap 0.5cm
set sec [$t appendSection Intro -style TwoCol -protected 1 -blocks [list $p1 $p2]]
ok {[$sec nodeName] eq "text:section"}                 "A: returns text:section"
ok {[$t sectionName $sec] eq "Intro"}                  "A: section name"
ok {[$t sectionStyleName $sec] eq "TwoCol"}            "A: section style"
ok {[$t sectionProtected $sec]}                        "A: protected"
ok {[llength [$t sectionBlocks $sec]] == 2}            "A: 2 blocks moved in"
# body now: heading, section, outside-paragraph
set bk [$t blocks]
ok {[$t kind [lindex $bk 1]] eq "section"}             "A: section is a block (kind)"
ok {[$t kind [lindex $bk 2]] eq "paragraph"}           "A: outside paragraph still in body"
ok {[catch {$t appendSection X -bogus 1}]}             "A: unknown option rejected"

# empty section form
set sec2 [$t appendSection Empty]
ok {[$t sectionName $sec2] eq "Empty"}                 "A: empty section appended"
ok {[llength [$t sectionBlocks $sec2]] == 0}           "A: empty section has no blocks"

$t flush
set odt [file join $out sections.odt]; $pkg save $odt
$t destroy; $pkg destroy

# ---- B) reload ----
set pkg2 [odf::Package new $odt]; set t2 [odf::Text new $pkg2]
ok {[lsort [$t2 sections]] eq {Empty Intro}}           "B: sections listed"
set sx ""
foreach s [$t2 blocks] { if {[$t2 kind $s] eq "section" && [$t2 sectionName $s] eq "Intro"} { set sx $s } }
ok {$sx ne ""}                                         "B: Intro section found"
ok {[$t2 sectionProtected $sx]}                        "B: protected persisted"
ok {[llength [$t2 sectionBlocks $sx]] == 2}            "B: 2 blocks persisted"
ok {[[lindex [$t2 sectionBlocks $sx] 0] asText] eq "First paragraph of the section."} "B: inner text persisted"
# the 2-column style exists in automatic-styles
set root [[$pkg2 tree content.xml] documentElement]
set found 0
foreach st [$root getElementsByTagName style:style] {
    if {[$st getAttribute style:name ""] eq "TwoCol" && [$st getAttribute style:family ""] eq "section"} {
        foreach co [$st getElementsByTagName style:columns] {
            if {[$co getAttribute fo:column-count ""] eq "2"} { set found 1 }
        }
    }
}
ok {$found}                                            "B: section style has fo:column-count=2"
ok {![catch {dom parse [encoding convertfrom utf-8 [$pkg2 part content.xml]] dd}]} "B: content.xml well-formed"
catch {dd delete}
$t2 destroy; $pkg2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
