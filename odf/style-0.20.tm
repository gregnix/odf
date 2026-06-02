## odf/style-0.11.tm  --  odf::style: named styles + page layout in styles.xml
##
## 0.20: defineListStyle (named text:list-style, ordered numbers or bullets) and
##       listStyleKind (classify a list style by name -> ordered/bullet) so
##       text:list elements can carry real numbering, not just default bullets.
## 0.19: ODF boolean attributes (text:sort-ascending, text:number-lines,
##       text:numbered-entries, style:num-letter-sync, ...) are now emitted as
##       "true"/"false" -- a Tcl 1/0 input is normalised; non-boolean input is
##       passed through unchanged (validator caught sort-ascending="1").
## 0.18: defineLineNumbering / lineNumbering (text:linenumbering-configuration)
##       and defineBibliographyConfiguration / bibliographyConfiguration
##       (text:bibliography-configuration + text:sort-key) in office:styles.
## 0.17: defineNotesConfiguration / notesConfiguration -- explicit
##       text:notes-configuration in office:styles for footnote/endnote
##       numbering (num-format, position, styles, ...), so LO's
##       implementation-defined note defaults are no longer relied upon.
## 0.16: setHeaderParts/setFooterParts now render in Writer: left/center/right
##       via ONE paragraph with center+right tab stops (Writer ignores
##       style:region-* in text headers). headerParts/footerParts read by tab.
## 0.15: left/right page headers/footers via -side (style:header-left etc.,
##       master-page children kept in schema order) and setHeaderFooterProps
##       (style:header-footer-properties: height, margins, border, background).
## 0.14: header/footer content: three regions (setHeaderParts/setFooterParts
##       with -left/-center/-right + headerParts/footerParts) and more field
##       tokens (%date% %time% %title% %author% %subject% %file%, %% literal).
## 0.13: removed -num-letter-sync from pageProperties (not allowed on
##       style:page-layout-properties by the ODF schema).
## 0.12: corrected style:style child order (table-cell before paragraph
##       before text), verified against the ODF validator.
## 0.11: order style:style property children per ODF schema.
## 0.10: removed defineTable/defineColumn/defineCellStyle -- table styling for
##       body tables must be automatic styles in content.xml; use odf::text
##       defineAutoTable/defineAutoColumn/defineAutoCellStyle instead.
## 0.7: multi-page: setPageUsage (mirrored/left/right), setNextPage (master
##      chaining), defineMasterPageStyle (first page different).
## 0.6: extra page properties: pageProperties (numbering, columns, border,
##      background, padding) + pageColumns read.
## 0.5: page-format presets (paper size + orientation): pageFormat,
##      definePageFormat, defineStandardFormat (A3/A4/A5/A6/Letter/Legal).
##
## Creates reusable common styles (office:styles) that odf::Text nodes
## reference via their style-name. Properties are real ODF attributes
## (e.g. fo:font-weight bold) -- no guessing; the caller picks the group.
##
##   set s [odf::Styles new $pkg]
##   $s defineText      GreenBold {fo:color #008844 fo:font-weight bold}
##   $s defineParagraph Centered  -paragraph {fo:text-align center} -text {fo:font-size 14pt}
##   $s defineCell      Warn      -cell {fo:background-color #FFE5E5}
##
## Page layout (page-layout in office:automatic-styles, master-page in
## office:master-styles of styles.xml):
##   $s definePageLayout PM {fo:page-width 21cm fo:page-height 29.7cm \
##         fo:margin-left 2.5cm fo:margin-right 2cm fo:margin-top 2cm \
##         fo:margin-bottom 2cm style:print-orientation portrait}
##   $s defineMasterPage Standard -pagelayout PM
##   # or in short: $s defineStandardPage {fo:page-width 21cm ...}
##   $s flush                       ;# back into the package's styles.xml
##
## Group options: -text -paragraph -cell  (each a dict of ODF attr -> value)

package require Tcl 8.6 9
package require tdom
package require odf

oo::class create odf::Styles {
    variable Pkg Doc Styles

    constructor {pkg} {
        set Pkg $pkg
        set Doc [$pkg tree styles.xml]
        set Styles [lindex [[$Doc documentElement] getElementsByTagName office:styles] 0]
        if {$Styles eq ""} { error "no office:styles in styles.xml" }
        $Pkg registerFlushHook [list [self] flush]
    }
    destructor { if {[info exists Doc] && $Doc ne ""} { $Doc delete } }

    # ---- read named styles ----
    method names {{family ""}} {
        set res {}
        foreach s [$Styles getElementsByTagName style:style] {
            if {$family eq "" || [$s getAttribute style:family ""] eq $family} {
                lappend res [$s getAttribute style:name ""]
            }
        }
        return $res
    }
    method has {name} {
        foreach s [$Styles getElementsByTagName style:style] {
            if {[$s getAttribute style:name ""] eq $name} { return 1 }
        }
        return 0
    }

    # ---- define named styles (idempotent: same name is replaced) ----
    method defineText {name props} {
        my Define $name text [list style:text-properties $props]
    }
    method defineParagraph {name args} {
        my Define $name paragraph [my Groups $args {-paragraph style:paragraph-properties -text style:text-properties}]
    }
    method defineCell {name args} {
        my Define $name table-cell [my Groups $args {-cell style:table-cell-properties -text style:text-properties -paragraph style:paragraph-properties}]
    }

    # ---- list styles (text:list-style: ordered numbers or bullets) ----
    # Define a named text:list-style in office:styles. Idempotent: a list style
    # with the same name is replaced. appendList / addSublist reference it by
    # name (text:style-name). Options:
    #   -kind ordered|bullet   numbering kind (default bullet)
    #   -levels N              list levels emitted (default 10, for nesting)
    #   -numFormat fmt         ordered: style:num-format (default 1; 1/a/A/i/I)
    #   -numSuffix s           ordered: style:num-suffix (default "."; "" = none)
    #   -bulletChar c          bullet: text:bullet-char (default U+2022 BULLET)
    method defineListStyle {name args} {
        set kind bullet; set levels 10
        set numFormat 1; set numSuffix "."; set bulletChar "\u2022"
        foreach {k v} $args {
            switch -- $k {
                -kind       { set kind $v }
                -levels     { set levels $v }
                -numFormat  { set numFormat $v }
                -numSuffix  { set numSuffix $v }
                -bulletChar { set bulletChar $v }
                default     { error "unknown option: $k" }
            }
        }
        if {$kind ni {ordered bullet}} { error "kind must be ordered or bullet: $kind" }
        if {![string is integer -strict $levels] || $levels < 1} {
            error "levels must be a positive integer: $levels"
        }
        foreach ls [$Styles getElementsByTagName text:list-style] {
            if {[$ls getAttribute style:name ""] eq $name} { $ls delete }
        }
        set ls [$Doc createElement text:list-style]
        $ls setAttribute style:name $name
        for {set lvl 1} {$lvl <= $levels} {incr lvl} {
            if {$kind eq "ordered"} {
                set lv [$Doc createElement text:list-level-style-number]
                $lv setAttribute text:level $lvl
                $lv setAttribute style:num-format $numFormat
                if {$numSuffix ne ""} { $lv setAttribute style:num-suffix $numSuffix }
            } else {
                set lv [$Doc createElement text:list-level-style-bullet]
                $lv setAttribute text:level $lvl
                $lv setAttribute text:bullet-char $bulletChar
            }
            # hanging indent per level: label at (lvl-1)*indent, text at lvl*indent
            set indent [format %.3fcm [expr {$lvl * 0.5}]]
            set hang   "-0.5cm"
            set props [$Doc createElement style:list-level-properties]
            $props setAttribute text:list-level-position-and-space-mode label-alignment
            set lab [$Doc createElement style:list-level-label-alignment]
            $lab setAttribute text:label-followed-by listtab
            $lab setAttribute text:list-tab-stop-position $indent
            $lab setAttribute fo:text-indent $hang
            $lab setAttribute fo:margin-left $indent
            $props appendChild $lab
            $lv appendChild $props
            $ls appendChild $lv
        }
        $Styles appendChild $ls
        return $ls
    }

    # Classify a list style by name -> "ordered" | "bullet" | "" (unknown/absent).
    # Looks in styles.xml first, then office:automatic-styles in content.xml
    # (where LibreOffice usually puts generated list styles).
    method listStyleKind {name} {
        set hit [my FindListStyle [$Doc documentElement] $name]
        if {$hit ne ""} { return $hit }
        if {[catch {$Pkg tree content.xml} cdoc]} { return "" }
        try {
            return [my FindListStyle [$cdoc documentElement] $name]
        } finally {
            $cdoc delete
        }
    }
    method FindListStyle {root name} {
        foreach ls [$root getElementsByTagName text:list-style] {
            if {[$ls getAttribute style:name ""] ne $name} continue
            foreach c [$ls childNodes] {
                if {[$c nodeType] ne "ELEMENT_NODE"} continue
                # prefix-agnostic: localName differs for created vs parsed nodes
                switch -- [lindex [split [$c nodeName] :] end] {
                    list-level-style-number { return ordered }
                    list-level-style-bullet { return bullet }
                    list-level-style-image  { return bullet }
                }
            }
            return ""
        }
        return ""
    }

    # Number format of an ordered list style -> e.g. 1 | a | A | i | I, or ""
    # (bullet / not found). Looks in styles.xml then content.xml automatic styles.
    method listStyleFormat {name} {
        set hit [my FindListFormat [$Doc documentElement] $name]
        if {$hit ne ""} { return $hit }
        if {[catch {$Pkg tree content.xml} cdoc]} { return "" }
        try {
            return [my FindListFormat [$cdoc documentElement] $name]
        } finally {
            $cdoc delete
        }
    }
    method FindListFormat {root name} {
        foreach ls [$root getElementsByTagName text:list-style] {
            if {[$ls getAttribute style:name ""] ne $name} continue
            foreach c [$ls childNodes] {
                if {[$c nodeType] ne "ELEMENT_NODE"} continue
                if {[lindex [split [$c nodeName] :] end] eq "list-level-style-number"} {
                    return [$c getAttribute style:num-format ""]
                }
            }
            return ""
        }
        return ""
    }

    # ---- page layout ----
    # page-layout (page size/margins/orientation). props = dict of
    # style:page-layout-properties attributes (fo:page-width, fo:margin-*,
    # style:print-orientation, ...). Idempotent.
    method definePageLayout {name props} {
        set auto [my AutoEl]
        foreach pl [$auto getElementsByTagName style:page-layout] {
            if {[$pl getAttribute style:name ""] eq $name} { $pl delete }
        }
        set pl [$Doc createElement style:page-layout]
        $pl setAttribute style:name $name
        set pp [$Doc createElement style:page-layout-properties]
        foreach {k v} $props { $pp setAttribute $k $v }
        $pl appendChild $pp
        $auto appendChild $pl
        return $pl
    }
    # master-page references a page-layout via -pagelayout. Idempotent.
    method defineMasterPage {name args} {
        set layout ""
        foreach {k v} $args {
            switch -- $k {
                -pagelayout { set layout $v }
                default     { error "unknown option: $k" }
            }
        }
        set master [my MasterEl]
        foreach mp [$master getElementsByTagName style:master-page] {
            if {[$mp getAttribute style:name ""] eq $name} { $mp delete }
        }
        set mp [$Doc createElement style:master-page]
        $mp setAttribute style:name $name
        if {$layout ne ""} { $mp setAttribute style:page-layout-name $layout }
        $master appendChild $mp
        return $mp
    }
    # Convenience: page-layout + master-page "Standard" (LibreOffice uses
    # "Standard" as the default page, so the layout applies to the body).
    method defineStandardPage {props {layoutName PMstandard}} {
        my definePageLayout $layoutName $props
        my defineMasterPage Standard -pagelayout $layoutName
        return Standard
    }

    # ---- page-format presets (paper size + orientation) ----
    # Known paper sizes as portrait {width height}. ISO 216 A-series + US.
    method PaperSizes {} {
        return {
            A3     {29.7cm 42cm}
            A4     {21cm 29.7cm}
            A5     {14.8cm 21cm}
            A6     {10.5cm 14.8cm}
            Letter {21.59cm 27.94cm}
            Legal  {21.59cm 35.56cm}
        }
    }
    # Names of all known paper formats (sorted).
    method pageFormats {} { return [lsort [dict keys [my PaperSizes]]] }

    # Pure helper: property dict for a named paper format. No side effect --
    # feed it to definePageLayout (optionally merged with margins). Landscape
    # swaps width and height. -orientation portrait|landscape (default portrait).
    #   $s definePageLayout PM [$s pageFormat A4 -orientation landscape]
    method pageFormat {format args} {
        set orient portrait
        foreach {k v} $args {
            switch -- $k {
                -orientation { set orient $v }
                default      { error "unknown option: $k" }
            }
        }
        if {$orient ni {portrait landscape}} {
            error "orientation must be portrait or landscape: $orient"
        }
        set sizes [my PaperSizes]
        if {![dict exists $sizes $format]} {
            error "unknown page format: $format (known: [join [my pageFormats] {, }])"
        }
        lassign [dict get $sizes $format] w h
        if {$orient eq "landscape"} { set tmp $w; set w $h; set h $tmp }
        return [list fo:page-width $w fo:page-height $h style:print-orientation $orient]
    }

    # Build a page-layout from a paper-format preset + margins + extra props.
    # -orientation portrait|landscape ; -margin <all> (uniform) OR
    # -margins {top right bottom left} (default 2cm all sides) ;
    # -extra {k v ...} for additional page-layout-properties (e.g.
    # style:num-format 1, style:writing-mode lr-tb). Idempotent.
    method definePageFormat {layoutName format args} {
        set orient portrait
        set marg {2cm 2cm 2cm 2cm}
        set extra {}
        foreach {k v} $args {
            switch -- $k {
                -orientation { set orient $v }
                -margin      { set marg [list $v $v $v $v] }
                -margins {
                    if {[llength $v] != 4} {
                        error "-margins needs {top right bottom left}: $v"
                    }
                    set marg $v
                }
                -extra { set extra $v }
                default { error "unknown option: $k" }
            }
        }
        lassign $marg mt mr mb ml
        set props [my pageFormat $format -orientation $orient]
        lappend props fo:margin-top $mt fo:margin-right $mr \
                      fo:margin-bottom $mb fo:margin-left $ml
        foreach {k v} $extra { lappend props $k $v }
        return [my definePageLayout $layoutName $props]
    }

    # Convenience: definePageFormat + master-page "Standard" so the format
    # applies to the body. Same options as definePageFormat, plus -layout <name>
    # for the page-layout name (default PMstandard).
    method defineStandardFormat {format args} {
        set layoutName PMstandard
        set pass {}
        foreach {k v} $args {
            switch -- $k {
                -layout { set layoutName $v }
                -orientation - -margin - -margins - -extra { lappend pass $k $v }
                default { error "unknown option: $k" }
            }
        }
        my definePageFormat $layoutName $format {*}$pass
        my defineMasterPage Standard -pagelayout $layoutName
        return Standard
    }

    # ---- extra page properties (numbering, columns, border, background) ----
    # style:page-layout-properties element of a named page-layout (created by
    # definePageLayout/definePageFormat). Errors if the layout is unknown.
    method PagePropsEl {name} {
        foreach pl [[my AutoEl] getElementsByTagName style:page-layout] {
            if {[$pl getAttribute style:name ""] ne $name} continue
            set pp [lindex [$pl getElementsByTagName style:page-layout-properties] 0]
            if {$pp eq ""} {
                set pp [$Doc createElement style:page-layout-properties]
                $pl appendChild $pp
            }
            return $pp
        }
        error "page-layout missing: $name (define it first, e.g. definePageFormat)"
    }
    # Augment an existing page-layout with extra properties. Idempotent (sets
    # attributes; replaces the style:columns child). Options:
    #   -num-format <v>        style:num-format (1, a, A, i, I)
    #   -background-color <v>  fo:background-color (e.g. #EEEEEE)
    #   -border <v>            fo:border (e.g. "0.5pt solid #000000")
    #   -border-top|-border-bottom|-border-left|-border-right <v>
    #   -padding <v>           fo:padding
    #   -columns <n> ?-column-gap <g>?   -> style:columns (equal columns)
    #   -attr {k v ...}        raw page-layout-properties attributes
    method pageProperties {name args} {
        set pp [my PagePropsEl $name]
        set cols ""; set gap ""; set attrs {}
        foreach {k v} $args {
            switch -- $k {
                -num-format       { lappend attrs style:num-format $v }
                -background-color { lappend attrs fo:background-color $v }
                -border           { lappend attrs fo:border $v }
                -border-top       { lappend attrs fo:border-top $v }
                -border-bottom    { lappend attrs fo:border-bottom $v }
                -border-left      { lappend attrs fo:border-left $v }
                -border-right     { lappend attrs fo:border-right $v }
                -padding          { lappend attrs fo:padding $v }
                -columns          { set cols $v }
                -column-gap       { set gap $v }
                -attr             { foreach {ak av} $v { lappend attrs $ak $av } }
                default           { error "unknown option: $k" }
            }
        }
        foreach {ak av} $attrs { $pp setAttribute $ak $av }
        if {$cols ne ""} {
            foreach c [$pp getElementsByTagName style:columns] { $c delete }
            set ce [$Doc createElement style:columns]
            $ce setAttribute fo:column-count $cols
            if {$gap ne ""} { $ce setAttribute fo:column-gap $gap }
            $pp appendChild $ce
        } elseif {$gap ne ""} {
            error "-column-gap requires -columns"
        }
        return $pp
    }
    # Read the columns of a page-layout: dict {count N gap G} or "" if none.
    method pageColumns {name} {
        foreach pl [[my AutoEl] getElementsByTagName style:page-layout] {
            if {[$pl getAttribute style:name ""] ne $name} continue
            set pp [lindex [$pl getElementsByTagName style:page-layout-properties] 0]
            if {$pp eq ""} { return "" }
            set ce [lindex [$pp getElementsByTagName style:columns] 0]
            if {$ce eq ""} { return "" }
            return [list count [$ce getAttribute fo:column-count ""] \
                         gap   [$ce getAttribute fo:column-gap ""]]
        }
        return ""
    }

    # ---- multi-page: page usage (mirrored) + master chaining (first page) ----
    # style:page-usage on the page-layout element: all|left|right|mirrored.
    # For "mirrored" the fo:margin-left/right act as inner/outer and alternate
    # on left/right pages. Errors if the layout is unknown.
    method setPageUsage {layout usage} {
        if {$usage ni {all left right mirrored}} {
            error "page-usage must be all|left|right|mirrored: $usage"
        }
        foreach pl [[my AutoEl] getElementsByTagName style:page-layout] {
            if {[$pl getAttribute style:name ""] eq $layout} {
                $pl setAttribute style:page-usage $usage
                return $pl
            }
        }
        error "page-layout missing: $layout (define it first, e.g. definePageFormat)"
    }
    method pageUsage {layout} {
        foreach pl [[my AutoEl] getElementsByTagName style:page-layout] {
            if {[$pl getAttribute style:name ""] eq $layout} {
                return [$pl getAttribute style:page-usage all]
            }
        }
        return ""
    }
    # Chain a master-page to the next one (style:next-style-name). Page 1 uses
    # this master, following pages use <next>. Errors if the master is unknown.
    method setNextPage {master next} {
        foreach mp [[my MasterEl] getElementsByTagName style:master-page] {
            if {[$mp getAttribute style:name ""] eq $master} {
                $mp setAttribute style:next-style-name $next
                return $mp
            }
        }
        error "master-page missing: $master (define it first with defineMasterPage)"
    }
    method nextPage {master} {
        foreach mp [[my MasterEl] getElementsByTagName style:master-page] {
            if {[$mp getAttribute style:name ""] eq $master} {
                return [$mp getAttribute style:next-style-name ""]
            }
        }
        return ""
    }
    # Paragraph style that starts a page on <master> (style:master-page-name).
    # Apply it to the first body paragraph to make page 1 use that master; with
    # setNextPage the following pages switch to the chained master. Idempotent.
    method defineMasterPageStyle {name master args} {
        set parent ""
        foreach {k v} $args {
            switch -- $k {
                -parent { set parent $v }
                default { error "unknown option: $k" }
            }
        }
        foreach s [$Styles getElementsByTagName style:style] {
            if {[$s getAttribute style:name ""] eq $name} { $s delete }
        }
        set st [$Doc createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family paragraph
        $st setAttribute style:master-page-name $master
        if {$parent ne ""} { $st setAttribute style:parent-style-name $parent }
        $Styles appendChild $st
        return $st
    }
    method masterPageOfStyle {name} {
        foreach s [$Styles getElementsByTagName style:style] {
            if {[$s getAttribute style:name ""] eq $name} {
                return [$s getAttribute style:master-page-name ""]
            }
        }
        return ""
    }

    # ---- font registration (office:font-face-decls in styles.xml) ----
    method registerFont {name args} {
        set family $name; set generic ""; set pitch ""
        foreach {k v} $args {
            switch -- $k {
                -family  { set family $v }
                -generic { set generic $v }
                -pitch   { set pitch $v }
                default  { error "unknown option: $k" }
            }
        }
        set decls [my FontDeclsEl]
        foreach ff [$decls getElementsByTagName style:font-face] {
            if {[$ff getAttribute style:name ""] eq $name} { $ff delete }
        }
        set ff [$Doc createElement style:font-face]
        $ff setAttribute style:name $name
        $ff setAttribute svg:font-family $family
        if {$generic ne ""} { $ff setAttribute style:font-family-generic $generic }
        if {$pitch ne ""}   { $ff setAttribute style:font-pitch $pitch }
        $decls appendChild $ff
        return $ff
    }
    method fonts {} {
        set r {}
        foreach ff [[my FontDeclsEl] getElementsByTagName style:font-face] {
            lappend r [$ff getAttribute style:name ""]
        }
        return $r
    }

    # ---- header/footer (in the master-page) ----
    # lines = list of {text ?style?}. In the text, %page%/%pages% are replaced
    # by page-number/page-count fields. Idempotent (replaces existing).
    # -side default|left|first selects style:header / -left / -first (left pages
    # need style:page-usage "mirrored"; see setPageUsage).
    method setHeader {masterName lines args} {
        return [my HeaderFooter $masterName [my HFTag style:header [my SideOpt $args]] $lines]
    }
    method setFooter {masterName lines args} {
        return [my HeaderFooter $masterName [my HFTag style:footer [my SideOpt $args]] $lines]
    }
    # Three-region header/footer (left / center / right). Each option is a text
    # string (field tokens like %page% allowed). ?-side default|left|first?.
    method setHeaderParts {masterName args} {
        lassign [my SplitSide $args] side rest
        return [my HFParts $masterName [my HFTag style:header $side] {*}$rest]
    }
    method setFooterParts {masterName args} {
        lassign [my SplitSide $args] side rest
        return [my HFParts $masterName [my HFTag style:footer $side] {*}$rest]
    }
    # Configure the header/footer box (style:header-footer-properties) of a
    # master-page's page-layout. -which header|footer is required.
    method setHeaderFooterProps {masterName args} {
        set which ""; set attrs {}
        foreach {k v} $args {
            switch -- $k {
                -which           { set which $v }
                -min-height      { lappend attrs fo:min-height $v }
                -height          { lappend attrs svg:height $v }
                -margin          { lappend attrs fo:margin $v }
                -margin-top      { lappend attrs fo:margin-top $v }
                -margin-bottom   { lappend attrs fo:margin-bottom $v }
                -margin-left     { lappend attrs fo:margin-left $v }
                -margin-right    { lappend attrs fo:margin-right $v }
                -border          { lappend attrs fo:border $v }
                -border-top      { lappend attrs fo:border-top $v }
                -border-bottom   { lappend attrs fo:border-bottom $v }
                -border-left     { lappend attrs fo:border-left $v }
                -border-right    { lappend attrs fo:border-right $v }
                -padding         { lappend attrs fo:padding $v }
                -background      { lappend attrs fo:background-color $v }
                -dynamic-spacing { lappend attrs style:dynamic-spacing $v }
                -attr            { foreach {a b} $v { lappend attrs $a $b } }
                default          { error "unknown option: $k" }
            }
        }
        if {$which ni {header footer}} { error "-which must be header or footer" }
        set plName [my masterPageLayout $masterName]
        if {$plName eq ""} { error "master-page has no page-layout: $masterName" }
        set base [expr {$which eq "header" ? "style:header" : "style:footer"}]
        set hp [my EnsureHFStyleEl $plName $base]
        if {$hp eq ""} { error "page-layout missing for $masterName" }
        foreach {a b} $attrs { $hp setAttribute $a $b }
        return $hp
    }

    # ---- read page layout ----
    method pageLayouts {} {
        set res {}
        foreach pl [[my AutoEl] getElementsByTagName style:page-layout] {
            lappend res [$pl getAttribute style:name ""]
        }
        return $res
    }
    method masterPages {} {
        set res {}
        foreach mp [[my MasterEl] getElementsByTagName style:master-page] {
            lappend res [$mp getAttribute style:name ""]
        }
        return $res
    }
    method pageLayoutProps {name} {
        foreach pl [[my AutoEl] getElementsByTagName style:page-layout] {
            if {[$pl getAttribute style:name ""] ne $name} continue
            set pp [lindex [$pl getElementsByTagName style:page-layout-properties] 0]
            if {$pp eq ""} { return [dict create] }
            set d [dict create]
            foreach a [$pp attributes] {
                lassign $a ln prefix uri
                set key [expr {$prefix ne "" ? "$prefix:$ln" : $ln}]
                dict set d $key [$pp getAttribute $key ""]
            }
            return $d
        }
        return [dict create]
    }
    method masterPageLayout {name} {
        foreach mp [[my MasterEl] getElementsByTagName style:master-page] {
            if {[$mp getAttribute style:name ""] eq $name} {
                return [$mp getAttribute style:page-layout-name ""]
            }
        }
        return ""
    }
    method headerLines {masterName args} { return [my HFLines $masterName [my HFTag style:header [my SideOpt $args]]] }
    method footerLines {masterName args} { return [my HFLines $masterName [my HFTag style:footer [my SideOpt $args]]] }
    method headerParts {masterName args} { return [my HFPartsRead $masterName [my HFTag style:header [my SideOpt $args]]] }
    method footerParts {masterName args} { return [my HFPartsRead $masterName [my HFTag style:footer [my SideOpt $args]]] }

    # ---- notes configuration (footnote/endnote numbering defaults) ----
    # Writes a text:notes-configuration into office:styles so footnote/endnote
    # numbering is explicit instead of relying on the consumer's
    # implementation-defined note defaults (LibreOffice defaults footnotes to
    # num-format "1"/page and endnotes to "i" (roman)/document). -class
    # footnote|endnote is required; the other options map 1:1 to ODF
    # attributes:
    #   -num-format          style:num-format         (1 i I a A, or a literal)
    #   -num-letter-sync     style:num-letter-sync    (boolean; pairs with a/A)
    #   -num-prefix          style:num-prefix
    #   -num-suffix          style:num-suffix
    #   -position            text:footnotes-position  (text|page|section|document)
    #   -start-value         text:start-value         (nonNegativeInteger)
    #   -start-numbering-at  text:start-numbering-at  (document|chapter|page)
    #   -default-style       text:default-style-name
    #   -citation-style      text:citation-style-name
    #   -citation-body-style text:citation-body-style-name
    #   -master-page         text:master-page-name
    # Idempotent per class: an existing configuration for the same note-class is
    # replaced. Returns the text:notes-configuration node.
    method defineNotesConfiguration {args} {
        set map {
            -num-format          style:num-format
            -num-letter-sync     style:num-letter-sync
            -num-prefix          style:num-prefix
            -num-suffix          style:num-suffix
            -position            text:footnotes-position
            -start-value         text:start-value
            -start-numbering-at  text:start-numbering-at
            -default-style       text:default-style-name
            -citation-style      text:citation-style-name
            -citation-body-style text:citation-body-style-name
            -master-page         text:master-page-name
        }
        set class ""
        set attrs {}
        foreach {k v} $args {
            if {$k eq "-class"} { set class $v; continue }
            if {![dict exists $map $k]} { error "unknown option: $k" }
            lappend attrs [dict get $map $k] $v
        }
        if {$class ni {footnote endnote}} {
            error "note class must be footnote or endnote: $class"
        }
        foreach nc [$Styles getElementsByTagName text:notes-configuration] {
            if {[$nc getAttribute text:note-class ""] eq $class} { $nc delete }
        }
        set nc [$Doc createElement text:notes-configuration]
        $nc setAttribute text:note-class $class
        foreach {a v} $attrs { my SetA $nc $a $v }
        $Styles appendChild $nc
        return $nc
    }
    # Read back. Without arg: list of note-classes that have a configuration.
    # With a class: dict of that configuration's set ODF attributes (empty if
    # none defined).
    method notesConfiguration {{class ""}} {
        if {$class eq ""} {
            set res {}
            foreach nc [$Styles getElementsByTagName text:notes-configuration] {
                lappend res [$nc getAttribute text:note-class ""]
            }
            return $res
        }
        set known {text:note-class style:num-format style:num-letter-sync \
            style:num-prefix style:num-suffix text:footnotes-position \
            text:start-value text:start-numbering-at text:default-style-name \
            text:citation-style-name text:citation-body-style-name \
            text:master-page-name}
        foreach nc [$Styles getElementsByTagName text:notes-configuration] {
            if {[$nc getAttribute text:note-class ""] eq $class} {
                set d {}
                foreach a $known {
                    if {[$nc hasAttribute $a]} { dict set d $a [$nc getAttribute $a] }
                }
                return $d
            }
        }
        return {}
    }

    # ---- line numbering configuration ----
    # Writes text:linenumbering-configuration into office:styles (only one is
    # allowed; an existing one is replaced). Options map 1:1 to ODF attributes:
    #   -number-lines        text:number-lines        (boolean; on/off)
    #   -num-format          style:num-format         (1 i I a A, or a literal)
    #   -num-letter-sync     style:num-letter-sync    (boolean; pairs with a/A)
    #   -style               text:style-name          (text style for the numbers)
    #   -increment           text:increment           (show every Nth line)
    #   -position            text:number-position     (left|right|inner|outer)
    #   -offset              text:offset              (distance from text, a length)
    #   -count-empty-lines   text:count-empty-lines   (boolean)
    #   -count-in-text-boxes text:count-in-text-boxes (boolean)
    #   -restart-on-page     text:restart-on-page     (boolean)
    # Optional separator child via -separator <text> (and -separator-increment N
    # for its text:increment). Returns the configuration node.
    method defineLineNumbering {args} {
        set map {
            -number-lines        text:number-lines
            -num-format          style:num-format
            -num-letter-sync     style:num-letter-sync
            -style               text:style-name
            -increment           text:increment
            -position            text:number-position
            -offset              text:offset
            -count-empty-lines   text:count-empty-lines
            -count-in-text-boxes text:count-in-text-boxes
            -restart-on-page     text:restart-on-page
        }
        set attrs {}
        set sep ""; set sepInc ""; set haveSep 0
        foreach {k v} $args {
            switch -- $k {
                -separator           { set sep $v; set haveSep 1 }
                -separator-increment { set sepInc $v; set haveSep 1 }
                default {
                    if {![dict exists $map $k]} { error "unknown option: $k" }
                    lappend attrs [dict get $map $k] $v
                }
            }
        }
        set lc [$Doc createElement text:linenumbering-configuration]
        foreach {a v} $attrs { my SetA $lc $a $v }
        if {$haveSep} {
            set se [$Doc createElement text:linenumbering-separator]
            if {$sepInc ne ""} { $se setAttribute text:increment $sepInc }
            if {$sep ne ""} { $se appendChild [$Doc createTextNode $sep] }
            $lc appendChild $se
        }
        foreach e [$Styles getElementsByTagName text:linenumbering-configuration] { $e delete }
        $Styles appendChild $lc
        return $lc
    }
    # Read the line-numbering configuration as a dict of set attributes (empty if
    # none). A separator child is reported as keys "separator" / "separator-increment".
    method lineNumbering {} {
        set lc [lindex [$Styles getElementsByTagName text:linenumbering-configuration] 0]
        if {$lc eq ""} { return {} }
        set known {text:number-lines style:num-format style:num-letter-sync \
            text:style-name text:increment text:number-position text:offset \
            text:count-empty-lines text:count-in-text-boxes text:restart-on-page}
        set d {}
        foreach a $known { if {[$lc hasAttribute $a]} { dict set d $a [$lc getAttribute $a] } }
        set se [lindex [$lc getElementsByTagName text:linenumbering-separator] 0]
        if {$se ne ""} {
            dict set d separator [$se text]
            if {[$se hasAttribute text:increment]} {
                dict set d separator-increment [$se getAttribute text:increment]
            }
        }
        return $d
    }

    # ---- bibliography configuration ----
    # Writes text:bibliography-configuration into office:styles (only one is
    # allowed; an existing one is replaced). Options map 1:1 to ODF attributes:
    #   -prefix           text:prefix              (citation body prefix, e.g. "[")
    #   -suffix           text:suffix              (e.g. "]")
    #   -numbered-entries text:numbered-entries    (boolean)
    #   -sort-by-position text:sort-by-position    (boolean)
    #   -language         fo:language
    #   -country          fo:country
    #   -script           fo:script
    #   -rfc-language-tag style:rfc-language-tag
    #   -sort-algorithm   text:sort-algorithm
    # -sort-keys takes a list of entries, each {key ?ascending?}; key is one of the
    # bibliography fields (author, title, year, ...). Returns the configuration node.
    method defineBibliographyConfiguration {args} {
        set map {
            -prefix            text:prefix
            -suffix            text:suffix
            -numbered-entries  text:numbered-entries
            -sort-by-position  text:sort-by-position
            -language          fo:language
            -country           fo:country
            -script            fo:script
            -rfc-language-tag  style:rfc-language-tag
            -sort-algorithm    text:sort-algorithm
        }
        set valid {address annote author bibliography-type booktitle chapter \
            custom1 custom2 custom3 custom4 custom5 edition editor howpublished \
            identifier institution isbn issn journal month note number \
            organizations pages publisher report-type school series title url \
            volume year}
        set attrs {}
        set sortKeys {}
        foreach {k v} $args {
            if {$k eq "-sort-keys"} { set sortKeys $v; continue }
            if {![dict exists $map $k]} { error "unknown option: $k" }
            lappend attrs [dict get $map $k] $v
        }
        # validate up front, before touching the tree (no partial mutation on error)
        foreach pair $sortKeys {
            if {[lindex $pair 0] ni $valid} { error "invalid sort key: [lindex $pair 0]" }
        }
        # build the new node fully (still detached), then swap atomically
        set bc [$Doc createElement text:bibliography-configuration]
        foreach {a v} $attrs { my SetA $bc $a $v }
        foreach pair $sortKeys {
            lassign $pair key asc
            set sk [$Doc createElement text:sort-key]
            $sk setAttribute text:key $key
            if {$asc ne ""} { my SetA $sk text:sort-ascending $asc }
            $bc appendChild $sk
        }
        foreach e [$Styles getElementsByTagName text:bibliography-configuration] { $e delete }
        $Styles appendChild $bc
        return $bc
    }
    # Read the bibliography configuration as a dict of set attributes (empty if
    # none). Sort keys are reported under "sort-keys" as a list of {key ?ascending?}.
    method bibliographyConfiguration {} {
        set bc [lindex [$Styles getElementsByTagName text:bibliography-configuration] 0]
        if {$bc eq ""} { return {} }
        set known {text:prefix text:suffix text:numbered-entries text:sort-by-position \
            fo:language fo:country fo:script style:rfc-language-tag text:sort-algorithm}
        set d {}
        foreach a $known { if {[$bc hasAttribute $a]} { dict set d $a [$bc getAttribute $a] } }
        set keys {}
        foreach sk [$bc getElementsByTagName text:sort-key] {
            set entry [list [$sk getAttribute text:key ""]]
            if {[$sk hasAttribute text:sort-ascending]} {
                lappend entry [$sk getAttribute text:sort-ascending]
            }
            lappend keys $entry
        }
        if {[llength $keys]} { dict set d sort-keys $keys }
        return $d
    }

    # ODF boolean attributes must be the literals "true"/"false". Bool normalises
    # a Tcl boolean (1/0/yes/no/true/false) to "true"/"false"; any other value is
    # passed through unchanged so a wrong value still surfaces (no silent fixing).
    method Bool {v} {
        if {[string is boolean -strict $v]} { return [expr {$v ? "true" : "false"}] }
        return $v
    }
    # set an attribute, coercing the known boolean-typed ODF attributes via Bool.
    method SetA {el a v} {
        set boolAttrs {style:num-letter-sync text:number-lines text:count-empty-lines \
            text:count-in-text-boxes text:restart-on-page text:numbered-entries \
            text:sort-by-position text:sort-ascending}
        if {$a in $boolAttrs} { set v [my Bool $v] }
        $el setAttribute $a $v
        return
    }

    method flush {} { $Pkg settree styles.xml $Doc; return }

    # ---- internal ----
    method Groups {argList map} {
        set out {}
        foreach {opt props} $argList {
            if {![dict exists $map $opt]} { error "unknown option: $opt" }
            lappend out [dict get $map $opt] $props
        }
        return $out
    }
    # Order property-group children by the ODF style:style schema order.
    method OrderProps {groups} {
        set rank {style:chart-properties 1 style:drawing-page-properties 2 \
            style:graphic-properties 3 style:table-properties 4 \
            style:table-column-properties 5 style:table-row-properties 6 \
            style:table-cell-properties 7 style:list-level-properties 8 \
            style:section-properties 9 style:ruby-properties 10 \
            style:paragraph-properties 11 style:text-properties 12}
        set pairs {}
        foreach {elem props} $groups {
            set r [expr {[dict exists $rank $elem] ? [dict get $rank $elem] : 99}]
            lappend pairs [list $r $elem $props]
        }
        set out {}
        foreach p [lsort -integer -index 0 $pairs] { lappend out [lindex $p 1] [lindex $p 2] }
        return $out
    }
    method Define {name family groups} {
        foreach s [$Styles getElementsByTagName style:style] {
            if {[$s getAttribute style:name ""] eq $name} { $s delete }
        }
        set st [$Doc createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family $family
        foreach {elem props} [my OrderProps $groups] {
            set pe [$Doc createElement $elem]
            foreach {k v} $props { $pe setAttribute $k $v }
            $st appendChild $pe
        }
        $Styles appendChild $st
        return $st
    }
    # office:automatic-styles in styles.xml (or create, before office:master-styles)
    method AutoEl {} {
        set root [$Doc documentElement]
        set el [lindex [$root getElementsByTagName office:automatic-styles] 0]
        if {$el eq ""} {
            set el [$Doc createElement office:automatic-styles]
            set m [lindex [$root getElementsByTagName office:master-styles] 0]
            if {$m ne ""} { $root insertBefore $el $m } else { $root appendChild $el }
        }
        return $el
    }
    method MasterEl {} {
        set root [$Doc documentElement]
        set el [lindex [$root getElementsByTagName office:master-styles] 0]
        if {$el eq ""} { set el [$Doc createElement office:master-styles]; $root appendChild $el }
        return $el
    }
    # get office:font-face-decls (or create, before office:styles)
    method FontDeclsEl {} {
        set root [$Doc documentElement]
        set el [lindex [$root getElementsByTagName office:font-face-decls] 0]
        if {$el eq ""} {
            set el [$Doc createElement office:font-face-decls]
            $root insertBefore $el [lindex [$root getElementsByTagName office:styles] 0]
        }
        return $el
    }
    method FindMaster {masterName} {
        foreach m [[my MasterEl] getElementsByTagName style:master-page] {
            if {[$m getAttribute style:name ""] eq $masterName} { return $m }
        }
        return ""
    }
    method HFTag {base side} {
        switch -- $side {
            "" - default { return $base }
            left         { return ${base}-left }
            first        { return ${base}-first }
            default      { error "unknown -side: $side (default|left|first)" }
        }
    }
    method SideOpt {argList} {
        set side ""
        foreach {k v} $argList { if {$k eq "-side"} { set side $v } else { error "unknown option: $k" } }
        return $side
    }
    method SplitSide {argList} {
        set side ""; set rest {}
        foreach {k v} $argList { if {$k eq "-side"} { set side $v } else { lappend rest $k $v } }
        return [list $side $rest]
    }
    method InsertHF {mp el tag} {
        set rank {style:header 1 style:header-left 2 style:header-first 3 \
                  style:footer 4 style:footer-left 5 style:footer-first 6}
        set r [dict get $rank $tag]
        set ref ""
        foreach c [$mp childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE"} continue
            set cn [$c nodeName]
            if {[dict exists $rank $cn] && [dict get $rank $cn] > $r} { set ref $c; break }
        }
        if {$ref ne ""} { $mp insertBefore $el $ref } else { $mp appendChild $el }
    }
    method HeaderFooter {masterName tag lines} {
        set mp [my FindMaster $masterName]
        if {$mp eq ""} { error "master-page missing: $masterName (define it first with defineMasterPage)" }
        foreach e [$mp getElementsByTagName $tag] { $e delete }
        set hf [$Doc createElement $tag]
        foreach spec $lines {
            set txt [lindex $spec 0]
            set sty [lindex $spec 1]
            set p [$Doc createElement text:p]
            if {$sty ne ""} { $p setAttribute text:style-name $sty }
            my MakeRuns $p $txt
            $hf appendChild $p
        }
        my InsertHF $mp $hf $tag
        my EnsureHFStyle $masterName $tag
        return $hf
    }
    # Three-region header/footer. args: ?-left T? ?-center T? ?-right T?.
    # Left/center/right via ONE paragraph with center + right tab stops -- this is
    # how Writer renders multi-part headers (style:region-* is ignored by Writer
    # text headers). Each option is a text string (field tokens allowed).
    method HFParts {masterName tag args} {
        set mp [my FindMaster $masterName]
        if {$mp eq ""} { error "master-page missing: $masterName (define it first with defineMasterPage)" }
        set parts [dict create left "" center "" right ""]
        foreach {k v} $args {
            switch -- $k {
                -left   { dict set parts left   $v }
                -center { dict set parts center $v }
                -right  { dict set parts right  $v }
                default { error "unknown option: $k" }
            }
        }
        set styleName [my EnsureHFParaStyle $masterName]
        foreach e [$mp getElementsByTagName $tag] { $e delete }
        set hf [$Doc createElement $tag]
        set p  [$Doc createElement text:p]
        if {$styleName ne ""} { $p setAttribute text:style-name $styleName }
        my MakeRuns $p [dict get $parts left]
        $p appendChild [$Doc createElement text:tab]
        my MakeRuns $p [dict get $parts center]
        $p appendChild [$Doc createElement text:tab]
        my MakeRuns $p [dict get $parts right]
        $hf appendChild $p
        my InsertHF $mp $hf $tag
        my EnsureHFStyle $masterName $tag
        return $hf
    }
    # Parse an ODF length "<num><unit>" -> {num unit}.
    method ParseLen {v} {
        if {[regexp {^\s*([0-9]+(?:\.[0-9]+)?)\s*([a-z]+)\s*$} $v -> num unit]} {
            return [list $num $unit]
        }
        error "cannot parse length: $v"
    }
    # Printable text width (page-width - left/right margins) of a master's layout.
    method HFTextWidth {masterName} {
        set plName [my masterPageLayout $masterName]
        if {$plName eq ""} { return "" }
        set pp [my pageLayoutProps $plName]
        if {![dict exists $pp fo:page-width]} { return "" }
        lassign [my ParseLen [dict get $pp fo:page-width]] pw unit
        set ml 0; set mr 0
        if {[dict exists $pp fo:margin-left]}  { lassign [my ParseLen [dict get $pp fo:margin-left]]  ml _ }
        if {[dict exists $pp fo:margin-right]} { lassign [my ParseLen [dict get $pp fo:margin-right]] mr _ }
        if {[dict exists $pp fo:margin] && ![dict exists $pp fo:margin-left]} {
            lassign [my ParseLen [dict get $pp fo:margin]] m _; set ml $m; set mr $m
        }
        return [list [expr {$pw - $ml - $mr}] $unit]
    }
    # Ensure an automatic paragraph style (in styles.xml) with center+right tab
    # stops for the master's text width; return its name ("" if width unknown).
    method EnsureHFParaStyle {masterName} {
        set wp [my HFTextWidth $masterName]
        if {$wp eq ""} { return "" }
        lassign $wp w unit
        set name "HF[regsub -all {[^A-Za-z0-9]} $masterName {}]"
        foreach st [[my AutoEl] getElementsByTagName style:style] {
            if {[$st getAttribute style:name ""] eq $name} { return $name }
        }
        set st [$Doc createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family paragraph
        set pp [$Doc createElement style:paragraph-properties]
        set ts [$Doc createElement style:tab-stops]
        set c [$Doc createElement style:tab-stop]
        $c setAttribute style:position "[expr {$w / 2.0}]$unit"
        $c setAttribute style:type center
        set r [$Doc createElement style:tab-stop]
        $r setAttribute style:position "$w$unit"
        $r setAttribute style:type right
        $ts appendChild $c; $ts appendChild $r
        $pp appendChild $ts
        $st appendChild $pp
        [my AutoEl] appendChild $st
        return $name
    }
    # split text into text nodes + fields. Tokens: %page% %pages% %date% %time%
    # %title% %author% %subject% %file%; %% is a literal percent sign.
    method MakeRuns {p text} {
        set fields {page text:page-number pages text:page-count \
                    date text:date time text:time title text:title \
                    author text:author-name subject text:subject file text:file-name}
        set re {%(?:pages|page|date|time|title|author|subject|file)%|%%}
        set rest $text
        while {[regexp -indices $re $rest m]} {
            lassign $m a b
            if {$a > 0} { $p appendChild [$Doc createTextNode [string range $rest 0 [expr {$a-1}]]] }
            set tok [string range $rest $a $b]
            if {$tok eq "%%"} {
                $p appendChild [$Doc createTextNode "%"]
            } else {
                set name [string trim $tok %]
                $p appendChild [$Doc createElement [dict get $fields $name]]
            }
            set rest [string range $rest [expr {$b + 1}] end]
        }
        if {$rest ne ""} { $p appendChild [$Doc createTextNode $rest] }
    }
    # ensure header-style/footer-style in the associated page-layout
    method EnsureHFStyle {masterName tag} {
        set plName [my masterPageLayout $masterName]
        if {$plName eq ""} return
        set base [expr {[string match "style:header*" $tag] ? "style:header" : "style:footer"}]
        my EnsureHFStyleEl $plName $base
        return
    }
    # Ensure style:header-style/footer-style (+ header-footer-properties) exist in
    # the page-layout; return the style:header-footer-properties element.
    method EnsureHFStyleEl {plName base} {
        set pl ""
        foreach x [[my AutoEl] getElementsByTagName style:page-layout] {
            if {[$x getAttribute style:name ""] eq $plName} { set pl $x; break }
        }
        if {$pl eq ""} { return "" }
        set styleTag [expr {$base eq "style:header" ? "style:header-style" : "style:footer-style"}]
        set hs [lindex [$pl getElementsByTagName $styleTag] 0]
        if {$hs eq ""} {
            set hs [$Doc createElement $styleTag]
            set hp [$Doc createElement style:header-footer-properties]
            $hp setAttribute fo:min-height 0.6cm
            if {$base eq "style:header"} {
                $hp setAttribute fo:margin-bottom 0.3cm
            } else {
                $hp setAttribute fo:margin-top 0.3cm
            }
            $hs appendChild $hp
            if {$styleTag eq "style:header-style"} {
                set plp [lindex [$pl getElementsByTagName style:page-layout-properties] 0]
                set after [$plp nextSibling]
                if {$after ne ""} { $pl insertBefore $hs $after } else { $pl appendChild $hs }
            } else {
                $pl appendChild $hs
            }
        }
        return [lindex [$hs getElementsByTagName style:header-footer-properties] 0]
    }
    method HFLines {masterName tag} {
        set mp [my FindMaster $masterName]
        if {$mp eq ""} { return {} }
        set hf [lindex [$mp getElementsByTagName $tag] 0]
        if {$hf eq ""} { return {} }
        set res {}
        foreach p [$hf getElementsByTagName text:p] { lappend res [$p asText] }
        return $res
    }
    # Read three-region header/footer: dict with keys left/center/right (only
    # those present). Empty dict if the master-page has no such header/footer.
    # Read a tab-split header/footer paragraph as {left .. center .. right ..}.
    method HFPartsRead {masterName tag} {
        set mp [my FindMaster $masterName]
        if {$mp eq ""} { return [dict create] }
        set hf [lindex [$mp getElementsByTagName $tag] 0]
        if {$hf eq ""} { return [dict create] }
        set p [lindex [$hf getElementsByTagName text:p] 0]
        if {$p eq ""} { return [dict create] }
        set segs [list ""]
        foreach c [$p childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:tab"} {
                lappend segs ""
            } elseif {[$c nodeType] eq "TEXT_NODE"} {
                lset segs end "[lindex $segs end][$c nodeValue]"
            } else {
                lset segs end "[lindex $segs end][$c asText]"
            }
        }
        set keys {left center right}
        set d [dict create]
        for {set i 0} {$i < [llength $segs] && $i < 3} {incr i} {
            dict set d [lindex $keys $i] [lindex $segs $i]
        }
        return $d
    }
}

package provide odf::style 0.20
