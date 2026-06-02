set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::sheet
package require odf::draw

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

proc rootMedia {pkg} {
    set man [encoding convertfrom utf-8 [$pkg part META-INF/manifest.xml]]
    return [lindex [regexp -inline {manifest:full-path="/" manifest:media-type="([^"]*)"} $man] 1]
}

# {builder ext expected-mimetype}
set cases {
    {odf::newTextTemplate  ott application/vnd.oasis.opendocument.text-template}
    {odf::newSheetTemplate ots application/vnd.oasis.opendocument.spreadsheet-template}
    {odf::newDrawTemplate  otg application/vnd.oasis.opendocument.graphics-template}
}

foreach c $cases {
    lassign $c ctor ext mime
    set p [$ctor]
    ok {[encoding convertfrom utf-8 [$p part mimetype]] eq $mime} "$ext: mimetype part = $ext media type"
    ok {[$p mimetype] eq $mime}                                   "$ext: mimetype accessor"
    ok {[rootMedia $p] eq $mime}                                  "$ext: manifest root media-type matches"
    # round-trip: the template survives save + reload (valid zip, mimetype STORED first)
    set dst [file join $out tpl.$ext]
    $p save $dst
    $p destroy
    set p2 [odf::Package new $dst]
    ok {[$p2 mimetype] eq $mime}                                  "$ext: mimetype survives reload"
    $p2 destroy
}

# A) a text template is still a full, editable text document
set p [odf::newTextTemplate]
set t [odf::Text new $p]
$t appendHeading "Vorlage" 1
$t appendParagraph "Platzhalter."
$t flush
ok {[llength [$t blocks]] >= 2}                "ott: content model still works (editable)"
$t destroy; $p destroy

# B) setMimetype primitive: turn a plain doc into a template, and back
set p [odf::newTextDoc]
ok {[$p mimetype] eq "application/vnd.oasis.opendocument.text"}  "setMimetype: starts as document"
$p setMimetype "application/vnd.oasis.opendocument.text-template"
ok {[$p mimetype] eq "application/vnd.oasis.opendocument.text-template"} "setMimetype: now a template"
ok {[rootMedia $p] eq "application/vnd.oasis.opendocument.text-template"} "setMimetype: manifest root updated too"
$p destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
