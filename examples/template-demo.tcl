#!/usr/bin/env tclsh
## template-demo.tcl -- ODF templates (.ott/.ots/.otg).
## A template is structurally identical to its document; only the media type
## differs. odf::newTextTemplate / newSheetTemplate / newDrawTemplate build them;
## Package setMimetype is the underlying primitive.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

# A text template (.ott) with placeholder content.
set pkg [odf::newTextTemplate]
set t   [odf::Text new $pkg]
$t appendHeading "Briefvorlage" 1
$t appendParagraph "Sehr geehrte/r \[Name\],"
$t appendParagraph "\[Inhalt\]"
$t appendParagraph "Mit freundlichen Gruessen"
$t flush
set dst [file join $out template-demo.ott]
$pkg save $dst
puts "geschrieben: $dst  (mimetype: [$pkg mimetype])"
$t destroy; $pkg destroy
