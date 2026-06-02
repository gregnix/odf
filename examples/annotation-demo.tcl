#!/usr/bin/env tclsh
## annotation-demo.tcl -- office:annotation (Anmerkungen) demo.
## Erzeugt annotation-demo.odt: ein Absatz mit Punkt-Anmerkung und ein Absatz
## mit Bereichs-Anmerkung (annotation + annotation-end).
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]

$t appendHeading "Anmerkungen-Demo" 1

set p1 [$t appendParagraph "Dieser Satz hat eine Anmerkung am Ende."]
$t addAnnotation $p1 "Bitte den Satz pruefen." -author "Max Mustermann" -initials "MM" -display true

set p2 [$t appendParagraph "Hier beginnt ein "]
$t addAnnotation    $p2 "Dieser Bereich ist markiert." -author "Max Mustermann" -name range1
$t addText          $p2 "markierter Bereich"
$t addAnnotationEnd $p2 range1
$t addText          $p2 " und endet hier."

$t flush
set dst [file join $out annotation-demo.odt]
$pkg save $dst
puts "geschrieben: $dst"
$t destroy; $pkg destroy
