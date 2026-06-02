set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf
package require odf::text
package require tdom

set src [lindex $argv 0]
if {$src eq "" || ![file isfile $src]} {
    puts stderr "Usage: tclsh test-odf2.tcl <file.odt>"
    puts stderr "  (pass an existing .odt file as argument)"
    exit 2
}
set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# 1x1 PNG (transparent) for addpart
set png [binary decode base64 \
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC"]

# ---- A) Pass-Through-Bearbeitung ----
set pkg [odf::Package new $src]
puts "Teile: [$pkg parts]"
set stylesBefore [$pkg part styles.xml]
set doc [$pkg tree content.xml]
set target ""
foreach tag {text:h text:p} { set ns [[$doc documentElement] getElementsByTagName $tag]; if {[llength $ns]} { set target [lindex $ns 0]; break } }
set vorher [$target asText]
$target appendChild [$doc createTextNode " \[GEAENDERT\]"]
$pkg settree content.xml $doc
$doc delete
$pkg save [file join $out mod.odt]
$pkg destroy

set p2 [odf::Package new [file join $out mod.odt]]
set d2 [$p2 tree content.xml]
set t2 ""
foreach tag {text:h text:p} { set ns [[$d2 documentElement] getElementsByTagName $tag]; if {[llength $ns]} { set t2 [lindex $ns 0]; break } }
puts "  '$vorher' -> '[$t2 asText]'"
ok {[string match {*\[GEAENDERT\]*} [$t2 asText]]}  "A: Aenderung present"
ok {[$p2 part styles.xml] eq $stylesBefore}         "A: styles.xml byte-identical"
$d2 delete; $p2 destroy

# ---- B) Manifest-Helfer ----
set pkg [odf::Package new $src]
set mbefore [$pkg manifest]
puts "Manifest-Eintraege vorher: [dict size $mbefore]"
ok {[dict exists $mbefore /]}            "B: root entry '/' in manifest"
ok {[dict exists $mbefore content.xml]}  "B: content.xml in manifest"

# Teil hinzufuegen
$pkg addpart Pictures/neu.png $png image/png
ok {[$pkg has Pictures/neu.png]}                         "B: part added"
ok {[dict get [$pkg manifest] Pictures/neu.png] eq "image/png"} "B: manifest entry set"
$pkg save [file join $out add.odt]
$pkg destroy

# after reload: Teil + Manifest-Eintrag persistent
set p3 [odf::Package new [file join $out add.odt]]
ok {[$p3 part Pictures/neu.png] eq $png}                 "B: PNG byte-identical after reload"
ok {[dict exists [$p3 manifest] Pictures/neu.png]}       "B: Manifest-Eintrag after reload"

# wieder entfernen
$p3 dropfile Pictures/neu.png
ok {![$p3 has Pictures/neu.png]}                          "B: part removed"
ok {![dict exists [$p3 manifest] Pictures/neu.png]}       "B: manifest entry removed"
# Originalteile unberuehrt
ok {[$p3 has content.xml] && [$p3 has styles.xml]}        "B: original parts preserved"
$p3 destroy

# ---- C) Settings.xml API (odf 0.8) ----
set pkgS [odf::newTextDoc]
# Initial: settings.xml exists noch nicht
ok {![$pkgS has settings.xml]}                                "C: settings.xml not auto-created"
# Write -> appears
$pkgS setSetting "ooo:view-settings/ZoomFactor"   100 int
$pkgS setSetting "ooo:view-settings/VisibleAreaTop" 0 int
$pkgS setSetting "ooo:configuration-settings/AutoCalculate" true boolean
$pkgS setSetting "ooo:view-settings/Greeting"     "Hello" string
ok {[$pkgS has settings.xml]}                                 "C: settings.xml created on first setSetting"
ok {[$pkgS setting "ooo:view-settings/ZoomFactor"] eq "100"}  "C: setting returns the value"
ok {[$pkgS setting "ooo:view-settings/Greeting"]  eq "Hello"} "C: string setting"
ok {[$pkgS setting "ooo:configuration-settings/AutoCalculate"] eq "true"} "C: nested set"
ok {[$pkgS setting "ooo:view-settings/NotExist"] eq ""}       "C: missing setting returns empty"
# Listing all settings
set allSet [$pkgS settings]
ok {[dict get $allSet "ooo:view-settings/ZoomFactor"] eq "100"} "C: settings dict has ZoomFactor"
ok {[dict get $allSet "ooo:configuration-settings/AutoCalculate"] eq "true"} "C: settings dict has nested AutoCalculate"
# Overwrite (dedup-by-name)
$pkgS setSetting "ooo:view-settings/ZoomFactor" 150 int
ok {[$pkgS setting "ooo:view-settings/ZoomFactor"] eq "150"}  "C: overwrite replaces value"
# Schema check on the persisted settings.xml: config:type carries on the items
set sxml [encoding convertfrom utf-8 [$pkgS part settings.xml]]
ok {[regexp {<config:config-item[^>]*config:name="ZoomFactor"[^>]*config:type="int"[^>]*>150</config:config-item>} $sxml]} \
                                                              "C: ZoomFactor written with config:type=int"
ok {[regexp {<config:config-item-set config:name="ooo:view-settings">} $sxml]} \
                                                              "C: top-level config-item-set named correctly"
# Remove
ok {[$pkgS removeSetting "ooo:view-settings/Greeting"] == 1}  "C: removeSetting returns 1 on hit"
ok {[$pkgS removeSetting "ooo:view-settings/Greeting"] == 0}  "C: removeSetting returns 0 on second call"
ok {[$pkgS setting "ooo:view-settings/Greeting"] eq ""}       "C: removed setting reads empty"
# Bad type rejected
ok {[catch {$pkgS setSetting "ooo:foo/Bar" 1 hexadecimal}]}   "C: bad config:type rejected"
# Bad path rejected
ok {[catch {$pkgS setSetting "no-slash" 1 int}]}              "C: setSetting requires set-name/item-name"

# Save -> reload -> settings persisted byte-identically
$pkgS save [file join $out settings-roundtrip.odt]
$pkgS destroy
set pkgRT [odf::Package new [file join $out settings-roundtrip.odt]]
ok {[$pkgRT setting "ooo:view-settings/ZoomFactor"] eq "150"} "C: setting survives save+reload"
ok {[$pkgRT setting "ooo:configuration-settings/AutoCalculate"] eq "true"} "C: nested setting survives reload"
$pkgRT destroy

# ---- D) Thumbnail (odf 0.8) ----
set pkgT [odf::newTextDoc]
ok {[$pkgT thumbnail] eq ""}                                  "D: thumbnail empty by default"
# Minimal valid 1x1 PNG (synthesized)
set png [binary decode base64 iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNgAAIAAAUAAen63NgAAAAASUVORK5CYII=]
$pkgT setThumbnail $png
ok {[$pkgT thumbnail] eq $png}                                "D: thumbnail readback byte-identical"
set mf [$pkgT manifest]
ok {[dict get $mf Thumbnails/thumbnail.png] eq "image/png"}   "D: manifest entry image/png"
# Overwrite
set png2 [string range $png 0 end-1]z
$pkgT setThumbnail $png2
ok {[$pkgT thumbnail] eq $png2}                               "D: thumbnail overwrite works"
$pkgT save [file join $out thumb-roundtrip.odt]
$pkgT destroy
set pkgT2 [odf::Package new [file join $out thumb-roundtrip.odt]]
ok {[$pkgT2 thumbnail] eq $png2}                              "D: thumbnail persists across save+reload"
$pkgT2 destroy

# ---- E) Container validate (odf 0.8) ----
set pkgV [odf::newTextDoc]
ok {[$pkgV validate] eq {}}                                   "E: fresh doc validates clean"
# Add a part WITHOUT a manifest entry: validate should flag it
$pkgV setpart orphan.xml "<orphan/>"
set issues [$pkgV validate]
ok {[llength $issues] == 1}                                   "E: one issue when orphan part added"
ok {[lindex [lindex $issues 0] 0] eq "part-without-manifest-entry"} "E: orphan-part issue kind"
ok {[lindex [lindex $issues 0] 1] eq "orphan.xml"}            "E: orphan-part issue detail"
# Fix with addpart -- now should validate
$pkgV removepart orphan.xml
$pkgV addpart orphan.xml "<orphan/>" application/xml
ok {[$pkgV validate] eq {}}                                   "E: clean after manifest entry added"
# Conversely: manifest entry without part is also a problem
# (Hack via the manifest doc -- not via the public API, simulating loaded corruption.)
set mfDoc [$pkgV tree META-INF/manifest.xml]
set newE  [$mfDoc createElement manifest:file-entry]
$newE setAttribute manifest:full-path "ghost.png"
$newE setAttribute manifest:media-type "image/png"
[$mfDoc documentElement] appendChild $newE
$pkgV settree META-INF/manifest.xml $mfDoc
set issues [$pkgV validate]
ok {[llength $issues] == 1}                                   "E: one issue when ghost manifest entry"
ok {[lindex [lindex $issues 0] 0] eq "manifest-entry-without-part"} "E: ghost-entry issue kind"
ok {[lindex [lindex $issues 0] 1] eq "ghost.png"}             "E: ghost-entry issue detail"
$pkgV destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
