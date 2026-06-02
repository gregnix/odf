#!/usr/bin/env tclsh
## formula-demo.tcl -- embedded MathML formulas (math:math via draw:object).
## Inline form: draw:frame > draw:object > math:math, no sub-document/manifest.
set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t appendHeading "Eingebettete Formeln" 1

set p [$t appendParagraph "Einstein: "]
$t addFormula $p {<mrow><mi>E</mi><mo>=</mo><mi>m</mi><msup><mi>c</mi><mn>2</mn></msup></mrow>}
$t addText $p "."

set p2 [$t appendParagraph "Pythagoras: "]
$t addFormula $p2 {<mrow><msup><mi>a</mi><mn>2</mn></msup><mo>+</mo><msup><mi>b</mi><mn>2</mn></msup><mo>=</mo><msup><mi>c</mi><mn>2</mn></msup></mrow>}
$t addText $p2 "."

set p3 [$t appendParagraph "Bruch: "]
$t addFormula $p3 {<mfrac><mrow><mi>a</mi><mo>+</mo><mi>b</mi></mrow><mn>2</mn></mfrac>}

$t flush
set dst [file join $out formula-demo.odt]
$pkg save $dst
puts "geschrieben: $dst  ([llength [$t formulas]] Formeln)"
$t destroy; $pkg destroy
