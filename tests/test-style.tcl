set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::style
package require odf::text
package require tdom

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) Styles in ein neues Dokument schreiben ----
set pkg [odf::newTextDoc]
set s   [odf::Styles new $pkg]
ok {![$s has GreenBold]}                       "A: empty at start"
$s defineText      GreenBold {fo:color #008844 fo:font-weight bold}
$s defineParagraph Centered  -paragraph {fo:text-align center} -text {fo:font-size 14pt}
$s defineCell      Warn      -cell {fo:background-color #FFE5E5}
ok {[$s has GreenBold] && [$s has Centered] && [$s has Warn]} "A: three styles created"
ok {"GreenBold" in [$s names text]}            "A: GreenBold is text family"
ok {"Centered"  in [$s names paragraph]}       "A: Centered is paragraph family"
$s flush

# Inhalt, der die Styles referenziert
set t [odf::Text new $pkg]
set p [$t appendParagraph "Centered mit 14pt." Centered]
set p2 [$t appendParagraph "Normal "]
$t addSpan $p2 "gruen-fett" GreenBold
$t flush
file mkdir $out
$pkg save [file join $out styled.odt]
$s destroy; $t destroy; $pkg destroy

# ---- B) Reload: Styles existieren + Properties stimmen + Referenzen passen ----
set p2 [odf::Package new [file join $out styled.odt]]
set s2 [odf::Styles new $p2]
ok {[$s2 has GreenBold] && [$s2 has Centered] && [$s2 has Warn]} "B: Styles present after reload"

# check property: GreenBold -> text-properties fo:color = #008844
set doc [$p2 tree styles.xml]
set found ""
foreach st [[$doc documentElement] getElementsByTagName style:style] {
    if {[$st getAttribute style:name ""] eq "GreenBold"} {
        set tp [lindex [$st getElementsByTagName style:text-properties] 0]
        set found [$tp getAttribute fo:color ""]
    }
}
ok {$found eq "#008844"}                        "B: GreenBold fo:color correct"
$doc delete

# reference in content: paragraph uses Centered, span uses GreenBold
set t2 [odf::Text new $p2]
set refsP {}; set refsSpan {}
foreach n [$t2 blocks] {
    if {[$t2 kind $n] eq "paragraph"} {
        lappend refsP [$t2 style $n]
        foreach r [$t2 runs $n] { if {[$t2 runKind $r] eq "span"} { lappend refsSpan [$t2 runStyle $r] } }
    }
}
ok {"Centered" in $refsP}                       "B: paragraph references Centered"
ok {"GreenBold" in $refsSpan}                   "B: span references GreenBold"
$t2 destroy; $s2 destroy; $p2 destroy

# ---- C) notes configuration (footnote/endnote numbering defaults) ----
set pkg3 [odf::newTextDoc]
set s3   [odf::Styles new $pkg3]
ok {[$s3 notesConfiguration] eq {}}                "C: no notes-config at start"
$s3 defineNotesConfiguration -class footnote -num-format 1 -position page
$s3 defineNotesConfiguration -class endnote  -num-format 1 -position document \
    -start-value 1 -default-style Endnote -start-numbering-at document
ok {[lsort [$s3 notesConfiguration]] eq {endnote footnote}} "C: both classes present"
set en [$s3 notesConfiguration endnote]
ok {[dict get $en text:note-class] eq "endnote"}  "C: endnote note-class"
ok {[dict get $en style:num-format] eq "1"}        "C: endnote num-format arabic (explicit, not roman default)"
ok {[dict get $en text:footnotes-position] eq "document"} "C: endnote position document"
ok {[dict get $en text:default-style-name] eq "Endnote"}  "C: endnote default-style mapped"
# idempotent per class: re-defining endnote replaces, does not duplicate
$s3 defineNotesConfiguration -class endnote -num-format I -position document
ok {[llength [$s3 notesConfiguration]] == 2}       "C: re-define endnote does not duplicate"
ok {[dict get [$s3 notesConfiguration endnote] style:num-format] eq "I"} "C: endnote num-format replaced 1->I"
ok {[catch {$s3 defineNotesConfiguration -class chapter}]} "C: invalid class rejected"
ok {[catch {$s3 defineNotesConfiguration -class footnote -bogus x}]} "C: unknown option rejected"
$s3 flush
$pkg3 save [file join $out notescfg.odt]
$s3 destroy; $pkg3 destroy
# reload: configuration survives the round-trip
set p4 [odf::Package new [file join $out notescfg.odt]]
set s4 [odf::Styles new $p4]
ok {[lsort [$s4 notesConfiguration]] eq {endnote footnote}} "C: configs present after reload"
ok {[dict get [$s4 notesConfiguration footnote] text:footnotes-position] eq "page"} "C: footnote position survives reload"
$s4 destroy; $p4 destroy

# ---- D) line numbering configuration ----
set pkg5 [odf::newTextDoc]
set s5   [odf::Styles new $pkg5]
ok {[$s5 lineNumbering] eq {}}                     "D: no line-numbering at start"
$s5 defineLineNumbering -number-lines true -num-format 1 -increment 5 \
    -position left -offset 0.5cm -count-empty-lines false -separator "|" -separator-increment 1
set ln [$s5 lineNumbering]
ok {[dict get $ln text:number-lines] eq "true"}    "D: number-lines set"
ok {[dict get $ln style:num-format] eq "1"}        "D: num-format arabic"
ok {[dict get $ln text:increment] eq "5"}          "D: increment every 5th line"
ok {[dict get $ln text:number-position] eq "left"} "D: number-position left"
ok {[dict get $ln separator] eq "|"}               "D: separator text"
ok {[dict get $ln separator-increment] eq "1"}     "D: separator increment"
# idempotent: redefining replaces, does not duplicate
$s5 defineLineNumbering -number-lines false
ok {[dict get [$s5 lineNumbering] text:number-lines] eq "false"} "D: redefine replaces value"
ok {[dict exists [$s5 lineNumbering] text:increment] == 0}        "D: redefine drops old separator/attrs"
ok {[catch {$s5 defineLineNumbering -bogus x}]}    "D: unknown option rejected"
$s5 flush
$pkg5 save [file join $out linenum.odt]
$s5 destroy; $pkg5 destroy
# reload: configuration survives the round-trip (this is why out/linenum.odt exists)
set p8 [odf::Package new [file join $out linenum.odt]]
set s8 [odf::Styles new $p8]
ok {[dict get [$s8 lineNumbering] text:number-lines] eq "false"} "D: line-numbering survives reload"
$s8 destroy; $p8 destroy

# ---- E) bibliography configuration ----
set pkg6 [odf::newTextDoc]
set s6   [odf::Styles new $pkg6]
ok {[$s6 bibliographyConfiguration] eq {}}         "E: no bibliography-config at start"
$s6 defineBibliographyConfiguration -prefix "\[" -suffix "\]" -numbered-entries true \
    -sort-by-position false -sort-algorithm alphanumeric \
    -sort-keys {{author 1} {year 0} {title}}
set bib [$s6 bibliographyConfiguration]
ok {[dict get $bib text:prefix] eq "\["}            "E: prefix set"
ok {[dict get $bib text:numbered-entries] eq "true"} "E: numbered-entries set"
ok {[dict get $bib text:sort-algorithm] eq "alphanumeric"} "E: sort-algorithm set"
ok {[llength [dict get $bib sort-keys]] == 3}      "E: three sort keys"
ok {[lindex [dict get $bib sort-keys] 0] eq {author true}} "E: first sort key author asc (ODF boolean true)"
ok {[lindex [dict get $bib sort-keys] 2] eq {title}}    "E: third sort key has no ascending"
ok {[catch {$s6 defineBibliographyConfiguration -sort-keys {{bogus 1}}}]} "E: invalid sort key rejected"
ok {[catch {$s6 defineBibliographyConfiguration -nope x}]}               "E: unknown option rejected"
$s6 flush
$pkg6 save [file join $out biblio.odt]
# regression guard: ODF boolean attrs must be true/false, never 1/0 (validator)
set xml [encoding convertfrom utf-8 [$pkg6 part styles.xml]]
ok {[regexp {text:sort-ascending="true"} $xml]}    "E: sort-ascending emitted as ODF boolean true"
ok {![regexp {text:sort-ascending="[01]"} $xml]}   "E: sort-ascending never 1/0"
ok {[regexp {text:numbered-entries="true"} $xml]}  "E: numbered-entries is true"
$s6 destroy; $pkg6 destroy
# reload: both survive round-trip
set p7 [odf::Package new [file join $out biblio.odt]]
set s7 [odf::Styles new $p7]
ok {[llength [dict get [$s7 bibliographyConfiguration] sort-keys]] == 3} "E: sort keys survive reload"
$s7 destroy; $p7 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
