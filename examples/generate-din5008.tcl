## generate-din5008.tcl  --  Demo: DIN 5008 business letter as ODT (with frames)
##
## Address block and date/info line are page-anchored text frames
## (window-envelope exact). The top page margin forms the DIN letterhead zone:
## the flowing text (subject/salutation/body/closing) starts below; the frames
## "float" page-anchored in the top zone.
##
## Usage:  tclsh generate-din5008.tcl   ->  out/din5008.odt

::tcl::tm::path add [file dirname [file dirname [file normalize [info script]]]]
package require odf
package require odf::text
package require odf::style

# ---------------------------------------------------------------- letter data
set sender   "Max Mustermann \u00b7 Musterstra\u00dfe 1 \u00b7 12345 Musterstadt"
set recipient {
    "Firma Beispiel GmbH"
    "Frau Erika Beispiel"
    "Beispielweg 12"
    "12345 Musterstadt"
}
set city        "Musterstadt"
set date      "24. Mai 2026"
set subject    "Angebot Nr. 2026-014 \u2013 Wartungsvertrag"
set salutation     "Sehr geehrte Frau Beispiel,"
set bodyParagraphs {
    "vielen Dank f\u00fcr Ihre Anfrage vom 18. Mai 2026. Gerne unterbreiten wir Ihnen das gew\u00fcnschte Angebot zu einem j\u00e4hrlichen Wartungsvertrag f\u00fcr Ihre Anlage."
    "Die Konditionen entnehmen Sie bitte der beigef\u00fcgten Aufstellung. Das Angebot ist bis zum 30. Juni 2026 g\u00fcltig. Bei Beauftragung bis zum 15. Juni gew\u00e4hren wir einen Fr\u00fchbucherrabatt von 5 %."
    "F\u00fcr R\u00fcckfragen stehen wir Ihnen jederzeit gern zur Verf\u00fcgung."
}
set closing      "Mit freundlichen Gr\u00fc\u00dfen"
set name       "Max Mustermann"

# ---------------------------------------------------- document + page layout
set pkg [odf::newTextDoc]

set s [odf::Styles new $pkg]
# A4: left 2.5cm, right 2cm, bottom 2cm; top 9.5cm = DIN letterhead zone
# (address block/date sit as page-anchored frames in this zone)
$s defineStandardPage {fo:page-width 21cm fo:page-height 29.7cm \
        fo:margin-left 2.5cm fo:margin-right 2cm fo:margin-top 9.5cm \
        fo:margin-bottom 2cm style:print-orientation portrait}
$s defineParagraph Sender  -text {fo:font-size 8pt}
$s defineParagraph Address -text {fo:font-size 11pt}
$s defineParagraph DateRight    -text {fo:font-size 11pt} -paragraph {fo:text-align end}
$s defineParagraph Subject   -text {fo:font-size 11pt fo:font-weight bold} \
                             -paragraph {fo:margin-bottom 0.42cm}
$s defineParagraph Body      -text {fo:font-size 11pt} -paragraph {fo:margin-bottom 0.30cm}
$s flush
$s destroy

# ----------------------------------------------------------------- content
set t [odf::Text new $pkg]

# borderless, page-relative graphic style for the frames
$t defineAutoGraphic FrameClear {draw:stroke none draw:fill none fo:padding 0cm \
        fo:border none style:wrap run-through style:run-through foreground \
        style:vertical-pos from-top style:vertical-rel page \
        style:horizontal-pos from-left style:horizontal-rel page}

# flowing text (starts at 9.5cm) -- first, so the frames anchor to it
$t appendParagraph $subject Subject
$t appendParagraph $salutation Body
foreach a $bodyParagraphs { $t appendParagraph $a Body }
$t appendParagraph $closing Body
$t appendParagraph "" Body
$t appendParagraph "" Body
$t appendParagraph $name Body

# address block: page-anchored at 20mm / 45mm, 85mm wide (window envelope)
set addressLines [list [list $sender Sender]]
foreach line $recipient { lappend addressLines [list $line Address] }
$t addTextFrame AddressBlock 2.0cm 4.5cm 8.5cm $addressLines -height 4.0cm -style FrameClear

# date/info line top right
$t addTextFrame InfoBlock 12.5cm 5.0cm 6.0cm \
    [list [list "$city, den $date" DateRight]] -height 0.6cm -style FrameClear

# fold marks (DIN 5008) on the left edge: 87mm, punch 148.5mm, 192mm
$t defineAutoGraphic FoldLine {draw:stroke solid svg:stroke-width 0.02cm svg:stroke-color #000000 \
        style:vertical-rel page style:horizontal-rel page}
$t addLine Fold1 0.5cm 8.7cm  1.0cm 8.7cm   -style FoldLine
$t addLine Punch  0.5cm 14.85cm 1.2cm 14.85cm -style FoldLine
$t addLine Fold2 0.5cm 19.2cm 1.0cm 19.2cm   -style FoldLine

$t flush

# ----------------------------------------------------------------- save
set out [file join [file dirname [file dirname [file normalize [info script]]]] out]
file mkdir $out
set odt [file join $out din5008.odt]
$pkg save $odt
$pkg destroy
puts "created $odt"
