## 0.24: ODS completeness niches in one slice.
##  - label-ranges: addLabelRange + labelRanges reader. Body prelude
##    element after content-validations.
##  - table scenario: setTableScenario + tableScenario reader. Optional
##    table:scenario child of a table:table (singleton per table),
##    inserted before the columns.
##  - dde-links: addDDELink + ddeLinks reader. Epilogue wrapper with
##    one table:dde-link per source (office:dde-source + minimal embedded
##    table). Reads dde-application/topic/item/name/auto-update/conv-mode.
##  Gap-tests for label-ranges and dde-links are closed; gap text narrowed
##  accordingly.
## 0.23: rich-text cell writing. New setCellRichText cell paragraph ?p2 ...?:
##       each paragraph is a list of run tokens -- {text X}, {span STYLE X},
##       {link HREF X ?STYLE?}, lb, tab, {space N}. Cell becomes string-typed;
##       multiple text:p children are emitted (one per paragraph), each with
##       the corresponding inline run mix. cellText already read this back
##       since the RichText helper handles spans/breaks/tabs recursively.
## 0.22: pivot depth tier 1. Pivot fields can now carry a table:data-pilot-level
##       wrapper with table:data-pilot-subtotals (per-level aggregation
##       functions) and table:data-pilot-members (selected/hidden members).
##       New field-spec tokens: -show-empty BOOL, -subtotals {fn ...},
##       -members {{name ?display?} ...}. Reader returns per-field level info.
##       Out of scope for this slice: data-pilot-display-info, sort-info,
##       layout-info, and the parallel data-pilot-groups branch -- separate
##       slices when needed.
## 0.21: formula API stabilised. setFormula now takes an optional value-spec
##       third arg ({float 10}, {string "x"}, ...) so a cell can be turned
##       into a formula-with-cached-value retroactively (previously only the
##       addRow {formula OF inner-spec} path could do this). setFormula with
##       formula="" removes table:formula (clear). New cellHasFormula reader.
##       Internals: value-attribute logic extracted from Cell into ApplyValueSpec.
## 0.20: explicit table:display="true" on table:help-message / table:error-message
##       so the messages actually show up in LibreOffice (RNG has no default;
##       LO treats the missing attribute as 'do not display'). New options
##       -help-display BOOL and -error-display BOOL on addContentValidation;
##       reader extended with help-display / error-display keys. Default true
##       when the message is emitted -- mirrors LO's reference output.
## 0.19: calculation settings (ODS slice 7). table:calculation-settings is the
##       first table-decls prelude element (before content-validations). It
##       controls how a consumer recalculates: case sensitivity, wildcards vs
##       regex in formulas, precision-as-shown, the null date, and iterative
##       calculation. New API: setCalculationSettings, calculationSettings.
## 0.18: pivot tables / data pilots (ODS slice 6). table:data-pilot-table is a
##       spreadsheet epilogue container (after database-ranges). MVP: a source
##       cell range plus fields with orientation (row/column/data/page) and an
##       optional aggregation function. ODF normalises format + function
##       semantics; the consumer (LibreOffice) generates the displayed result
##       in the target range. New API: addDataPilotTable, dataPilotTables.
## 0.17: subtotals (ODS slice 5) -- table:subtotal-rules, a child of
##       table:database-range (after sort). Grouped aggregation using the same
##       function enums as data pilots (sum/count/average/...). Added as the
##       -subtotals option on addDatabaseRange; databaseRanges reports them.
## 0.16: database ranges + AutoFilter (ODS slice 4). table:database-ranges is
##       a spreadsheet epilogue container (after named-expressions). New API:
##       addDatabaseRange (target range, filter buttons, optional filter/sort),
##       databaseRanges (reader). Epilogue order is normalised by OrderEpilogue.
## 0.15: conditional formatting (ODS slice 3) via style:map -- the official,
##       validator-clean mechanism (calcext:* is a non-standard LO extension,
##       absent from the ODF 1.3 RNG, so not used). New API:
##       defineConditionalFormat (table-cell style + style:map children),
##       styleMaps (reader).
## 0.14: content validation (data validation) -- ODS slice 2. table:
##       content-validations is a PRELUDE container (before the tables).
##       New API: addContentValidation (writer), setCellValidation/
##       cellValidation (cell ref), contentValidations (reader).
## 0.13: named ranges + named expressions (ODS slice 1 of the spreadsheet
##       feature block). table:named-expressions container holds
##       table:named-range (name + cell-range-address, optional base-cell +
##       range-usable-as) and table:named-expression (name + expression,
##       optional base-cell). Per ODF 1.3 the container is document-level
##       epilogue content -- it must come AFTER all table:table children;
##       addTable keeps it last if present, so call order does not matter.
##       New API: addNamedRange / addNamedExpression (writers),
##       namedRanges / namedExpressions (readers, name->address/expression).
## sheet-0.12.tm  --  ODS (OpenDocument Spreadsheet), slice 1..9
## 0.12: newSheetTemplate -- create a .ots spreadsheet template (setMimetype).
##
## Sibling of odf::text: works on content.xml's office:spreadsheet. Reuses the
## format-neutral odf::Package (container) and odf::Styles (styles.xml).
##
##   package require odf::sheet
##   set pkg [odf::newSheetDoc]
##   set sh  [odf::Sheet new $pkg]
##   set t   [$sh addTable "Sheet1"]
##   $sh addColumns $t 3
##   $sh addStringRow $t {Name Qty Note}
##   $sh addRow $t {{string Bob} {float 42} {percentage 0.2} {currency 9.9 EUR} \
##                  {date 2026-06-02} {time PT1H30M} {boolean true}}
##   $sh flush ; $pkg save out.ods
##
## Slice 1: tables (sheets), columns, rows, string + float cells, read-back.
## Slice 2 (read): number-columns-repeated / number-rows-repeated are expanded
## on read; trailing empty (fill) cells/rows are trimmed, so real LibreOffice
## Calc files -- which repeat blank cells/rows up to the sheet limits -- read
## back to their logical extent without materialising the huge fill.
## Slice 3 (read): typed values for every value-type (float/percentage/
## currency via office:value, date via office:date-value, time via
## office:time-value, boolean via office:boolean-value, string via
## office:string-value); rich cellText (multi-paragraph joined by \n, text:s
## spaces, text:tab, text:line-break); cell merges -- covered cells are kept as
## column positions and cellSpan/cellCovered expose the merge.
## Slice 4 (read): cellFormula exposes the raw table:formula (OpenFormula).
## Slice 5 (write): typed cell specs beyond string/float --
##   {percentage N ?disp?}  {currency N ?CUR? ?disp?}  {date ISO ?disp?}
##   {time DURATION ?disp?}  {boolean true|false ?disp?}
## written with the matching office:*-value attribute + a display text:p.
## Slice 9 (write): column widths + binding a page (master-page) to a sheet.
##   defineColumnStyle / addColumnWidths set style:column-width on table-columns;
##   defineTableStyle name -master MP makes a family=table style carrying
##   style:master-page-name, assigned to a sheet via addTable's style arg. The
##   page-layout / master-page / header / footer themselves are built with the
##   existing odf::Styles API on styles.xml (definePageFormat, defineMasterPage,
##   setHeader/setFooter). Readers: tableStyleName, masterPageOf, columnWidthOf.
## Slice 8 (write): merges and formulas.
##   mergeCells table r0 c0 ncols nrows -- sets number-columns/rows-spanned on
##     the anchor and turns the covered positions into table:covered-table-cell
##     (operates on the plain grid this writer builds: one cell per column).
##   cell spec {formula OF VALSPEC...} writes table:formula plus the cached
##     typed value (e.g. {formula {of:=SUM([.A1:.B1])} float 10}); setFormula
##     attaches a formula to an existing cell.
## Slice 7 (write): guarantee the mandatory table:table-column structure --
## ODF requires >=1 column, before the rows, and LibreOffice expects columns
## covering the widest row. flush now ensures this for every table even when
## addColumns was not called (columns are required structure, not "magic").
## Slice 6 (write): number formats. define{Number,Percentage,Currency,Date,
## Time,Boolean}Style create number: data styles in content.xml automatic-
## styles; defineCellFormat links a table-cell style to a data style; addRow's
## optional cellStyles assigns per-cell table:style-name. Reading: cellStyleName
## and dataStyleOf resolve the chain. "No magic": cell type stays explicit; no number guessing.

package require Tcl 8.6 9
package require tdom
package require odf

namespace eval odf {}

## Empty spreadsheet document skeleton (mirrors odf::newTextDoc).
proc odf::newSheetDoc {} {
    set NS_O urn:oasis:names:tc:opendocument:xmlns:office:1.0
    set mimetype "application/vnd.oasis.opendocument.spreadsheet"
    set manifest "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<manifest:manifest xmlns:manifest=\"urn:oasis:names:tc:opendocument:xmlns:manifest:1.0\" manifest:version=\"1.3\"><manifest:file-entry manifest:full-path=\"/\" manifest:media-type=\"$mimetype\"/><manifest:file-entry manifest:full-path=\"content.xml\" manifest:media-type=\"text/xml\"/><manifest:file-entry manifest:full-path=\"styles.xml\" manifest:media-type=\"text/xml\"/><manifest:file-entry manifest:full-path=\"meta.xml\" manifest:media-type=\"text/xml\"/></manifest:manifest>"
    set content "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-content xmlns:office=\"$NS_O\" xmlns:style=\"urn:oasis:names:tc:opendocument:xmlns:style:1.0\" xmlns:text=\"urn:oasis:names:tc:opendocument:xmlns:text:1.0\" xmlns:table=\"urn:oasis:names:tc:opendocument:xmlns:table:1.0\" xmlns:fo=\"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0\" xmlns:number=\"urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0\" xmlns:of=\"urn:oasis:names:tc:opendocument:xmlns:of:1.2\" xmlns:draw=\"urn:oasis:names:tc:opendocument:xmlns:drawing:1.0\" xmlns:svg=\"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" office:version=\"1.3\"><office:body><office:spreadsheet/></office:body></office:document-content>"
    set styles "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-styles xmlns:office=\"$NS_O\" xmlns:style=\"urn:oasis:names:tc:opendocument:xmlns:style:1.0\" xmlns:fo=\"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0\" xmlns:text=\"urn:oasis:names:tc:opendocument:xmlns:text:1.0\" xmlns:table=\"urn:oasis:names:tc:opendocument:xmlns:table:1.0\" xmlns:number=\"urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0\" xmlns:svg=\"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0\" office:version=\"1.3\"><office:styles/><office:automatic-styles/><office:master-styles/></office:document-styles>"
    set meta "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-meta xmlns:office=\"$NS_O\" xmlns:meta=\"urn:oasis:names:tc:opendocument:xmlns:meta:1.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" office:version=\"1.3\"><office:meta><meta:generator>odf-tcl</meta:generator></office:meta></office:document-meta>"

    set pkg [odf::Package new]
    $pkg setpart mimetype $mimetype
    $pkg setpart META-INF/manifest.xml [encoding convertto utf-8 $manifest]
    $pkg setpart content.xml [encoding convertto utf-8 $content]
    $pkg setpart styles.xml  [encoding convertto utf-8 $styles]
    $pkg setpart meta.xml    [encoding convertto utf-8 $meta]
    return $pkg
}

## Slice 11 (fix): freeze settings.xml must declare xmlns:ooo, else LibreOffice
## silently ignores the view-settings (verified via headless LO hasFrozenPanes).
## Slice 10 (write+read): print ranges + freeze panes. setPrintRange sets the
## table:print-ranges attribute (content.xml, validated). freezePanes records a
## per-sheet freeze that flush emits into settings.xml (LibreOffice view-settings,
## HorizontalSplitMode/VerticalSplitMode = 2 = freeze). Readers: printRange,
## freezeOf.
oo::class create odf::Sheet {
    variable Pkg Doc Body Freezes

    constructor {pkg} {
        set Pkg $pkg
        set Doc [$pkg tree content.xml]
        set Body [lindex [[$Doc documentElement] getElementsByTagName office:spreadsheet] 0]
        if {$Body eq ""} { error "no office:spreadsheet in content.xml" }
        set Freezes [dict create]
        $Pkg registerFlushHook [list [self] flush]
    }
    destructor { if {[info exists Doc] && $Doc ne ""} { $Doc delete } }

    # ---- write ----

    # A sheet: table:table with table:name. Returns the table node.
    method addTable {name {style ""}} {
        set t [$Doc createElement table:table]
        $t setAttribute table:name $name
        if {$style ne ""} { $t setAttribute table:style-name $style }
        $Body appendChild $t
        # 0.16: keep the spreadsheet epilogue containers last and in RNG order
        # (named-expressions, then database-ranges), regardless of call order.
        my OrderEpilogue
        return $t
    }
    # Print range(s) for a sheet: an ODF cell-range-address list, e.g.
    # "Sheet1.A1:Sheet1.D10" (space-separate several). Sets table:print-ranges.
    method setPrintRange {table range} { $table setAttribute table:print-ranges $range; return $table }
    method printRange {table} { return [$table getAttribute table:print-ranges ""] }
    # Freeze the first <cols> columns and <rows> rows of a sheet (0 = no freeze in
    # that direction). Emitted into settings.xml on flush; LibreOffice honours it.
    method freezePanes {table cols rows} {
        if {![string is integer -strict $cols] || ![string is integer -strict $rows] || $cols < 0 || $rows < 0} {
            error "freezePanes: cols and rows must be non-negative integers"
        }
        dict set Freezes [$table getAttribute table:name ""] [list $cols $rows]
        return $table
    }
    # {cols rows} freeze for a sheet from settings.xml, or {} if none.
    method freezeOf {table} {
        set name [$table getAttribute table:name ""]
        if {![$Pkg has settings.xml]} { return {} }
        set sd [$Pkg tree settings.xml]
        set cols 0; set rows 0; set found 0
        foreach e [[$sd documentElement] getElementsByTagName config:config-item-map-entry] {
            if {[$e getAttribute config:name ""] ne $name} continue
            set found 1
            foreach ci [$e getElementsByTagName config:config-item] {
                switch -- [$ci getAttribute config:name ""] {
                    HorizontalSplitPosition { set cols [$ci asText] }
                    VerticalSplitPosition   { set rows [$ci asText] }
                }
            }
        }
        $sd delete
        if {!$found} { return {} }
        return [list $cols $rows]
    }

    # Declare n columns (table:table-column). Optional column style-name.
    method addColumns {table n {style ""}} {
        for {set i 0} {$i < $n} {incr i} {
            set c [$Doc createElement table:table-column]
            if {$style ne ""} { $c setAttribute table:style-name $style }
            $table appendChild $c
        }
        return
    }

    # Build a table:table-cell from an explicit spec {type value}.
    #   {string S} -> office:value-type=string, <text:p>S</text:p>
    #   {float  N} -> office:value-type=float, office:value=N, <text:p>N</text:p>
    method NormBool {v} {
        switch -- [string tolower $v] {
            true - 1 - yes { return true }
            false - 0 - no { return false }
            default { error "boolean cell value must be true/false: $v" }
        }
    }
    # Build a table:table-cell from an explicit spec. Forms:
    #   {string TEXT}
    #   {float N ?display?}        {percentage N ?display?}
    #   {currency N ?CUR? ?display?}
    #   {date ISO ?display?}       {time DURATION ?display?}
    #   {boolean true|false ?display?}
    # The display text:p is the value unless an explicit display is given
    # (nice locale formatting needs a number: data style -- later slice).
    method Cell {spec} {
        set type [lindex $spec 0]
        if {$type eq "formula"} {
            # {formula OF-STRING INNER-SPEC...}: build the inner typed cell,
            # then attach table:formula. INNER-SPEC is a normal cell spec
            # carrying the cached result, e.g. {float 10}.
            set inner [lrange $spec 2 end]
            if {![llength $inner]} { error "formula cell needs an inner value spec: {formula OF {float N}}" }
            set cell [my Cell $inner]
            $cell setAttribute table:formula [lindex $spec 1]
            return $cell
        }
        set cell [$Doc createElement table:table-cell]
        my ApplyValueSpec $cell $spec
        return $cell
    }

    # Apply a typed value spec (string/float/percentage/currency/date/time/
    # boolean) to an existing table:table-cell: sets office:value-type and the
    # type-specific value attribute, and (re)builds the display text:p. Strips
    # prior office:* value attributes and prior text:p children so the cell
    # ends up in a consistent state. Does NOT touch table:formula -- callers
    # combine ApplyValueSpec + setFormula explicitly. The "formula" type is
    # handled in Cell, not here, to keep this helper single-purpose.
    method ApplyValueSpec {cell spec} {
        set type [lindex $spec 0]
        set val  [lindex $spec 1]
        # Strip prior value-* attributes (we are replacing the value)
        foreach a {office:value-type office:value office:date-value \
                   office:time-value office:boolean-value office:string-value \
                   office:currency} {
            if {[$cell hasAttribute $a]} { $cell removeAttribute $a }
        }
        # Strip prior text:p children (we will rebuild the display)
        foreach c [$cell childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:p"} {
                $cell removeChild $c
            }
        }
        switch -- $type {
            string {
                $cell setAttribute office:value-type string
                set display $val
            }
            float - percentage {
                if {![string is double -strict $val]} { error "$type cell value not numeric: $val" }
                $cell setAttribute office:value-type $type
                $cell setAttribute office:value $val
                set display [expr {[llength $spec] >= 3 ? [lindex $spec 2] : $val}]
            }
            currency {
                if {![string is double -strict $val]} { error "currency cell value not numeric: $val" }
                $cell setAttribute office:value-type currency
                $cell setAttribute office:value $val
                if {[llength $spec] >= 3 && [lindex $spec 2] ne ""} {
                    $cell setAttribute office:currency [lindex $spec 2]
                }
                set display [expr {[llength $spec] >= 4 ? [lindex $spec 3] : $val}]
            }
            date {
                $cell setAttribute office:value-type date
                $cell setAttribute office:date-value $val
                set display [expr {[llength $spec] >= 3 ? [lindex $spec 2] : $val}]
            }
            time {
                $cell setAttribute office:value-type time
                $cell setAttribute office:time-value $val
                set display [expr {[llength $spec] >= 3 ? [lindex $spec 2] : $val}]
            }
            boolean {
                set b [my NormBool $val]
                $cell setAttribute office:value-type boolean
                $cell setAttribute office:boolean-value $b
                set display [expr {[llength $spec] >= 3 ? [lindex $spec 2] : $b}]
            }
            default {
                error "unknown cell type: $type (string|float|percentage|currency|date|time|boolean)"
            }
        }
        set p [$Doc createElement text:p]
        $p appendChild [$Doc createTextNode $display]
        $cell appendChild $p
        return $cell
    }

    # Row from a list of explicit cell specs (see Cell). Optional cellStyles =
    # a parallel list of table-cell style names (from defineCellFormat) applied
    # as table:style-name per cell.
    method addRow {table cells {cellStyles ""}} {
        set row [$Doc createElement table:table-row]
        set i 0
        foreach spec $cells {
            set cell [my Cell $spec]
            set cs [lindex $cellStyles $i]
            if {$cs ne ""} { $cell setAttribute table:style-name $cs }
            $row appendChild $cell
            incr i
        }
        $table appendChild $row
        return $row
    }

    # Convenience: a row of plain string cells.
    method addStringRow {table values} {
        set specs {}
        foreach v $values { lappend specs [list string $v] }
        return [my addRow $table $specs]
    }

    # ---- number formats (data styles) ----
    # office:automatic-styles in content.xml (created before office:body).
    method AutoStylesEl {} {
        set root [$Doc documentElement]
        set el [lindex [$root getElementsByTagName office:automatic-styles] 0]
        if {$el eq ""} {
            set el [$Doc createElement office:automatic-styles]
            set body [lindex [$root getElementsByTagName office:body] 0]
            $root insertBefore $el $body
        }
        return $el
    }
    method NumText {parent t} {
        set e [$Doc createElement number:text]
        $e appendChild [$Doc createTextNode $t]
        $parent appendChild $e
        return $e
    }
    # <number:number-style>: -decimals N (2), -grouping 0/1, -min-integer N (1).
    method defineNumberStyle {name args} {
        set dec 2; set grp 0; set mi 1
        foreach {k v} $args { switch -- $k {
            -decimals {set dec $v} -grouping {set grp $v} -min-integer {set mi $v}
            default {error "unknown option: $k"} } }
        set st [$Doc createElement number:number-style]
        $st setAttribute style:name $name
        set n [$Doc createElement number:number]
        $n setAttribute number:decimal-places $dec
        $n setAttribute number:min-integer-digits $mi
        if {$grp} { $n setAttribute number:grouping true }
        $st appendChild $n
        [my AutoStylesEl] appendChild $st
        return $name
    }
    # <number:percentage-style>: number + "%". -decimals N (2).
    method definePercentageStyle {name args} {
        set dec 2
        foreach {k v} $args { switch -- $k {-decimals {set dec $v} default {error "unknown option: $k"}} }
        set st [$Doc createElement number:percentage-style]
        $st setAttribute style:name $name
        set n [$Doc createElement number:number]
        $n setAttribute number:decimal-places $dec
        $n setAttribute number:min-integer-digits 1
        $st appendChild $n
        my NumText $st "%"
        [my AutoStylesEl] appendChild $st
        return $name
    }
    # <number:currency-style>: -decimals N (2), -symbol S (EUR sign), -grouping 0/1,
    # -symbol-first 0/1 (0 = "1,00 €", 1 = "€ 1,00").
    method defineCurrencyStyle {name args} {
        set dec 2; set sym "€"; set grp 1; set first 0
        foreach {k v} $args { switch -- $k {
            -decimals {set dec $v} -symbol {set sym $v} -grouping {set grp $v} -symbol-first {set first $v}
            default {error "unknown option: $k"} } }
        set st [$Doc createElement number:currency-style]
        $st setAttribute style:name $name
        set n [$Doc createElement number:number]
        $n setAttribute number:decimal-places $dec
        $n setAttribute number:min-integer-digits 1
        if {$grp} { $n setAttribute number:grouping true }
        set cs [$Doc createElement number:currency-symbol]
        $cs appendChild [$Doc createTextNode $sym]
        if {$first} { $st appendChild $cs; my NumText $st " "; $st appendChild $n }         else        { $st appendChild $n;  my NumText $st " "; $st appendChild $cs }
        [my AutoStylesEl] appendChild $st
        return $name
    }
    # <number:date-style>: -order dmy|ymd|mdy (dmy), -sep S (".").
    method defineDateStyle {name args} {
        set order dmy; set sep "."
        foreach {k v} $args { switch -- $k {-order {set order $v} -sep {set sep $v} default {error "unknown option: $k"}} }
        set map {d number:day m number:month y number:year}
        set st [$Doc createElement number:date-style]
        $st setAttribute style:name $name
        set parts [split $order ""]
        set i 0
        foreach ch $parts {
            if {![dict exists $map $ch]} { error "date -order chars must be d/m/y: $order" }
            set e [$Doc createElement [dict get $map $ch]]
            $e setAttribute number:style long
            $st appendChild $e
            if {$i < [llength $parts]-1} { my NumText $st $sep }
            incr i
        }
        [my AutoStylesEl] appendChild $st
        return $name
    }
    # <number:time-style>: -seconds 0/1 (0).
    method defineTimeStyle {name args} {
        set sec 0
        foreach {k v} $args { switch -- $k {-seconds {set sec $v} default {error "unknown option: $k"}} }
        set st [$Doc createElement number:time-style]
        $st setAttribute style:name $name
        set h [$Doc createElement number:hours];   $h setAttribute number:style long; $st appendChild $h
        my NumText $st ":"
        set m [$Doc createElement number:minutes]; $m setAttribute number:style long; $st appendChild $m
        if {$sec} { my NumText $st ":"; set se [$Doc createElement number:seconds]; $se setAttribute number:style long; $st appendChild $se }
        [my AutoStylesEl] appendChild $st
        return $name
    }
    method defineBooleanStyle {name} {
        set st [$Doc createElement number:boolean-style]
        $st setAttribute style:name $name
        $st appendChild [$Doc createElement number:boolean]
        [my AutoStylesEl] appendChild $st
        return $name
    }
    # A table-cell automatic style that links to a data style. Optional -cell
    # {fo:.. ..} props for cell-properties (e.g. alignment/background).
    method defineCellFormat {name dataStyle args} {
        set cellProps {}
        foreach {k v} $args { switch -- $k {-cell {set cellProps $v} default {error "unknown option: $k"}} }
        set st [$Doc createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family table-cell
        if {$dataStyle ne ""} { $st setAttribute style:data-style-name $dataStyle }
        if {[llength $cellProps]} {
            set pe [$Doc createElement style:table-cell-properties]
            foreach {a val} $cellProps { $pe setAttribute $a $val }
            $st appendChild $pe
        }
        [my AutoStylesEl] appendChild $st
        return $name
    }

    # ---- 0.15: conditional formatting via style:map ---------------------
    # defineConditionalFormat NAME ?-data DATASTYLE? ?-cell {fo:.. ..}?
    #         ?-paragraph {fo:.. ..}? ?-text {fo:.. ..}?
    #         -map {CONDITION APPLY-STYLE ?BASE-CELL?} ...
    # Builds a table-cell style:style with optional own data-style and
    # property groups, plus one or more style:map children -- the official ODF
    # conditional-formatting mechanism. Property groups are emitted in the RNG
    # order for table-cell (cell -> paragraph -> text); use -text for font
    # weight/colour (e.g. {fo:font-weight bold fo:color #cc0000}), -cell for
    # background/border. Each -map is {condition apply-style-name ?base?};
    # CONDITION is an ODF condition passed through verbatim (value()>100,
    # cell-content()="X", cell-content-is-between(1,9)). APPLY-STYLE names
    # another table-cell style applied when the condition holds. style:map
    # children are emitted LAST, as the RNG requires. Returns the style name.
    method defineConditionalFormat {name args} {
        set dataStyle ""; set cellProps {}; set parProps {}; set textProps {}
        set maps {}
        foreach {k v} $args {
            switch -- $k {
                -data      { set dataStyle $v }
                -cell      { set cellProps $v }
                -paragraph { set parProps $v }
                -text      { set textProps $v }
                -map       { lappend maps $v }
                default { error "unknown option: $k" }
            }
        }
        if {![llength $maps]} {
            error "defineConditionalFormat: at least one -map required"
        }
        set st [$Doc createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family table-cell
        if {$dataStyle ne ""} { $st setAttribute style:data-style-name $dataStyle }
        # property groups in RNG order for table-cell: cell, paragraph, text
        foreach {opt el} {cellProps style:table-cell-properties \
                          parProps  style:paragraph-properties \
                          textProps style:text-properties} {
            set props [set $opt]
            if {[llength $props]} {
                set pe [$Doc createElement $el]
                foreach {a val} $props { $pe setAttribute $a $val }
                $st appendChild $pe
            }
        }
        foreach m $maps {
            lassign $m cond applyStyle base
            if {$cond eq "" || $applyStyle eq ""} {
                error "bad -map: need {condition apply-style-name ?base?}"
            }
            set mp [$Doc createElement style:map]
            $mp setAttribute style:condition $cond
            $mp setAttribute style:apply-style-name $applyStyle
            if {$base ne ""} { $mp setAttribute style:base-cell-address $base }
            $st appendChild $mp
        }
        [my AutoStylesEl] appendChild $st
        return $name
    }
    # styleMaps STYLENAME -> list of {condition apply-style-name base} (base "" if absent)
    method styleMaps {styleName} {
        set out {}
        foreach st [[my AutoStylesEl] childNodes] {
            if {[$st nodeType] ne "ELEMENT_NODE" || [$st nodeName] ne "style:style"} continue
            if {[$st getAttribute style:name ""] ne $styleName} continue
            foreach m [$st childNodes] {
                if {[$m nodeType] eq "ELEMENT_NODE" && [$m nodeName] eq "style:map"} {
                    lappend out [list \
                        [$m getAttribute style:condition ""] \
                        [$m getAttribute style:apply-style-name ""] \
                        [$m getAttribute style:base-cell-address ""]]
                }
            }
        }
        return $out
    }
    method TableMaxWidth {table} {
        set w 0
        foreach r [$table childNodes] {
            if {[$r nodeType] ne "ELEMENT_NODE" || [$r nodeName] ne "table:table-row"} continue
            set n 0
            foreach c [my CellNodes $r] { incr n [my Rep $c table:number-columns-repeated] }
            if {$n > $w} { set w $n }
        }
        return $w
    }
    method ColumnCount {table} {
        set n 0
        foreach c [$table childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:table-column"} {
                incr n [my Rep $c table:number-columns-repeated]
            }
        }
        return $n
    }
    method EnsureColumns {table} {
        set width [my TableMaxWidth $table]
        if {$width < 1} { set width 1 }
        set need [expr {$width - [my ColumnCount $table]}]
        if {$need < 1} return
        set col [$Doc createElement table:table-column]
        if {$need > 1} { $col setAttribute table:number-columns-repeated $need }
        set firstRow ""
        foreach c [$table childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:table-row"} { set firstRow $c; break }
        }
        if {$firstRow eq ""} { $table appendChild $col } else { $table insertBefore $col $firstRow }
    }
    # ---- column widths / table (master-page) styles ----
    # A free style name not yet used in content.xml automatic-styles.
    method UniqueName {prefix} {
        set used {}
        foreach st [[my AutoStylesEl] childNodes] {
            if {[$st nodeType] eq "ELEMENT_NODE"} { lappend used [$st getAttribute style:name ""] }
        }
        set i 1
        while {"$prefix$i" in $used} { incr i }
        return "$prefix$i"
    }
    # A table-column automatic style carrying style:column-width (e.g. 3cm).
    method defineColumnStyle {name args} {
        set width ""
        foreach {k v} $args { switch -- $k {-width {set width $v} default {error "unknown option: $k"}} }
        set st [$Doc createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family table-column
        if {$width ne ""} {
            set pe [$Doc createElement style:table-column-properties]
            $pe setAttribute style:column-width $width
            $st appendChild $pe
        }
        [my AutoStylesEl] appendChild $st
        return $name
    }
    # Append one table:table-column per given width (each gets its own column
    # style). widths e.g. {3cm 2cm 2cm}. Returns the created style names.
    method addColumnWidths {table widths} {
        set names {}
        foreach w $widths {
            set nm [my defineColumnStyle [my UniqueName co] -width $w]
            set c [$Doc createElement table:table-column]
            $c setAttribute table:style-name $nm
            $table appendChild $c
            lappend names $nm
        }
        return $names
    }
    # A family=table automatic style; -master binds a master-page (page setup +
    # header/footer defined via odf::Styles) to the sheet that uses this style.
    method defineTableStyle {name args} {
        set master ""
        foreach {k v} $args { switch -- $k {-master {set master $v} default {error "unknown option: $k"}} }
        set st [$Doc createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family table
        if {$master ne ""} { $st setAttribute style:master-page-name $master }
        [my AutoStylesEl] appendChild $st
        return $name
    }

    # ---- merges / formulas (write) ----
    # Merge an ncols x nrows block whose top-left logical cell is (r0,c0)
    # (0-based, over the plain grid of table-cells this writer builds). The
    # anchor gets number-columns/rows-spanned; the other covered positions
    # become table:covered-table-cell. Errors if the range exceeds the grid.
    method mergeCells {table r0 c0 ncols nrows} {
        if {$ncols < 1 || $nrows < 1} { error "merge span must be >= 1x1" }
        set rows {}
        foreach c [$table childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:table-row"} { lappend rows $c }
        }
        if {$r0 < 0 || $r0 + $nrows > [llength $rows]} { error "merge row range out of bounds" }
        for {set rr $r0} {$rr < $r0 + $nrows} {incr rr} {
            set row [lindex $rows $rr]
            set cells [my CellNodes $row]
            if {$c0 < 0 || $c0 + $ncols > [llength $cells]} { error "merge col range out of bounds in row $rr" }
            for {set cc $c0} {$cc < $c0 + $ncols} {incr cc} {
                set cell [lindex $cells $cc]
                if {$rr == $r0 && $cc == $c0} {
                    if {$ncols > 1} { $cell setAttribute table:number-columns-spanned $ncols }
                    if {$nrows > 1} { $cell setAttribute table:number-rows-spanned $nrows }
                } else {
                    set cov [$Doc createElement table:covered-table-cell]
                    $row insertBefore $cov $cell
                    $row removeChild $cell
                }
            }
        }
        return
    }
    # Attach an OpenFormula string (e.g. "of:=SUM([.A1:.B1])") to a cell node.
    # Set or clear the formula on a cell.
    #   setFormula cell ""                       -> remove table:formula
    #   setFormula cell "of:=SUM([.A1:.A3])"     -> set table:formula only
    #   setFormula cell "of:=SUM(...)" {float 6} -> set formula AND replace the
    #                                                cell's cached typed value
    # The optional value-spec uses the same forms as addRow's cell specs
    # (string/float/percentage/currency/date/time/boolean -- not "formula"
    # itself, that would be recursive). Use this for retroactive edits; for
    # building rows from scratch the addRow {formula OF inner-spec} form is
    # usually cleaner.
    method setFormula {cell formula args} {
        if {[llength $args] > 1} { error "setFormula: too many arguments (cell formula ?value-spec?)" }
        if {[llength $args] == 1} {
            set spec [lindex $args 0]
            if {[lindex $spec 0] eq "formula"} {
                error "setFormula: value-spec must be a plain typed cell spec, not 'formula'"
            }
            my ApplyValueSpec $cell $spec
        }
        if {$formula eq ""} {
            if {[$cell hasAttribute table:formula]} { $cell removeAttribute table:formula }
        } else {
            $cell setAttribute table:formula $formula
        }
        return $cell
    }

    # ---- 0.23: rich-text cell writing -----------------------------------
    # setCellRichText cell paragraph ?paragraph2 ...?
    #
    # Turn a cell into a string-typed cell with one or more text:p children,
    # each carrying a mix of inline runs. Each paragraph is a Tcl list of
    # run tokens:
    #
    #   {text "plain text"}          -- a text node
    #   {span STYLE-NAME "text"}     -- text:span with text:style-name
    #   {link HREF "text" ?STYLE?}   -- text:a (xlink:href + display text)
    #   lb                           -- text:line-break (bare word, no list)
    #   tab                          -- text:tab
    #   {space N}                    -- text:s text:c="N"   (N >= 1)
    #
    # Examples:
    #   $sh setCellRichText $c [list {span Bold "WARNING"} {text " please verify"}]
    #   $sh setCellRichText $c [list {text "para 1"}] [list {text "para 2"}]
    #
    # The cell's prior office:* value attributes and text:p children are
    # stripped (same cleanup as ApplyValueSpec). office:value-type is set to
    # "string"; office:value / office:date-value / etc. are removed. The
    # existing cellText reader handles the multi-paragraph / multi-span
    # output without changes (RichText recursion + "\n" join across text:p).
    method setCellRichText {cell args} {
        if {![llength $args]} {
            error "setCellRichText: at least one paragraph required"
        }
        # Fail-atomic: validate every run before touching the cell. A bad run
        # in paragraph 3 must not leave paragraphs 1-2 attached (and must not
        # have stripped the cell's prior content either).
        foreach para $args {
            foreach run $para { my CheckRichRun $run }
        }
        # Strip prior value-* attributes
        foreach a {office:value-type office:value office:date-value \
                   office:time-value office:boolean-value office:string-value \
                   office:currency} {
            if {[$cell hasAttribute $a]} { $cell removeAttribute $a }
        }
        # Strip prior text:p children
        foreach c [$cell childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:p"} {
                $cell removeChild $c
            }
        }
        $cell setAttribute office:value-type string
        foreach para $args {
            set p [$Doc createElement text:p]
            foreach run $para {
                my ApplyRichRun $p $run
            }
            $cell appendChild $p
        }
        return $cell
    }

    # Pure validator -- same checks as ApplyRichRun but no DOM mutation.
    # Used by setCellRichText for fail-atomic semantics.
    method CheckRichRun {run} {
        if {$run eq "lb" || $run eq "tab"} { return }
        set kind [lindex $run 0]
        switch -- $kind {
            text {
                if {[llength $run] != 2} { error "bad rich-text run: need {text \"X\"}, got: $run" }
            }
            span {
                if {[llength $run] != 3} { error "bad rich-text run: need {span STYLE \"X\"}, got: $run" }
            }
            link {
                if {[llength $run] != 3 && [llength $run] != 4} {
                    error "bad rich-text run: need {link HREF \"X\" ?STYLE?}, got: $run"
                }
            }
            space {
                if {[llength $run] != 2} { error "bad rich-text run: need {space N}, got: $run" }
                set n [lindex $run 1]
                if {![string is integer -strict $n] || $n < 1} {
                    error "bad rich-text run: space count must be positive integer, got: $n"
                }
            }
            default {
                error "unknown rich-text run: $run (one of: text|span|link|space|lb|tab)"
            }
        }
    }

    # ApplyRichRun -- append one run token to a paragraph node. Run tokens are
    # described in the setCellRichText docstring. Centralised so future
    # readers/writers can share the dispatch.
    method ApplyRichRun {par run} {
        # bare-word tokens
        if {$run eq "lb"}  { $par appendChild [$Doc createElement text:line-break]; return }
        if {$run eq "tab"} { $par appendChild [$Doc createElement text:tab];        return }
        set kind [lindex $run 0]
        switch -- $kind {
            text {
                if {[llength $run] != 2} { error "bad rich-text run: need {text \"X\"}, got: $run" }
                $par appendChild [$Doc createTextNode [lindex $run 1]]
            }
            span {
                if {[llength $run] != 3} { error "bad rich-text run: need {span STYLE \"X\"}, got: $run" }
                set sp [$Doc createElement text:span]
                set sty [lindex $run 1]
                if {$sty ne ""} { $sp setAttribute text:style-name $sty }
                $sp appendChild [$Doc createTextNode [lindex $run 2]]
                $par appendChild $sp
            }
            link {
                if {[llength $run] != 3 && [llength $run] != 4} {
                    error "bad rich-text run: need {link HREF \"X\" ?STYLE?}, got: $run"
                }
                set a [$Doc createElement text:a]
                $a setAttribute xlink:type simple
                $a setAttribute xlink:href [lindex $run 1]
                if {[llength $run] == 4 && [lindex $run 3] ne ""} {
                    $a setAttribute text:style-name [lindex $run 3]
                }
                $a appendChild [$Doc createTextNode [lindex $run 2]]
                $par appendChild $a
            }
            space {
                if {[llength $run] != 2} { error "bad rich-text run: need {space N}, got: $run" }
                set n [lindex $run 1]
                if {![string is integer -strict $n] || $n < 1} {
                    error "bad rich-text run: space count must be positive integer, got: $n"
                }
                set se [$Doc createElement text:s]
                if {$n > 1} { $se setAttribute text:c $n }
                $par appendChild $se
            }
            default {
                error "unknown rich-text run: $run (one of: text|span|link|space|lb|tab)"
            }
        }
    }

    # ---- 0.13: named ranges + named expressions -------------------------
    # The table:named-expressions container is document-level epilogue content
    # (after all table:table). Created lazily and kept last (see addTable).
    method NamedExpressionsEl {create} {
        foreach c [$Body childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c nodeName] eq "table:named-expressions"} { return $c }
        }
        if {!$create} { return "" }
        set el [$Doc createElement table:named-expressions]
        $Body appendChild $el
        return $el
    }
    # addNamedRange NAME CELLRANGE ?-base BASECELL? ?-usable-as LIST?
    # CELLRANGE e.g. "Sheet1.A1:Sheet1.B10"; LIST is space-separated from
    # {print-range filter repeat-row repeat-column} (or "none").
    method addNamedRange {name cellRange args} {
        set base ""; set usable ""
        foreach {k v} $args {
            switch -- $k {
                -base      { set base $v }
                -usable-as { set usable $v }
                default { error "unknown option: $k" }
            }
        }
        foreach u $usable {
            if {[lsearch -exact {none print-range filter repeat-row repeat-column} $u] < 0} {
                error "bad -usable-as token: $u (none|print-range|filter|repeat-row|repeat-column)"
            }
        }
        set ne [my NamedExpressionsEl 1]
        # overwrite same-name entry (range or expression)
        my RemoveNamed $ne $name
        set el [$Doc createElement table:named-range]
        $el setAttribute table:name $name
        $el setAttribute table:cell-range-address $cellRange
        if {$base   ne ""} { $el setAttribute table:base-cell-address $base }
        if {$usable ne ""} { $el setAttribute table:range-usable-as $usable }
        $ne appendChild $el
        my OrderEpilogue
        return $el
    }
    # addNamedExpression NAME EXPRESSION ?-base BASECELL?
    method addNamedExpression {name expression args} {
        set base ""
        foreach {k v} $args {
            switch -- $k {
                -base { set base $v }
                default { error "unknown option: $k" }
            }
        }
        set ne [my NamedExpressionsEl 1]
        my RemoveNamed $ne $name
        set el [$Doc createElement table:named-expression]
        $el setAttribute table:name $name
        $el setAttribute table:expression $expression
        if {$base ne ""} { $el setAttribute table:base-cell-address $base }
        $ne appendChild $el
        my OrderEpilogue
        return $el
    }
    method RemoveNamed {ne name} {
        foreach c [$ne childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c getAttribute table:name ""] eq $name} { $ne removeChild $c }
        }
    }
    # namedRanges -> dict name -> cell-range-address
    method namedRanges {} {
        set out [dict create]
        set ne [my NamedExpressionsEl 0]
        if {$ne eq ""} { return $out }
        foreach c [$ne childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:named-range"} {
                dict set out [$c getAttribute table:name ""] [$c getAttribute table:cell-range-address ""]
            }
        }
        return $out
    }
    # namedExpressions -> dict name -> expression
    method namedExpressions {} {
        set out [dict create]
        set ne [my NamedExpressionsEl 0]
        if {$ne eq ""} { return $out }
        foreach c [$ne childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:named-expression"} {
                dict set out [$c getAttribute table:name ""] [$c getAttribute table:expression ""]
            }
        }
        return $out
    }

    # ---- 0.16: epilogue ordering + database ranges / AutoFilter ---------
    # Keep the spreadsheet epilogue containers last and in RNG order:
    # named-expressions, then database-ranges. Idempotent; safe to call after
    # any epilogue-affecting operation.
    method OrderEpilogue {} {
        foreach nm {table:named-expressions table:database-ranges table:data-pilot-tables table:dde-links} {
            foreach c [$Body childNodes] {
                if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq $nm} {
                    $Body removeChild $c; $Body appendChild $c
                    break
                }
            }
        }
    }
    method DatabaseRangesEl {create} {
        foreach c [$Body childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c nodeName] eq "table:database-ranges"} { return $c }
        }
        if {!$create} { return "" }
        set el [$Doc createElement table:database-ranges]
        $Body appendChild $el
        return $el
    }
    # addDatabaseRange NAME RANGE ?options? -- a table:database-range, the basis
    # for AutoFilter, sorting and subtotals over a cell range.
    #   RANGE                 table:target-range-address, e.g. Tab.A1:Tab.C20
    #   -filter-buttons BOOL  table:display-filter-buttons (the AutoFilter dropdowns)
    #   -header BOOL          table:contains-header
    #   -orientation V        column | row
    #   -filter {COND ...}    each COND = {field-number operator value ?-type T?};
    #                         one -> table:filter-condition, several -> filter-and
    #   -sort {SPEC ...}       each SPEC = {field-number ?-order asc|desc? ?-type T?}
    # field-number is 0-based. operator is an ODF filter operator passed through
    # verbatim (=, !=, <, >, <=, >=, match, !match, empty, !empty, contains, ...).
    # Same-name ranges are overwritten. Returns the element.
    method addDatabaseRange {name range args} {
        set fbtn ""; set header ""; set orient ""; set filters {}; set sorts {}
        set subtotals {}
        foreach {k v} $args {
            switch -- $k {
                -filter-buttons { set fbtn $v }
                -header         { set header $v }
                -orientation    { set orient $v }
                -filter         { set filters $v }
                -sort           { set sorts $v }
                -subtotals      { set subtotals $v }
                default { error "unknown option: $k" }
            }
        }
        if {$orient ne "" && $orient ni {column row}} {
            error "bad -orientation: $orient (column|row)"
        }
        foreach {lbl b} [list -filter-buttons $fbtn -header $header] {
            if {$b ne "" && ![string is boolean -strict $b]} {
                error "$lbl must be boolean, got: $b"
            }
        }
        set dr [my DatabaseRangesEl 1]
        foreach c [$dr childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c getAttribute table:name ""] eq $name} { $dr removeChild $c }
        }
        set el [$Doc createElement table:database-range]
        $el setAttribute table:name $name
        $el setAttribute table:target-range-address $range
        if {$fbtn   ne ""} { $el setAttribute table:display-filter-buttons $fbtn }
        if {$header ne ""} { $el setAttribute table:contains-header $header }
        if {$orient ne ""} { $el setAttribute table:orientation $orient }
        # child order per RNG: (source) filter? sort? subtotal-rules?
        if {[llength $filters]}   { $el appendChild [my BuildFilter $filters] }
        if {[llength $sorts]}     { $el appendChild [my BuildSort $sorts] }
        if {[llength $subtotals]} { $el appendChild [my BuildSubtotals $subtotals] }
        $dr appendChild $el
        my OrderEpilogue
        return $el
    }
    method FilterCond {spec} {
        lassign $spec field op value
        if {$field eq "" || $op eq ""} {
            error "bad filter condition: need {field-number operator value ?-type T?}"
        }
        set type ""
        foreach {k v} [lrange $spec 3 end] {
            if {$k eq "-type"} { set type $v } else { error "bad filter token: $k" }
        }
        set fc [$Doc createElement table:filter-condition]
        $fc setAttribute table:field-number $field
        $fc setAttribute table:operator $op
        $fc setAttribute table:value $value
        if {$type ne ""} { $fc setAttribute table:data-type $type }
        return $fc
    }
    method BuildFilter {conds} {
        set f [$Doc createElement table:filter]
        if {[llength $conds] == 1} {
            $f appendChild [my FilterCond [lindex $conds 0]]
        } else {
            set fa [$Doc createElement table:filter-and]
            foreach c $conds { $fa appendChild [my FilterCond $c] }
            $f appendChild $fa
        }
        return $f
    }
    method BuildSort {specs} {
        set s [$Doc createElement table:sort]
        foreach spec $specs {
            set field [lindex $spec 0]
            if {$field eq ""} { error "bad sort spec: need {field-number ?-order V? ?-type T?}" }
            set order ""; set type ""
            foreach {k v} [lrange $spec 1 end] {
                switch -- $k {
                    -order { set order [string map {asc ascending desc descending} $v] }
                    -type  { set type $v }
                    default { error "bad sort token: $k" }
                }
            }
            set sb [$Doc createElement table:sort-by]
            $sb setAttribute table:field-number $field
            if {$order ne ""} { $sb setAttribute table:order $order }
            if {$type  ne ""} { $sb setAttribute table:data-type $type }
            $s appendChild $sb
        }
        return $s
    }
    # The aggregation functions valid for table:subtotal-field (and shared with
    # data pilots): a fixed RNG enum, not a computation subsystem.
    method SubtotalFns {} {
        return {average count countnums max min product stdev stdevp sum var varp}
    }
    # BuildSubtotals RULES -> table:subtotal-rules. Each rule is
    #   {GROUP-BY-FIELD {FIELD FUNCTION} {FIELD FUNCTION} ...}
    # GROUP-BY-FIELD and FIELD are 0-based column numbers; FUNCTION is one of the
    # subtotal/data-pilot function names. Empty field lists are allowed (a rule
    # that only groups). child order: sort-groups? then subtotal-rule*.
    method BuildSubtotals {rules} {
        set sr [$Doc createElement table:subtotal-rules]
        foreach rule $rules {
            set gby [lindex $rule 0]
            if {$gby eq ""} {
                error "bad subtotal rule: need {group-by-field {field function} ...}"
            }
            set re [$Doc createElement table:subtotal-rule]
            $re setAttribute table:group-by-field-number $gby
            foreach fld [lrange $rule 1 end] {
                lassign $fld field fn
                if {$field eq "" || $fn eq ""} {
                    error "bad subtotal field: need {field-number function}"
                }
                if {$fn ni [my SubtotalFns]} {
                    error "bad subtotal function: $fn (one of: [my SubtotalFns])"
                }
                set fe [$Doc createElement table:subtotal-field]
                $fe setAttribute table:field-number $field
                $fe setAttribute table:function $fn
                $re appendChild $fe
            }
            $sr appendChild $re
        }
        return $sr
    }
    # databaseRanges -> dict name -> {range R filter-buttons B header H orientation O
    #   filters {{field op value type} ...} sorts {{field order type} ...}}
    method databaseRanges {} {
        set out [dict create]
        set dr [my DatabaseRangesEl 0]
        if {$dr eq ""} { return $out }
        foreach c [$dr childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE" || [$c nodeName] ne "table:database-range"} continue
            set d [dict create \
                range          [$c getAttribute table:target-range-address ""] \
                filter-buttons [$c getAttribute table:display-filter-buttons ""] \
                header         [$c getAttribute table:contains-header ""] \
                orientation    [$c getAttribute table:orientation ""] \
                filters {} sorts {} subtotals {}]
            foreach ch [$c childNodes] {
                if {[$ch nodeType] ne "ELEMENT_NODE"} continue
                switch -- [$ch nodeName] {
                    table:filter         { dict set d filters    [my ReadFilter $ch] }
                    table:sort           { dict set d sorts      [my ReadSort $ch] }
                    table:subtotal-rules { dict set d subtotals  [my ReadSubtotals $ch] }
                }
            }
            dict set out [$c getAttribute table:name ""] $d
        }
        return $out
    }
    method ReadFilter {f} {
        set out {}
        foreach n [$f childNodes] {
            if {[$n nodeType] ne "ELEMENT_NODE"} continue
            switch -- [$n nodeName] {
                table:filter-condition { lappend out [my ReadCond $n] }
                table:filter-and - table:filter-or {
                    foreach c [$n childNodes] {
                        if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:filter-condition"} {
                            lappend out [my ReadCond $c]
                        }
                    }
                }
            }
        }
        return $out
    }
    method ReadCond {c} {
        return [list [$c getAttribute table:field-number ""] \
                     [$c getAttribute table:operator ""] \
                     [$c getAttribute table:value ""] \
                     [$c getAttribute table:data-type ""]]
    }
    method ReadSort {s} {
        set out {}
        foreach n [$s childNodes] {
            if {[$n nodeType] eq "ELEMENT_NODE" && [$n nodeName] eq "table:sort-by"} {
                lappend out [list [$n getAttribute table:field-number ""] \
                                  [$n getAttribute table:order ""] \
                                  [$n getAttribute table:data-type ""]]
            }
        }
        return $out
    }
    # ReadSubtotals -> list of rules; each rule {group-by-field {{field function} ...}}
    method ReadSubtotals {sr} {
        set rules {}
        foreach r [$sr childNodes] {
            if {[$r nodeType] ne "ELEMENT_NODE" || [$r nodeName] ne "table:subtotal-rule"} continue
            set fields {}
            foreach f [$r childNodes] {
                if {[$f nodeType] eq "ELEMENT_NODE" && [$f nodeName] eq "table:subtotal-field"} {
                    lappend fields [list [$f getAttribute table:field-number ""] \
                                         [$f getAttribute table:function ""]]
                }
            }
            lappend rules [list [$r getAttribute table:group-by-field-number ""] $fields]
        }
        return $rules
    }

    # ---- 0.18: pivot tables / data pilots -------------------------------
    # Data pilots are an epilogue container after database-ranges. Note: the
    # data-pilot-table stores the *definition* (source range, fields, functions);
    # the consumer (e.g. LibreOffice) computes and lays out the result in the
    # target range when the document is opened or refreshed -- ODF normalises
    # the format and the function semantics, not the layout algorithm.
    method DataPilotTablesEl {create} {
        foreach c [$Body childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c nodeName] eq "table:data-pilot-tables"} { return $c }
        }
        if {!$create} { return "" }
        set el [$Doc createElement table:data-pilot-tables]
        $Body appendChild $el
        return $el
    }
    method DataPilotFns {} {
        return {auto average count countnums max min product stdev stdevp sum var varp}
    }
    # addDataPilotTable NAME -target RANGE ?-source RANGE? ?-grand-total V?
    #                        ?-show-filter-button BOOL?
    #                        -field {SOURCE-NAME ORIENTATION ?-function F?} ...
    # Emits a table:data-pilot-table. -target (table:target-range-address) is
    # where the consumer will display the computed pivot; -source builds a
    # table:source-cell-range (table:cell-range-address). Each -field is
    # {source-field-name orientation ?-function F?}: orientation is one of
    # row|column|data|page|hidden; function (for data fields) is from the enum
    # (auto/average/count/.../varp). At least one -field is required. Returns
    # the element.
    method addDataPilotTable {name args} {
        set target ""; set source ""; set grand ""; set showFilter ""
        set fields {}
        foreach {k v} $args {
            switch -- $k {
                -target             { set target $v }
                -source             { set source $v }
                -grand-total        { set grand $v }
                -show-filter-button { set showFilter $v }
                -field              { lappend fields $v }
                default { error "unknown option: $k" }
            }
        }
        if {$target eq ""} { error "addDataPilotTable: -target is required" }
        if {![llength $fields]} { error "addDataPilotTable: at least one -field required" }
        if {$grand ne "" && $grand ni {none row column both}} {
            error "bad -grand-total: $grand (none|row|column|both)"
        }
        if {$showFilter ne "" && ![string is boolean -strict $showFilter]} {
            error "-show-filter-button must be boolean, got: $showFilter"
        }
        set dpts [my DataPilotTablesEl 1]
        foreach c [$dpts childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c getAttribute table:name ""] eq $name} { $dpts removeChild $c }
        }
        set el [$Doc createElement table:data-pilot-table]
        $el setAttribute table:name $name
        $el setAttribute table:target-range-address $target
        if {$grand      ne ""} { $el setAttribute table:grand-total $grand }
        if {$showFilter ne ""} { $el setAttribute table:show-filter-button $showFilter }
        # child order: (source) then one-or-more fields
        if {$source ne ""} {
            set scr [$Doc createElement table:source-cell-range]
            $scr setAttribute table:cell-range-address $source
            $el appendChild $scr
        }
        foreach f $fields {
            lassign $f srcName orient
            if {$srcName eq "" || $orient eq ""} {
                error "bad -field: need {source-field-name orientation ?-function F? ?-show-empty B? ?-subtotals {fn...}? ?-members {{name ?display?}...}?}"
            }
            if {$orient ni {row column data page hidden}} {
                error "bad field orientation: $orient (row|column|data|page|hidden)"
            }
            set fn ""; set showEmpty ""; set subs {}; set members {}
            set seSet 0; set subSet 0; set memSet 0
            foreach {tk tv} [lrange $f 2 end] {
                switch -- $tk {
                    -function    { set fn $tv }
                    -show-empty  { set showEmpty $tv; set seSet 1 }
                    -subtotals   { set subs $tv; set subSet 1 }
                    -members     { set members $tv; set memSet 1 }
                    default      { error "bad field token: $tk" }
                }
            }
            if {$fn ne "" && $fn ni [my DataPilotFns]} {
                error "bad field function: $fn (one of: [my DataPilotFns])"
            }
            if {$seSet && ![string is boolean -strict $showEmpty]} {
                error "bad field -show-empty: $showEmpty (boolean)"
            }
            foreach sfn $subs {
                if {$sfn ni [my DataPilotFns]} {
                    error "bad field subtotal function: $sfn (one of: [my DataPilotFns])"
                }
            }
            set fe [$Doc createElement table:data-pilot-field]
            $fe setAttribute table:source-field-name $srcName
            $fe setAttribute table:orientation $orient
            if {$fn ne ""} { $fe setAttribute table:function $fn }
            # Build table:data-pilot-level if any depth token was given. RNG
            # child order: subtotals BEFORE members. Empty member specs are
            # rejected here (an empty -members {} is a user mistake; the
            # whole level is omitted by not passing -members at all).
            if {$seSet || $subSet || $memSet} {
                set lev [$Doc createElement table:data-pilot-level]
                if {$seSet} { $lev setAttribute table:show-empty $showEmpty }
                if {$subSet} {
                    if {![llength $subs]} {
                        error "bad field -subtotals: empty list (give at least one function or omit the token)"
                    }
                    set subsEl [$Doc createElement table:data-pilot-subtotals]
                    foreach sfn $subs {
                        set s1 [$Doc createElement table:data-pilot-subtotal]
                        $s1 setAttribute table:function $sfn
                        $subsEl appendChild $s1
                    }
                    $lev appendChild $subsEl
                }
                if {$memSet} {
                    if {![llength $members]} {
                        error "bad field -members: empty list (give at least one member or omit the token)"
                    }
                    set memsEl [$Doc createElement table:data-pilot-members]
                    foreach m $members {
                        set mname [lindex $m 0]
                        set mdisp [lindex $m 1]
                        if {$mname eq ""} {
                            error "bad field member: need {name ?display?}, got: $m"
                        }
                        if {$mdisp ne "" && ![string is boolean -strict $mdisp]} {
                            error "bad field member display: $mdisp (boolean)"
                        }
                        set me [$Doc createElement table:data-pilot-member]
                        $me setAttribute table:name $mname
                        if {$mdisp ne ""} { $me setAttribute table:display $mdisp }
                        $memsEl appendChild $me
                    }
                    $lev appendChild $memsEl
                }
                $fe appendChild $lev
            }
            $el appendChild $fe
        }
        $dpts appendChild $el
        my OrderEpilogue
        return $el
    }
    # dataPilotTables -> dict name -> {target T source S grand-total G
    #   fields {{source-name orientation function} ...}}
    method dataPilotTables {} {
        set out [dict create]
        set dpts [my DataPilotTablesEl 0]
        if {$dpts eq ""} { return $out }
        foreach c [$dpts childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE" || [$c nodeName] ne "table:data-pilot-table"} continue
            set src ""; set fields {}
            foreach ch [$c childNodes] {
                if {[$ch nodeType] ne "ELEMENT_NODE"} continue
                switch -- [$ch nodeName] {
                    table:source-cell-range {
                        set src [$ch getAttribute table:cell-range-address ""]
                    }
                    table:data-pilot-field {
                        set fdict [dict create \
                            source-name [$ch getAttribute table:source-field-name ""] \
                            orientation [$ch getAttribute table:orientation ""] \
                            function    [$ch getAttribute table:function ""] \
                            show-empty  "" subtotals {} members {}]
                        foreach lc [$ch childNodes] {
                            if {[$lc nodeType] ne "ELEMENT_NODE"} continue
                            if {[$lc nodeName] ne "table:data-pilot-level"} continue
                            dict set fdict show-empty [$lc getAttribute table:show-empty ""]
                            foreach lc2 [$lc childNodes] {
                                if {[$lc2 nodeType] ne "ELEMENT_NODE"} continue
                                switch -- [$lc2 nodeName] {
                                    table:data-pilot-subtotals {
                                        set subs {}
                                        foreach s [$lc2 childNodes] {
                                            if {[$s nodeType] eq "ELEMENT_NODE" \
                                                && [$s nodeName] eq "table:data-pilot-subtotal"} {
                                                lappend subs [$s getAttribute table:function ""]
                                            }
                                        }
                                        dict set fdict subtotals $subs
                                    }
                                    table:data-pilot-members {
                                        set mems {}
                                        foreach m [$lc2 childNodes] {
                                            if {[$m nodeType] eq "ELEMENT_NODE" \
                                                && [$m nodeName] eq "table:data-pilot-member"} {
                                                lappend mems [list \
                                                    [$m getAttribute table:name ""] \
                                                    [$m getAttribute table:display ""]]
                                            }
                                        }
                                        dict set fdict members $mems
                                    }
                                }
                            }
                        }
                        lappend fields $fdict
                    }
                }
            }
            dict set out [$c getAttribute table:name ""] [dict create \
                target      [$c getAttribute table:target-range-address ""] \
                source      $src \
                grand-total [$c getAttribute table:grand-total ""] \
                fields      $fields]
        }
        return $out
    }

    # ---- 0.19: calculation settings (prelude singleton) ----------------
    # table:calculation-settings is the FIRST table-decls element (before
    # content-validations). Singleton; setCalculationSettings rebuilds it.
    method CalculationSettingsEl {} {
        foreach c [$Body childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c nodeName] eq "table:calculation-settings"} { return $c }
        }
        return ""
    }
    # setCalculationSettings ?options? -- create/replace table:calculation-settings,
    # controlling how a consumer recalculates the sheet.
    #   -case-sensitive BOOL           -precision-as-shown BOOL
    #   -search-criteria-whole-cell BOOL    -automatic-find-labels BOOL
    #   -use-regular-expressions BOOL  -use-wildcards BOOL
    #   -null-year INT                 (century pivot for two-digit years)
    #   -null-date DATE                table:null-date, e.g. 1899-12-30
    #   -iteration {STATUS ?-steps N? ?-max-difference D?}   STATUS=enable|disable
    # Note: regular-expressions and wildcards are mutually exclusive in consumers
    # (both off => literal matching). Each call sets the COMPLETE state -- options
    # not given are dropped, not merged (plain "set" semantics). Idempotent.
    # Returns the element.
    method setCalculationSettings {args} {
        set boolMap {
            -case-sensitive             table:case-sensitive
            -precision-as-shown         table:precision-as-shown
            -search-criteria-whole-cell table:search-criteria-must-apply-to-whole-cell
            -automatic-find-labels      table:automatic-find-labels
            -use-regular-expressions    table:use-regular-expressions
            -use-wildcards              table:use-wildcards
        }
        set attrs [dict create]
        set nullYear ""; set nullDate ""; set iteration ""
        foreach {k v} $args {
            if {[dict exists $boolMap $k]} {
                if {![string is boolean -strict $v]} { error "$k must be boolean, got: $v" }
                dict set attrs [dict get $boolMap $k] $v
            } else {
                switch -- $k {
                    -null-year { set nullYear $v }
                    -null-date { set nullDate $v }
                    -iteration { set iteration $v }
                    default { error "unknown option: $k" }
                }
            }
        }
        if {$nullYear ne "" && ![string is integer -strict $nullYear]} {
            error "-null-year must be an integer, got: $nullYear"
        }
        set old [my CalculationSettingsEl]
        if {$old ne ""} { $Body removeChild $old }
        set el [$Doc createElement table:calculation-settings]
        dict for {a v} $attrs { $el setAttribute $a $v }
        if {$nullYear ne ""} { $el setAttribute table:null-year $nullYear }
        # child order per RNG: null-date? then iteration?
        if {$nullDate ne ""} {
            set nd [$Doc createElement table:null-date]
            $nd setAttribute table:value-type date
            $nd setAttribute table:date-value $nullDate
            $el appendChild $nd
        }
        if {$iteration ne ""} {
            set status [lindex $iteration 0]
            if {$status ni {enable disable}} { error "iteration status must be enable|disable" }
            set steps ""; set maxdiff ""
            foreach {ik iv} [lrange $iteration 1 end] {
                switch -- $ik {
                    -steps          { set steps $iv }
                    -max-difference { set maxdiff $iv }
                    default { error "bad iteration token: $ik" }
                }
            }
            set it [$Doc createElement table:iteration]
            $it setAttribute table:status $status
            if {$steps ne ""}   { $it setAttribute table:steps $steps }
            if {$maxdiff ne ""} { $it setAttribute table:maximum-difference $maxdiff }
            $el appendChild $it
        }
        # must be the first table-decls element, before content-validations etc.
        set first [$Body firstChild]
        if {$first ne ""} { $Body insertBefore $el $first } else { $Body appendChild $el }
        return $el
    }
    # calculationSettings -> dict (empty if unset). Set attributes (without the
    # table: prefix), plus null-date and iteration {status steps max-difference}.
    method calculationSettings {} {
        set out [dict create]
        set el [my CalculationSettingsEl]
        if {$el eq ""} { return $out }
        foreach {opt attr} {
            case-sensitive             table:case-sensitive
            precision-as-shown         table:precision-as-shown
            search-criteria-whole-cell table:search-criteria-must-apply-to-whole-cell
            automatic-find-labels      table:automatic-find-labels
            use-regular-expressions    table:use-regular-expressions
            use-wildcards              table:use-wildcards
            null-year                  table:null-year
        } {
            set v [$el getAttribute $attr ""]
            if {$v ne ""} { dict set out $opt $v }
        }
        foreach c [$el childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE"} continue
            switch -- [$c nodeName] {
                table:null-date { dict set out null-date [$c getAttribute table:date-value ""] }
                table:iteration {
                    dict set out iteration [list \
                        [$c getAttribute table:status ""] \
                        [$c getAttribute table:steps ""] \
                        [$c getAttribute table:maximum-difference ""]]
                }
            }
        }
        return $out
    }

    # ---- 0.14: content validation (data validation) --------------------
    # table:content-validations is a document PRELUDE container (before the
    # tables, after table:calculation-settings if present) -- unlike the
    # named-expressions epilogue. Created lazily and kept first.
    method ContentValidationsEl {create} {
        foreach c [$Body childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c nodeName] eq "table:content-validations"} { return $c }
        }
        if {!$create} { return "" }
        set el [$Doc createElement table:content-validations]
        # Place after table:calculation-settings if present, else as first
        # child, so it precedes every table:table and the epilogue.
        set calc ""
        foreach c [$Body childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c nodeName] eq "table:calculation-settings"} { set calc $c; break }
        }
        set ref [expr {$calc ne "" ? [$calc nextSibling] : [$Body firstChild]}]
        if {$ref ne ""} { $Body insertBefore $el $ref } else { $Body appendChild $el }
        return $el
    }
    # addContentValidation NAME ?options? -- defines a table:content-validation.
    #   -condition COND     ODF condition, e.g. of:cell-content-is-in-list("A";"B")
    #                       or of:cell-content() > 0  (passed through verbatim)
    #   -base CELL          table:base-cell-address (anchor for relative refs)
    #   -allow-empty BOOL   table:allow-empty-cell
    #   -display-list V     none | unsorted | sort-ascending  (dropdown)
    #   -help-title T  -help-text TXT     input-hint message
    #   -error-title T -error-type V -error-text TXT   V: stop|warning|information
    # Same-name validations are overwritten. Returns the element.
    method addContentValidation {name args} {
        set cond ""; set base ""; set allow ""; set disp ""
        set ht ""; set hx ""; set htSet 0; set hxSet 0; set hdisp ""; set hdispSet 0
        set et ""; set etype ""; set ex ""; set etSet 0; set exSet 0; set edisp ""; set edispSet 0
        foreach {k v} $args {
            switch -- $k {
                -condition     { set cond $v }
                -base          { set base $v }
                -allow-empty   { set allow $v }
                -display-list  { set disp $v }
                -help-title    { set ht $v; set htSet 1 }
                -help-text     { set hx $v; set hxSet 1 }
                -help-display  { set hdisp $v; set hdispSet 1 }
                -error-title   { set et $v; set etSet 1 }
                -error-type    { set etype $v }
                -error-text    { set ex $v; set exSet 1 }
                -error-display { set edisp $v; set edispSet 1 }
                default { error "unknown option: $k" }
            }
        }
        if {$disp ne "" && [lsearch -exact {none unsorted sort-ascending} $disp] < 0} {
            error "bad -display-list: $disp (none|unsorted|sort-ascending)"
        }
        if {$etype ne "" && [lsearch -exact {stop warning information} $etype] < 0} {
            error "bad -error-type: $etype (stop|warning|information)"
        }
        if {$allow ne "" && ![string is boolean -strict $allow]} {
            error "bad -allow-empty: $allow (boolean)"
        }
        if {$hdispSet && ![string is boolean -strict $hdisp]} {
            error "bad -help-display: $hdisp (boolean)"
        }
        if {$edispSet && ![string is boolean -strict $edisp]} {
            error "bad -error-display: $edisp (boolean)"
        }
        set cv [my ContentValidationsEl 1]
        foreach c [$cv childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c getAttribute table:name ""] eq $name} { $cv removeChild $c }
        }
        set el [$Doc createElement table:content-validation]
        $el setAttribute table:name $name
        if {$cond  ne ""} { $el setAttribute table:condition $cond }
        if {$base  ne ""} { $el setAttribute table:base-cell-address $base }
        if {$allow ne ""} { $el setAttribute table:allow-empty-cell $allow }
        if {$disp  ne ""} { $el setAttribute table:display-list $disp }
        # child order per RNG: help-message THEN error-message
        if {$htSet || $hxSet || $hdispSet} {
            set hm [$Doc createElement table:help-message]
            if {$htSet} { $hm setAttribute table:title $ht }
            # default display="true" (LO-compatible; RNG has no default but LO treats
            # missing as do-not-display, defeating the point of having a help message)
            $hm setAttribute table:display [expr {$hdispSet ? $hdisp : "true"}]
            if {$hxSet} { my MsgPara $hm $hx }
            $el appendChild $hm
        }
        if {$etSet || $exSet || $etype ne "" || $edispSet} {
            set em [$Doc createElement table:error-message]
            if {$etSet}       { $em setAttribute table:title $et }
            if {$etype ne ""} { $em setAttribute table:message-type $etype }
            $em setAttribute table:display [expr {$edispSet ? $edisp : "true"}]
            if {$exSet}       { my MsgPara $em $ex }
            $el appendChild $em
        }
        $cv appendChild $el
        return $el
    }
    method MsgPara {parent text} {
        set p [$Doc createElement text:p]
        $p appendChild [$Doc createTextNode $text]
        $parent appendChild $p
        return $p
    }
    # Attach a validation (by name) to a cell node (from addRow/cells).
    method setCellValidation {cell name} {
        $cell setAttribute table:content-validation-name $name; return $cell
    }
    method cellValidation {cell} {
        return [$cell getAttribute table:content-validation-name ""]
    }
    # contentValidations -> dict name -> {condition .. base .. allow-empty ..
    #   display-list .. help-title .. help-text .. error-title .. error-type ..
    #   error-text ..}
    method contentValidations {} {
        set out [dict create]
        set cv [my ContentValidationsEl 0]
        if {$cv eq ""} { return $out }
        foreach c [$cv childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE" \
                || [$c nodeName] ne "table:content-validation"} continue
            set d [dict create \
                condition    [$c getAttribute table:condition ""] \
                base         [$c getAttribute table:base-cell-address ""] \
                allow-empty  [$c getAttribute table:allow-empty-cell ""] \
                display-list [$c getAttribute table:display-list ""] \
                help-title "" help-text "" help-display "" \
                error-title "" error-type "" error-text "" error-display ""]
            foreach m [$c childNodes] {
                if {[$m nodeType] ne "ELEMENT_NODE"} continue
                switch -- [$m nodeName] {
                    table:help-message {
                        dict set d help-title   [$m getAttribute table:title ""]
                        dict set d help-display [$m getAttribute table:display ""]
                        dict set d help-text    [my MsgText $m]
                    }
                    table:error-message {
                        dict set d error-title   [$m getAttribute table:title ""]
                        dict set d error-type    [$m getAttribute table:message-type ""]
                        dict set d error-display [$m getAttribute table:display ""]
                        dict set d error-text    [my MsgText $m]
                    }
                }
            }
            dict set out [$c getAttribute table:name ""] $d
        }
        return $out
    }
    method MsgText {msgEl} {
        set out ""
        foreach p [$msgEl childNodes] {
            if {[$p nodeType] eq "ELEMENT_NODE" && [$p nodeName] eq "text:p"} {
                append out [$p asText]
            }
        }
        return $out
    }

    method flush {} {
        foreach t [[$Doc documentElement] getElementsByTagName table:table] { my EnsureColumns $t }
        $Pkg settree content.xml $Doc
        if {[dict size $Freezes]} {
            $Pkg addpart settings.xml [encoding convertto utf-8 [my BuildSettingsXml]] text/xml
        }
        return
    }
    method XmlEsc {s} { return [string map {& &amp; < &lt; > &gt; \" &quot;} $s] }
    # Build a LibreOffice view-settings settings.xml carrying per-sheet freezes.
    method CI {name type val} { return "<config:config-item config:name=\"$name\" config:type=\"$type\">$val</config:config-item>" }
    method BuildSettingsXml {} {
        set NS_O urn:oasis:names:tc:opendocument:xmlns:office:1.0
        set NS_C urn:oasis:names:tc:opendocument:xmlns:config:1.0
        set NS_OOO http://openoffice.org/2004/office
        # Per-sheet view settings replicate exactly what LibreOffice Calc writes
        # for a frozen sheet (split mode 2 = freeze), so Calc honours the freeze.
        set entries ""
        dict for {name cr} $Freezes {
            lassign $cr cols rows
            set hmode [expr {$cols > 0 ? 2 : 0}]
            set vmode [expr {$rows > 0 ? 2 : 0}]
            append entries "<config:config-item-map-entry config:name=\"[my XmlEsc $name]\">"
            append entries [my CI CursorPositionX int 0]
            append entries [my CI CursorPositionY int 0]
            append entries [my CI HorizontalSplitMode short $hmode]
            append entries [my CI VerticalSplitMode short $vmode]
            append entries [my CI HorizontalSplitPosition int $cols]
            append entries [my CI VerticalSplitPosition int $rows]
            append entries [my CI ActiveSplitRange short 0]
            append entries [my CI PositionLeft int 0]
            append entries [my CI PositionRight int $cols]
            append entries [my CI PositionTop int 0]
            append entries [my CI PositionBottom int $rows]
            append entries [my CI ZoomType short 0]
            append entries [my CI ZoomValue int 100]
            append entries [my CI PageViewZoomValue int 60]
            append entries "</config:config-item-map-entry>"
        }
        set xml "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        append xml "<office:document-settings xmlns:office=\"$NS_O\" xmlns:config=\"$NS_C\" xmlns:ooo=\"$NS_OOO\" office:version=\"1.3\">"
        append xml "<office:settings><config:config-item-set config:name=\"ooo:view-settings\">"
        append xml [my CI VisibleAreaTop int 0]
        append xml [my CI VisibleAreaLeft int 0]
        append xml [my CI VisibleAreaWidth int 10000]
        append xml [my CI VisibleAreaHeight int 10000]
        append xml "<config:config-item-map-indexed config:name=\"Views\"><config:config-item-map-entry>"
        append xml [my CI ViewId string view1]
        append xml "<config:config-item-map-named config:name=\"Tables\">$entries</config:config-item-map-named>"
        append xml "</config:config-item-map-entry></config:config-item-map-indexed>"
        append xml "</config:config-item-set></office:settings></office:document-settings>"
        return $xml
    }

    # ---- read ----

    method tables {} {
        set res {}
        foreach c [$Body childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:table"} { lappend res $c }
        }
        return $res
    }
    method tableName {table} { return [$table getAttribute table:name ""] }

    # number-(columns|rows)-repeated as a positive integer (default 1).
    method Rep {node attr} {
        set v [$node getAttribute $attr ""]
        if {$v eq "" || ![string is integer -strict $v] || $v < 1} { return 1 }
        return $v
    }
    method PhysChildren {parent name} {
        set res {}
        foreach c [$parent childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq $name} { lappend res $c }
        }
        return $res
    }
    # A cell counts as empty if it has no value-type and no text. Such cells
    # (and whole rows of them) at the END are ODF fill/padding -- LibreOffice
    # repeats them up to the sheet limits, so we must NOT materialise their
    # huge repeat. We expand only up to the last non-empty cell/row.
    method CellEmpty {cell} {
        return [expr {[$cell getAttribute office:value-type ""] eq "" && [string trim [$cell asText]] eq ""}]
    }
    method RowEmpty {row} {
        foreach c [my CellNodes $row] { if {![my CellEmpty $c]} { return 0 } }
        return 1
    }
    method LastNonEmpty {nodes emptyMethod} {
        set last -1
        for {set i 0} {$i < [llength $nodes]} {incr i} {
            if {![my $emptyMethod [lindex $nodes $i]]} { set last $i }
        }
        return $last
    }

    # Logical rows: number-rows-repeated expanded, trailing empty rows dropped.
    # Repeated rows yield the SAME node handle N times (no DOM copy).
    method rows {table} {
        set phys [my PhysChildren $table table:table-row]
        set last [my LastNonEmpty $phys RowEmpty]
        if {$last < 0} { return {} }
        set out {}
        for {set i 0} {$i <= $last} {incr i} {
            set row [lindex $phys $i]
            set rep [my Rep $row table:number-rows-repeated]
            for {set k 0} {$k < $rep} {incr k} { lappend out $row }
        }
        return $out
    }
    # Cell-like children in document order: table:table-cell AND
    # table:covered-table-cell (merge placeholders keep column positions aligned).
    method CellNodes {row} {
        set res {}
        foreach c [$row childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" &&
                [$c nodeName] in {table:table-cell table:covered-table-cell}} {
                lappend res $c
            }
        }
        return $res
    }
    # Logical cells of a row: number-columns-repeated expanded, trailing empty
    # cells dropped; interior empty cells (gaps) and covered (merged-away) cells
    # are kept so column positions line up. A merge collapses at the row end to
    # its anchor cell (its cellSpan stays authoritative for the merged width).
    method cells {row} {
        set phys [my CellNodes $row]
        set last [my LastNonEmpty $phys CellEmpty]
        if {$last < 0} { return {} }
        set out {}
        for {set i 0} {$i <= $last} {incr i} {
            set cell [lindex $phys $i]
            set rep [my Rep $cell table:number-columns-repeated]
            for {set k 0} {$k < $rep} {incr k} { lappend out $cell }
        }
        return $out
    }
    # Logical column count = widest logical row.
    method width {table} {
        set w 0
        foreach r [my rows $table] {
            set n [llength [my cells $r]]
            if {$n > $w} { set w $n }
        }
        return $w
    }
    # Column nodes (table:table-column), number-columns-repeated expanded but
    # bounded by the data width so a trailing default-column fill never explodes.
    method columns {table} {
        set phys [my PhysChildren $table table:table-column]
        set w [my width $table]
        if {$w == 0} { return $phys }
        set out {}
        foreach col $phys {
            set rep [my Rep $col table:number-columns-repeated]
            for {set k 0} {$k < $rep} {incr k} {
                lappend out $col
                if {[llength $out] >= $w} { return $out }
            }
        }
        return $out
    }

    method cellType {cell} { return [$cell getAttribute office:value-type ""] }

    # ---- merges ----
    # Is this a merged-away (covered) cell?
    method cellCovered {cell} { return [expr {[$cell nodeName] eq "table:covered-table-cell"}] }
    # {columnsSpanned rowsSpanned} of a merge anchor (1 1 if not merged).
    method cellSpan {cell} {
        return [list [my Rep $cell table:number-columns-spanned] \
                     [my Rep $cell table:number-rows-spanned]]
    }

    # ---- rich text ----
    # Inline text of a node: text:s -> spaces, text:tab -> \t, text:line-break
    # -> \n, spans recursed.
    method RichText {node} {
        set out ""
        foreach c [$node childNodes] {
            switch -- [$c nodeType] {
                TEXT_NODE { append out [$c nodeValue] }
                ELEMENT_NODE {
                    switch -- [$c nodeName] {
                        text:line-break { append out "\n" }
                        text:tab        { append out "\t" }
                        text:s          { append out [string repeat " " [my Rep $c text:c]] }
                        default         { append out [my RichText $c] }
                    }
                }
            }
        }
        return $out
    }
    # Display text: paragraphs (text:p) joined by newline, each rendered richly.
    method cellText {cell} {
        set ps {}
        foreach c [$cell childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:p"} {
                lappend ps [my RichText $c]
            }
        }
        if {[llength $ps]} { return [join $ps "\n"] }
        return [$cell asText]
    }
    # Currency code (office:currency), e.g. EUR -- "" if none.
    method cellCurrency {cell} { return [$cell getAttribute office:currency ""] }

    # Raw cell formula (table:formula), e.g. "of:=SUM([.B3:.E3])"; "" if none.
    # Returned verbatim (no de-namespacing) -- the computed result is cellValue.
    method cellFormula {cell} { return [$cell getAttribute table:formula ""] }
    method cellHasFormula {cell} { return [$cell hasAttribute table:formula] }

    # ---- style chain (read) ----
    method tableStyleName {table} { return [$table getAttribute table:style-name ""] }
    # style:master-page-name of a named (table) style in content automatic-styles.
    method masterPageOf {styleName} {
        if {$styleName eq ""} { return "" }
        foreach st [[$Doc documentElement] getElementsByTagName style:style] {
            if {[$st getAttribute style:name ""] eq $styleName} {
                return [$st getAttribute style:master-page-name ""]
            }
        }
        return ""
    }
    # style:column-width of a named table-column style; "" if none.
    method columnWidthOf {styleName} {
        if {$styleName eq ""} { return "" }
        foreach st [[$Doc documentElement] getElementsByTagName style:style] {
            if {[$st getAttribute style:name ""] eq $styleName} {
                set pe [lindex [$st getElementsByTagName style:table-column-properties] 0]
                if {$pe ne ""} { return [$pe getAttribute style:column-width ""] }
            }
        }
        return ""
    }
    method cellStyleName {cell} { return [$cell getAttribute table:style-name ""] }
    # style:data-style-name of a named table-cell style (searches content.xml
    # automatic-styles then styles.xml office:styles); "" if none.
    method dataStyleOf {styleName} {
        if {$styleName eq ""} { return "" }
        foreach where [list \
                [$Doc documentElement] \
                [expr {[$Pkg has styles.xml] ? [[$Pkg tree styles.xml] documentElement] : ""}]] {
            if {$where eq ""} continue
            foreach st [$where getElementsByTagName style:style] {
                if {[$st getAttribute style:name ""] eq $styleName} {
                    return [$st getAttribute style:data-style-name ""]
                }
            }
        }
        return ""
    }

    # ---- typed value ----
    # The value attribute appropriate to the cell's value-type:
    #   float/percentage/currency -> office:value
    #   date                      -> office:date-value
    #   time                      -> office:time-value
    #   boolean                   -> office:boolean-value
    #   string                    -> office:string-value (else display text)
    #   (none)                    -> display text
    method cellValue {cell} {
        switch -- [my cellType $cell] {
            float - percentage - currency { return [$cell getAttribute office:value ""] }
            date    { return [$cell getAttribute office:date-value ""] }
            time    { return [$cell getAttribute office:time-value ""] }
            boolean { return [$cell getAttribute office:boolean-value ""] }
            string  {
                set sv [$cell getAttribute office:string-value ""]
                return [expr {$sv ne "" ? $sv : [my cellText $cell]}]
            }
            default { return [my cellText $cell] }
        }
    }

    # ====================================================================
    #  0.24: ODS completeness niches (label-ranges, scenarios, dde-links)
    # ====================================================================

    # ---- label-ranges ---------------------------------------------------
    # table:label-ranges is a prelude wrapper holding one or more
    # table:label-range entries. Each labels a data area with a header area.
    method LabelRangesEl {create} {
        foreach c [$Body childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c nodeName] eq "table:label-ranges"} { return $c }
        }
        if {!$create} { return "" }
        set el [$Doc createElement table:label-ranges]
        # Place after content-validations / calculation-settings (whichever is
        # last) so the prelude order remains:
        #   calc-settings, content-validations, label-ranges, [tables...]
        set anchor ""
        foreach nm {table:content-validations table:calculation-settings} {
            foreach c [$Body childNodes] {
                if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq $nm} {
                    set anchor $c; break
                }
            }
            if {$anchor ne ""} break
        }
        if {$anchor eq ""} {
            set ref [$Body firstChild]
            if {$ref ne ""} { $Body insertBefore $el $ref } else { $Body appendChild $el }
        } else {
            set ref [$anchor nextSibling]
            if {$ref ne ""} { $Body insertBefore $el $ref } else { $Body appendChild $el }
        }
        return $el
    }
    # addLabelRange LABEL-RANGE DATA-RANGE ?-orientation column|row?
    #   LABEL-RANGE  cell-range with the header cells, e.g. Sales.A1:Sales.A1
    #   DATA-RANGE   cell-range with the data,       e.g. Sales.A2:Sales.A20
    #   -orientation column (default) | row
    method addLabelRange {labelRange dataRange args} {
        set orient column
        foreach {k v} $args {
            switch -- $k {
                -orientation { set orient $v }
                default      { error "unknown option: $k" }
            }
        }
        if {$labelRange eq ""} { error "addLabelRange: label-range is required" }
        if {$dataRange  eq ""} { error "addLabelRange: data-range is required"  }
        if {$orient ni {column row}} {
            error "bad -orientation: $orient (column|row)"
        }
        set wrap [my LabelRangesEl 1]
        set lr [$Doc createElement table:label-range]
        $lr setAttribute table:label-cell-range-address $labelRange
        $lr setAttribute table:data-cell-range-address  $dataRange
        $lr setAttribute table:orientation              $orient
        $wrap appendChild $lr
        return $lr
    }
    # labelRanges -> list of {label data orientation} entries.
    method labelRanges {} {
        set out {}
        set wrap [my LabelRangesEl 0]
        if {$wrap eq ""} { return $out }
        foreach c [$wrap childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE" || [$c nodeName] ne "table:label-range"} continue
            lappend out [list \
                [$c getAttribute table:label-cell-range-address ""] \
                [$c getAttribute table:data-cell-range-address  ""] \
                [$c getAttribute table:orientation              ""]]
        }
        return $out
    }

    # ---- table scenario -------------------------------------------------
    # table:scenario is an optional singleton child of a table:table. It
    # marks the table (or part of it) as a what-if scenario. Per RNG it
    # sits between table:table-source / office:dde-source and the columns;
    # in our table shape (columns + rows only) we insert it as the very
    # first child so the columns/rows that follow are untouched.
    method TableScenarioEl {table} {
        foreach c [$table childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:scenario"} {
                return $c
            }
        }
        return ""
    }
    # setTableScenario TABLE -ranges {R1 R2 ...} ?options?
    #   -ranges {RANGES}        table:scenario-ranges (cell range list)
    #   -active BOOL            table:is-active            (default unset)
    #   -display-border BOOL    table:display-border
    #   -border-color COLOR     table:border-color
    #   -copy-back BOOL         table:copy-back
    #   -copy-styles BOOL       table:copy-styles
    #   -copy-formulas BOOL     table:copy-formulas
    # Setting twice on the same table replaces the prior scenario.
    method setTableScenario {table args} {
        set ranges ""; set active ""; set displayB ""; set bcol ""
        set cback ""; set cstyles ""; set cformulas ""
        foreach {k v} $args {
            switch -- $k {
                -ranges          { set ranges $v }
                -active          { set active $v }
                -display-border  { set displayB $v }
                -border-color    { set bcol $v }
                -copy-back       { set cback $v }
                -copy-styles     { set cstyles $v }
                -copy-formulas   { set cformulas $v }
                default          { error "unknown option: $k" }
            }
        }
        if {$ranges eq ""} { error "setTableScenario: -ranges is required" }
        foreach {nm val} [list \
            active     $active \
            displayB   $displayB \
            cback      $cback \
            cstyles    $cstyles \
            cformulas  $cformulas] {
            if {$val ne "" && ![string is boolean -strict $val]} {
                error "setTableScenario: $nm must be boolean, got: $val"
            }
        }
        # Remove prior scenario (singleton semantics)
        set old [my TableScenarioEl $table]
        if {$old ne ""} { $table removeChild $old }
        set sc [$Doc createElement table:scenario]
        # cellRangeAddressList is whitespace-separated; accept a Tcl list and join.
        $sc setAttribute table:scenario-ranges [join $ranges " "]
        if {$active   ne ""} { $sc setAttribute table:is-active       $active }
        if {$displayB ne ""} { $sc setAttribute table:display-border  $displayB }
        if {$bcol     ne ""} { $sc setAttribute table:border-color    $bcol }
        if {$cback    ne ""} { $sc setAttribute table:copy-back       $cback }
        if {$cstyles  ne ""} { $sc setAttribute table:copy-styles     $cstyles }
        if {$cformulas ne ""} { $sc setAttribute table:copy-formulas   $cformulas }
        # Insert as first child of the table (before columns/rows)
        set first [$table firstChild]
        if {$first ne ""} { $table insertBefore $sc $first } else { $table appendChild $sc }
        return $sc
    }
    # tableScenario TABLE -> dict (empty dict if no scenario)
    method tableScenario {table} {
        set sc [my TableScenarioEl $table]
        if {$sc eq ""} { return [dict create] }
        return [dict create \
            ranges         [$sc getAttribute table:scenario-ranges  ""] \
            active         [$sc getAttribute table:is-active        ""] \
            display-border [$sc getAttribute table:display-border   ""] \
            border-color   [$sc getAttribute table:border-color     ""] \
            copy-back      [$sc getAttribute table:copy-back        ""] \
            copy-styles    [$sc getAttribute table:copy-styles      ""] \
            copy-formulas  [$sc getAttribute table:copy-formulas    ""]]
    }

    # ---- dde-links ------------------------------------------------------
    # table:dde-links is an epilogue wrapper for one or more table:dde-link
    # entries. Each entry pairs an office:dde-source (connection details:
    # application/topic/item) with an embedded table:table that holds the
    # most recently fetched data. We emit a minimal one-column embedded
    # table so the result is schema-valid; the consumer fills it on update.
    method DDELinksEl {create} {
        foreach c [$Body childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" \
                && [$c nodeName] eq "table:dde-links"} { return $c }
        }
        if {!$create} { return "" }
        set el [$Doc createElement table:dde-links]
        $Body appendChild $el
        my OrderEpilogue
        return $el
    }
    # addDDELink NAME -application APP -topic TOPIC -item ITEM
    #                ?-auto-update BOOL? ?-conversion-mode V?
    # NAME is the office:name on the dde-source (also used as table:name on
    # the embedded table for predictable lookup). conversion-mode is one of
    #   into-default-style-data-style | into-english-number | keep-text
    method addDDELink {name args} {
        set app ""; set topic ""; set item ""
        set auto ""; set conv ""
        foreach {k v} $args {
            switch -- $k {
                -application      { set app $v }
                -topic            { set topic $v }
                -item             { set item $v }
                -auto-update      { set auto $v }
                -conversion-mode  { set conv $v }
                default           { error "unknown option: $k" }
            }
        }
        if {$name eq ""} { error "addDDELink: name is required" }
        if {$app  eq ""} { error "addDDELink: -application is required" }
        if {$topic eq ""} { error "addDDELink: -topic is required" }
        if {$item eq ""} { error "addDDELink: -item is required" }
        if {$auto ne "" && ![string is boolean -strict $auto]} {
            error "addDDELink: -auto-update must be boolean, got: $auto"
        }
        if {$conv ne "" && $conv ni {into-default-style-data-style into-english-number keep-text}} {
            error "bad -conversion-mode: $conv (into-default-style-data-style|into-english-number|keep-text)"
        }
        set wrap [my DDELinksEl 1]
        # Replace existing entry with same name (idempotency on the name key)
        foreach c [$wrap childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE" || [$c nodeName] ne "table:dde-link"} continue
            foreach gc [$c childNodes] {
                if {[$gc nodeType] eq "ELEMENT_NODE" \
                    && [$gc nodeName] eq "office:dde-source" \
                    && [$gc getAttribute office:name ""] eq $name} {
                    $wrap removeChild $c; break
                }
            }
        }
        set link [$Doc createElement table:dde-link]
        set src  [$Doc createElement office:dde-source]
        $src setAttribute office:name             $name
        $src setAttribute office:dde-application  $app
        $src setAttribute office:dde-topic        $topic
        $src setAttribute office:dde-item         $item
        if {$auto ne ""} { $src setAttribute office:automatic-update $auto }
        if {$conv ne ""} { $src setAttribute office:conversion-mode  $conv }
        $link appendChild $src
        # Minimal embedded table: one column, one row, one empty cell.
        set tab [$Doc createElement table:table]
        $tab setAttribute table:name $name
        $tab appendChild [$Doc createElement table:table-column]
        set row [$Doc createElement table:table-row]
        $row appendChild [$Doc createElement table:table-cell]
        $tab appendChild $row
        $link appendChild $tab
        $wrap appendChild $link
        return $link
    }
    # ddeLinks -> dict NAME -> dict with the dde-source attributes.
    method ddeLinks {} {
        set out [dict create]
        set wrap [my DDELinksEl 0]
        if {$wrap eq ""} { return $out }
        foreach c [$wrap childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE" || [$c nodeName] ne "table:dde-link"} continue
            foreach gc [$c childNodes] {
                if {[$gc nodeType] ne "ELEMENT_NODE" || [$gc nodeName] ne "office:dde-source"} continue
                dict set out [$gc getAttribute office:name ""] [dict create \
                    application     [$gc getAttribute office:dde-application  ""] \
                    topic           [$gc getAttribute office:dde-topic        ""] \
                    item            [$gc getAttribute office:dde-item         ""] \
                    auto-update     [$gc getAttribute office:automatic-update ""] \
                    conversion-mode [$gc getAttribute office:conversion-mode  ""]]
                break
            }
        }
        return $out
    }
}

# A spreadsheet template (.ots): same content model as a spreadsheet document,
# only the media type differs (application/vnd.oasis.opendocument.spreadsheet-template).
proc odf::newSheetTemplate {} {
    set pkg [odf::newSheetDoc]
    $pkg setMimetype "application/vnd.oasis.opendocument.spreadsheet-template"
    return $pkg
}

package provide odf::sheet 0.24
