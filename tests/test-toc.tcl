set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]

# ---- A) build a TOC between real headings ----
set h1 [$t appendHeading "Introduction" 1]
set toc [$t appendTOC -title "Contents" -levels 3 -name "TOC1"]
$t appendHeading "Background" 1
$t appendParagraph "Body text"
set h2 [$t appendHeading "Details" 2]
ok {[$t tableOfContents] eq {TOC1}}                    "A: TOC name"
ok {[$t kind $toc] eq "toc"}                           "A: block kind is toc"
ok {[$t kind $h1] eq "heading" && [$t level $h1] eq "1"} "A: real heading (text:h) with outline-level"
set kinds [lmap n [$t blocks] {$t kind $n}]
ok {[lindex $kinds 1] eq "toc"}                        "A: TOC sits after first heading"

# ---- B) structure: source + per-level entry templates + index-body ----
$t flush
set doc [$pkg tree content.xml]; set xml [$doc asXML]; $doc delete
ok {[regexp {text:outline-level="3"} $xml]}            "B: source outline-level=3"
ok {[regexp -all {<text:table-of-content-entry-template } $xml] == 3} "B: three entry templates"
ok {[regexp {<text:index-entry-text/?>} $xml]}         "B: entry has index-entry-text"
ok {[regexp {style:type="right"} $xml]}                "B: right tab stop"
ok {[regexp {style:leader-char="\."} $xml]}            "B: dot leader"
ok {[regexp {<text:index-entry-page-number/?>} $xml]}  "B: entry has page number"
ok {[regexp {<text:index-body/?>} $xml]}               "B: index-body present (filled by consumer)"
ok {[regexp {Contents_20_Heading} $xml]}               "B: title template style"

# ---- C) validation ----
ok {[catch {$t appendTOC -levels 0}]}                  "C: non-positive levels rejected"
ok {[catch {$t appendTOC -levels abc}]}                "C: non-integer levels rejected"
ok {[catch {$t appendTOC -nope x}]}                    "C: unknown option rejected"

# ---- D) full TOC: clickable entries + fillTOC populating the index-body ----
$t flush
set doc [$pkg tree content.xml]; set xml [$doc asXML]; $doc delete
ok {[regexp -all {<text:index-entry-link-start/?>} $xml] == 3} "D: link-start per level (default on)"
ok {[regexp -all {<text:index-entry-link-end/?>} $xml] == 3}   "D: link-end per level"

$t fillTOC $toc
set ib [lindex [$toc getElementsByTagName text:index-body] 0]
ok {[llength [$ib getElementsByTagName text:index-title]] == 1} "D: fillTOC adds index-title"
proc countEntries {ib} {
    set n 0
    foreach p [$ib getElementsByTagName text:p] {
        if {[string match Contents_20_* [$p getAttribute text:style-name ""]]} { incr n }
    }
    return $n
}
ok {[countEntries $ib] == 4}                           "D: index-title para + 3 in-range headings"
$t fillTOC $toc
set ib [lindex [$toc getElementsByTagName text:index-body] 0]
ok {[countEntries $ib] == 4}                           "D: fillTOC is idempotent (clears before refill)"

# links off + chapter number, on a fresh document
set pkg2 [odf::newTextDoc]; set t3 [odf::Text new $pkg2]
$t3 appendTOC -levels 2 -links 0 -chapter 1
$t3 flush
set d3 [$pkg2 tree content.xml]; set x3 [$d3 asXML]; $d3 delete
ok {[regexp -all {<text:index-entry-link-start} $x3] == 0} "D: -links 0 omits link markers"
ok {[regexp -all {<text:index-entry-chapter } $x3] == 2}   "D: -chapter adds a chapter number per level"
$t3 destroy; $pkg2 destroy

$t flush
$pkg save [file join $out toc.odt]
$t destroy; $pkg destroy

# ---- E) round-trip ----
set p [odf::Package new [file join $out toc.odt]]
set t2 [odf::Text new $p]
ok {[$t2 tableOfContents] eq {TOC1}}                   "E: TOC survives reload"
set d2 [$p tree content.xml]
set ib2 [lindex [$d2 getElementsByTagName text:index-body] 0]
ok {[countEntries $ib2] == 4}                          "E: filled entries survive reload"
$d2 delete
$t2 destroy; $p destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
