## chart-0.1.tm -- odf::chart: build OpenDocument chart content (office:chart).
## Pure tdom; no Tk. Part of the "odf" ODF 1.3 toolkit.
##
## The chart construction is shared by two callers:
##   - odf::text appendChart   -> embeds buildContent as an OLE object (Object N/)
##   - odf::newChartDoc        -> wraps buildContent as a standalone .odc package
## Extracting it here keeps a single source of truth for the chart model and
## keeps text.tm smaller. No magic, no fallbacks: unknown options error out.
##
## 0.4: chart-vervollstaendigung. Five new chart types: area, ring (donut),
##      scatter (XY), radar, bubble -- now 9 in total. New y-axis options:
##      -ymin/-ymax (chart:minimum/maximum), -ylog (chart:logarithmic),
##      -ytick-major (chart:interval-major) -- emitted as a separate
##      style:chart-properties block on the y-axis style. New gridline
##      options: -ygrid and -xgrid {none|major|minor|both} -- emit
##      chart:grid children with chart:class major/minor on the respective
##      axis. All schema-grounded. RNG render verification deferred to
##      LO-render testing (follow-up).
## 0.3: buildContent gains -3d (chart:three-dimensional on the plot-area
##      style) and y-axis number format -yformat number|percentage with
##      -ydecimals/-ygrouping (a number:number-style/percentage-style data
##      style referenced from the value axis via style:data-style-name).
## 0.2: buildContent gains -labels none|value|percentage|value-and-percentage
##      (data labels via chart:data-label-number on the plot-area style) and
##      -xtitle/-ytitle (chart:title on the x/y chart:axis). RNG-grounded.
## 0.1: extracted buildContent + ColLetter/ChartCell from odf::text 0.42
##      (appendChart) and added the standalone chart-document factory
##      newChartDoc/newChartTemplate (.odc/.otc).

package require tdom
package require odf

namespace eval odf::chart {
    namespace export buildContent
}

# Spreadsheet column letter for a 1-based index (1->A, 2->B, 27->AA).
proc odf::chart::ColLetter {n} {
    set s ""
    while {$n > 0} {
        set r [expr {($n - 1) % 26}]
        set s [format %c [expr {65 + $r}]]$s
        set n [expr {($n - 1) / 26}]
    }
    return $s
}

# Build a chart local-table cell: a string cell (label) or a float cell.
proc odf::chart::ChartCell {cdoc kind val} {
    set c [$cdoc createElement table:table-cell]
    if {$kind eq "float"} {
        $c setAttribute office:value-type float
        $c setAttribute office:value $val
    } else {
        $c setAttribute office:value-type string
    }
    set p [$cdoc createElement text:p]
    $p appendChild [$cdoc createTextNode $val]
    $c appendChild $p
    return $c
}

# Build a data style for an axis number format: number:number-style or
# number:percentage-style with the given decimal places and grouping.
proc odf::chart::NumberStyle {cdoc name kind decimals grouping} {
    set tag [expr {$kind eq "percentage" ? "number:percentage-style" : "number:number-style"}]
    set st [$cdoc createElement $tag]
    $st setAttribute style:name $name
    set n [$cdoc createElement number:number]
    $n setAttribute number:decimal-places $decimals
    $n setAttribute number:min-integer-digits 1
    if {$grouping} { $n setAttribute number:grouping true }
    $st appendChild $n
    if {$kind eq "percentage"} {
        set t [$cdoc createElement number:text]
        $t appendChild [$cdoc createTextNode "%"]
        $st appendChild $t
    }
    return $st
}

# Build the content.xml of an OpenDocument chart: a full office:document-content
# with office:body > office:chart > chart:chart and a self-contained local-table.
# Returns the XML string -- exactly the chart sub-document used both as an
# embedded object (odf::text appendChart) and as a standalone .odc (newChartDoc).
#   categories  list of category labels (x axis)
#   series      {name values ...} pairs; each values list as long as categories
# Options: -type bar|column|line|pie (default column), -title T, -colors {#hex..}
#   (per series), -stacked B, -percent B, -legend none|start|end|top|bottom,
#   -vertical B (bar orientation; default: bar=true=horizontal, else false),
#   -labels none|value|percentage|value-and-percentage (data labels, default
#   none), -xtitle T / -ytitle T (axis titles), -3d B (three-dimensional chart),
#   -yformat ""|number|percentage with -ydecimals N (default 2) and -ygrouping B
#   (y-axis number format via a data style on the value axis).
proc odf::chart::buildContent {categories series args} {
    set type column; set title ""; set colors {}; set stacked 0
    set percent 0; set legend none; set vertical ""
    set labels none; set xtitle ""; set ytitle ""
    set td 0; set yformat ""; set ydecimals 2; set ygrouping 0
    set ymin ""; set ymax ""; set ylog 0; set ytickMajor ""
    set ygrid none; set xgrid none
    foreach {k v} $args {
        switch -- $k {
            -type     { set type $v }
            -title    { set title $v }
            -colors   { set colors $v }
            -stacked  { set stacked $v }
            -percent  { set percent $v }
            -legend   { set legend $v }
            -vertical { set vertical $v }
            -labels   { set labels $v }
            -xtitle   { set xtitle $v }
            -ytitle   { set ytitle $v }
            -3d        { set td $v }
            -yformat   { set yformat $v }
            -ydecimals { set ydecimals $v }
            -ygrouping { set ygrouping $v }
            -ymin        { set ymin $v }
            -ymax        { set ymax $v }
            -ylog        { set ylog $v }
            -ytick-major { set ytickMajor $v }
            -ygrid       { set ygrid $v }
            -xgrid       { set xgrid $v }
            default   { error "unknown chart option: $k" }
        }
    }
    # Validate grid choices
    foreach {opt val} [list -xgrid $xgrid -ygrid $ygrid] {
        if {[lsearch -exact {none major minor both} $val] < 0} {
            error "$opt must be none|major|minor|both (got: $val)"
        }
    }
    if {[llength $series] % 2} { error "series must be {name values ...} pairs" }
    set ncat [llength $categories]
    foreach {sn sv} $series {
        if {[llength $sv] != $ncat} { error "series \"$sn\" has [llength $sv] values, expected $ncat" }
    }
    set classMap {bar chart:bar column chart:bar line chart:line pie chart:circle \
                    area chart:area ring chart:ring scatter chart:scatter \
                    radar chart:radar bubble chart:bubble}
    if {![dict exists $classMap $type]} { error "unknown chart type: $type" }
    set cls [dict get $classMap $type]
    if {[lsearch -exact {none start end top bottom} $legend] < 0} { error "unknown legend position: $legend" }
    if {[lsearch -exact {none value percentage value-and-percentage} $labels] < 0} {
        error "unknown data-label kind: $labels (none|value|percentage|value-and-percentage)"
    }
    if {[lsearch -exact {"" number percentage} $yformat] < 0} {
        error "unknown y-axis format: $yformat (number|percentage)"
    }
    if {$yformat ne "" && ![string is integer -strict $ydecimals]} {
        error "-ydecimals must be an integer: $ydecimals"
    }
    # bar orientation: chart:vertical=true draws horizontal bars. Default from
    # type unless overridden: "bar" -> horizontal (true), else vertical (false).
    if {$vertical eq ""} { set vertical [expr {$type eq "bar"}] }

    set NS_O  urn:oasis:names:tc:opendocument:xmlns:office:1.0
    set NS_C  urn:oasis:names:tc:opendocument:xmlns:chart:1.0
    set NS_T  urn:oasis:names:tc:opendocument:xmlns:table:1.0
    set NS_TX urn:oasis:names:tc:opendocument:xmlns:text:1.0
    set NS_ST urn:oasis:names:tc:opendocument:xmlns:style:1.0
    set NS_D  urn:oasis:names:tc:opendocument:xmlns:drawing:1.0
    set NS_N  urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0
    set skel "<office:document-content xmlns:office=\"$NS_O\" xmlns:chart=\"$NS_C\" xmlns:table=\"$NS_T\" xmlns:text=\"$NS_TX\" xmlns:style=\"$NS_ST\" xmlns:draw=\"$NS_D\" xmlns:number=\"$NS_N\" xmlns:svg=\"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0\" office:version=\"1.3\"><office:body><office:chart/></office:body></office:document-content>"
    set cdoc [dom parse $skel]
    set root    [$cdoc documentElement]
    set bodyEl  [lindex [$root getElementsByTagName office:body] 0]
    set chartEl [lindex [$root getElementsByTagName office:chart] 0]

    # ---- automatic styles (only what is needed); office:automatic-styles
    # precedes office:body. plot-area chart-properties (stacked/percentage/
    # vertical) + per-series graphic-properties (fill colour). ----
    set styleEls {}
    set plotStyle ""
    if {$stacked || $percent || $labels ne "none" || $td || $type in {bar column}} {
        set plotStyle chartplot
        set st [$cdoc createElement style:style]
        $st setAttribute style:name $plotStyle
        $st setAttribute style:family chart
        set cp [$cdoc createElement style:chart-properties]
        if {$stacked} { $cp setAttribute chart:stacked true }
        if {$percent} { $cp setAttribute chart:percentage true }
        if {$labels ne "none"} { $cp setAttribute chart:data-label-number $labels }
        if {$td} { $cp setAttribute chart:three-dimensional true }
        if {$type in {bar column}} { $cp setAttribute chart:vertical [expr {$vertical ? "true" : "false"}] }
        $st appendChild $cp
        lappend styleEls $st
    }
    set seriesStyleNames {}
    set ci 0
    foreach {sn sv} $series {
        set nm ""
        set hex [lindex $colors $ci]
        if {$hex ne ""} {
            set nm "chartseries$ci"
            set st [$cdoc createElement style:style]
            $st setAttribute style:name $nm
            $st setAttribute style:family chart
            set gp [$cdoc createElement style:graphic-properties]
            $gp setAttribute draw:fill solid
            $gp setAttribute draw:fill-color $hex
            $st appendChild $gp
            lappend styleEls $st
        }
        lappend seriesStyleNames $nm
        incr ci
    }
    # y-axis number format: a data style (number:number-style/percentage-style)
    # referenced by a chart-family style via style:data-style-name. The chart
    # axis then carries that style via chart:style-name. Additional axis
    # properties (min/max/log/tick-major) ride on the same chart-family style
    # as a separate style:chart-properties block.
    set numStyleEls {}; set yAxisStyle ""
    set yAxisHasProps [expr {$ymin ne "" || $ymax ne "" || $ylog || $ytickMajor ne ""}]
    if {$yformat ne "" || $yAxisHasProps} {
        if {$yformat ne ""} {
            set fmtName axisfmt
            lappend numStyleEls [NumberStyle $cdoc $fmtName $yformat $ydecimals $ygrouping]
        }
        set yAxisStyle axisstyle
        set as [$cdoc createElement style:style]
        $as setAttribute style:name $yAxisStyle
        $as setAttribute style:family chart
        if {$yformat ne ""} { $as setAttribute style:data-style-name $fmtName }
        if {$yAxisHasProps} {
            set cp [$cdoc createElement style:chart-properties]
            if {$ymin       ne ""} { $cp setAttribute chart:minimum         $ymin }
            if {$ymax       ne ""} { $cp setAttribute chart:maximum         $ymax }
            if {$ylog}             { $cp setAttribute chart:logarithmic     true }
            if {$ytickMajor ne ""} { $cp setAttribute chart:interval-major  $ytickMajor }
            $as appendChild $cp
        }
        lappend styleEls $as
    }
    if {[llength $styleEls] || [llength $numStyleEls]} {
        set autoEl [$cdoc createElement office:automatic-styles]
        foreach st $numStyleEls { $autoEl appendChild $st }
        foreach st $styleEls    { $autoEl appendChild $st }
        $root insertBefore $autoEl $bodyEl
    }

    # ---- chart ----
    set chart [$cdoc createElement chart:chart]
    $chart setAttribute chart:class $cls
    $chart setAttribute svg:width 12cm
    $chart setAttribute svg:height 8cm
    $chartEl appendChild $chart
    if {$title ne ""} {
        set tt [$cdoc createElement chart:title]
        set tp [$cdoc createElement text:p]; $tp appendChild [$cdoc createTextNode $title]
        $tt appendChild $tp; $chart appendChild $tt
    }
    # chart:chart child order: title?, subtitle?, footer?, legend?, plot-area, table?
    if {$legend ne "none"} {
        set lg [$cdoc createElement chart:legend]
        $lg setAttribute chart:legend-position $legend
        $chart appendChild $lg
    }
    set plot [$cdoc createElement chart:plot-area]
    $plot setAttribute chart:data-source-has-labels both
    if {$plotStyle ne ""} { $plot setAttribute chart:style-name $plotStyle }
    $chart appendChild $plot
    # x (category) axis with the categories cell range; optional axis title
    # (chart:title is the first child of chart:axis, before chart:categories).
    set ax [$cdoc createElement chart:axis]
    $ax setAttribute chart:dimension x
    $ax setAttribute chart:name primary-x
    if {$xtitle ne ""} {
        set xt [$cdoc createElement chart:title]
        set xp [$cdoc createElement text:p]; $xp appendChild [$cdoc createTextNode $xtitle]
        $xt appendChild $xp; $ax appendChild $xt
    }
    set cats [$cdoc createElement chart:categories]
    $cats setAttribute table:cell-range-address "local-table.A2:.A[expr {$ncat + 1}]"
    $ax appendChild $cats
    # Gridlines on the x axis -- chart:class major|minor, both optional
    if {$xgrid in {major both}} {
        set g [$cdoc createElement chart:grid]; $g setAttribute chart:class major
        $ax appendChild $g
    }
    if {$xgrid in {minor both}} {
        set g [$cdoc createElement chart:grid]; $g setAttribute chart:class minor
        $ax appendChild $g
    }
    $plot appendChild $ax
    # y (value) axis; optional axis title
    set ay [$cdoc createElement chart:axis]
    $ay setAttribute chart:dimension y
    $ay setAttribute chart:name primary-y
    if {$yAxisStyle ne ""} { $ay setAttribute chart:style-name $yAxisStyle }
    if {$ytitle ne ""} {
        set yt [$cdoc createElement chart:title]
        set yp [$cdoc createElement text:p]; $yp appendChild [$cdoc createTextNode $ytitle]
        $yt appendChild $yp; $ay appendChild $yt
    }
    # Gridlines on the y axis -- chart:class major|minor, both optional
    if {$ygrid in {major both}} {
        set g [$cdoc createElement chart:grid]; $g setAttribute chart:class major
        $ay appendChild $g
    }
    if {$ygrid in {minor both}} {
        set g [$cdoc createElement chart:grid]; $g setAttribute chart:class minor
        $ay appendChild $g
    }
    $plot appendChild $ay
    # one chart:series per data series, referencing its column in local-table
    set ci 0
    foreach {sn sv} $series {
        set colLetter [ColLetter [expr {$ci + 2}]]   ;# B, C, D, ...
        set se [$cdoc createElement chart:series]
        $se setAttribute chart:values-cell-range-address "local-table.${colLetter}2:.${colLetter}[expr {$ncat + 1}]"
        $se setAttribute chart:label-cell-address "local-table.${colLetter}1"
        $se setAttribute chart:class $cls
        set nm [lindex $seriesStyleNames $ci]
        if {$nm ne ""} { $se setAttribute chart:style-name $nm }
        $plot appendChild $se
        incr ci
    }
    # local-table: row 1 = labels (empty corner + series names), rows 2.. =
    # category label + one value per series. Flat column/row model (valid).
    set tbl [$cdoc createElement table:table]
    $tbl setAttribute table:name local-table
    set tc [$cdoc createElement table:table-column]
    $tc setAttribute table:number-columns-repeated [expr {[llength $series] / 2 + 1}]
    $tbl appendChild $tc
    # header row
    set hr [$cdoc createElement table:table-row]
    $hr appendChild [ChartCell $cdoc string ""]
    foreach {sn sv} $series { $hr appendChild [ChartCell $cdoc string $sn] }
    $tbl appendChild $hr
    # data rows
    for {set i 0} {$i < $ncat} {incr i} {
        set dr [$cdoc createElement table:table-row]
        $dr appendChild [ChartCell $cdoc string [lindex $categories $i]]
        foreach {sn sv} $series { $dr appendChild [ChartCell $cdoc float [lindex $sv $i]] }
        $tbl appendChild $dr
    }
    $chart appendChild $tbl

    set content "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n[[$cdoc documentElement] asXML]"
    $cdoc delete
    return $content
}

# Standalone chart document (.odc): a package whose content.xml is a chart built
# by buildContent. Only the package media type differs from other documents; the
# chart's automatic styles live in content.xml, so styles.xml stays a skeleton.
# Same positional arguments and options as buildContent.
proc odf::newChartDoc {categories series args} {
    set NS_O urn:oasis:names:tc:opendocument:xmlns:office:1.0
    set mimetype "application/vnd.oasis.opendocument.chart"
    set content [odf::chart::buildContent $categories $series {*}$args]
    set manifest "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<manifest:manifest xmlns:manifest=\"urn:oasis:names:tc:opendocument:xmlns:manifest:1.0\" manifest:version=\"1.3\"><manifest:file-entry manifest:full-path=\"/\" manifest:media-type=\"$mimetype\"/><manifest:file-entry manifest:full-path=\"content.xml\" manifest:media-type=\"text/xml\"/><manifest:file-entry manifest:full-path=\"styles.xml\" manifest:media-type=\"text/xml\"/><manifest:file-entry manifest:full-path=\"meta.xml\" manifest:media-type=\"text/xml\"/></manifest:manifest>"
    set styles "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-styles xmlns:office=\"$NS_O\" xmlns:style=\"urn:oasis:names:tc:opendocument:xmlns:style:1.0\" xmlns:fo=\"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0\" xmlns:svg=\"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0\" office:version=\"1.3\"><office:styles/><office:automatic-styles/><office:master-styles/></office:document-styles>"
    set meta "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-meta xmlns:office=\"$NS_O\" xmlns:meta=\"urn:oasis:names:tc:opendocument:xmlns:meta:1.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" office:version=\"1.3\"><office:meta><meta:generator>odf-tcl</meta:generator></office:meta></office:document-meta>"
    set pkg [odf::Package new]
    $pkg setpart mimetype $mimetype
    $pkg setpart META-INF/manifest.xml [encoding convertto utf-8 $manifest]
    $pkg setpart content.xml [encoding convertto utf-8 $content]
    $pkg setpart styles.xml  [encoding convertto utf-8 $styles]
    $pkg setpart meta.xml    [encoding convertto utf-8 $meta]
    return $pkg
}

# A chart template (.otc): same content model, only the media type differs.
proc odf::newChartTemplate {categories series args} {
    set pkg [odf::newChartDoc $categories $series {*}$args]
    $pkg setMimetype "application/vnd.oasis.opendocument.chart-template"
    return $pkg
}

package provide odf::chart 0.4
