set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) build a master document (.odm) ----
set pkg [odf::newMasterDoc]
ok {[$pkg version] eq "1.3"}                                                 "A: office:version 1.3"
ok {[encoding convertfrom utf-8 [$pkg part mimetype]] eq "application/vnd.oasis.opendocument.text-master"} "A: mimetype part is text-master"
set man [encoding convertfrom utf-8 [$pkg part META-INF/manifest.xml]]
ok {[string match "*vnd.oasis.opendocument.text-master*" $man]}             "A: manifest root media-type is text-master"

set t [odf::Text new $pkg]
# the master may carry its own content (e.g. a title) plus the linked sections
$t appendHeading "Collected Works" 1
set s1 [$t appendSubdocument Chapter1 chapter1.odt]
set s2 [$t appendSubdocument Chapter2 chapter2.odt -filter-name writer8 -protected 1]
set s3 [$t appendSubdocument Appendix appendix.odt -section-name PartB -filter-name "" -protected 0 -style MySect]

ok {[$s1 nodeName] eq "text:section"}                                       "A: appendSubdocument returns text:section"

# ---- B) RNG child order: section-source is the FIRST child of text:section ----
set kids {}
foreach c [$s1 childNodes] { if {[$c nodeType] eq "ELEMENT_NODE"} { lappend kids [$c nodeName] } }
ok {[lindex $kids 0] eq "text:section-source"}                              "B: section-source is first child (RNG order)"

set src1 ""
foreach c [$s1 childNodes] { if {[$c nodeName] eq "text:section-source"} { set src1 $c; break } }
ok {[$src1 getAttribute xlink:href ""] eq "chapter1.odt"}                   "B: href set"
ok {[$src1 getAttribute xlink:type ""] eq "simple"}                         "B: xlink:type simple"
ok {[$src1 getAttribute xlink:show ""] eq "embed"}                          "B: xlink:show embed"
ok {[$src1 getAttribute text:filter-name ""] eq "writer8"}                  "B: default filter writer8"
ok {[$s1 getAttribute text:protected ""] eq "true"}                         "B: protected by default"

# explicit -filter-name "" omits the attribute; -protected 0 -> false; -style set
set src3 ""
foreach c [$s3 childNodes] { if {[$c nodeName] eq "text:section-source"} { set src3 $c; break } }
ok {[$src3 getAttribute text:filter-name "MISSING"] eq "MISSING"}           "B: -filter-name {} omits attribute"
ok {[$src3 getAttribute text:section-name ""] eq "PartB"}                   "B: -section-name imported"
ok {[$s3 getAttribute text:protected ""] eq "false"}                        "B: -protected 0 -> false"
ok {[$s3 getAttribute text:style-name ""] eq "MySect"}                      "B: -style set"

ok {[catch {$t appendSubdocument X y.odt -bogus 1}]}                        "B: unknown option rejected"

# ---- C) reader ----
set subs [$t subdocuments]
ok {[llength $subs] == 3}                                                   "C: three subdocuments listed"
ok {[dict get [lindex $subs 0] name] eq "Chapter1"}                         "C: first name"
ok {[dict get [lindex $subs 0] href] eq "chapter1.odt"}                     "C: first href"
ok {[dict get [lindex $subs 0] protected]}                                  "C: first protected true"
ok {![dict get [lindex $subs 2] protected]}                                 "C: third protected false"
ok {[dict get [lindex $subs 2] section-name] eq "PartB"}                    "C: third section-name"
# a plain (non-linked) section must NOT appear as a subdocument
$t appendSection PlainOne
ok {[llength [$t subdocuments]] == 3}                                       "C: plain section not counted as subdocument"
ok {[llength [$t sections]] == 4}                                           "C: sections lists all four"

# ---- D) save + reload: structure and media type persist ----
$t flush
set odm [file join $out master.odm]; $pkg save $odm
$t destroy; $pkg destroy

set pkg2 [odf::Package new $odm]
ok {[encoding convertfrom utf-8 [$pkg2 part mimetype]] eq "application/vnd.oasis.opendocument.text-master"} "D: mimetype persisted"
set t2 [odf::Text new $pkg2]
set subs2 [$t2 subdocuments]
ok {[llength $subs2] == 3}                                                  "D: subdocuments persisted"
ok {[dict get [lindex $subs2 1] href] eq "chapter2.odt"}                    "D: href persisted"
ok {![catch {dom parse [encoding convertfrom utf-8 [$pkg2 part content.xml]] dd}]} "D: content.xml well-formed"
catch {dd delete}
$t2 destroy; $pkg2 destroy

# ---- E) master template (.otm) ----
set pkgT [odf::newMasterTemplate]
ok {[encoding convertfrom utf-8 [$pkgT part mimetype]] eq "application/vnd.oasis.opendocument.text-master-template"} "E: .otm media type"
$pkgT destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
