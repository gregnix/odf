#!/usr/bin/env tclsh
## toc-demo.tcl -- a full table of contents.
## appendTOC builds the field (clickable entry templates per level); fillTOC then
## populates the index-body from the document's headings, so the entries are
## visible immediately (a consumer can still regenerate page numbers with F9).
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]

set toc [$t appendTOC -title "Inhaltsverzeichnis" -levels 3]

$t appendHeading "Einleitung" 1
$t appendParagraph "Worum es geht."
$t appendHeading "Grundlagen" 1
$t appendHeading "Begriffe" 2
$t appendParagraph "Definitionen."
$t appendHeading "Vertiefung" 2
$t appendHeading "Zusammenfassung" 1

$t fillTOC $toc

$t flush
set dst [file join $out toc-demo.odt]
$pkg save $dst
puts "geschrieben: $dst  (TOC: [$t tableOfContents])"
$t destroy; $pkg destroy
