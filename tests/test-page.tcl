set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) fresh document: default page + a normal style ----
set pkg [odf::newTextDoc]
set s   [odf::Styles new $pkg]
$s defineParagraph Body -text {fo:font-size 11pt}
$s defineStandardPage {fo:page-width 21cm fo:page-height 29.7cm \
        fo:margin-left 2.5cm fo:margin-right 2cm fo:margin-top 2cm \
        fo:margin-bottom 2cm style:print-orientation portrait}
$s flush
$s destroy
$pkg save [file join $out page.odt]
$pkg destroy

# ---- B) reload: layout + master-page + properties + coexistence ----
set pkg2 [odf::Package new [file join $out page.odt]]
set s2   [odf::Styles new $pkg2]
ok {"PMstandard" in [$s2 pageLayouts]}                       "B: page-layout PMstandard present"
ok {"Standard"   in [$s2 masterPages]}                       "B: master-page Standard present"
ok {[$s2 masterPageLayout Standard] eq "PMstandard"}         "B: master-page -> page-layout linked"
set p [$s2 pageLayoutProps PMstandard]
ok {[dict get $p fo:page-width]  eq "21cm"}                  "B: page-width 21cm"
ok {[dict get $p fo:page-height] eq "29.7cm"}                "B: page-height 29.7cm"
ok {[dict get $p fo:margin-left] eq "2.5cm"}                 "B: margin-left 2.5cm (DIN)"
ok {[dict get $p fo:margin-right] eq "2cm"}                  "B: margin-right 2cm"
ok {[dict get $p style:print-orientation] eq "portrait"}     "B: portrait"
ok {[$s2 has Body]}                                          "B: named style coexists"
$s2 destroy; $pkg2 destroy

# ---- C) idempotency: redefining replaces, does not duplicate ----
set pkg3 [odf::Package new [file join $out page.odt]]
set s3   [odf::Styles new $pkg3]
$s3 definePageLayout PMstandard {fo:page-width 21cm fo:margin-left 3cm}
ok {[llength [$s3 pageLayouts]] == 1}                        "C: no duplicate (exactly 1 page-layout)"
ok {[dict get [$s3 pageLayoutProps PMstandard] fo:margin-left] eq "3cm"} "C: overridden (3cm)"
$s3 destroy; $pkg3 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
