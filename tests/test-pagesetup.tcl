set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) pure helper: presets + orientation ----
set pkg [odf::newTextDoc]
set s   [odf::Styles new $pkg]
ok {[$s pageFormats] eq {A3 A4 A5 A6 Legal Letter}}                "A: format list"
set a4 [$s pageFormat A4]
ok {[dict get $a4 fo:page-width]  eq "21cm"}                       "A: A4 width 21cm"
ok {[dict get $a4 fo:page-height] eq "29.7cm"}                     "A: A4 height 29.7cm"
set a4l [$s pageFormat A4 -orientation landscape]
ok {[dict get $a4l fo:page-width] eq "29.7cm"}                     "A: A4 landscape swaps width"
ok {[dict get $a4l style:print-orientation] eq "landscape"}        "A: A4 landscape orientation"
ok {[dict get [$s pageFormat Letter] fo:page-width] eq "21.59cm"}  "A: Letter width 21.59cm"

# ---- B) define layouts from presets + standard page ----
$s defineParagraph Body -text {fo:font-size 11pt}
$s defineStandardFormat A4                                         ;# PMstandard, default 2cm margins
$s definePageFormat PMa3 A3 -orientation landscape -margin 1.5cm
$s definePageFormat PMletter Letter -margins {9.5cm 2cm 2cm 2.5cm} -extra {style:num-format 1}
$s flush; $s destroy
$pkg save [file join $out pagesetup.odt]; $pkg destroy

# ---- C) reload: dimensions, orientation, margins, extra persist ----
set pkg2 [odf::Package new [file join $out pagesetup.odt]]
set s2   [odf::Styles new $pkg2]
ok {"Standard" in [$s2 masterPages]}                               "C: master-page Standard present"
ok {[$s2 masterPageLayout Standard] eq "PMstandard"}               "C: Standard -> PMstandard"
set std [$s2 pageLayoutProps PMstandard]
ok {[dict get $std fo:page-width]  eq "21cm"}                      "C: A4 width persisted"
ok {[dict get $std fo:page-height] eq "29.7cm"}                    "C: A4 height persisted"
ok {[dict get $std fo:margin-top]  eq "2cm"}                       "C: default margin 2cm"
ok {[dict get $std style:print-orientation] eq "portrait"}         "C: portrait persisted"
set a3 [$s2 pageLayoutProps PMa3]
ok {[dict get $a3 fo:page-width]  eq "42cm"}                       "C: A3 landscape width 42cm"
ok {[dict get $a3 fo:page-height] eq "29.7cm"}                     "C: A3 landscape height 29.7cm"
ok {[dict get $a3 fo:margin-left] eq "1.5cm"}                      "C: uniform margin 1.5cm"
set le [$s2 pageLayoutProps PMletter]
ok {[dict get $le fo:page-width] eq "21.59cm"}                     "C: Letter width persisted"
ok {[dict get $le fo:margin-top] eq "9.5cm"}                       "C: explicit margins (top 9.5cm)"
ok {[dict get $le style:num-format] eq "1"}                        "C: extra prop num-format"
ok {[$s2 has Body]}                                                "C: named style coexists"
$s2 destroy; $pkg2 destroy

# ---- D) error cases ----
set pkg3 [odf::newTextDoc]; set s3 [odf::Styles new $pkg3]
ok {[catch {$s3 pageFormat A7}]}                                   "D: unknown format -> error"
ok {[catch {$s3 pageFormat A4 -orientation foo}]}                  "D: bad orientation -> error"
ok {[catch {$s3 definePageFormat PMx A4 -margins {1cm 2cm}}]}      "D: bad -margins length -> error"
$s3 destroy; $pkg3 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
