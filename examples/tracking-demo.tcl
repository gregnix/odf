#!/usr/bin/env tclsh
## tracking-demo.tcl -- change tracking (text:tracked-changes).
## Erzeugt tracking-demo.odt: eine eingefuegte (Bereich) und eine geloeschte
## (Punkt) Aenderung, je mit Autor/Datum und Kommentar.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]

$t appendHeading "Aenderungsverfolgung" 1

set p [$t appendParagraph "Der Vertrag gilt ab "]
$t addInsertion ins1 -author "Max Mustermann" -comment "Datum ergaenzt"
$t addChangeStart $p ins1
$t addText        $p "1. Juni 2026"
$t addChangeEnd   $p ins1
$t addText        $p "."

set p2 [$t appendParagraph "Hinweis: "]
$t addDeletion del1 -author "Max Mustermann" -content "veralteter Absatz" -comment "nicht mehr gueltig"
$t addChange      $p2 del1
$t addText        $p2 "siehe Anlage."

$t flush
set dst [file join $out tracking-demo.odt]
$pkg save $dst
puts "geschrieben: $dst  ([llength [$t changedRegions]] Aenderungen)"
$t destroy; $pkg destroy
