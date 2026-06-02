set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# ---- A) database-display: the column-value merge field ----
set p [$t appendParagraph "Dear "]
set d [$t addDatabaseDisplay $p -source Addresses -table Sheet1 -column FirstName \
           -type table -style Stylish -text "Jane"]
ok {[$d nodeName] eq "text:database-display"}             "A: element is database-display"
ok {[$d getAttribute text:table-name]  eq "Sheet1"}       "A: table-name set"
ok {[$d getAttribute text:column-name] eq "FirstName"}    "A: column-name set"
ok {[$d getAttribute text:database-name] eq "Addresses"}  "A: source -> database-name"
ok {[$d getAttribute text:table-type]  eq "table"}        "A: table-type set"
ok {[$d getAttribute style:data-style-name] eq "Stylish"} "A: data-style-name set"
ok {[$d asText] eq "Jane"}                                "A: cached display text"

# source is optional per schema (registered name may be omitted)
set d2 [$t addDatabaseDisplay $p -table Sheet1 -column LastName]
ok {[$d2 getAttribute text:database-name ""] eq ""}       "A: source optional -> no database-name attr"
ok {[$d2 getAttribute text:column-name] eq "LastName"}    "A: second display column"

# ---- B) next / row-select / row-number ----
set n [$t addDatabaseNext $p -source Addresses -table Sheet1 -condition "1=1"]
ok {[$n nodeName] eq "text:database-next"}                "B: database-next element"
ok {[$n getAttribute text:condition] eq "1=1"}            "B: next condition"
set rs [$t addDatabaseRowSelect $p -table Sheet1 -row 3 -condition "x>0"]
ok {[$rs nodeName] eq "text:database-row-select"}         "B: row-select element"
ok {[$rs getAttribute text:row-number] eq "3"}            "B: row-select row-number"
ok {[$rs getAttribute text:condition] eq "x>0"}           "B: row-select condition"
set rn [$t addDatabaseRowNumber $p -table Sheet1 -numformat 1 -value 5 -text "5"]
ok {[$rn nodeName] eq "text:database-row-number"}         "B: row-number element"
ok {[$rn getAttribute style:num-format] eq "1"}           "B: row-number num-format"
ok {[$rn getAttribute text:value] eq "5"}                 "B: row-number cached value"

# ---- C) validation (no magic: required args + strict options) ----
ok {[catch {$t addDatabaseDisplay $p -table Sheet1}]}              "C: -column required"
ok {[catch {$t addDatabaseDisplay $p -column C}]}                  "C: -table required"
ok {[catch {$t addDatabaseDisplay $p -table T -column C -type bogus}]} "C: bad table-type rejected"
ok {[catch {$t addDatabaseNext $p -table T -nope x}]}              "C: unknown option rejected"

# ---- D) reader ----
set df [$t databaseFields]
ok {[llength $df] == 2}                                    "D: two display fields"
ok {[lindex $df 0] eq {Addresses Sheet1 FirstName}}        "D: first {source table column}"
ok {[lindex $df 1] eq {{} Sheet1 LastName}}                "D: second has empty source"

# ---- E) well-formed + round-trip ----
$t flush
set doc [$pkg tree content.xml]; set xml [$doc asXML]; $doc delete
ok {[regexp {text:database-display} $xml]}                 "E: display serialized"
set wf 1
if {[catch {set dd [dom parse $xml]}]} { set wf 0 } else { $dd delete }
ok {$wf}                                                   "E: content.xml well-formed"

$pkg save [file join $out dbfields.odt]
$t destroy; $pkg destroy

set p2 [odf::Package new [file join $out dbfields.odt]]
set t2 [odf::Text new $p2]
set df2 [$t2 databaseFields]
ok {[llength $df2] == 2}                                   "E: fields survive reload"
ok {[lindex $df2 0] eq {Addresses Sheet1 FirstName}}       "E: first field intact after reload"
$t2 destroy; $p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
