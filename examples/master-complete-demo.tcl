#!/usr/bin/env tclsh
## master-complete-demo.tcl -- a COMPLETE master document (.odm).
## Unlike master-demo.tcl (which only links names), this generates the master
## AND every linked chapter as a real .odt, all written as siblings into one
## directory. Open out/master-complete/handbook.odm in LibreOffice: because the
## chapter files sit next to it, the linked sections resolve and the whole book
## assembles. The hrefs are relative filenames, so the folder is portable.
## Output: out/master-complete/  (handbook.odm + chapter-*.odt)
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out master-complete]; file mkdir $out
package require odf::text

# ---- the chapters: real, standalone .odt files ----
# {filename  title  {paragraph ...}}
set chapters {
    {chapter-intro.odt     "Introduction"
        {"This handbook is assembled from independent chapter documents."
         "Each chapter is a normal .odt that can be edited on its own."}}
    {chapter-install.odt   "Installation"
        {"Unpack the archive and add the module directory to the Tcl module path."
         "Run the test suite to confirm the environment is set up correctly."}}
    {chapter-usage.odt     "Usage"
        {"Create a document, append content, flush, then save the package."
         "The same builder serves text, spreadsheet and drawing documents."}}
    {chapter-appendix.odt  "Appendix: Licensing"
        {"The library is distributed under its repository licence."}}
}

foreach ch $chapters {
    lassign $ch fn title paras
    set pkg [odf::newTextDoc]
    set t   [odf::Text new $pkg]
    $t appendHeading $title 1
    foreach p $paras { $t appendParagraph $p }
    $t flush
    $pkg save [file join $out $fn]
    $pkg destroy
}

# ---- the master document linking those chapters ----
set mpkg [odf::newMasterDoc]
set mt   [odf::Text new $mpkg]
$mt appendHeading "Project Handbook" 1
$mt appendParagraph "A master document linking the chapters in this folder."
$mt appendTOC -title "Contents" -levels 3
foreach ch $chapters {
    lassign $ch fn title paras
    # section name from the title (no spaces/colons), href = the sibling file
    set secname [string map {{ } _ : ""} $title]
    $mt appendSubdocument $secname $fn
}
$mt flush
set master [file join $out handbook.odm]
$mpkg save $master
$mpkg destroy

puts "created $master"
puts "linked chapters:"
foreach ch $chapters { puts "  [lindex $ch 0]" }
