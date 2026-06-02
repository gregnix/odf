#!/usr/bin/env tclsh
## master-demo.tcl -- ODF master document (.odm).
## A master document is a normal office:text body whose content is mostly links
## to external sub-documents (one protected text:section > text:section-source
## each). odf::newMasterDoc sets the text-master media type; appendSubdocument
## adds the linked sections. The referenced .odt files are external siblings and
## are NOT embedded -- a reader (e.g. LibreOffice) loads them at open time.
## Output: out/master-demo.odm
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newMasterDoc]
set t   [odf::Text new $pkg]

# The master may carry its own content: a title and a table of contents that the
# reader fills from the headings of the linked chapters.
$t appendHeading "Project Handbook" 1
$t appendTOC -title "Contents" -levels 3

# Link three chapters and an appendix. Defaults: protected, filter writer8.
$t appendSubdocument Introduction intro.odt
$t appendSubdocument Architecture  architecture.odt
$t appendSubdocument Reference      reference.odt
# Import only the "Licensing" section from a shared legal document, editable.
$t appendSubdocument Licensing legal.odt -section-name Licensing -protected 0

$t flush
set path [$pkg save [file join $out master-demo.odm]]
$pkg destroy
puts "created $path"
