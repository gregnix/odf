set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) appendObject: generic embedding primitive ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t appendHeading "Embedded objects" 1
set mini "<?xml version=\"1.0\"?>\n<office:document-content xmlns:office=\"urn:oasis:names:tc:opendocument:xmlns:office:1.0\" office:version=\"1.3\"><office:body><office:text/></office:body></office:document-content>"
set fr [$t appendObject application/vnd.oasis.opendocument.text $mini -name Obj1 -width 10cm -height 6cm]

ok {[$fr nodeName] eq "draw:frame"}                                         "A: appendObject returns draw:frame"
set obj [lindex [$fr getElementsByTagName draw:object] 0]
ok {[$obj getAttribute xlink:href ""] eq "./Object 1"}                      "A: draw:object href -> ./Object 1"
ok {[$obj getAttribute xlink:type ""] eq "simple"}                          "A: xlink:type simple"
ok {[$obj getAttribute xlink:show ""] eq "embed"}                           "A: xlink:show embed"
ok {[$obj getAttribute xlink:actuate ""] eq "onLoad"}                       "A: xlink:actuate onLoad"
ok {[$fr getAttribute svg:width ""] eq "10cm"}                              "A: frame width"
ok {[$pkg has "Object 1/content.xml"]}                                      "A: object content part present"
set man [$pkg manifest]
ok {[dict exists $man "Object 1/"]}                                         "A: manifest has Object 1/ dir entry"
ok {[dict get $man "Object 1/"] eq "application/vnd.oasis.opendocument.text"} "A: dir entry media type (generic object)"
ok {[dict get $man "Object 1/content.xml"] eq "text/xml"}                   "A: content.xml media type text/xml"

# ---- B) appendChart: build + embed a real chart ----
set frC [$t appendChart {Q1 Q2 Q3} {Sales {10 20 15} Costs {6 9 8}} -type column -title "Quarterly" -name Chart1]
ok {[$frC nodeName] eq "draw:frame"}                                        "B: appendChart returns draw:frame"
ok {[$pkg has "Object 2/content.xml"]}                                      "B: second object auto-numbered Object 2"

set cdoc [dom parse [encoding convertfrom utf-8 [$pkg part "Object 2/content.xml"]]]
set ce [$cdoc documentElement]
set chart [lindex [$ce getElementsByTagName chart:chart] 0]
ok {[$chart getAttribute chart:class ""] eq "chart:bar"}                    "B: column maps to chart:bar"
ok {[llength [$ce getElementsByTagName chart:title]] == 1}                  "B: title present"
ok {[[lindex [$ce getElementsByTagName text:p] 0] asText] eq "Quarterly"}  "B: title text"
set axes [$ce getElementsByTagName chart:axis]
ok {[llength $axes] == 2}                                                   "B: two axes (x,y)"
set cats [lindex [$ce getElementsByTagName chart:categories] 0]
ok {[$cats getAttribute table:cell-range-address ""] eq "local-table.A2:.A4"} "B: categories range A2:A4"
set ser [$ce getElementsByTagName chart:series]
ok {[llength $ser] == 2}                                                    "B: two series"
ok {[[lindex $ser 0] getAttribute chart:values-cell-range-address ""] eq "local-table.B2:.B4"} "B: series1 values B2:B4"
ok {[[lindex $ser 0] getAttribute chart:label-cell-address ""] eq "local-table.B1"} "B: series1 label B1"
ok {[[lindex $ser 1] getAttribute chart:values-cell-range-address ""] eq "local-table.C2:.C4"} "B: series2 values C2:C4 (ColLetter)"
# local-table: 1 header row + 3 data rows; header has empty corner + 2 names
set tbl [lindex [$ce getElementsByTagName table:table] 0]
ok {[$tbl getAttribute table:name ""] eq "local-table"}                     "B: local-table name"
set rows [$tbl getElementsByTagName table:table-row]
ok {[llength $rows] == 4}                                                   "B: 4 rows (header + 3 cats)"
set hcells [[lindex $rows 0] getElementsByTagName table:table-cell]
ok {[[lindex $hcells 1] asText] eq "Sales"}                                "B: header cell = series name"
set d1 [[lindex $rows 1] getElementsByTagName table:table-cell]
ok {[[lindex $d1 0] asText] eq "Q1"}                                       "B: first data row category Q1"
ok {[[lindex $d1 1] getAttribute office:value ""] eq "10"}                 "B: first data value 10"
ok {[[lindex $d1 1] getAttribute office:value-type ""] eq "float"}         "B: value cell type float"
$cdoc delete

# ---- C) readers ----
set objs [$t objects]
ok {[llength $objs] == 2}                                                   "C: two embedded objects (text + chart)"
set chs [$t charts]
ok {[llength $chs] == 1}                                                    "C: one is a chart (by media type)"
ok {[dict get [lindex $chs 0] name] eq "Chart1"}                           "C: chart name resolved"
ok {[dict get [lindex $chs 0] href] eq "./Object 2"}                       "C: chart href resolved"

# ---- D) error cases ----
ok {[catch {$t appendChart {a b} {S {1 2 3}}}]}                            "D: series length mismatch rejected"
ok {[catch {$t appendChart {a} {S {1}} -type bogus}]}                     "D: unknown chart type rejected"
ok {[catch {$t appendChart {a} {S {1}} -bogus 1}]}                        "D: unknown opt rejected (passed through to appendObject)"
ok {[catch {$t appendObject text/xml "<x/>" -bogus 1}]}                   "D: appendObject unknown option rejected"

# ---- E) save + reload ----
$t flush
set odt [file join $out chart.odt]; $pkg save $odt
$t destroy; $pkg destroy

set pkg2 [odf::Package new $odt]
ok {[$pkg2 has "Object 2/content.xml"]}                                    "E: object part persisted"
ok {[dict exists [$pkg2 manifest] "Object 2/"]}                            "E: manifest dir entry persisted"
set t2 [odf::Text new $pkg2]
ok {[llength [$t2 charts]] == 1}                                           "E: charts reader after reload"
ok {[llength [$t2 objects]] == 2}                                          "E: objects reader after reload"
ok {![catch {dom parse [encoding convertfrom utf-8 [$pkg2 part "Object 2/content.xml"]] cc}]} "E: chart content.xml well-formed"
catch {cc delete}
$t2 destroy; $pkg2 destroy

# ---- F) chart styling: colors, stacked, legend, orientation ----
set pkgS [odf::newTextDoc]
set tS   [odf::Text new $pkgS]
$tS appendChart {Q1 Q2 Q3} {A {1 2 3} B {4 5 6}} -type column \
    -colors {#1A56DB #C5221F} -stacked 1 -legend end -title "Styled"
$tS flush
set cdoc [dom parse [encoding convertfrom utf-8 [$pkgS part "Object 1/content.xml"]]]
set ce [$cdoc documentElement]
ok {[llength [$ce getElementsByTagName office:automatic-styles]] == 1}      "F: automatic-styles present"
set chartStyles [$ce getElementsByTagName style:style]
ok {[llength $chartStyles] == 3}                                           "F: 3 chart styles (plot + 2 series)"
# plot style: stacked + vertical=false (column)
set cp [lindex [$ce getElementsByTagName style:chart-properties] 0]
ok {[$cp getAttribute chart:stacked ""] eq "true"}                         "F: chart:stacked true"
ok {[$cp getAttribute chart:vertical ""] eq "false"}                       "F: chart:vertical false (column)"
set plot [lindex [$ce getElementsByTagName chart:plot-area] 0]
ok {[$plot getAttribute chart:style-name ""] eq "chartplot"}               "F: plot-area references plot style"
# series fill colours
set gps [$ce getElementsByTagName style:graphic-properties]
ok {[llength $gps] == 2}                                                   "F: two series graphic-properties"
ok {[[lindex $gps 0] getAttribute draw:fill-color ""] eq "#1A56DB"}        "F: series 1 fill colour"
ok {[[lindex $gps 0] getAttribute draw:fill ""] eq "solid"}                "F: fill solid"
set sers [$ce getElementsByTagName chart:series]
ok {[[lindex $sers 0] getAttribute chart:style-name ""] eq "chartseries0"} "F: series references its style"
ok {[[lindex $sers 1] getAttribute chart:style-name ""] eq "chartseries1"} "F: second series style"
# legend present, positioned, and BEFORE plot-area (RNG child order)
set lg [lindex [$ce getElementsByTagName chart:legend] 0]
ok {$lg ne "" && [$lg getAttribute chart:legend-position ""] eq "end"}     "F: legend at end"
set chartKids {}
foreach c [[lindex [$ce getElementsByTagName chart:chart] 0] childNodes] { if {[$c nodeType] eq "ELEMENT_NODE"} { lappend chartKids [$c nodeName] } }
ok {[lsearch -exact $chartKids chart:legend] < [lsearch -exact $chartKids chart:plot-area]} "F: legend precedes plot-area (RNG order)"
$cdoc delete
# bar (horizontal) sets vertical=true
$tS appendChart {a b} {S {1 2}} -type bar
set cdoc [dom parse [encoding convertfrom utf-8 [$pkgS part "Object 2/content.xml"]]]
ok {[[lindex [[$cdoc documentElement] getElementsByTagName style:chart-properties] 0] getAttribute chart:vertical ""] eq "true"} "F: bar -> chart:vertical true"
$cdoc delete
ok {[catch {$tS appendChart {a} {S {1}} -legend sideways}]}                "F: unknown legend position rejected"
$tS destroy; $pkgS destroy

# ---- G) chart 0.4: new types, axis options, gridlines ----
# New chart types -- each must map to a known chart:class and survive serialization.
foreach {type cls} {area chart:area ring chart:ring scatter chart:scatter radar chart:radar bubble chart:bubble} {
    set pkgG [odf::newTextDoc]; set tG [odf::Text new $pkgG]
    $tG appendChart {a b c} [list S [list 1 2 3]] -type $type
    set cdoc [dom parse [encoding convertfrom utf-8 [$pkgG part "Object 1/content.xml"]]]
    set chartEl [lindex [[$cdoc documentElement] getElementsByTagName chart:chart] 0]
    ok {[$chartEl getAttribute chart:class ""] eq $cls}                "G: chart type '$type' -> $cls"
    $cdoc delete; $tG destroy; $pkgG destroy
}
# Unknown type still rejected
ok {[catch {[odf::Text new [odf::newTextDoc]] appendChart {a} {S {1}} -type lollipop}]} \
                                                                       "G: unknown type 'lollipop' rejected"

# Y-axis options: -ymin, -ymax, -ylog, -ytick-major
set pkgG [odf::newTextDoc]; set tG [odf::Text new $pkgG]
$tG appendChart {a b c d} {S {10 50 200 1000}} -type line \
    -ymin 0 -ymax 1000 -ylog 1 -ytick-major 100
set cdoc [dom parse [encoding convertfrom utf-8 [$pkgG part "Object 1/content.xml"]]]
set props [lindex [[$cdoc documentElement] getElementsByTagName style:chart-properties] end]
ok {[$props getAttribute chart:minimum ""] eq "0"}                    "G: chart:minimum on axis style"
ok {[$props getAttribute chart:maximum ""] eq "1000"}                 "G: chart:maximum on axis style"
ok {[$props getAttribute chart:logarithmic ""] eq "true"}             "G: chart:logarithmic"
ok {[$props getAttribute chart:interval-major ""] eq "100"}           "G: chart:interval-major"
$cdoc delete; $tG destroy; $pkgG destroy

# Gridlines: chart:grid as child of chart:axis with class major|minor
set pkgG [odf::newTextDoc]; set tG [odf::Text new $pkgG]
$tG appendChart {a b c} {S {1 2 3}} -type line -ygrid both -xgrid major
set cdoc [dom parse [encoding convertfrom utf-8 [$pkgG part "Object 1/content.xml"]]]
set axes [[$cdoc documentElement] getElementsByTagName chart:axis]
set gridsByAxis {x {} y {}}
foreach ax $axes {
    set dim [$ax getAttribute chart:dimension ""]
    foreach g [$ax getElementsByTagName chart:grid] {
        dict lappend gridsByAxis $dim [$g getAttribute chart:class ""]
    }
}
ok {[lsort [dict get $gridsByAxis x]] eq {major}}                     "G: x-axis grid major only"
ok {[lsort [dict get $gridsByAxis y]] eq {major minor}}               "G: y-axis grid both (major + minor)"
$cdoc delete; $tG destroy; $pkgG destroy

# Bad -ygrid value should error with a helpful message
set err ""
catch {[odf::Text new [odf::newTextDoc]] appendChart {a} {S {1}} -ygrid sideways} err
ok {[string match {*-ygrid must be none|major|minor|both*} $err]}     "G: -ygrid rejects bad value"

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
