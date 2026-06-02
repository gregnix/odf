set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

proc autoStyleProp {pkg name elem attr} {
    set doc [$pkg tree content.xml]
    set as [lindex [[$doc documentElement] getElementsByTagName office:automatic-styles] 0]
    set v ""
    foreach s [$as getElementsByTagName style:style] {
        if {[$s getAttribute style:name ""] eq $name} {
            set pe [lindex [$s getElementsByTagName $elem] 0]
            if {$pe ne ""} { set v [$pe getAttribute $attr ""] }
        }
    }
    $doc delete; return $v
}

# ---- A) new document: create automatic styles (skeleton has no office:automatic-styles yet) ----
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
ok {[$t autoNames] eq ""}                              "A: initially no automatic styles"
$t defineAutoParagraph P_center -paragraph {fo:text-align center} -text {fo:font-size 14pt}
$t defineAutoText      T_red    {fo:color #CC0000 fo:font-weight bold}
ok {[$t autoHas P_center] && [$t autoHas T_red]}       "A: two automatic styles created"
set p [$t appendParagraph "Lokal zentriert." P_center]
set p2 [$t appendParagraph "Mit "]
$t addSpan $p2 "rot-fett" T_red
$t flush
$pkg save [file join $out auto.odt]
$t destroy; $pkg destroy

# ---- B) reload: in content.xml/office:automatic-styles + properties + reference ----
set p2 [odf::Package new [file join $out auto.odt]]
ok {[autoStyleProp $p2 P_center style:paragraph-properties fo:text-align] eq "center"} "B: P_center text-align=center"
ok {[autoStyleProp $p2 P_center style:text-properties fo:font-size] eq "14pt"}         "B: P_center font-size=14pt"
ok {[autoStyleProp $p2 T_red style:text-properties fo:color] eq "#CC0000"}             "B: T_red color"
set t2 [odf::Text new $p2]
set refs {}; foreach n [$t2 blocks] { if {[$t2 kind $n] eq "paragraph"} { lappend refs [$t2 style $n]; foreach r [$t2 runs $n] { if {[$t2 runKind $r] eq "span"} { lappend refs [$t2 runStyle $r] } } } }
ok {"P_center" in $refs && "T_red" in $refs}           "B: content references automatic styles"
$t2 destroy; $p2 destroy

# ---- C) Vorhandenes Dokument mit Auto-Styles: hinzufuegen, Bestand preserved ----
set src [file join [file dirname [file normalize [info script]]] fixtures odt-automatic-styles-testdokument.odt]
set p3 [odf::Package new $src]
set t3 [odf::Text new $p3]
set before [llength [$t3 autoNames]]
ok {$before > 0 && "AutoP_CenterBlue" in [$t3 autoNames]}  "C: existing automatic styles detected"
$t3 defineAutoText NeuStyle {fo:color #003366}
$t3 flush
$p3 save [file join $out auto2.odt]
$t3 destroy; $p3 destroy
set p4 [odf::Package new [file join $out auto2.odt]]
set t4 [odf::Text new $p4]
ok {[$t4 autoHas NeuStyle]}                            "C: new automatic style present"
ok {"AutoP_CenterBlue" in [$t4 autoNames]}             "C: existing automatic style preserved (pass-through)"
ok {[llength [$t4 autoNames]] == $before + 1}          "C: exactly one added"
$t4 destroy; $p4 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
