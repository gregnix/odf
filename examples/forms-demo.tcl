#!/usr/bin/env tclsh
## forms-demo.tcl -- ein einfaches ODF-Formular (office:forms / form:form).
## Erzeugt out/forms-demo.odt: Anmeldeformular mit Text-, Listbox-, Checkbox-
## und Button-Controls. Jeder Control ist zweiteilig -- der logische form:*
## Eintrag in <form:form> (xml:id = die ID) und ein sichtbares
## <draw:control draw:control="ID"> im Textfluss. LibreOffice Writer zeigt die
## Controls; ueber Formular > Entwurfsmodus wird zwischen Bearbeiten und
## Ausfuellen umgeschaltet. Keine Datenbankbindung -- rein lokales Formular.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
$pkg setMeta -title "Anmeldeformular" -description "ODF form demo"
set t [odf::Text new $pkg]

$t appendHeading "Anmeldung zur Veranstaltung" 1
$t appendParagraph "Bitte fuellen Sie das Formular aus:"

set form [$t newForm -name "Anmeldung"]

set p [$t appendParagraph "Name:      "]
$t addFormText $form $p -name txtName -width 7cm -maxlength 60

set p [$t appendParagraph "E-Mail:    "]
$t addFormText $form $p -name txtMail -width 7cm -maxlength 80

set p [$t appendParagraph "Teilnahme: "]
$t addFormListbox $form $p {Vormittag Nachmittag Ganztags} \
    -name lstSlot -values {am pm full} -selected 2 -dropdown 1 -width 4cm

set p [$t appendParagraph ""]
$t addFormCheckbox $form $p -name chkNews -label "Newsletter abonnieren" -checked 0 -width 6cm
set p [$t appendParagraph ""]
$t addFormCheckbox $form $p -name chkAGB  -label "AGB akzeptiert"         -checked 0 -width 6cm

set p [$t appendParagraph ""]
$t addFormButton $form $p -name btnSubmit -label "Absenden" -width 3cm

$t flush
set dst [file join $out forms-demo.odt]
$pkg save $dst
puts "geschrieben: $dst  ([llength [$t formControls $form]] Controls in Form \"[$t formName $form]\")"
$t destroy; $pkg destroy
