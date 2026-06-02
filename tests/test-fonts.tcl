set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

proc childElems {el} {
    set r {}; foreach c [$el childNodes] { if {[$c nodeType] eq "ELEMENT_NODE"} { lappend r [$c nodeName] } }
    return $r
}

# ---- A) styles.xml: register a font + use it in a common style ----
set pkg [odf::newTextDoc]
set s   [odf::Styles new $pkg]
$s registerFont Arial -family Arial -generic swiss -pitch variable
$s defineParagraph Body -text {fo:font-size 11pt style:font-name Arial}
$s flush
$s destroy

# ---- A2) content.xml: register a font + use it in an automatic style ----
set t [odf::Text new $pkg]
$t registerFont "DejaVu Sans Mono" -generic modern -pitch fixed
$t defineAutoText Code {fo:font-size 10pt style:font-name "DejaVu Sans Mono"}
$t flush
$pkg save [file join $out fonts.odt]
$t destroy; $pkg destroy

# ---- B) reload: declarations present + in correct position ----
set pkg2 [odf::Package new [file join $out fonts.odt]]
set s2 [odf::Styles new $pkg2]
ok {"Arial" in [$s2 fonts]}                                  "B: Arial declared in styles.xml"
$s2 destroy
set t2 [odf::Text new $pkg2]
ok {"DejaVu Sans Mono" in [$t2 fonts]}                       "B: mono font declared in content.xml"
$t2 destroy

# Position styles.xml: font-face-decls VOR office:styles
set sd [$pkg2 tree styles.xml]
set sk [childElems [$sd documentElement]]
ok {[lsearch $sk office:font-face-decls] < [lsearch $sk office:styles]} "B: styles.xml: font-face-decls before office:styles"
ok {[lsearch $sk office:font-face-decls] >= 0}               "B: styles.xml: font-face-decls exists"
$sd delete
# Position content.xml: font-face-decls VOR office:automatic-styles und office:body
set cd [$pkg2 tree content.xml]
set ck [childElems [$cd documentElement]]
ok {[lsearch $ck office:font-face-decls] < [lsearch $ck office:body]} "B: content.xml: font-face-decls before office:body"
ok {[lsearch $ck office:font-face-decls] < [lsearch $ck office:automatic-styles]} "B: content.xml: before automatic-styles"
$cd delete
$pkg2 destroy

# ---- C) idempotent ----
set pkg3 [odf::Package new [file join $out fonts.odt]]
set s3 [odf::Styles new $pkg3]
$s3 registerFont Arial -family Arial -generic roman
ok {[llength [$s3 fonts]] == 1}                              "C: no duplicate (exactly 1 font)"
$s3 destroy; $pkg3 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
