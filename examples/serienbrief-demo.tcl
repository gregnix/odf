#!/usr/bin/env tclsh
## serienbrief-demo.tcl -- mail-merge template (Weg B: LibreOffice does the merge).
## Erzeugt serienbrief-demo.odt: eine Serienbrief-Vorlage mit Datenbank-Feldern
## (text:database-display) aus einer registrierten Datenquelle "Addresses".
## Die Daten (Tabelle/CSV) liegen ausserhalb -- kein .odb noetig. Bis eine
## Datenquelle "Addresses" in LibreOffice registriert ist, zeigen die Felder
## ihren gecachten Text; danach macht Writer den echten Seriendruck.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set src   Addresses
set table Recipients

set pkg [odf::newTextDoc]
$pkg setMeta -title "Serienbrief-Vorlage" -description "mail-merge template"
set t [odf::Text new $pkg]

# Anschriftenblock
set p [$t appendParagraph ""]
$t addDatabaseDisplay $p -source $src -table $table -column Title    -text "Frau"
$t addText $p " "
$t addDatabaseDisplay $p -source $src -table $table -column FirstName -text "Erika"
$t addText $p " "
$t addDatabaseDisplay $p -source $src -table $table -column LastName  -text "Mustermann"

set p [$t appendParagraph ""]
$t addDatabaseDisplay $p -source $src -table $table -column Street -text "Musterstrasse 1"
set p [$t appendParagraph ""]
$t addDatabaseDisplay $p -source $src -table $table -column Zip  -text "12345"
$t addText $p " "
$t addDatabaseDisplay $p -source $src -table $table -column City -text "Musterstadt"

# Datum (eingefroren auf Erzeugungszeit) + Anrede
set p [$t appendParagraph ""]
$t addText $p "Datum: "
$t addDate $p -value [clock format [clock seconds] -format %Y-%m-%d] -fixed true \
    -text [clock format [clock seconds] -format %Y-%m-%d]

set p [$t appendParagraph "Sehr geehrte/r "]
$t addDatabaseDisplay $p -source $src -table $table -column Title    -text "Frau"
$t addText $p " "
$t addDatabaseDisplay $p -source $src -table $table -column LastName -text "Mustermann"
$t addText $p ","

$t appendParagraph "vielen Dank fuer Ihr Interesse. Anbei die gewuenschten Unterlagen."
$t appendParagraph "Mit freundlichen Gruessen"

# Fusszeilen-artige Zeile: Seitenzahl
set p [$t appendParagraph "Seite "]
$t addPageNumber $p -format 1 -text "1"
$t addText $p " von "
$t addPageCount  $p -format 1 -text "1"

$t flush
set dst [file join $out serienbrief-demo.odt]
$pkg save $dst
puts "geschrieben: $dst  ([llength [$t databaseFields]] Merge-Felder)"
$t destroy; $pkg destroy
