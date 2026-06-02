::tcl::tm::path add [file dirname [file dirname [file normalize [info script]]]]
package require odf::text
package require odf::style
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) real document: resolve properties ----
set pkg [odf::Package new [file join [file dirname [file normalize [info script]]] fixtures odt-style-resolution-testdokument.odt]]
set t [odf::Text new $pkg]
set reg [$t styleRegistry]
ok {[llength [dict keys $reg]] >= 20}                                  "A: registry filled (>=20)"
set h ""; foreach n [$t blocks] { if {[$t style $n] eq "TitleStyle"} { set h $n; break } }
ok {$h ne ""}                                                          "A: TitleStyle node found"
ok {[$t effectiveProp $h style:text-properties fo:font-size $reg] eq "24pt"}   "A: Title font-size 24pt"
ok {[$t effectiveProp $h style:text-properties fo:font-weight $reg] eq "bold"} "A: Title bold"
ok {[$t effectiveProp $h style:text-properties fo:color $reg] eq "#222222"}    "A: Title color"
set b ""; foreach n [$t blocks] { if {[$t style $n] eq "BodyText"} { set b $n; break } }
ok {[$t effectiveProp $b style:text-properties fo:font-size $reg] eq "11pt"}   "A: BodyText 11pt"
ok {[$t resolveStyle "DoesNotExist" $reg] eq ""}                        "A: unknown style -> empty"
$t destroy; $pkg destroy

# ---- B) synthetic inheritance: common base + automatic style with parent ----
set pkg [odf::newTextDoc]
set st  [odf::Styles new $pkg]
$st defineParagraph Base -paragraph {fo:margin-top 0.20cm} -text {fo:font-size 12pt fo:color #000000}
$st flush
$st destroy
set t [odf::Text new $pkg]
set node [$t defineAutoParagraph P_sub -paragraph {fo:text-align center} -text {fo:font-size 14pt}]
$node setAttribute style:parent-style-name Base
set r [$t resolveStyle P_sub]
ok {[dict get $r style:text-properties fo:font-size] eq "14pt"}        "B: child overrides (font-size 14pt)"
ok {[dict get $r style:text-properties fo:color] eq "#000000"}         "B: inherited (color from Base)"
ok {[dict get $r style:paragraph-properties fo:text-align] eq "center"} "B: own property (text-align)"
ok {[dict get $r style:paragraph-properties fo:margin-top] eq "0.20cm"} "B: inherited (margin-top from Base)"
$t destroy; $pkg destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
