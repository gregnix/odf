set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) embed a spreadsheet object ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t appendHeading "Embedded spreadsheet" 1
set fr [$t appendSpreadsheet {
    {{string Region} {string Q1} {string Q2}}
    {{string North}  {float 100}  {float 120}}
    {{string South}  {float 90}   {float 110}}
    {{string Total}  {formula "of:=SUM([.B2:.B3])" float 190} {formula "of:=SUM([.C2:.C3])" float 230}}
} -sheet Sales -name SalesObj -width 12cm -height 5cm]

ok {[$fr nodeName] eq "draw:frame"}                                         "A: appendSpreadsheet returns draw:frame"
ok {[$fr getAttribute draw:name ""] eq "SalesObj"}                          "A: frame name (appendObject pass-through)"
ok {[$fr getAttribute svg:width ""] eq "12cm"}                              "A: frame width pass-through"
set obj [lindex [$fr getElementsByTagName draw:object] 0]
ok {[$obj getAttribute xlink:href ""] eq "./Object 1"}                      "A: draw:object href"
ok {[$pkg has "Object 1/content.xml"]}                                      "A: object content present"
set man [$pkg manifest]
ok {[dict get $man "Object 1/"] eq "application/vnd.oasis.opendocument.spreadsheet"} "A: dir entry = spreadsheet media type"

# ---- B) the embedded content is a real spreadsheet ----
set sdoc [dom parse [encoding convertfrom utf-8 [$pkg part "Object 1/content.xml"]]]
set se [$sdoc documentElement]
ok {[llength [$se getElementsByTagName office:spreadsheet]] == 1}           "B: office:spreadsheet body"
set tbl [lindex [$se getElementsByTagName table:table] 0]
ok {[$tbl getAttribute table:name ""] eq "Sales"}                          "B: table name = -sheet"
ok {[llength [$tbl getElementsByTagName table:table-column]] >= 1}          "B: has table-column (odf::sheet EnsureColumns)"
set rows [$tbl getElementsByTagName table:table-row]
ok {[llength $rows] == 4}                                                   "B: four rows"
set cellsR2 [[lindex $rows 1] getElementsByTagName table:table-cell]
ok {[[lindex $cellsR2 1] getAttribute office:value ""] eq "100"}           "B: North/Q1 value 100"
ok {[[lindex $cellsR2 1] getAttribute office:value-type ""] eq "float"}    "B: value cell type float"
set totalCells [[lindex $rows 3] getElementsByTagName table:table-cell]
ok {[[lindex $totalCells 1] getAttribute table:formula ""] eq {of:=SUM([.B2:.B3])}} "B: formula cell carries table:formula"
ok {[[lindex $totalCells 1] getAttribute office:value ""] eq "190"}        "B: formula cached result"
$sdoc delete

# ---- C) readers ----
ok {[llength [$t objects]] == 1}                                           "C: one embedded object"
ok {[llength [$t spreadsheets]] == 1}                                      "C: one embedded spreadsheet"
ok {[llength [$t charts]] == 0}                                            "C: no charts"
ok {[dict get [lindex [$t spreadsheets] 0] name] eq "SalesObj"}            "C: spreadsheet name resolved"

# a chart alongside: spreadsheets and charts stay distinct
$t appendChart {a b} {S {1 2}} -name Chartlet
ok {[llength [$t objects]] == 2}                                           "C: two objects (sheet + chart)"
ok {[llength [$t spreadsheets]] == 1}                                      "C: still one spreadsheet"
ok {[llength [$t charts]] == 1}                                            "C: one chart"

# ---- D) error: bad cell spec propagates from odf::sheet ----
ok {[catch {$t appendSpreadsheet {{{float notanumber}}}}]}                 "D: non-numeric float cell rejected"

# ---- E) save + reload ----
$t flush
set odt [file join $out embed-sheet.odt]; $pkg save $odt
$t destroy; $pkg destroy
set pkg2 [odf::Package new $odt]
ok {[dict get [$pkg2 manifest] "Object 1/"] eq "application/vnd.oasis.opendocument.spreadsheet"} "E: media type persisted"
set t2 [odf::Text new $pkg2]
ok {[llength [$t2 spreadsheets]] == 1}                                     "E: spreadsheets reader after reload"
ok {![catch {dom parse [encoding convertfrom utf-8 [$pkg2 part "Object 1/content.xml"]] cc}]} "E: spreadsheet content.xml well-formed"
catch {cc delete}
$t2 destroy; $pkg2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
