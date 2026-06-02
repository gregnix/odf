set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) set + read metadata ----
set pkg [odf::newTextDoc]
ok {[dict get [$pkg meta] generator] eq "odf-tcl"}   "A: generator skeleton present"
$pkg setMeta -title "My Document" -subject "Testing" -description "A demo" \
    -creator "Max Mustermann" -initial-creator "Max Mustermann" -language "de-DE" \
    -creation-date "2026-05-26T00:00:00" -editing-cycles "3" \
    -keywords {tcl odf metadata} \
    -user-defined {{Project odf} {Reviewed true boolean} {Pages 12 float}}
set m [$pkg meta]
ok {[dict get $m title] eq "My Document"}             "A: title set"
ok {[dict get $m subject] eq "Testing"}               "A: subject set"
ok {[dict get $m creator] eq "Max Mustermann"}                "A: creator set"
ok {[dict get $m initial-creator] eq "Max Mustermann"}        "A: initial-creator set"
ok {[dict get $m language] eq "de-DE"}                "A: language set"
ok {[dict get $m editing-cycles] eq "3"}              "A: editing-cycles set"
ok {[dict get $m keywords] eq {tcl odf metadata}}     "A: keywords as list"
ok {[llength [dict get $m user-defined]] == 3}        "A: three user-defined fields"
ok {[lindex [dict get $m user-defined] 1] eq {Reviewed true boolean}} "A: typed user-defined field"

# ---- B) partial update: setting one field leaves the rest intact ----
$pkg setMeta -title "My Document v2"
set m2 [$pkg meta]
ok {[dict get $m2 title] eq "My Document v2"}         "B: title replaced"
ok {[dict get $m2 subject] eq "Testing"}              "B: subject untouched"
ok {[dict get $m2 keywords] eq {tcl odf metadata}}    "B: keywords untouched"
# replacing keywords replaces the whole set
$pkg setMeta -keywords {alpha}
ok {[dict get [$pkg meta] keywords] eq {alpha}}       "B: keywords fully replaced"
# user-defined replace-by-name
$pkg setMeta -user-defined {{Project odf-lib}}
set ud [dict get [$pkg meta] user-defined]
ok {[lsearch -index 0 $ud Project] >= 0 && [lindex [lindex $ud [lsearch -index 0 $ud Project]] 1] eq "odf-lib"} "B: user-defined replaced by name"
ok {[llength $ud] == 3}                               "B: other user-defined fields kept"

# ---- C) validation ----
ok {[catch {$pkg setMeta -nope x}]}                   "C: unknown option rejected"
ok {[catch {$pkg setMeta -user-defined {{X y bogus}}}]} "C: invalid value-type rejected"

# ---- D) round-trip ----
$pkg save [file join $out meta.odt]
$pkg destroy
set p2 [odf::Package new [file join $out meta.odt]]
set mr [$p2 meta]
ok {[dict get $mr title] eq "My Document v2"}         "D: title survives reload"
ok {[dict get $mr language] eq "de-DE"}               "D: language survives reload"
ok {[dict get $mr keywords] eq {alpha}}               "D: keywords survive reload"
ok {[llength [dict get $mr user-defined]] == 3}       "D: user-defined survive reload"
$p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
