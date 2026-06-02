#!/usr/bin/env tclsh
## forms-all-demo.tcl -- jedes v0.46/0.47-Control einmal, beschriftet.
## Erzeugt out/forms-all-demo.odt. In LibreOffice Writer oeffnen und rendern.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
$pkg setMeta -title "Alle Formular-Controls"
set t [odf::Text new $pkg]
$t appendHeading "Formular-Controls" 1

set form [$t newForm -name "Alle"]
proc row {t form label} { return [$t appendParagraph $label] }

$t addFormText     $form [row $t $form "Text:      "] -name txt -value "Beispiel" -width 6cm
$t addFormTextarea $form [row $t $form "Mehrzeilig:"] -name area -value "Zeile 1" -width 6cm -height 2cm
$t addFormPassword $form [row $t $form "Passwort:  "] -name pw -echochar "*" -width 4cm
$t addFormNumber   $form [row $t $form "Zahl:      "] -name num -value 5 -min 0 -max 100 -width 3cm
$t addFormDate     $form [row $t $form "Datum:     "] -name dt -value 2026-05-27 -width 4cm
$t addFormTime     $form [row $t $form "Zeit:      "] -name tm -value 12:30:00 -width 3cm
$t addFormCombobox $form [row $t $form "Combobox:  "] {Alpha Beta Gamma} -name cb -value Beta -width 4cm
$t addFormListbox  $form [row $t $form "Listbox:   "] {Rot Gruen Blau} -name lb -selected 1 -dropdown 1 -width 4cm
$t addFormCheckbox $form [row $t $form ""] -name chk -label "Checkbox" -checked 1 -width 6cm
$t addFormRadio    $form [row $t $form ""] -name rg -label "Option A" -value a -checked 1 -width 6cm
$t addFormRadio    $form [row $t $form ""] -name rg -label "Option B" -value b -width 6cm
$t addFormLabel    $form [row $t $form ""] -name lbl -label "Fixed-Text-Label" -width 6cm
$t addFormButton   $form [row $t $form ""] -name btn -label "Button" -width 3cm

$t flush
set dst [file join $out forms-all-demo.odt]
$pkg save $dst
puts "geschrieben: $dst  ([llength [$t formControls $form]] Controls)"
$t destroy; $pkg destroy
