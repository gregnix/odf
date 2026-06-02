#!/usr/bin/env tclsh
## admonition-demo.tcl -- Note/Tip/Caution/Warning callouts via appendAdmonition.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t appendHeading "Admonitions" 1
$t appendParagraph "Die vier Callout-Arten:"
$t appendAdmonition note    "Everything you send to a forum is publicly archived."
$t appendAdmonition tip     "Designing with LibreOffice is about layout, not every feature."
$t appendAdmonition caution "Saving in another format may lose some formatting."
$t appendAdmonition warning "This action cannot be undone."
$t flush
set dst [file join $out admonition-demo.odt]
$pkg save $dst
puts "geschrieben: $dst  ([llength [$t admonitions]] Admonitions)"
$t destroy; $pkg destroy
