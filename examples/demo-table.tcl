## examples/demo-table.tcl  --  Demo: styled table (widths, header row, cell styles)
##
## Column widths via column styles, table width + centered alignment via a table
## style, fully bordered cells with a shaded/bold header via cell styles
## (defineCellStyle: border, background, padding, vertical-align).
##
## Usage:  tclsh demo-table.tcl   ->  out/table.odt

set base [file dirname [file dirname [file normalize [info script]]]]
::tcl::tm::path add $base
set out [file join $base out]; file mkdir $out
package require odf::text
package require odf::style

set pkg [odf::newTextDoc]
set t   [odf::Text new $pkg]
$t defineAutoTable  T1 {style:width 15cm table:align center \
                        fo:margin-top 0.3cm fo:margin-bottom 0.3cm}
$t defineAutoColumn Cwide   {style:column-width 8cm}
$t defineAutoColumn Cnarrow {style:column-width 3.5cm}
$t defineAutoCellStyle Head -border "0.5pt solid #1F3864" -background #305080 \
   -color #FFFFFF -bold true -valign middle -padding 0.1cm -align center
$t defineAutoCellStyle Cell -border "0.5pt solid #AAAAAA" -valign top -padding 0.1cm

$t appendHeading "Product list" 1
set tab [$t appendTableCols {Cwide Cnarrow Cnarrow} T1]
$t addHeaderRow $tab {Product Qty Price} {Head Head Head}
foreach {p q pr} {Apple 12 1.20  Pear 8 1.50  Cherry 30 4.90  Plum 15 2.10} {
    $t addRow $tab [list $p $q $pr] {Cell Cell Cell}
}
$t flush; $t destroy

set odt [file join $out table.odt]
$pkg save $odt
$pkg destroy
puts "created $odt"
