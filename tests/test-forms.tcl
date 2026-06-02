set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pass 0; set fail 0
proc ok {b m} { if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} else {incr ::fail; puts "FAIL $m"} }

# ---- build a registration form ----
set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]
set form [$t newForm -name "Reg"]
set dcTxt [$t addFormText     $form [$t appendParagraph "Name: "] -name txtName -value "Max" -maxlength 40 -width 6cm]
set dcChk [$t addFormCheckbox $form [$t appendParagraph ""]        -name chkAGB -label "AGB" -checked 1]
set dcBtn [$t addFormButton   $form [$t appendParagraph ""]        -name btnOK  -label "OK"]
set firstId [$t controlId [lindex [$t formControls $form] 0]]
set dcLbl [$t addFormLabel    $form [$t appendParagraph ""]        -name lbl1   -label "Land" -for $firstId]
set dcLst [$t addFormListbox  $form [$t appendParagraph "Land: "] {DE AT CH} \
              -name lstLand -values {de at ch} -selected 1 -dropdown 1]

# ---- A) structure / readers ----
ok {[llength [$t forms]] == 1}        "A: one form"
ok {[$t formName $form] eq "Reg"}     "A: form name"
set ctrls [$t formControls $form]
ok {[llength $ctrls] == 5}            "A: five controls"
ok {[lmap c $ctrls {$t controlKind $c}] eq {text checkbox button fixed-text listbox}} "A: control kinds in order"
ok {[lsort [lmap c $ctrls {$t controlId $c}]] eq {ctrl1 ctrl2 ctrl3 ctrl4 ctrl5}}      "A: unique ids ctrl1..5"

# ---- B) binding draw:control <-> xml:id ----
ok {[$dcTxt getAttribute draw:control] eq [$t controlId [lindex $ctrls 0]]} "B: draw:control binds text id"
ok {[$dcTxt getAttribute text:anchor-type] eq "as-char"}                    "B: control anchored as-char"
ok {[$dcLst getAttribute draw:control] eq "ctrl5"}                          "B: draw:control binds listbox id"

# ---- C) per-control attributes ----
ok {[$t controlValue [lindex $ctrls 0]] eq "Max"}                       "C: text value"
ok {[[lindex $ctrls 0] getAttribute form:max-length ""] eq "40"}        "C: text max-length"
ok {[$t controlState [lindex $ctrls 1]] eq "checked"}                   "C: checkbox checked"
ok {[$t controlLabel [lindex $ctrls 1]] eq "AGB"}                       "C: checkbox label"
ok {[[lindex $ctrls 2] getAttribute form:button-type ""] eq "push"}     "C: button type push"
ok {[[lindex $ctrls 3] getAttribute form:for ""] eq $firstId}           "C: label for -> first control"
ok {[$t listboxOptions [lindex $ctrls 4]] eq {DE AT CH}}                "C: listbox options"
set opts [[lindex $ctrls 4] getElementsByTagName form:option]
ok {[[lindex $opts 1] getAttribute form:current-selected ""] eq "true"} "C: listbox selected idx 1"
ok {[[lindex $opts 0] getAttribute form:value ""] eq "de"}              "C: listbox option value"

# ---- D) serialized XML: namespace + placement ----
$t flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[string match {*xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"*} $xml]} "D: form: prefix bound on root"
ok {[string match {*xmlns:ooo="http://openoffice.org/2004/office"*} $xml]} "D: ooo: prefix bound (control-implementation QName)"
ok {[regexp {<office:text[^>]*><office:forms} $xml]}            "D: office:forms is first child of office:text"
ok {[string match {*<draw:control draw:control="ctrl1"*} $xml]} "D: draw:control in body"
ok {[string match {*<draw:control *draw:style-name="FormCtl"*} $xml]}            "D: draw:control carries graphic style"
ok {[string match {*<style:style style:name="FormCtl" style:family="graphic"*} $xml]} "D: FormCtl graphic style defined"
set wf 1; if {[catch {set dd [dom parse $xml]}]} {set wf 0} else {$dd delete}
ok {$wf} "D: content.xml well-formed"

# ---- E) validation ----
ok {[catch {$t addFormText $form [$t appendParagraph ""] -nope x}]} "E: unknown option rejected"

# ---- F) save + reload round-trip ----
set dst [file join $out forms-test.odt]
$pkg save $dst
$t destroy; $pkg destroy
set p2 [odf::Package new $dst]
set t2 [odf::Text new $p2]
ok {[llength [$t2 forms]] == 1}                          "F: form survives reload"
set f2 [lindex [$t2 forms] 0]
ok {[llength [$t2 formControls $f2]] == 5}               "F: controls survive reload"
ok {[lmap c [$t2 formControls $f2] {$t2 controlKind $c}] eq {text checkbox button fixed-text listbox}} "F: kinds survive reload"
ok {[$t2 controlState [lindex [$t2 formControls $f2] 1]] eq "checked"} "F: checkbox state survives reload"
$t2 destroy; $p2 destroy

# ---- G) new controls (textarea/password/number/date/time/combobox/radio) ----
set pkg [odf::newTextDoc]
set t [odf::Text new $pkg]
set f [$t newForm -name "V2"]
$t addFormTextarea $f [$t appendParagraph ""] -name txtNote -value "Hallo" -height 2cm
$t addFormPassword $f [$t appendParagraph ""] -name pw -echochar "*"
$t addFormNumber   $f [$t appendParagraph ""] -name num -value 3 -min 0 -max 10
$t addFormDate     $f [$t appendParagraph ""] -name dt  -value 2026-05-27
$t addFormTime     $f [$t appendParagraph ""] -name tm  -value 12:30:00
$t addFormCombobox $f [$t appendParagraph ""] {Alpha Beta Gamma} -name cb -value Beta
$t addFormRadio    $f [$t appendParagraph ""] -name grp -label "Ja"   -value yes -checked 1
$t addFormRadio    $f [$t appendParagraph ""] -name grp -label "Nein" -value no
set gc [$t formControls $f]
ok {[lmap c $gc {$t controlKind $c}] eq {textarea password formatted-text date time combobox radio radio}} "G: new control kinds (number -> formatted-text, LO numeric field)"
ok {[[lindex $gc 0] getAttribute form:control-implementation ""] ne ""}                "G: control-implementation set"
ok {[llength [[lindex $gc 0] getElementsByTagName form:property]] >= 1}                 "G: DefaultControl property present"
ok {[[lindex $gc 2] getAttribute form:control-implementation ""] eq "ooo:com.sun.star.form.component.NumericField"} "G: numeric field impl = NumericField"
ok {[[lindex $gc 0] getAttribute form:current-value ""] eq "Hallo"}  "G: textarea value"
ok {[[lindex $gc 1] getAttribute form:echo-char ""] eq "*"}          "G: password echo-char"
ok {[[lindex $gc 2] getAttribute form:value ""] eq "3" && [[lindex $gc 2] getAttribute form:max-value ""] eq "10"} "G: number value/max"
ok {[[lindex $gc 3] getAttribute form:value ""] eq "2026-05-27"}     "G: date value"
ok {[[lindex $gc 4] getAttribute form:value ""] eq "12:30:00"}       "G: time value"
ok {[$t comboboxItems [lindex $gc 5]] eq {Alpha Beta Gamma}}         "G: combobox items"
ok {[[lindex $gc 5] getAttribute form:current-value ""] eq "Beta"}   "G: combobox current-value"
ok {[$t controlName [lindex $gc 6]] eq "grp" && [$t controlName [lindex $gc 7]] eq "grp"} "G: radio group shares name"
ok {[[lindex $gc 6] getAttribute form:current-selected ""] eq "true"} "G: radio 1 selected"
$t flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[regexp -all {<draw:control } $xml] == 8}            "G: 8 draw:control shapes"
ok {[regexp -all {draw:style-name="FormCtl"} $xml] == 8} "G: all carry FormCtl style"
set wf 1; if {[catch {set dd [dom parse $xml]}]} {set wf 0} else {$dd delete}
ok {$wf} "G: content.xml well-formed"
$pkg save [file join $out forms-v2.odt]
$t destroy; $pkg destroy

# ---- H) form:time strict (xsd:time) vs LO-compat (ISO duration) ----
set pkg [odf::newTextDoc]; set t [odf::Text new $pkg]; set f [$t newForm]
$t addFormTime $f [$t appendParagraph ""] -name t1 -value 12:30:00
set c1 [lindex [$t formControls $f] 0]
ok {[$c1 getAttribute form:value ""] eq "12:30:00"}             "H: strict time = xsd:time (default)"
$t addFormTime $f [$t appendParagraph ""] -name t2 -value 12:30:00 -lo-compat 1
set c2 [lindex [$t formControls $f] 1]
ok {[$c2 getAttribute form:value ""] eq "PT12H30M0S"}           "H: per-call -lo-compat = ISO duration"
ok {[$t formCompat] eq "strict"}                                "H: default mode strict"
$t formCompat lo
ok {[$t formCompat] eq "lo"}                                    "H: mode set to lo"
$t addFormTime $f [$t appendParagraph ""] -name t3 -value 09:05:00
set c3 [lindex [$t formControls $f] 2]
ok {[$c3 getAttribute form:value ""] eq "PT9H5M0S"}             "H: document lo mode = ISO duration"
ok {[catch {$t formCompat bogus}]}                              "H: invalid mode rejected"
$t destroy; $pkg destroy

# ---- I) generic form:property API + hidden control + id collision fix ----
set pkg [odf::newTextDoc]; set t [odf::Text new $pkg]; set f [$t newForm]
set h [$t addFormHidden $f -name secret -value 42]
ok {[$t controlKind $h] eq "hidden"}              "I: hidden control kind"
ok {[$h getAttribute form:value ""] eq "42"}      "I: hidden value"
$t addFormText $f [$t appendParagraph ""] -name txt
ok {[lsort [lmap c [$t formControls $f] {$t controlId $c}]] eq {ctrl1 ctrl2}} "I: ids unique across hidden+visual (no collision)"
set lb [$t addFormListbox $f [$t appendParagraph ""] {Rot Gruen Blau} -name lb]
set lbctrl [lindex [$t formControls $f] 2]
$t controlProperty     $lbctrl Foo bar
$t controlListProperty $lbctrl StringItemList {Rot Gruen Blau}
ok {[$t controlPropertyValue $lbctrl Foo] eq "bar"}  "I: controlProperty round-trip"
$t flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[regexp -all {<form:list-value office:string-value=} $xml] == 3} "I: list-property values emitted"
ok {[regexp {<form:listbox[^>]*><form:properties>} $xml]}            "I: form:properties stays first child of control"
set wf 1; if {[catch {set dd [dom parse $xml]}]} {set wf 0} else {$dd delete}
ok {$wf} "I: content.xml well-formed"
$pkg save [file join $out forms-prop.odt]
$t destroy; $pkg destroy

# ---- J) DB-bound forms foundation: formDatasource / controlBind / controlPlace ----
set pkg [odf::newTextDoc]; set t [odf::Text new $pkg]
set f [$t newForm -name "Reg"]
ok {[$f getAttribute form:control-implementation ""] eq "ooo:com.sun.star.form.component.Form"} \
                                                            "J: newForm sets form:control-implementation"
$t formDatasource $f -datasource "colalldb" -command-type table -command "colors" \
    -apply-filter 1 -allow-inserts 1 -allow-updates 1 -allow-deletes 0
ok {[$f getAttribute form:datasource ""]    eq "colalldb"}  "J: form:datasource"
ok {[$f getAttribute form:command ""]       eq "colors"}    "J: form:command"
ok {[$f getAttribute form:command-type ""]  eq "table"}     "J: form:command-type"
ok {[$f getAttribute form:apply-filter ""]  eq "true"}      "J: form:apply-filter"
ok {[$f getAttribute form:allow-inserts ""] eq "true"}      "J: form:allow-inserts true"
ok {[$f getAttribute form:allow-deletes ""] eq "false"}     "J: form:allow-deletes false"
set dcText [$t addFormText $f [$t appendParagraph "Name: "] -name txtName]
$t controlBind  $dcText -data-field "NAME"
set lc [$t controlLogical $dcText]
ok {$lc ne "" && [$lc getAttribute form:data-field ""] eq "NAME"}  "J: controlBind data-field on logical control"
# form:validation is schema-OK only on form:formatted-text -- strict-skipped elsewhere
$t controlBind $dcText -validation 1
ok {[$lc getAttribute form:validation ""] eq ""}            "J: validation skipped in strict mode on form:text"
set dcNum [$t addFormNumber $f [$t appendParagraph "Menge: "] -name num -value 1]
$t controlBind $dcNum -validation 1
ok {[[$t controlLogical $dcNum] getAttribute form:validation ""] eq "true"} \
                                                            "J: validation emitted in strict on form:formatted-text"
$t controlPlace $dcText -anchor paragraph -x 2cm -y 3cm -z-index 1 -width 5cm
ok {[$dcText getAttribute text:anchor-type ""] eq "paragraph"} "J: controlPlace anchor=paragraph"
ok {[$dcText getAttribute svg:x ""]            eq "2cm"}    "J: controlPlace x"
ok {[$dcText getAttribute svg:y ""]            eq "3cm"}    "J: controlPlace y"
ok {[$dcText getAttribute draw:z-index ""]     eq "1"}      "J: controlPlace z-index"
ok {[$dcText getAttribute draw:style-name ""]  eq "FormCtlP"} "J: paragraph anchor swaps to FormCtlP"
$t flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[string match {*style:name="FormCtlP"*style:vertical-pos="from-top"*style:vertical-rel="paragraph"*} $xml]} \
                                                            "J: FormCtlP style defined for paragraph positioning"
set wf 1; if {[catch {set dd [dom parse $xml]}]} {set wf 0} else {$dd delete}
ok {$wf}                                                    "J: content.xml well-formed"
$pkg save [file join $out forms-db.odt]
$t destroy; $pkg destroy

# Separately: form:input-required is a LO extension -- gated on formCompat.
set pkg2 [odf::newTextDoc]; set t2 [odf::Text new $pkg2]; set f2 [$t2 newForm]
set dc2 [$t2 addFormText $f2 [$t2 appendParagraph ""] -name x]
$t2 controlBind $dc2 -input-required 1
set lc2 [$t2 controlLogical $dc2]
ok {[$lc2 getAttribute form:input-required ""] eq ""}       "J: input-required skipped in strict mode (LO extension)"
$t2 formCompat lo
$t2 controlBind $dc2 -input-required 1
ok {[$lc2 getAttribute form:input-required ""] eq "true"}   "J: input-required emitted in lo-compat mode"
$t2 destroy; $pkg2 destroy

# ---- K) listbox + combobox source binding (slice 2 of DB-bound forms) ----
set pkg [odf::newTextDoc]; set t [odf::Text new $pkg]
set f [$t newForm -name "Recipients"]
$t formDatasource $f -datasource "addressdb" -command-type table -command "Recipients" -apply-filter 1

set lb [$t addFormListbox $f [$t appendParagraph "Last name: "] {} -name lbLast]
$t controlBind $lb -data-field "LastName" -list-source-type sql \
    -list-source {SELECT "LastName", "LastName" FROM "Recipients"} \
    -bound-column 1 -size 20
set lbctrl [$t controlLogical $lb]
ok {[$lbctrl getAttribute form:list-source-type ""] eq "sql"}        "K: listbox list-source-type"
ok {[string match {SELECT*Recipients*} [$lbctrl getAttribute form:list-source ""]]} "K: listbox list-source"
ok {[$lbctrl getAttribute form:bound-column ""] eq "1"}              "K: listbox bound-column"
ok {[$lbctrl getAttribute form:size ""] eq "20"}                     "K: listbox size"
$t controlListProperty $lbctrl DefaultSelection {0} float

set cb [$t addFormCombobox $f [$t appendParagraph "First name: "] {} -name cbFirst]
$t controlBind $cb -list-source-type sql \
    -list-source {SELECT DISTINCT "FirstName" FROM "Recipients"} \
    -size 20 -auto-complete 1 -convert-empty-to-null 1
set cbctrl [$t controlLogical $cb]
ok {[$cbctrl getAttribute form:list-source-type ""] eq "sql"}        "K: combobox list-source-type"
ok {[$cbctrl getAttribute form:auto-complete ""] eq "true"}          "K: combobox auto-complete"
ok {[$cbctrl getAttribute form:convert-empty-to-null ""] eq "true"}  "K: combobox convert-empty-to-null"

$t flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[regexp {<form:list-property form:property-name="DefaultSelection" office:value-type="float"><form:list-value office:value="0"/></form:list-property>} $xml]} \
                                                                     "K: DefaultSelection populated with index 0"
$pkg save [file join $out forms-list.odt]
$t destroy; $pkg destroy

# ---- L) number-format data styles + Text property (slice 3 of DB-bound forms) ----
set pkg [odf::newTextDoc]; set t [odf::Text new $pkg]

$t defineTimeStyle   "C60"    -format "HH:mm"
$t defineDateStyle   "DateDE" -format "dd.MM.yyyy"
$t defineNumberStyle "Money"  -decimals 2 -grouping 1

ok {[lsearch -exact [$t timeStyles]   C60]    >= 0}                  "L: defineTimeStyle listed"
ok {[lsearch -exact [$t dateStyles]   DateDE] >= 0}                  "L: defineDateStyle listed"
ok {[lsearch -exact [$t numberStyles] Money]  >= 0}                  "L: defineNumberStyle listed"

set f [$t newForm]
set dcTime [$t addFormTime $f [$t appendParagraph "Uhrzeit: "] -name uhr -value "12:30:00"]
ok {[$t controlPropertyValue [$t controlLogical $dcTime] Text] eq "12:30:00"} \
                                                                     "L: addFormTime sets Text property for LO display"
$t controlPlace $dcTime -data-style C60
ok {[$dcTime getAttribute draw:style-name ""] eq "FormCtl_C60"}      "L: controlPlace -data-style creates FormCtl_C60 variant"

$t flush
set xml [encoding convertfrom utf-8 [$pkg part content.xml]]
ok {[string match {*<number:time-style style:name="C60">*<number:hours number:style="long"/>*<number:text>:</number:text>*<number:minutes number:style="long"/>*</number:time-style>*} $xml]} \
                                                                     "L: time-style structure: HH:mm"
ok {[string match {*<number:date-style style:name="DateDE">*<number:day number:style="long"/>*<number:month number:style="long"/>*<number:year number:style="long"/>*</number:date-style>*} $xml]} \
                                                                     "L: date-style structure: dd.MM.yyyy"
ok {[string match {*<number:number-style style:name="Money">*number:decimal-places="2"*number:grouping="true"*} $xml]} \
                                                                     "L: number-style decimals + grouping"
ok {[string match {*<style:style style:name="FormCtl_C60" style:family="graphic" style:data-style-name="C60">*} $xml]} \
                                                                     "L: variant graphic style with data-style-name"
ok {[string match {*<form:property form:property-name="Text" office:value-type="string" office:string-value="12:30:00"/>*} $xml]} \
                                                                     "L: Text UNO property emitted on form:time"
$pkg save [file join $out forms-fmt.odt]
$t destroy; $pkg destroy

# ---- M) controlPlace -x/-y guard (F2) + controlListPropertyValue symmetry (0.54) ----
set pkg [odf::newTextDoc]; set t [odf::Text new $pkg]; set f [$t newForm]
set dc [$t addFormText $f [$t appendParagraph ""] -name x]
ok {[catch {$t controlPlace $dc -x 2cm}]}                            "M: -x without -anchor paragraph errors"
$t controlPlace $dc -anchor paragraph -x 2cm -y 3cm
ok {[$dc getAttribute text:anchor-type ""] eq "paragraph"}           "M: anchor=paragraph set"
ok {[$dc getAttribute svg:x ""] eq "2cm"}                            "M: x set"
$t controlPlace $dc -x 4cm
ok {[$dc getAttribute svg:x ""] eq "4cm"}                            "M: subsequent -x OK once anchor is paragraph"
$t controlPlace $dc -anchor as-char
ok {[catch {$t controlPlace $dc -x 5cm}]}                            "M: -x errors again after anchor reset to as-char"

set lb [$t addFormListbox $f [$t appendParagraph ""] {} -name lb]
set lbctrl [$t controlLogical $lb]
$t controlListProperty $lbctrl Choices {Rot Gruen Blau}
ok {[$t controlListPropertyValue $lbctrl Choices] eq {Rot Gruen Blau}} "M: list-property string list round-trip"
$t controlListProperty $lbctrl DefaultSelection {0 2} float
ok {[$t controlListPropertyValue $lbctrl DefaultSelection] eq {0 2}}   "M: list-property float list round-trip"
ok {[$t controlListPropertyValue $lbctrl Missing] eq ""}               "M: list-property missing returns ''"
$t destroy; $pkg destroy

puts "\nPASS $pass   FAIL $fail"
exit [expr {$fail ? 1 : 0}]
