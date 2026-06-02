#!/usr/bin/env tclsh
## forms-time-lo-demo.tcl -- LibreOffice-Kompatibilitaetsmodus fuer form:time.
## Erzeugt out/forms-time-lo.odt: ein Zeitfeld im lo-compat-Modus (ISO-Dauer
## PT12H30M0S), das LibreOffice anzeigt. ACHTUNG: bewusst NICHT odfvalidator-
## clean -- LOs Zeit-Wertformat ist kein gueltiges xsd:time. Der Strict-Modus
## (Default) schreibt HH:MM:SS und bleibt validator-clean, wird von LO aber nicht
## angezeigt. Umschalten via [$t formCompat lo] oder -lo-compat 1.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
set pkg [odf::newTextDoc]
$pkg setMeta -title "Zeitfeld LO-Kompat"
set t [odf::Text new $pkg]
$t formCompat lo
$t appendHeading "Zeitfeld (LO-Kompatibilitaetsmodus)" 1
set form [$t newForm -name "Zeit"]
$t addFormTime $form [$t appendParagraph "Uhrzeit: "] -name uhr -value 12:30:00 -width 3cm
$t flush
set dst [file join $out forms-time-lo.odt]
$pkg save $dst
puts "geschrieben: $dst (lo-compat: ISO-Dauer; NICHT validator-clean by design)"
$t destroy; $pkg destroy
