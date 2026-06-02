## tests/run-all.tcl  --  collective runner for the odf library
##
## Runs each test against its matching fixtures (as a subprocess, so a crash or
## skip of one test does not affect the others), reads the "PASS n FAIL m"
## tally and sums up a total.
##
##   tclsh tests/run-all.tcl          ;# uses the same interpreter
##   tclsh9.0 tests/run-all.tcl

set here     [file normalize [file dirname [info script]]]
set fixtures [file join $here fixtures]
set tclsh    [info nameofexecutable]

# fixture list
set odts [lsort [glob -nocomplain -directory $fixtures *.odt]]

# plan: {testfile argument label}
set plan {}
lappend plan [list test-container.tcl [file join $fixtures deinedatei.odt] "Container/Manifest"]
lappend plan [list test-inline.tcl    [file join $fixtures deinedatei.odt] "Inline runs"]
foreach f $odts { lappend plan [list test-listtable.tcl $f "Lists/Tables: [file tail $f]"] }
lappend plan [list test-build.tcl     $fixtures "Builder (from scratch)"]
lappend plan [list test-meta.tcl      "" "Document metadata"]
lappend plan [list test-version.tcl   "" "ODF version (office:version)"]
lappend plan [list test-readsamples.tcl "" "Read real-world SDK docs (ODF 1.0)"]
lappend plan [list test-template.tcl   "" "Templates (.ott/.ots/.otg)"]
lappend plan [list test-master.tcl     "" "Master document (.odm) subdocuments"]
lappend plan [list test-chart.tcl      "" "Embedded objects + charts"]
lappend plan [list test-embed-sheet.tcl "" "Embedded spreadsheet (.ods in .odt)"]
lappend plan [list test-chart-doc.tcl   "" "Standalone chart document (.odc)"]
lappend plan [list test-style.tcl     "" "Write styles"]
lappend plan [list test-page.tcl      "" "Page layout"]
lappend plan [list test-pagesetup.tcl "" "Page setup (formats)"]
lappend plan [list test-pageprops.tcl "" "Page properties"]
lappend plan [list test-multipage.tcl "" "Multi-page"]
lappend plan [list test-tablestruct.tcl "" "Table structure"]
lappend plan [list test-tablecells.tcl "" "Table cell styles"]
lappend plan [list test-tablespan.tcl "" "Table cell spanning"]
lappend plan [list test-headerfooter.tcl "" "Header/footer"]
lappend plan [list test-fonts.tcl     "" "Font registration"]
lappend plan [list test-autostyle.tcl "" "Automatic Styles"]
lappend plan [list test-inline2.tcl   "" "Inline: links/breaks/tabs"]
lappend plan [list test-bookmark.tcl  "" "Bookmarks/cross-refs"]
lappend plan [list test-toc.tcl       "" "Table of contents"]
lappend plan [list test-admonition.tcl "" "Admonitions (Note/Tip/Caution/Warning)"]
lappend plan [list test-bibliography.tcl "" "Bibliography marks/index"]
lappend plan [list test-index.tcl     "" "Alphabetical index"]
lappend plan [list test-caption.tcl   "" "Captions + figure/table indexes"]
lappend plan [list test-fields.tcl    "" "Document fields"]
lappend plan [list test-dbfield.tcl   "" "Database / mail-merge fields"]
lappend plan [list test-base.tcl      "" "Database document (.odb file-based source)"]
lappend plan [list test-forms.tcl     "" "Forms (office:forms / form:form + controls)"]
lappend plan [list test-annotation.tcl "" "Annotations (office:annotation)"]
lappend plan [list test-tracking.tcl   "" "Change tracking (text:tracked-changes)"]
lappend plan [list test-formula.tcl   "" "Embedded math (math:math via draw:object)"]
lappend plan [list test-imagefit.tcl  "" "Image fit to page"]
lappend plan [list test-image.tcl "" "Images/frames"]
lappend plan [list test-section.tcl   "" "Sections"]
lappend plan [list test-sublist.tcl   "" "Nested lists"]
lappend plan [list test-liststyle.tcl "" "List styles (ordered/bullet)"]
lappend plan [list test-resolve.tcl   "" "Style resolution"]
lappend plan [list test-textframe.tcl "" "Absolute text frames"]
lappend plan [list test-line.tcl      "" "Lines/fold marks"]
lappend plan [list test-sheet.tcl     "" "Spreadsheet (ODS)"]
lappend plan [list test-draw.tcl      "" "Drawing (ODG)"]
lappend plan [list test-gaps.tcl      "" "Expected-missing / deliberate gaps"]
lappend plan [list test-lo-interop.tcl "" "LibreOffice interop (ref corpus)"]

set gp 0; set gf 0; set nrun 0; set nskip 0; set nerr 0
puts "=== odf Test-Suite ([file tail $tclsh]) ==="
foreach item $plan {
    lassign $item test arg label
    set code [catch {exec $tclsh [file join $here $test] $arg} out]
    # find the last PASS/FAIL line
    set p ""; set f ""
    foreach line [split $out \n] {
        if {[regexp {PASS\s+(\d+)\s+FAIL\s+(\d+)} $line -> a b]} { set p $a; set f $b }
    }
    if {$p ne ""} {
        incr gp $p; incr gf $f; incr nrun
        set tag [expr {$f == 0 ? "ok " : "FAIL"}]
        puts [format "  %-4s %-42s PASS %-3s FAIL %s" $tag $label $p $f]
    } elseif {[string match *skipped* $out]} {
        incr nskip
        puts [format "  %-4s %-42s (skipped)" "--" $label]
    } else {
        incr nerr
        puts [format "  %-4s %-42s (ERROR, exit=%s)" "ERR" $label $code]
        foreach line [lrange [split $out \n] end-2 end] { if {[string trim $line] ne ""} { puts "         $line" } }
    }
}
puts "-------------------------------------------------------------------"
puts [format "Tests: %d run, %d skipped, %d errors   |   PASS %d  FAIL %d" \
        $nrun $nskip $nerr $gp $gf]
exit [expr {($gf == 0 && $nerr == 0) ? 0 : 1}]
