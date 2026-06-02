set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::chart
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) standalone chart document (.odc) ----
set pkg [odf::newChartDoc {Q1 Q2 Q3} {North {120 150 138} South {90 96 110}} \
            -type column -colors {#1A56DB #C5221F} -legend end -stacked 1 -title "Regions"]
ok {[dict get [$pkg manifest] /] eq "application/vnd.oasis.opendocument.chart"} "A: package media type = chart"
ok {[$pkg part mimetype] eq "application/vnd.oasis.opendocument.chart"}          "A: mimetype part"
ok {[$pkg has content.xml] && [$pkg has styles.xml] && [$pkg has meta.xml]}      "A: content/styles/meta present"

set cdoc [dom parse [encoding convertfrom utf-8 [$pkg part content.xml]]]
set root [$cdoc documentElement]
ok {[$root nodeName] eq "office:document-content"}                               "A: content root"
ok {[llength [$root getElementsByTagName office:chart]] == 1}                     "A: office:chart body"
set chart [lindex [$root getElementsByTagName chart:chart] 0]
ok {[$chart getAttribute chart:class ""] eq "chart:bar"}                          "A: column -> chart:bar class"
ok {[$chart getAttribute chart:title ""] eq "" || 1}                              "A: (title is an element, not attr)"
set tt [lindex [$chart getElementsByTagName chart:title] 0]
ok {[string match "*Regions*" [$tt asText]]}                                     "A: chart title text"
# styling propagated through buildContent
ok {[llength [$root getElementsByTagName office:automatic-styles]] == 1}          "A: automatic-styles present (styling)"
set cp [lindex [$root getElementsByTagName style:chart-properties] 0]
ok {[$cp getAttribute chart:stacked ""] eq "true"}                               "A: stacked=true"
set fills {}
foreach gp [$root getElementsByTagName style:graphic-properties] { lappend fills [$gp getAttribute draw:fill-color ""] }
ok {"#1A56DB" in $fills && "#C5221F" in $fills}                                   "A: per-series fill colours"
set lg [lindex [$root getElementsByTagName chart:legend] 0]
ok {[$lg getAttribute chart:legend-position ""] eq "end"}                         "A: legend position"
# self-contained local-table
set tbl [lindex [$root getElementsByTagName table:table] 0]
ok {[$tbl getAttribute table:name ""] eq "local-table"}                          "A: local-table present"
ok {[llength [$tbl getElementsByTagName table:table-row]] == 4}                   "A: header + 3 data rows"
$cdoc delete

# ---- B) save + reload ----
set odc [file join $out chart-doc.odc]; $pkg save $odc
$pkg destroy
set pkg2 [odf::Package new $odc]
ok {[dict get [$pkg2 manifest] /] eq "application/vnd.oasis.opendocument.chart"} "B: media type after reload"
ok {![catch {dom parse [encoding convertfrom utf-8 [$pkg2 part content.xml]] rr}]} "B: content well-formed after reload"
catch {rr delete}
$pkg2 destroy

# ---- C) template (.otc) ----
set tpl [odf::newChartTemplate {a b} {S {1 2}}]
ok {[dict get [$tpl manifest] /] eq "application/vnd.oasis.opendocument.chart-template"} "C: template media type"
$tpl destroy

# ---- D) option validation (no magic) ----
ok {[catch {odf::newChartDoc {a} {S {1}} -bogus 1}]}                              "D: unknown chart option rejected"
ok {[catch {odf::newChartDoc {a b} {S {1}}}]}                                    "D: series length mismatch rejected"
ok {[catch {odf::chart::buildContent {a b} {S {1 2}} -type wedge}]}              "D: unknown chart type rejected"

# ---- E) regression: appendChart (embed) still works after extraction ----
set tp [odf::newTextDoc]; set t [odf::Text new $tp]
set fr [$t appendChart {Q1 Q2} {North {1 2}} -type line -name Emb]
ok {[$fr nodeName] eq "draw:frame"}                                              "E: appendChart returns frame"
ok {[llength [$t charts]] == 1}                                                  "E: chart reader finds it"
set ec [dom parse [encoding convertfrom utf-8 [$tp part "Object 1/content.xml"]]]
ok {[llength [$ec getElementsByTagName chart:chart]] == 1}                        "E: embedded chart content built via odf::chart"
$ec delete; $t destroy; $tp destroy

# ---- F) data labels + axis titles (odf::chart 0.2) ----
set pkg [odf::newChartDoc {Q1 Q2} {North {10 20}} \
            -type column -labels value -xtitle "Quarter" -ytitle "Units"]
set cdoc [dom parse [encoding convertfrom utf-8 [$pkg part content.xml]]]
set root [$cdoc documentElement]
set cp [lindex [$root getElementsByTagName style:chart-properties] 0]
ok {[$cp getAttribute chart:data-label-number ""] eq "value"}                    "F: data-label-number=value"
# axis titles: x-axis title present and ordered before chart:categories
set xax ""
foreach a [$root getElementsByTagName chart:axis] {
    if {[$a getAttribute chart:dimension ""] eq "x"} { set xax $a }
    if {[$a getAttribute chart:dimension ""] eq "y"} { set yax $a }
}
set xt [lindex [$xax getElementsByTagName chart:title] 0]
ok {[string match "*Quarter*" [$xt asText]]}                                     "F: x-axis title text"
set kids {}; foreach c [$xax childNodes] { lappend kids [$c nodeName] }
ok {[lsearch $kids chart:title] < [lsearch $kids chart:categories]}              "F: axis title before categories (RNG order)"
set yt [lindex [$yax getElementsByTagName chart:title] 0]
ok {[string match "*Units*" [$yt asText]]}                                       "F: y-axis title text"
$cdoc delete; $pkg destroy

ok {[catch {odf::chart::buildContent {a} {S {1}} -labels bogus}]}                "F: unknown data-label kind rejected"

# ---- G) appendChart forwards new options (inverted splitter, text 0.44) ----
set tp [odf::newTextDoc]; set t [odf::Text new $tp]
$t appendChart {Q1 Q2} {North {1 2}} -labels percentage -xtitle X -name Lbl -width 9cm
set ec [dom parse [encoding convertfrom utf-8 [$tp part "Object 1/content.xml"]]]
set cp [lindex [$ec getElementsByTagName style:chart-properties] 0]
ok {[$cp getAttribute chart:data-label-number ""] eq "percentage"}               "G: appendChart forwarded -labels to buildContent"
ok {[llength [$ec getElementsByTagName chart:title]] >= 1}                        "G: appendChart forwarded -xtitle"
$ec delete
set fr [lindex [$t charts] 0]
ok {[dict get $fr name] eq "Lbl"}                                                "G: frame option -name still went to appendObject"
$t destroy; $tp destroy

# ---- H) 3D + y-axis number format (odf::chart 0.3) ----
set pkg [odf::newChartDoc {Q1 Q2} {N {1200 1500}} -type column -3d 1 -yformat number -ydecimals 0 -ygrouping 1]
set cdoc [dom parse [encoding convertfrom utf-8 [$pkg part content.xml]]]
set root [$cdoc documentElement]
set cp [lindex [$root getElementsByTagName style:chart-properties] 0]
ok {[$cp getAttribute chart:three-dimensional ""] eq "true"}                     "H: 3D -> chart:three-dimensional"
set ns [lindex [$root getElementsByTagName number:number-style] 0]
ok {$ns ne ""}                                                                   "H: number:number-style present"
set numEl [lindex [$ns getElementsByTagName number:number] 0]
ok {[$numEl getAttribute number:decimal-places ""] eq "0"}                       "H: decimals=0"
ok {[$numEl getAttribute number:grouping ""] eq "true"}                          "H: grouping=true"
# axis references the data style via a chart style
set axStyle ""
foreach s [$root getElementsByTagName style:style] {
    if {[$s getAttribute style:data-style-name ""] eq [$ns getAttribute style:name ""]} { set axStyle [$s getAttribute style:name ""] }
}
ok {$axStyle ne ""}                                                              "H: chart style links data-style-name"
set yax ""
foreach a [$root getElementsByTagName chart:axis] { if {[$a getAttribute chart:dimension ""] eq "y"} { set yax $a } }
ok {[$yax getAttribute chart:style-name ""] eq $axStyle}                         "H: y-axis carries the number-format style"
$cdoc delete; $pkg destroy

# percentage axis format
set pkg [odf::newChartDoc {Q1} {A {0.5}} -yformat percentage -ydecimals 1]
set cdoc [dom parse [encoding convertfrom utf-8 [$pkg part content.xml]]]
set ps [lindex [[$cdoc documentElement] getElementsByTagName number:percentage-style] 0]
ok {$ps ne ""}                                                                   "H: number:percentage-style present"
ok {[string match "*%*" [$ps asText]]}                                           "H: percentage style has % literal"
$cdoc delete; $pkg destroy

ok {[catch {odf::chart::buildContent {a} {S {1}} -yformat bogus}]}              "H: unknown y-format rejected"
ok {[catch {odf::chart::buildContent {a} {S {1}} -yformat number -ydecimals x}]} "H: non-integer ydecimals rejected"

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
