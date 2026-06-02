set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) define A4 standard page, then augment with extra properties ----
set pkg [odf::newTextDoc]
set s   [odf::Styles new $pkg]
$s defineStandardFormat A4
$s pageProperties PMstandard -num-format i \
   -columns 2 -column-gap 0.7cm \
   -border "0.5pt solid #000000" -background-color #F8F8F8 -padding 0.2cm
set p [$s pageLayoutProps PMstandard]
ok {[dict get $p style:num-format] eq "i"}                     "A: num-format i"
ok {[dict get $p fo:border] eq "0.5pt solid #000000"}          "A: border"
ok {[dict get $p fo:background-color] eq "#F8F8F8"}            "A: background-color"
ok {[dict get $p fo:padding] eq "0.2cm"}                       "A: padding"
ok {[dict get [$s pageColumns PMstandard] count] eq "2"}       "A: 2 columns"
ok {[dict get [$s pageColumns PMstandard] gap] eq "0.7cm"}     "A: column gap 0.7cm"
$s flush; $s destroy
$pkg save [file join $out pageprops.odt]; $pkg destroy

# ---- B) reload: all extra properties persist ----
set pkg2 [odf::Package new [file join $out pageprops.odt]]
set s2   [odf::Styles new $pkg2]
set p2 [$s2 pageLayoutProps PMstandard]
ok {[dict get $p2 style:num-format] eq "i"}                    "B: num-format persisted"
ok {[dict get $p2 fo:border] eq "0.5pt solid #000000"}         "B: border persisted"
ok {[dict get $p2 fo:background-color] eq "#F8F8F8"}          "B: background persisted"
ok {[dict get [$s2 pageColumns PMstandard] count] eq "2"}      "B: columns persisted"
ok {[dict get $p2 fo:page-width] eq "21cm"}                    "B: A4 size still intact"
$s2 destroy; $pkg2 destroy

# ---- C) idempotency: re-running replaces the columns child ----
set pkg3 [odf::Package new [file join $out pageprops.odt]]
set s3   [odf::Styles new $pkg3]
$s3 pageProperties PMstandard -columns 3
ok {[dict get [$s3 pageColumns PMstandard] count] eq "3"}      "C: columns now 3"
set sd [$pkg3 tree styles.xml]
set root [$sd documentElement]
ok {[llength [$root getElementsByTagName style:columns]] == 1} "C: exactly one style:columns"
$sd delete; $s3 destroy; $pkg3 destroy

# ---- D) error cases ----
set pkg4 [odf::newTextDoc]; set s4 [odf::Styles new $pkg4]
$s4 defineStandardFormat A4
ok {[catch {$s4 pageProperties DoesNotExist -num-format 1}]}   "D: unknown layout -> error"
ok {[catch {$s4 pageProperties PMstandard -column-gap 1cm}]}   "D: gap without columns -> error"
ok {[catch {$s4 pageProperties PMstandard -bogus x}]}          "D: unknown option -> error"
$s4 destroy; $pkg4 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
