#!/usr/bin/env tclsh
## base-demo.tcl -- self-contained mail-merge package via odf::base + odf::text.
## Erzeugt out/mailmerge/ mit:
##   Recipients.csv            die Daten
##   db/Addresses.odb          die Datenquelle (odf::base, file-based, href "../")
##   serienbrief.odt           die Vorlage (text:database-display -> Addresses/Recipients)
## Layout wie von LibreOffice erwartet: die .odb liegt in db/, ihr href "../"
## zeigt auf den Ordner mit der CSV. Tabellenname = Dateiname ohne Endung
## ("Recipients"). Danach in LO die .odb als "Addresses" anmelden und mergen --
## kein Datenbank-Assistent mehr noetig.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out mailmerge]
file mkdir [file join $out db]
package require odf::base
package require odf::text

set src   Addresses
set table Recipients

# 1) data
set rows {
    {Frau Erika  Mustermann "Musterstrasse 1"  12345 Musterstadt}
    {Herr Max    Beispiel   "Beispielweg 7"    54321 Beispielhausen}
    {Frau Anna   Schmidt    "Hauptstrasse 22"  67890 Musterdorf}
}
set cols {Title FirstName LastName Street Zip City}
set f [open [file join $out Recipients.csv] w]
fconfigure $f -encoding utf-8
puts $f [join $cols ,]
foreach r $rows { puts $f [join $r ,] }
close $f

# 2) data source (.odb) -- points one level up (../) to the CSV folder
set odb [odf::newBaseDoc -href ../ -extension csv -media-type text/csv]
$odb save [file join $out db Addresses.odb]
$odb destroy

# 3) template (.odt) with merge fields against the registered source
set pkg [odf::newTextDoc]
$pkg setMeta -title "Serienbrief"
set t [odf::Text new $pkg]
set p [$t appendParagraph "Sehr geehrte/r "]
$t addDatabaseDisplay $p -source $src -table $table -column Title    -text "Frau"
$t addText $p " "
$t addDatabaseDisplay $p -source $src -table $table -column LastName -text "Mustermann"
$t addText $p ","
$t appendParagraph "anbei die gewuenschten Unterlagen."
set p [$t appendParagraph "Anschrift: "]
$t addDatabaseDisplay $p -source $src -table $table -column Street -text "Musterstrasse 1"
$t addText $p ", "
$t addDatabaseDisplay $p -source $src -table $table -column Zip  -text "12345"
$t addText $p " "
$t addDatabaseDisplay $p -source $src -table $table -column City -text "Musterstadt"
$t flush
$pkg save [file join $out serienbrief.odt]
$t destroy; $pkg destroy

puts "geschrieben nach: $out"
puts "  Recipients.csv, db/Addresses.odb, serienbrief.odt"
puts "In LibreOffice: db/Addresses.odb als \"Addresses\" anmelden, serienbrief.odt oeffnen, mergen."
