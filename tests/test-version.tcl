set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf
package require odf::text
package require odf::draw
package require odf::sheet

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- A) freshly created documents are ODF 1.3 ----
foreach {ctor label} {odf::newTextDoc text odf::newDrawDoc draw odf::newSheetDoc sheet} {
    set pkg [$ctor]
    ok {[$pkg version] eq "1.3"} "A: fresh $label doc is office:version 1.3"
    $pkg destroy
}

# ---- B) loading preserves the source version (pass-through, no magic) ----
set fx [file join $base tests fixtures odt-automatic-styles-testdokument.odt]
set p [odf::Package new $fx]
ok {[$p version] eq "1.2"} "B: loaded 1.2 fixture keeps 1.2 (pass-through)"
set nstyles [regexp -all {<style:style } [encoding convertfrom utf-8 [$p part styles.xml]]]

# ---- C) setVersion is explicit and sets every present part ----
ok {[$p setVersion 1.3] eq "1.3"}                      "C: setVersion returns the version"
ok {[$p version] eq "1.3"}                             "C: version now 1.3"
foreach part {content.xml styles.xml meta.xml} {
    if {[$p has $part]} {
        set d [$p tree $part]
        ok {[[$d documentElement] getAttribute office:version ""] eq "1.3"} "C: $part bumped to 1.3"
        $d delete
    }
}
# content is preserved (setVersion only touches office:version)
ok {[regexp -all {<style:style } [encoding convertfrom utf-8 [$p part styles.xml]]] == $nstyles} "C: styles preserved by setVersion"
# setVersion also bumps the manifest version (so the package is internally consistent)
ok {[regexp {manifest:version="1.3"} [encoding convertfrom utf-8 [$p part META-INF/manifest.xml]]]} "C: setVersion also bumps manifest:version"
$p destroy

# ---- D) round-trip: a freshly created, conformant doc survives save+reload ----
# (The foreign odfpy fixture above has its own content defects and is loaded only
# to test pass-through + version reading; we never re-emit it as a product.)
set fresh [odf::newTextDoc]
set ft [odf::Text new $fresh]
$ft appendHeading "Version round-trip" 1
$ft appendParagraph "Frisch erzeugtes, ODF-1.3-konformes Dokument."
$ft flush
$fresh setVersion 1.3
$fresh save [file join $out version.odt]
$ft destroy; $fresh destroy
set p2 [odf::Package new [file join $out version.odt]]
ok {[$p2 version] eq "1.3"}                            "D: 1.3 survives reload"
ok {[regexp {manifest:version="1.3"} [encoding convertfrom utf-8 [$p2 part META-INF/manifest.xml]]]} "D: manifest:version present in saved doc"
$p2 destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
