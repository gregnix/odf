set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) default page + header/footer ----
set pkg [odf::newTextDoc]
set s   [odf::Styles new $pkg]
$s defineStandardPage {fo:page-width 21cm fo:page-height 29.7cm fo:margin-left 2cm fo:margin-right 2cm fo:margin-top 2cm fo:margin-bottom 2cm}
$s defineParagraph Centered -paragraph {fo:text-align center}
$s setHeader Standard {{"Mustermann GmbH \u2013 Vertraulich" Centered}}
$s setFooter Standard {{"Seite %page% von %pages%" Centered}}
$s flush
$s destroy
$pkg save [file join $out hf.odt]
$pkg destroy

# ---- B) reload: content + fields + page-layout entries ----
set pkg2 [odf::Package new [file join $out hf.odt]]
set s2   [odf::Styles new $pkg2]
ok {[string match "*Mustermann GmbH*" [lindex [$s2 headerLines Standard] 0]]}  "B: header text"
set fl [lindex [$s2 footerLines Standard] 0]
ok {[string match "Seite * von *" $fl]}                       "B: footer text (fields empty in asText)"
$s2 destroy
# check fields + header-style/footer-style directly in styles.xml
set sd [$pkg2 tree styles.xml]
set root [$sd documentElement]
ok {[llength [$root getElementsByTagName text:page-number]] == 1}  "B: page-number field present"
ok {[llength [$root getElementsByTagName text:page-count]] == 1}   "B: page-count field present"
ok {[llength [$root getElementsByTagName style:header-style]] == 1} "B: header-style in page-layout"
ok {[llength [$root getElementsByTagName style:footer-style]] == 1} "B: footer-style in page-layout"
# order in page-layout: properties, header-style, footer-style
set pl [lindex [$root getElementsByTagName style:page-layout] 0]
set childElems {}; foreach c [$pl childNodes] { if {[$c nodeType] eq "ELEMENT_NODE"} { lappend childElems [$c nodeName] } }
ok {$childElems eq {style:page-layout-properties style:header-style style:footer-style}} "B: correct child order"
$sd delete; $pkg2 destroy

# ---- C) idempotent + error case ----
set pkg3 [odf::Package new [file join $out hf.odt]]
set s3   [odf::Styles new $pkg3]
$s3 setHeader Standard {{"Neuer Kopf" Centered}}
ok {[llength [$s3 headerLines Standard]] == 1}                 "C: no duplicate header"
ok {[lindex [$s3 headerLines Standard] 0] eq "Neuer Kopf"}     "C: header replaced"
ok {[catch {$s3 setFooter DoesNotExist {{"x"}}}]}              "C: missing master-page -> error"
$s3 destroy; $pkg3 destroy

# ---- D) three-part header (tab stops) + extended fields ----
set pkg4 [odf::newTextDoc]
set s4   [odf::Styles new $pkg4]
$s4 defineStandardPage {fo:page-width 21cm fo:page-height 29.7cm fo:margin-left 2cm fo:margin-right 2cm fo:margin-top 2cm fo:margin-bottom 2cm}
$s4 setHeaderParts Standard -left "%title%" -center "%date%" -right "Page %page%"
$s4 setFooterParts Standard -left "100%% done" -right "%author%"
$s4 flush
set sd4 [$pkg4 tree styles.xml]; set root4 [$sd4 documentElement]
set hdr4 [lindex [$root4 getElementsByTagName style:header] 0]
set hp4  [lindex [$hdr4 getElementsByTagName text:p] 0]
ok {[llength [$hp4 getElementsByTagName text:tab]] == 2}             "D: header has 2 tab stops (3 parts)"
ok {[$hp4 getAttribute text:style-name ""] ne ""}                    "D: header paragraph references a style"
ok {[llength [$root4 getElementsByTagName style:tab-stops]] >= 1}    "D: tab-stops style present"
ok {[llength [$root4 getElementsByTagName text:date]] == 1}          "D: %date% field"
ok {[llength [$root4 getElementsByTagName text:title]] == 1}         "D: %title% field"
ok {[llength [$root4 getElementsByTagName text:author-name]] == 1}   "D: %author% field"
ok {[llength [$root4 getElementsByTagName text:page-number]] == 1}   "D: %page% field"
ok {[string match "*100% done*" [dict get [$s4 footerParts Standard] left]]} "D: %% -> literal percent"
# center tab at half the 17cm text width
set tabpos {}; foreach ts [$root4 getElementsByTagName style:tab-stop] { lappend tabpos [$ts getAttribute style:position ""] }
ok {"8.5cm" in $tabpos && "17cm" in $tabpos}                         "D: center+right tab positions"
$sd4 delete; $s4 destroy
$pkg4 save [file join $out hf-regions.odt]; $pkg4 destroy

# ---- E) reload three-part header ----
set pkg5 [odf::Package new [file join $out hf-regions.odt]]
set s5   [odf::Styles new $pkg5]
set hp [$s5 headerParts Standard]
ok {[dict exists $hp left] && [dict exists $hp center] && [dict exists $hp right]} "E: header parts persisted"
ok {[string match "Page*" [dict get $hp right]]}              "E: right part text persisted"
ok {[dict get [$s5 footerParts Standard] right] eq ""}        "E: footer author field empty in asText"
$s5 destroy; $pkg5 destroy

# ---- F) different left/right page headers ----
set pkg6 [odf::newTextDoc]
set s6   [odf::Styles new $pkg6]
$s6 defineStandardPage {fo:page-width 21cm fo:page-height 29.7cm fo:margin-left 2cm fo:margin-right 2cm fo:margin-top 2cm fo:margin-bottom 2cm}
$s6 setPageUsage PMstandard mirrored
$s6 setHeaderParts Standard -right "Page %page%"             ;# default / right pages
$s6 setHeaderParts Standard -side left -left "Page %page%"   ;# left / even pages
$s6 flush
set sd6 [$pkg6 tree styles.xml]; set root6 [$sd6 documentElement]
set mp6 [lindex [$root6 getElementsByTagName style:master-page] 0]
set kids6 {}; foreach c [$mp6 childNodes] { if {[$c nodeType] eq "ELEMENT_NODE"} { lappend kids6 [$c nodeName] } }
ok {$kids6 eq {style:header style:header-left}}               "F: header before header-left (schema order)"
ok {[llength [$root6 getElementsByTagName style:header-left]] == 1} "F: header-left present"
$sd6 delete; $s6 destroy
$pkg6 save [file join $out hf-leftright.odt]; $pkg6 destroy
set pkg7 [odf::Package new [file join $out hf-leftright.odt]]
set s7   [odf::Styles new $pkg7]
ok {[dict exists [$s7 headerParts Standard] right]}           "F: default (right) header persisted"
ok {[dict exists [$s7 headerParts Standard -side left] left]} "F: left header persisted"
$s7 destroy; $pkg7 destroy

# ---- G) configurable header/footer box ----
set pkg8 [odf::newTextDoc]
set s8   [odf::Styles new $pkg8]
$s8 defineStandardPage {fo:page-width 21cm fo:page-height 29.7cm fo:margin-left 2cm fo:margin-right 2cm fo:margin-top 2cm fo:margin-bottom 2cm}
$s8 setHeaderParts Standard -center "x"
$s8 setHeaderFooterProps Standard -which header -min-height 1.2cm -height 1.2cm \
    -border "0.5pt solid #000000" -background #EEEEEE
$s8 flush
set sd8 [$pkg8 tree styles.xml]; set root8 [$sd8 documentElement]
set hsp8 [lindex [[lindex [$root8 getElementsByTagName style:header-style] 0] getElementsByTagName style:header-footer-properties] 0]
ok {[$hsp8 getAttribute fo:min-height ""] eq "1.2cm"}         "G: min-height set"
ok {[$hsp8 getAttribute svg:height ""] eq "1.2cm"}            "G: height (svg:height) set"
ok {[$hsp8 getAttribute fo:border ""] eq "0.5pt solid #000000"} "G: border set"
ok {[$hsp8 getAttribute fo:background-color ""] eq "#EEEEEE"} "G: background set"
ok {[catch {$s8 setHeaderFooterProps Standard -which body}]} "G: bad -which -> error"
$sd8 delete; $s8 destroy; $pkg8 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
