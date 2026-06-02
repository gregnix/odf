set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) first page different + mirrored book layout ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
set s   [odf::Styles new $pkg]
$s definePageFormat PMfirst A4 -margins {6cm 2cm 2cm 2.5cm}
$s definePageFormat PMrest  A4 -margins {2.5cm 2cm 2cm 2.5cm}
$s defineMasterPage First -pagelayout PMfirst
$s defineMasterPage Rest  -pagelayout PMrest
$s setNextPage First Rest
$s defineMasterPageStyle FirstStart First
$s definePageFormat PMbook A4 -margins {2cm 1.5cm 2cm 3cm}
$s setPageUsage PMbook mirrored
$s defineParagraph Body -text {fo:font-size 11pt}
ok {[$s nextPage First] eq "Rest"}                      "A: First chains to Rest"
ok {[$s masterPageOfStyle FirstStart] eq "First"}       "A: style starts on First master"
ok {[$s pageUsage PMbook] eq "mirrored"}                "A: PMbook mirrored"
ok {[$s pageUsage PMrest] eq "all"}                     "A: PMrest default all"
$s flush; $s destroy
$t appendParagraph "First page heading on its own master" FirstStart
$t appendParagraph "Body text continues here." Body
$t flush; $t destroy
$pkg save [file join $out multipage.odt]; $pkg destroy

# ---- B) reload: chaining, usage and master-page-name persist ----
set pkg2 [odf::Package new [file join $out multipage.odt]]
set s2   [odf::Styles new $pkg2]
ok {[$s2 nextPage First] eq "Rest"}                     "B: next-style-name persisted"
ok {[$s2 pageUsage PMbook] eq "mirrored"}               "B: page-usage persisted"
ok {[$s2 masterPageOfStyle FirstStart] eq "First"}      "B: master-page-name persisted"
ok {"First" in [$s2 masterPages] && "Rest" in [$s2 masterPages]} "B: both masters present"
ok {[$s2 has FirstStart]}                               "B: paragraph style present"
$s2 destroy; $pkg2 destroy

# ---- C) reads on absent things ----
set pkg3 [odf::newTextDoc]; set s3 [odf::Styles new $pkg3]
$s3 defineStandardFormat A4
ok {[$s3 pageUsage PMstandard] eq "all"}                "C: unset usage reads as all"
ok {[$s3 nextPage Standard] eq ""}                      "C: no next-style -> empty"
ok {[$s3 masterPageOfStyle Nope] eq ""}                 "C: unknown style -> empty"
$s3 destroy; $pkg3 destroy

# ---- D) error cases ----
set pkg4 [odf::newTextDoc]; set s4 [odf::Styles new $pkg4]
$s4 defineStandardFormat A4
ok {[catch {$s4 setPageUsage PMstandard slanted}]}      "D: bad usage -> error"
ok {[catch {$s4 setPageUsage Nope mirrored}]}           "D: missing layout -> error"
ok {[catch {$s4 setNextPage Nope Standard}]}            "D: missing master -> error"
ok {[catch {$s4 defineMasterPageStyle X First -bogus 1}]} "D: unknown option -> error"
$s4 destroy; $pkg4 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
