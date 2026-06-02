set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::base

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) defaults (mirror LO's working Text/CSV connection) ----
set pkg [odf::newBaseDoc]
ok {[$pkg part mimetype] eq "application/vnd.oasis.opendocument.base"}  "A: mimetype"
set parts [lsort [$pkg parts]]
ok {$parts eq {META-INF/manifest.xml content.xml mimetype settings.xml}} "A: part set (mimetype/settings/content/manifest)"
set s [odf::base::source $pkg]
ok {[dict get $s href] eq "../"}             "A: default href ../"
ok {[dict get $s media-type] eq "text/csv"}  "A: default media-type text/csv"
ok {[dict get $s extension] eq "csv"}        "A: default extension csv"
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[string match {*xlink:type="simple"*} $xml]}     "A: xlink:type=simple (schema-required, LO omits it)"
ok {![string match {*<db:delimiter*} $xml]}          "A: no delimiter by default (LO defaults)"
ok {[string match {*<db:table-filter-pattern>%</db:table-filter-pattern>*} $xml]} "A: table-filter %"
$pkg destroy

# ---- B) custom source ----
set pkg [odf::newBaseDoc -href ./data -extension txt -media-type text/plain]
set s [odf::base::source $pkg]
ok {[dict get $s href] eq "./data"}            "B: custom href"
ok {[dict get $s extension] eq "txt"}          "B: custom extension"
ok {[dict get $s media-type] eq "text/plain"}  "B: custom media-type"
$pkg destroy

# ---- C) explicit delimiters + encoding (no-magic option) ----
set pkg [odf::newBaseDoc -field , -string {"} -decimal . -encoding UTF-8]
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[string match {*<db:delimiter *db:field=","*} $xml]}        "C: db:delimiter field"
ok {[string match {*db:string="&quot;"*} $xml]}                 "C: db:string escaped"
ok {[string match {*<db:character-set db:encoding="UTF-8"*} $xml]} "C: db:character-set"
$pkg destroy

# ---- D) validation ----
ok {[catch {odf::newBaseDoc -nope x}]}  "D: unknown option rejected"

# ---- E) well-formed + round-trip ----
set pkg [odf::newBaseDoc -href ../ -extension csv]
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
set wf 1
if {[catch {set dd [dom parse $xml]}]} { set wf 0 } else { $dd delete }
ok {$wf}  "E: content.xml well-formed"
$pkg save [file join $out base.odb]
$pkg destroy
set p2 [odf::Package new [file join $out base.odb]]
set s2 [odf::base::source $p2]
ok {[dict get $s2 href] eq "../" && [dict get $s2 extension] eq "csv"}  "E: source survives reload"
$p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
