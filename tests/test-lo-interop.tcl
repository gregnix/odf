## tests/test-lo-interop.tcl  --  LibreOffice interop tests
##
## RT-Lesetests und strukturelle Diffs gegen das LibreOffice-Referenzkorpus
## unter nogit/docs/ref-lo/ods/ (gitignored; nicht im Repo). Skip-on-missing:
## wenn das Verzeichnis oder einzelne Dateien fehlen, wird die jeweilige
## Sektion klar uebersprungen statt zu failen. Der Korpus ist nicht Teil des
## Repos -- diese Tests laufen nur, wenn der Entwickler die Dateien lokal
## vorhaelt (siehe nogit/docs/10-lo-referenzkorpus.md).
##
## Was geprueft wird:
##   A) ref-formula-results.ods   -- 9 Sheets, ~34 Formeln; RT-Lesetest,
##                                   Stichproben einzelner Formeln + Sollwerte.
##   B) ref-validation.ods        -- 5 Sheets, 1 content-validation (val1);
##                                   RT-Lesetest, Schluesselattribute.
##   C) Strukturabgleich CV       -- odf erzeugt val1 mit denselben Parametern
##                                   wie LO und die wesentlichen Attribute /
##                                   Kind-Elemente werden semantisch verglichen
##                                   (nicht byte-equivalent: XML-Attribut-
##                                   Reihenfolge und &apos; vs ' sind hier
##                                   irrelevant).

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
package require odf::sheet
package require tdom

set pass 0; set fail 0; set skipped 0
proc ok {b m} {
    if {[uplevel 1 [list expr $b]]} {incr ::pass; puts "ok   $m"} \
    else                              {incr ::fail; puts "FAIL $m"}
}
proc skip {m} { incr ::skipped; puts "skip $m" }

set refdir [file join $base nogit docs ref-lo ods]
set f_formulas [file join $refdir ref-formula-results.ods]
set f_validate [file join $refdir ref-validation.ods]

# =============================================================================
# A) ref-formula-results.ods -- ofcalc soll-value corpus
# =============================================================================
puts "\n-- A) ref-formula-results.ods --"
if {![file exists $f_formulas]} {
    skip "A: ref-formula-results.ods not in $refdir"
} else {
    set pkg [odf::Package new]; $pkg load $f_formulas
    set sh  [odf::Sheet new $pkg]

    ok {[$pkg version] eq "1.4"}                       "A: file is ODF 1.4 (LO output)"

    set tables [$sh tables]
    ok {[llength $tables] >= 8}                        "A: sheets count >= 8 (got [llength $tables])"

    # Sammele alle Formel-Zellen ueber alle Sheets ein
    set total 0
    set perSheet [dict create]
    foreach tbl $tables {
        set name [$sh tableName $tbl]; set n 0
        foreach row [$sh rows $tbl] {
            foreach c [$sh cells $row] {
                if {[$sh cellHasFormula $c]} { incr n; incr total }
            }
        }
        dict set perSheet $name $n
    }
    ok {$total >= 30}                                  "A: total formulas >= 30 (got $total)"

    # Stichprobe: 01-arithmetic sollte mehrere Formeln tragen
    if {[dict exists $perSheet 01-arithmetic]} {
        set n1 [dict get $perSheet 01-arithmetic]
        ok {$n1 >= 5}                                  "A: 01-arithmetic has >= 5 formulas (got $n1)"
    } else { skip "A: sheet 01-arithmetic not present" }

    # Stichprobe: erste Formel-Zelle in 01-arithmetic hat einen of:= Praefix
    set first ""
    foreach tbl $tables {
        if {[$sh tableName $tbl] ne "01-arithmetic"} continue
        foreach row [$sh rows $tbl] {
            foreach c [$sh cells $row] {
                if {[$sh cellHasFormula $c]} { set first [$sh cellFormula $c]; break }
            }
            if {$first ne ""} break
        }
    }
    ok {[string match "of:=*" $first]}                 "A: formula uses of:= prefix (got '$first')"

    # Stichprobe: zu jeder Formel existiert ein cached value (LO speichert ihn
    # immer mit). Wir pruefen das per Sample, nicht erschoepfend.
    set withVal 0; set withoutVal 0
    foreach tbl $tables {
        foreach row [$sh rows $tbl] {
            foreach c [$sh cells $row] {
                if {![$sh cellHasFormula $c]} continue
                if {[$sh cellType $c] ne ""} { incr withVal } else { incr withoutVal }
            }
        }
    }
    ok {$withVal >= 25 && $withoutVal <= 5}            "A: most formulas carry cached value-type ($withVal w/, $withoutVal w/o)"

    $sh destroy; $pkg destroy
}

# =============================================================================
# B) ref-validation.ods -- content-validation reference
# =============================================================================
puts "\n-- B) ref-validation.ods --"
if {![file exists $f_validate]} {
    skip "B: ref-validation.ods not in $refdir"
} else {
    set pkg [odf::Package new]; $pkg load $f_validate
    set sh  [odf::Sheet new $pkg]

    ok {[$pkg version] eq "1.4"}                       "B: file is ODF 1.4 (LO output)"
    ok {[llength [$sh tables]] >= 5}                   "B: at least 5 categorised sheets"

    set vs [$sh contentValidations]
    ok {[dict size $vs] >= 1}                          "B: at least one content-validation defined"
    ok {[dict exists $vs val1]}                        "B: validation named 'val1' present"

    if {[dict exists $vs val1]} {
        set v [dict get $vs val1]
        ok {[dict get $v condition] eq "of:cell-content-is-in-list(\[.\$H\$1:.\$H\$4\])"} \
                                                       "B: val1 condition matches LO"
        ok {[dict get $v allow-empty] eq "true"}       "B: val1 allow-empty=true"
        ok {[dict get $v display-list] eq "unsorted"}  "B: val1 display-list=unsorted"
        ok {[dict get $v error-type] eq "stop"}        "B: val1 error-type=stop"
        ok {[dict get $v error-display] eq "true"}     "B: val1 error-display=true (LO sets it)"
        # base-cell-address with sheet qualifier (apos quoting transparent to reader)
        ok {[string match "*01-simple-list*A1*" [dict get $v base]]} \
                                                       "B: val1 base-cell-address contains sheet ref"
    }

    # val2-val5 reader probes -- skip per-validation if the corpus is reduced.
    # Each row: name, condition-substring (key OF function), expects-display-list.
    foreach {nm condFrag wantsList sheetFrag} {
        val2 "cell-content-is-whole-number"  0  "02-number-range"
        val3 "cell-content-is-date"          0  "03-date-validation"
        val4 "is-true-formula"               0  "04-custom-formula"
        val5 "cell-content-is-in-list"       1  "05-cross-sheet-list"
    } {
        if {![dict exists $vs $nm]} { skip "B: $nm not in corpus" ; continue }
        set v [dict get $vs $nm]
        ok {[string match "*$condFrag*" [dict get $v condition]]} \
                                                       "B: $nm condition contains '$condFrag'"
        ok {[dict get $v allow-empty] eq "true"}       "B: $nm allow-empty=true"
        ok {[dict get $v error-type]  eq "stop"}       "B: $nm error-type=stop"
        ok {[dict get $v error-display] eq "true"}     "B: $nm error-display=true"
        ok {[string match "*$sheetFrag*A1*" [dict get $v base]]} \
                                                       "B: $nm base on sheet '$sheetFrag'"
        if {$wantsList} {
            ok {[dict get $v display-list] eq "unsorted"} \
                                                       "B: $nm display-list=unsorted (dropdown)"
        } else {
            ok {[dict get $v display-list] eq ""}      "B: $nm no display-list (condition-only)"
        }
    }

    $sh destroy; $pkg destroy
}

# =============================================================================
# C) Strukturabgleich: odf vs LO fuer dieselbe CV-Definition
# =============================================================================
puts "\n-- C) CV structural diff (odf vs LO) --"
if {![file exists $f_validate]} {
    skip "C: needs ref-validation.ods"
} else {
    # LO-Original einlesen
    set pkgL [odf::Package new]; $pkgL load $f_validate
    set shL  [odf::Sheet new $pkgL]
    set vL   [dict get [$shL contentValidations] val1]

    # odf-Pendant aufbauen
    set pkgO [odf::newSheetDoc]; set shO [odf::Sheet new $pkgO]
    set t [$shO addTable "01-simple-list"]; $shO addColumns $t 8
    $shO addContentValidation val1 \
        -condition {of:cell-content-is-in-list([.$H$1:.$H$4])} \
        -allow-empty true -display-list unsorted \
        -base "'01-simple-list'.A1" \
        -error-type stop
    set vO [dict get [$shO contentValidations] val1]

    # Felder-Diff (semantisch, nicht byte-genau)
    foreach key {condition allow-empty display-list error-type error-display} {
        set a [dict get $vL $key]; set b [dict get $vO $key]
        ok {$a eq $b}                                  "C: $key matches LO ('$a' vs '$b')"
    }
    # base-cell-address: Reader liefert beidseitig den entquoteten Wert
    set baseL [dict get $vL base]; set baseO [dict get $vO base]
    ok {$baseL eq $baseO}                              "C: base-cell-address matches LO ('$baseL' vs '$baseO')"

    $shL destroy; $pkgL destroy; $shO destroy; $pkgO destroy

    # val5 -- cross-sheet list with $-prefixed external sheet reference.
    # Second structural diff to cover the other dropdown variant (display-list
    # present + condition referencing a foreign sheet). val5 is skipped if the
    # corpus does not contain it.
    set pkgL5 [odf::Package new]; $pkgL5 load $f_validate
    set shL5  [odf::Sheet new $pkgL5]
    set vsL5 [$shL5 contentValidations]
    if {![dict exists $vsL5 val5]} {
        skip "C: val5 not in corpus (cross-sheet diff)"
    } else {
        set v5L [dict get $vsL5 val5]
        set pkgO5 [odf::newSheetDoc]; set shO5 [odf::Sheet new $pkgO5]
        # both sheets must exist so the address is meaningful
        set t5a [$shO5 addTable "05-cross-sheet-list"]; $shO5 addColumns $t5a 1
        set t5b [$shO5 addTable "lookup-values"];        $shO5 addColumns $t5b 1
        $shO5 addContentValidation val5 \
            -condition {of:cell-content-is-in-list([$'lookup-values'.$A$1:.$A$5])} \
            -allow-empty true -display-list unsorted \
            -base "'05-cross-sheet-list'.A1" \
            -error-type stop
        set v5O [dict get [$shO5 contentValidations] val5]
        foreach key {condition allow-empty display-list error-type error-display} {
            set a [dict get $v5L $key]; set b [dict get $v5O $key]
            ok {$a eq $b}                              "C: val5 $key matches LO ('$a' vs '$b')"
        }
        ok {[dict get $v5L base] eq [dict get $v5O base]} \
                                                       "C: val5 base matches LO ('[dict get $v5L base]' vs '[dict get $v5O base]')"
        $shO5 destroy; $pkgO5 destroy
    }
    $shL5 destroy; $pkgL5 destroy
}

puts "\nPASS $pass   FAIL $fail   SKIP $skipped"
exit [expr {$fail ? 1 : 0}]
