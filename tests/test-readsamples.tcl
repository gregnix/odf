set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
set fx  [file join $base tests fixtures sdk]
# Round-trips of these FOREIGN ODF-1.0 files go into a throwaway temp dir, never
# into out/: the StarOffice 8 sources use the legacy OOo manifest namespace and
# are not conformant to a strict validator, so their faithful pass-through copies
# must not look like odf products under out/.
set rtdir [file join $base tests .readsamples-rt]; file mkdir $rtdir
package require odf
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# Real-world SDK documents (StarOffice 8 / OOo 680, ODF 1.0). Read + pass-through.
# {file expected-version type}
set cases {
    {index.odt                      1.0 text}
    {inserting_bookmarks.odt        1.0 text}
    {burger_factory.odt             1.0 text}
    {TextTemplateWithUserFields.odt 1.0 text}
    {ToDo.ods                       1.0 other}
    {importexportofasciifiles.odg   1.0 other}
    {SimplePresentation.odp         1.0 other}
}

foreach c $cases {
    lassign $c name ver type
    set f [file join $fx $name]
    # A) loads + reads its declared version (pass-through, no rewrite)
    set p [odf::Package new $f]
    ok {[$p version] eq $ver}                 "$name: version $ver read"
    ok {[llength [$p parts]] > 0}             "$name: has parts"
    # B) text documents classify into blocks
    if {$type eq "text"} {
        set t [odf::Text new $p]
        ok {[llength [$t blocks]] > 0}        "$name: blocks classified"
        $t destroy
    }
    # C) round-trip: save + reload keeps the version (pass-through)
    set dst [file join $rtdir "rt-$name"]
    $p save $dst
    $p destroy
    set p2 [odf::Package new $dst]
    ok {[$p2 version] eq $ver}                "$name: version survives round-trip"
    $p2 destroy
}

# D) pass-through of an unmodelled area: index.odt carries office:forms on the
#    body level; the round-tripped copy must still contain it verbatim.
set rt [file join $rtdir rt-index.odt]
set p [odf::Package new $rt]
set content [encoding convertfrom utf-8 [$p part content.xml]]
ok {[string match {*office:forms*} $content]} "index.odt: office:forms preserved (pass-through)"
$p destroy

file delete -force $rtdir

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
