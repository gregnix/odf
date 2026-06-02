set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

$t appendParagraph "Body."
set tip [$t appendAdmonition tip "Layout matters." "Second paragraph."]
$t appendAdmonition note -title "Achtung" "Ein Hinweis."
$t appendAdmonition caution "Vorsicht."
$t appendAdmonition warning "Gefahr."
$t appendAdmonition Tip "Case-insensitive kind."   ;# second tip -> styles must not duplicate

ok {[$tip nodeName] eq "table:table"}                  "A: returns a 1x1 table"
set cell [lindex [$tip getElementsByTagName table:table-cell] 0]
ok {[$cell getAttribute table:style-name ""] eq "Admon_Tip_Cell"} "A: per-kind cell style"
set ps [$cell getElementsByTagName text:p]
ok {[llength $ps] == 3}                                 "A: label paragraph + 2 body paragraphs"
ok {[llength [$cell getElementsByTagName text:span]] == 1} "A: bold label is a span"

# kinds + count via reader
set kinds [lmap a [$t admonitions] {lindex $a 1}]
ok {[llength $kinds] == 5}                              "B: five admonitions"
ok {$kinds eq {tip note caution warning tip}}          "B: kinds in document order"

# style dedup: two tips share one style definition
$t flush
set doc [$pkg tree content.xml]; set xml [$doc asXML]; $doc delete
ok {[regexp -all {style:name="Admon_Tip_Cell"} $xml] == 1}  "C: cell style defined once despite two tips"
ok {[regexp -all {style:name="Admon_Tip_Label"} $xml] == 1} "C: label style defined once"
ok {[regexp {fo:background-color="#FCE8E6"} $xml]}      "C: warning background tint present"
ok {[regexp {fo:font-weight="bold"} $xml]}             "C: bold label"

# default title = capitalized kind; explicit -title respected
ok {[string match {*>Caution<*} $xml] || [regexp {Caution} $xml]} "C: default label from kind"
ok {[regexp {Achtung} $xml]}                           "C: explicit -title used"

# validation
ok {[catch {$t appendAdmonition bogus "x"}]}           "D: unknown kind rejected"

# round-trip
$pkg save [file join $out admonition-block.odt]
$t destroy; $pkg destroy
set p [odf::Package new [file join $out admonition-block.odt]]
set t2 [odf::Text new $p]
ok {[llength [$t2 admonitions]] == 5}                   "E: admonitions survive reload"
$t2 destroy; $p destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
