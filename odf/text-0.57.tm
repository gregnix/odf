## odf/text-0.2.tm  --  odf::text (phase 2): content model over content.xml
##
## Thin, editable view of the body (office:text). Works on
## the package's tdom tree -- unmodelled nodes stay verbatim (PASS-THROUGH).
## 0.57: documentation correction (no behaviour change). Render evidence from
##       LO's own reference (odf_forms_controls_reference.odt) shows that LO
##       does NOT render listbox entries or the selected value in static print/
##       PDF output -- even with form:current-selected/form:selected set and
##       the StringItemList UNO property populated. The same applies to combobox
##       dropdown contents (only form:current-value shows in the input area;
##       the entries appear only when the user clicks the dropdown).
##       This is an LO interactive-only behaviour; the markup is correct.
##       NOTE updated accordingly. The 0.56 auto-StringItemList emission stays
##       in place -- it matches LO's structural expectation and is needed for
##       interactive use; it just does not help static rendering.
## 0.56: value-list listbox / combobox rendering (slice 4). LO renders the
##       dropdown entries from a parallel UNO StringItemList property, not from
##       form:option/form:item alone. Verified against odf_forms_controls_reference
##       .odt -- LO writes <form:property StringItemList> mirroring the entries.
##       addFormListbox and addFormCombobox now auto-emit this list-property in
##       schema-correct form (office:string-value via controlListProperty; LO's
##       own output uses form:string-value, which is non-conformant). New
##       options: addFormListbox -size, -bound-column; addFormCombobox -size.
##       addFormListbox -selected now accepts either INDEX or VALUE (string).
##       form:item switched from text content to form:label attribute (LO's
##       canonical form; comboboxItems reader updated to read form:label with
##       text-content fallback for back-compat). addFormCombobox -value now
##       sets both form:value AND form:current-value (combobox is the one
##       control where common-current-value-attlist applies).
## 0.55: correction to 0.53. Render evidence shows the form:property Text
##       does NOT make LibreOffice display an xsd:time form:value in static
##       rendering. LO needs a PT.. ISO-duration in form:current-value to
##       render the time field; the Text property is just a parallel UNO
##       property (LO writes it too, schema-OK, may help interactive editing),
##       it does not override LO's display computation. Strict mode therefore
##       remains validator-clean but invisible-in-LO for time; lo-compat is
##       still the only path to LO display. NOTE in the module updated to
##       reflect this empirical truth; auto-emission of the Text property is
##       kept (matches LO's own output, harmless).
## 0.54: maintenance: review findings F1-F3 + reader symmetry.
##       - controlPlace now guards -x/-y: errors if the resulting anchor is
##         as-char (LO would silently ignore the coordinates). The user must
##         set -anchor paragraph (or page/frame) in the same call, or have it
##         set previously, before specifying absolute coordinates.
##       - Removed a stale duplicate doc-line on NextControlId.
##       - controlListPropertyValue: symmetric reader for form:list-property
##         (returns the list of values; parallel to controlListProperty writer).
## 0.53: number-format data styles (slice 3 of DB-bound forms) +
##       schema-conformant time display via Text property. New methods:
##       defineDateStyle / defineTimeStyle / defineNumberStyle (number:date-style /
##       number:time-style / number:number-style in office:automatic-styles).
##       Format mini-language (Java-like): yyyy/yy year, MMMM/MMM/MM/M month
##       (textual long/short, numeric long/short), dd/d day, HH/H hours, mm/m
##       minutes, ss/s seconds; other characters are literal text. controlPlace
##       -data-style NAME attaches style:data-style-name to a per-control variant
##       graphic style (FormCtl_NAME / FormCtlP_NAME), matching color.odt's
##       gr2->C60 pattern. addFormTime now also writes form:property Text=
##       "HH:MM[:SS]" -- a schema-conformant UNO property that LibreOffice uses
##       as the displayed time string, resolving the strict-mode display gap
##       from 0.49 (LO renders the time now even with xsd:time form:value).
##       Readers: dateStyles, timeStyles, numberStyles.
## 0.52: listbox + combobox source binding (slice 2 of DB-bound forms).
##       controlBind gains -list-source-type sql|valuelist|table|query,
##       -list-source (SQL or table/query name), -bound-column N, -size N
##       (visible rows). Combobox-specific: -auto-complete 0|1,
##       -convert-empty-to-null 0|1 (also applies to form:text). Default-
##       selection / item list use the existing controlListProperty API:
##         $t controlListProperty $lb DefaultSelection {0} float
##       Grounded against the test01.odt Base form reference (SQL listbox +
##       SQL combobox). All new attributes are schema-conformant.
## 0.51: foundation for database-bound forms (verified against a Base form
##       reference: color.odt -> form:datasource registered name, form:command,
##       command-type, apply-filter, allow-*; paragraph-anchored controls with
##       svg:x/y/z-index and a sibling graphic style FormCtlP). New methods:
##       formDatasource (DB attrs on form:form), controlBind (-data-field,
##       -input-required, -validation on the logical control), controlPlace
##       (anchor/x/y/z-index/width/height/name on the visible draw:control; auto-
##       swaps draw:style-name to FormCtlP when -anchor paragraph). Helper
##       controlLogical (find form:* logical control for a draw:control via xml:id).
##       newForm now sets form:control-implementation=Form (LO convention).
##       Deferred to next slices: listbox/combobox source binding
##       (-list-source-type/-list-source/-bound-column) and number-format data
##       styles (number:time-style/date-style/number-style via style:data-style-name).
## 0.50: generic form:property API + hidden control. controlProperty (single)
##       and controlListProperty (form:list-property + form:list-value) attach
##       LO/UNO properties conformantly (this is how the listbox StringItemList/
##       DefaultSelection display will be added once a populated LO reference is
##       on hand). addFormHidden adds a value-carrying form:hidden (no visible
##       shape). NextControlId now scans every control xml:id under office:forms
##       (hidden controls have an xml:id but no draw:control -> avoid id clashes).
## 0.49: form:time strict vs LibreOffice-compatibility mode. LO displays time
##       control values only as ISO durations (PT12H30M0S), which are NOT valid
##       xsd:time; the ODF schema wants HH:MM:SS, which LO does not show. So this
##       is a deliberate choice, not a silent quirk: formCompat strict|lo (default
##       strict) and a per-call -lo-compat 0|1 on addFormTime. strict keeps
##       validator-clean xsd:time; lo emits PT.. so LibreOffice renders the value.
## 0.48: match LibreOffice so controls render reliably (verified against a real
##       LO 'fillable' .odt). Every control now carries form:control-implementation
##       (ooo:com.sun.star.form.component.*) + a form:properties/DefaultControl
##       entry. The numeric field is form:formatted-text (impl NumericField) --
##       LO does not render a bare form:number. The FormCtl graphic style mirrors
##       LO's control style (style:wrap=run-through, vertical-rel=line, horizontal
##       from-left/paragraph; no fill/stroke -- the control paints itself).
## 0.47: more form controls -- addFormTextarea (multi-line), addFormPassword
##       (echo-char), addFormNumber / addFormDate / addFormTime (form:value +
##       min/max), addFormCombobox (editable dropdown, form:item entries) and
##       addFormRadio (radios sharing -name form a group). Same two-node model
##       (logical form:* control + visible draw:control with the FormCtl graphic
##       style). Reader: comboboxItems. Still no DB binding.
## 0.46: forms -- office:forms / form:form with controls. newForm creates a
##       <form:form> in <office:forms> (first child of office:text); addFormText,
##       addFormCheckbox, addFormButton, addFormLabel (fixed-text), addFormListbox
##       each add a logical control (xml:id = the ID, form:id mirror, form:name)
##       AND a visible <draw:control draw:control=ID> in a given paragraph. The
##       form: prefix is bound on the content.xml root on demand. Readers: forms,
##       formName, formControls, controlKind/Name/Id/Label/Value/State,
##       listboxOptions. Each draw:control carries a graphic style (FormCtl, in
##       office:automatic-styles) -- required for LibreOffice to RENDER the control
##       (a style-less draw:control is schema-valid but invisible in LO). DB-bound
##       forms (form:datasource etc.) are out of scope.
## 0.45: database / mail-merge fields -- addDatabaseDisplay (text:database-display,
##       the column-value merge field), addDatabaseNext, addDatabaseRowSelect,
##       addDatabaseRowNumber. The data source is referenced by registered NAME
##       (text:database-name); the data lives outside the document, so no .odb is
##       built (embedded form:connection-resource is out of scope by design).
##       Reader: databaseFields -> {source table column} per database-display.
## 0.44: appendChart now forwards every non-frame option to odf::chart (the
##       frame/appendObject options are a fixed set), so new chart options
##       (e.g. odf::chart 0.2 -labels/-xtitle/-ytitle) work through appendChart
##       without any change here. Behaviour for existing options is unchanged.
## 0.43: chart model extracted to the odf::chart package. appendChart is now a
##       thin wrapper (split chart vs frame options, call odf::chart::buildContent,
##       embed via appendObject); the inline chart builder + ChartCell/ColLetter
##       were removed (text.tm ~160 lines smaller). odf::chart also provides the
##       standalone chart-document factory odf::newChartDoc (.odc). No behaviour
##       change for appendChart.
## 0.42: embedded spreadsheet -- appendSpreadsheet builds a small .ods with
##       odf::sheet (loaded on demand) and embeds it as an editable OLE object
##       via appendObject (Object N/, media type ...opendocument.spreadsheet).
##       Cell specs are the explicit odf::sheet format (no auto-typing). Reader:
##       spreadsheets. Completes the embedded-objects strand (chart + spreadsheet).
## 0.41: chart styling -- appendChart gains -colors (per-series fill via
##       style:graphic-properties draw:fill-color), -stacked / -percent and
##       -vertical (style:chart-properties on the plot-area style), and -legend
##       none|start|end|top|bottom (chart:legend, inserted before plot-area per
##       the RNG child order). Styles live in the chart sub-document's
##       office:automatic-styles and are referenced via chart:style-name.
## 0.40: embedded objects + charts -- appendObject is the generic embedding /
##       pass-through primitive: it stores a sub-document as "Object N/content.xml"
##       (+ optional styles.xml) with a manifest directory entry carrying the
##       object media type, and references it from the body via draw:frame >
##       draw:object (xlink href group, RNG-grounded). appendChart builds a
##       minimal valid office:chart sub-document (bar/column/line/pie, category
##       axis + value axis, one chart:series per data series) with a self-
##       contained local-table holding the data, then embeds it. Readers:
##       objects, charts.
## 0.39: master documents (.odm) -- newMasterDoc / newMasterTemplate set the
##       text-master(-template) media type; appendSubdocument links an external
##       document as a protected text:section > text:section-source (the source
##       is the section's FIRST child per the ODF 1.3 RNG; href/type/show group,
##       optional text:section-name/-filter-name). A master body is a normal
##       office:text (no office:text-master element exists); the master nature is
##       the package media type plus the linked sections. Reader: subdocuments.
## 0.38: fix draw:frame child order -- ImageFrame emitted svg:title/svg:desc
##       BEFORE draw:image, which is invalid per the ODF 1.3 RNG (the frame
##       content draw:image must precede svg:title/svg:desc, which in turn
##       precede draw:contour-*). LibreOffice tolerated it but odfvalidator
##       rejected titled/described image frames. Now draw:image is appended
##       first, then svg:title, then svg:desc. Readers are order-independent.
## 0.37: admonitions -- appendAdmonition builds a Note/Tip/Caution/Warning callout
##       as a 1x1 framed table (per-kind background tint + border) with a bold,
##       coloured label paragraph and the body paragraph(s). Reader: admonitions.
## 0.36: TOC full -- appendTOC entry templates now wrap each entry in
##       text:index-entry-link-start/-end (clickable, default on, -links) and can
##       add a chapter number (-chapter); new fillTOC populates the index-body
##       from the document's headings (text:index-title + Contents_N paragraphs)
##       so the TOC is visible without a consumer regenerating it.
## 0.35: embedded math -- addFormula embeds MathML inline as draw:frame >
##       draw:object > math:math (no sub-document/manifest needed; the ODF RNG
##       allows math:math directly inside draw:object). Options -anchor/-width/
##       -height. Readers: formulas, formulaMathML; runKind reports formula.
## 0.34: change tracking -- text:tracked-changes container with addInsertion /
##       addDeletion / addFormatChange (text:changed-region + office:change-info:
##       dc:creator/dc:date + optional comment; deletion carries deleted text),
##       and inline addChangeStart / addChangeEnd / addChange (text:change-id).
##       Readers: changedRegions, changeType/Author/Date/Comment/Id; kind reports
##       tracked-changes, runKind change / change-start / change-end.
## 0.33: newTextTemplate -- create a .ott text template (text-template media
##       type via Package setMimetype; same content model as newTextDoc).
## 0.32: annotations -- addAnnotation (office:annotation with optional
##       office:name/office:display, dc:creator/dc:date/meta:creator-initials
##       and text:p body) and addAnnotationEnd (ranged, office:name). Readers:
##       annotations, annotationAuthor/Date/Text/Name; runKind reports
##       annotation / annotation-end. content.xml now declares dc/meta NS.
## 0.31: document fields -- addPageNumber / addPageCount / addDate / addTime /
##       addTitle / addSubject / addAuthor / addChapter / addFileName (inline
##       text fields). Reader fields; runKind reports the field kinds.
## 0.30: captions + figure/table indexes -- appendCaption (text:sequence field
##       with auto sequence-decl), addSequenceField, and appendIllustrationIndex /
##       appendTableIndex. Readers: captions, illustrationIndexes, tableIndexes;
##       kind reports illustration-index/table-index, runKind reports sequence.
## 0.29: alphabetical index -- addIndexMark (inline text:alphabetical-index-mark
##       with text:string-value + key1/key2/main-entry) and appendIndex
##       (text:alphabetical-index; consumer regenerates the entry list). Readers:
##       indexMarks, alphabeticalIndexes; kind reports index, runKind index-mark.
## 0.28: bibliography -- addBibliographyMark (inline text:bibliography-mark
##       with text:bibliography-type + field attributes) and appendBibliography
##       (text:bibliography index; consumer regenerates the entry list). Readers:
##       bibliographyMarks, bibliographies; kind reports bibliography, runKind
##       reports bibliography-mark.
## 0.27: bookmarks and cross-references -- addBookmark / addBookmarkStart /
##       addBookmarkEnd / addReferenceMark(+Start/End) (inline anchors), and
##       addBookmarkRef / addReferenceRef (text:reference-format). Readers:
##       bookmarks, referenceMarks; runKind reports bookmark*/ref*/refmark*.
## 0.22: -align now anchors the image as-char (inline) so a centered/left/
##       right block image actually renders centered (paragraph-anchored
##       frames float and ignore text-align).
## 0.21: images/frames: embedImage/appendImageFile (embed from disk),
##       appendImageFit gains -anchor/-align/-style/-title/-desc, defineFrameStyle
##       (wrap/position/border/background), images/imageInfo readers, GIF size.
## 0.20: cell spanning: spanCell (table:number-columns-spanned /
##       -rows-spanned + table:covered-table-cell) and cellSpan reader.
## 0.19: declare xmlns:svg in the styles.xml skeleton (font-face uses
##       svg:font-family; odf::style registerFont writes to styles.xml).
## 0.18: corrected the style:style child order to the real ODF schema
##       order: table-cell-properties before paragraph-properties before
##       text-properties (verified against the ODF validator).
## 0.17: order style:style property children per ODF schema (fixes
##       table-cell styles with paragraph+cell+text groups).
## 0.16: defineAutoTable/defineAutoColumn/defineAutoCellStyle (automatic
##       table styles in content.xml -- body tables need these to render).
## 0.15: setCellStyle (assign a cell style to an existing cell).
## 0.14: tables: appendTableCols (column styles/widths), addHeaderRow,
##       addRow cell styles, tableColumns/isHeaderRow reads.
## 0.13: addLine (absolute draw:line, e.g. fold marks).
## 0.12: registerFont (office:font-face-decls in content.xml).
## 0.11: addTextFrame (absolutely positioned text frames) + defineAutoGraphic.
## 0.10: style resolution (styleRegistry/resolveStyle/effectiveProps, inheritance).
## 0.9: appendImageFit also for JPEG (SOF marker).
## 0.8: addSublist (nested lists when building).
## 0.7: appendImageFit (PNG size automatic, scaled to page width).
## 0.6: inline expansion (links text:a, line-break, tab; runKind link|linebreak|tab).
## 0.5: automatic styles (defineAuto* in content.xml/office:automatic-styles).
## 0.4: builder (newTextDoc + appendList/appendTable/appendImage).
## 0.3: lists & tables (items, rows/cells read+edit).
## 0.2: run level for inline-preserving editing (text:span/bold/italic
## are preserved when you change a run).
##
##   set t [odf::Text new $pkg]
##   foreach n [$t blocks] { puts "[$t kind $n]: [$t text $n]" }
##   foreach r [$t runs $node] { puts "[$t runKind $r] [$t runStyle $r]: [$t runText $r]" }
##   $t setRunText $run "new text"       ;# only this run, rest stays
##   $t addSpan $node "bold" BoldStyle
##   $t flush; $pkg save out.odt
##
## kind: heading|paragraph|list|table|image|unknown ; runKind: text|span|other

package require Tcl 8.6 9
package require tdom
package require odf

oo::class create odf::Text {
    variable Pkg Doc Body FormCompat

    constructor {pkg} {
        set Pkg $pkg
        set Doc [$pkg tree content.xml]
        set Body [lindex [[$Doc documentElement] getElementsByTagName office:text] 0]
        if {$Body eq ""} { error "no office:text in content.xml" }
        set FormCompat strict
        $Pkg registerFlushHook [list [self] flush]
    }
    destructor { if {[info exists Doc] && $Doc ne ""} { $Doc delete } }

    # ---- Navigation ----
    method blocks {} {
        set res {}
        foreach n [$Body childNodes] {
            if {[$n nodeType] eq "ELEMENT_NODE"} { lappend res $n }
        }
        return $res
    }

    # ---- classification / reading ----
    method kind {node} {
        switch -- [$node nodeName] {
            text:h      { return heading }
            text:p      { return [expr {[my HasImage $node] ? "image" : "paragraph"}] }
            text:list   { return list }
            table:table  { return table }
            text:section { return section }
            text:table-of-content { return toc }
            text:bibliography { return bibliography }
            text:alphabetical-index { return index }
            text:illustration-index { return illustration-index }
            text:table-index { return table-index }
            text:sequence-decls { return sequence-decls }
            text:tracked-changes { return tracked-changes }
            default      { return unknown }
        }
    }
    method level {node} { return [$node getAttribute text:outline-level ""] }
    method style {node} { return [$node getAttribute text:style-name ""] }
    method text  {node} { return [$node asText] }
    method find  {wanted} {
        set res {}
        foreach n [my blocks] { if {[my kind $n] eq $wanted} { lappend res $n } }
        return $res
    }

    # ---- inline runs (text:span, text nodes, other) ----
    # Returns the run nodes of a paragraph/heading as handles.
    method runs {node} {
        set res {}
        foreach c [$node childNodes] {
            set t [$c nodeType]
            if {$t eq "TEXT_NODE" || $t eq "ELEMENT_NODE"} { lappend res $c }
        }
        return $res
    }
    method runKind {run} {
        if {[$run nodeType] eq "TEXT_NODE"} { return text }
        switch -- [$run nodeName] {
            text:span               { return span }
            text:a                  { return link }
            text:line-break         { return linebreak }
            text:tab                { return tab }
            text:note               { return note }
            office:annotation       { return annotation }
            office:annotation-end   { return annotation-end }
            text:change             { return change }
            text:change-start       { return change-start }
            text:change-end         { return change-end }
            draw:frame              { return [expr {[llength [$run getElementsByTagName math:math]] ? "formula" : "frame"}] }
            text:bookmark           { return bookmark }
            text:bookmark-start     { return bookmark-start }
            text:bookmark-end       { return bookmark-end }
            text:reference-mark       { return refmark }
            text:reference-mark-start { return refmark-start }
            text:reference-mark-end   { return refmark-end }
            text:bookmark-ref       { return bookmark-ref }
            text:reference-ref      { return reference-ref }
            text:bibliography-mark  { return bibliography-mark }
            text:alphabetical-index-mark { return index-mark }
            text:sequence           { return sequence }
            text:page-number        { return page-number }
            text:page-count         { return page-count }
            text:date               { return date }
            text:time               { return time }
            text:title              { return title }
            text:subject            { return subject }
            text:author-name        { return author-name }
            text:chapter            { return chapter }
            text:file-name          { return file-name }
            default                 { return other }
        }
    }
    method linkHref {run} { return [$run getAttribute xlink:href ""] }
    method runText {run} {
        if {[$run nodeType] eq "TEXT_NODE"} { return [$run nodeValue] }
        return [$run asText]
    }
    method runStyle {run} {
        if {[$run nodeType] eq "ELEMENT_NODE"} { return [$run getAttribute text:style-name ""] }
        return ""
    }

    # Inline-erhaltend: Text genau EINES Runs ersetzen; Geschwister bleiben.
    method setRunText {run newtext} {
        if {[$run nodeType] eq "TEXT_NODE"} {
            $run nodeValue $newtext
        } else {
            foreach c [$run childNodes] { $c delete }
            $run appendChild [$Doc createTextNode $newtext]
        }
        return $run
    }
    # Append runs without destroying existing content.
    method addText {node text} {
        set tn [$Doc createTextNode $text]; $node appendChild $tn; return $tn
    }
    method addSpan {node text style} {
        set sp [$Doc createElement text:span]
        if {$style ne ""} { $sp setAttribute text:style-name $style }
        $sp appendChild [$Doc createTextNode $text]
        $node appendChild $sp
        return $sp
    }
    method addLink {node text href {style ""}} {
        set a [$Doc createElement text:a]
        $a setAttribute xlink:type simple
        $a setAttribute xlink:href $href
        if {$style ne ""} { $a setAttribute text:style-name $style }
        $a appendChild [$Doc createTextNode $text]
        $node appendChild $a
        return $a
    }
    method addBreak {node} { set b [$Doc createElement text:line-break]; $node appendChild $b; return $b }
    method addTab   {node} { set t [$Doc createElement text:tab];        $node appendChild $t; return $t }

    # ---- bookmarks, reference marks, cross-references (inline anchors) ----
    # A point bookmark (text:bookmark) at the current position in the paragraph.
    method addBookmark {node name} {
        set b [$Doc createElement text:bookmark]
        $b setAttribute text:name $name
        $node appendChild $b
        return $b
    }
    # Range bookmark: place addBookmarkStart, then content, then addBookmarkEnd
    # with the SAME name (the consumer matches them by name).
    method addBookmarkStart {node name} {
        set b [$Doc createElement text:bookmark-start]
        $b setAttribute text:name $name
        $node appendChild $b
        return $b
    }
    method addBookmarkEnd {node name} {
        set b [$Doc createElement text:bookmark-end]
        $b setAttribute text:name $name
        $node appendChild $b
        return $b
    }
    # Reference marks (the parallel mechanism to bookmarks; LO uses these for
    # "insert > cross-reference > set reference").
    method addReferenceMark {node name} {
        set r [$Doc createElement text:reference-mark]
        $r setAttribute text:name $name
        $node appendChild $r
        return $r
    }
    method addReferenceMarkStart {node name} {
        set r [$Doc createElement text:reference-mark-start]
        $r setAttribute text:name $name
        $node appendChild $r
        return $r
    }
    method addReferenceMarkEnd {node name} {
        set r [$Doc createElement text:reference-mark-end]
        $r setAttribute text:name $name
        $node appendChild $r
        return $r
    }
    # Cross-reference to a bookmark: text:bookmark-ref pointing at ref-name.
    # ?-format page|chapter|direction|text|number|number-no-superior|number-all-superior?
    # ?-text DISPLAY? (the cached display text; defaults to the ref-name). The
    # consumer recomputes the display text on update.
    method addBookmarkRef {node name args} {
        return [my MakeRef text:bookmark-ref $node $name $args]
    }
    # Cross-reference to a reference mark: text:reference-ref. Same options.
    method addReferenceRef {node name args} {
        return [my MakeRef text:reference-ref $node $name $args]
    }
    method MakeRef {tag node name optargs} {
        set valid {page chapter direction text number number-no-superior number-all-superior}
        set format ""; set disp $name
        foreach {k v} $optargs {
            switch -- $k {
                -format { if {$v ni $valid} { error "invalid reference-format: $v" }; set format $v }
                -text   { set disp $v }
                default { error "unknown option: $k" }
            }
        }
        set r [$Doc createElement $tag]
        $r setAttribute text:ref-name $name
        if {$format ne ""} { $r setAttribute text:reference-format $format }
        $r appendChild [$Doc createTextNode $disp]
        $node appendChild $r
        return $r
    }
    # Bookmark names in the document (point bookmarks + range starts).
    method bookmarks {} {
        set root [$Doc documentElement]
        set names {}
        foreach b [$root getElementsByTagName text:bookmark]       { lappend names [$b getAttribute text:name ""] }
        foreach b [$root getElementsByTagName text:bookmark-start] { lappend names [$b getAttribute text:name ""] }
        return $names
    }
    # Reference-mark names in the document (point marks + range starts).
    method referenceMarks {} {
        set root [$Doc documentElement]
        set names {}
        foreach r [$root getElementsByTagName text:reference-mark]       { lappend names [$r getAttribute text:name ""] }
        foreach r [$root getElementsByTagName text:reference-mark-start] { lappend names [$r getAttribute text:name ""] }
        return $names
    }
    # Read a cross-reference run's target name and format.
    method refName {run}   { return [$run getAttribute text:ref-name ""] }
    method refFormat {run} { return [$run getAttribute text:reference-format ""] }

    # Existing text:note ids in the document.
    method NoteIds {} {
        set ids {}
        foreach n [[$Doc documentElement] getElementsByTagName text:note] {
            set id [$n getAttribute text:id ""]; if {$id ne ""} { lappend ids $id }
        }
        return $ids
    }
    # Inline footnote/endnote anchored in a paragraph node. ?-class footnote|endnote?
    # ?-id ID? ?-citation MARK?. The body is a single text:p with <text>. Returns
    # the text:note node. Citation defaults to the next number within the class;
    # the consumer (e.g. LibreOffice) renumbers on open.
    method addFootnote {node text args} {
        set class footnote; set id ""; set citation ""
        foreach {k v} $args {
            switch -- $k {
                -class    { set class $v }
                -id       { set id $v }
                -citation { set citation $v }
                default   { error "unknown option: $k" }
            }
        }
        if {$class ni {footnote endnote}} { error "note class must be footnote or endnote: $class" }
        if {$id eq ""} {
            set prefix [expr {$class eq "endnote" ? "edn" : "ftn"}]
            set ids [my NoteIds]; set i 1
            while {"$prefix$i" in $ids} { incr i }
            set id "$prefix$i"
        }
        if {$citation eq ""} {
            set n 0
            foreach nn [[$Doc documentElement] getElementsByTagName text:note] {
                if {[$nn getAttribute text:note-class ""] eq $class} { incr n }
            }
            set citation [expr {$n + 1}]
        }
        set note [$Doc createElement text:note]
        $note setAttribute text:id $id
        $note setAttribute text:note-class $class
        set cit [$Doc createElement text:note-citation]
        $cit appendChild [$Doc createTextNode $citation]
        $note appendChild $cit
        set body [$Doc createElement text:note-body]
        set para [$Doc createElement text:p]
        $para appendChild [$Doc createTextNode $text]
        $body appendChild $para
        $note appendChild $body
        $node appendChild $note
        return $note
    }
    method addEndnote {node text args} { return [my addFootnote $node $text -class endnote {*}$args] }

    # ---- annotations (office:annotation) -- an inline comment at the current
    # position in a paragraph. Options: -name (for a ranged annotation, matched
    # by addAnnotationEnd with the same name), -author, -date (ISO 8601; default
    # = now), -initials, -display (boolean -> true/false). Child order follows
    # the schema: dc:creator, dc:date, meta:creator-initials, then the text:p body.
    method addAnnotation {node text args} {
        set name ""; set author ""; set initials ""; set display ""
        set date [clock format [clock seconds] -format %Y-%m-%dT%H:%M:%S]
        foreach {k v} $args {
            switch -- $k {
                -name     { set name $v }
                -author   { set author $v }
                -date     { set date $v }
                -initials { set initials $v }
                -display  { set display $v }
                default   { error "unknown option: $k" }
            }
        }
        set ann [$Doc createElement office:annotation]
        if {$name ne ""} { $ann setAttribute office:name $name }
        if {$display ne ""} {
            $ann setAttribute office:display [expr {$display ? "true" : "false"}]
        }
        if {$author ne ""} {
            set c [$Doc createElement dc:creator]
            $c appendChild [$Doc createTextNode $author]
            $ann appendChild $c
        }
        if {$date ne ""} {
            set d [$Doc createElement dc:date]
            $d appendChild [$Doc createTextNode $date]
            $ann appendChild $d
        }
        if {$initials ne ""} {
            set ci [$Doc createElement meta:creator-initials]
            $ci appendChild [$Doc createTextNode $initials]
            $ann appendChild $ci
        }
        if {$text ne ""} {
            set p [$Doc createElement text:p]
            $p appendChild [$Doc createTextNode $text]
            $ann appendChild $p
        }
        $node appendChild $ann
        return $ann
    }
    # Range annotation end: same office:name as the matching addAnnotation -name.
    method addAnnotationEnd {node name} {
        set e [$Doc createElement office:annotation-end]
        $e setAttribute office:name $name
        $node appendChild $e
        return $e
    }
    # Annotation readers.
    method annotations {} {
        return [[$Doc documentElement] getElementsByTagName office:annotation]
    }
    method annotationName   {run} { return [$run getAttribute office:name ""] }
    method annotationAuthor {run} {
        set c [lindex [$run getElementsByTagName dc:creator] 0]
        return [expr {$c eq "" ? "" : [$c asText]}]
    }
    method annotationDate {run} {
        set d [lindex [$run getElementsByTagName dc:date] 0]
        return [expr {$d eq "" ? "" : [$d asText]}]
    }
    method annotationText {run} {
        set ps {}
        foreach para [$run getElementsByTagName text:p] { lappend ps [$para asText] }
        return [join $ps "\n"]
    }

    # ---- change tracking (text:tracked-changes) -------------------------------
    # The body-level container holding text:changed-region entries. Created in the
    # office:text prelude (after office:forms if present) when first needed.
    method TrackedChanges {} {
        set tc [lindex [$Body getElementsByTagName text:tracked-changes] 0]
        if {$tc ne ""} { return $tc }
        set tc [$Doc createElement text:tracked-changes]
        set ref ""
        foreach ch [$Body childNodes] {
            if {[$ch nodeName] eq "office:forms"} { continue }
            set ref $ch; break
        }
        if {$ref eq ""} { $Body appendChild $tc } else { $Body insertBefore $tc $ref }
        return $tc
    }
    # Register a changed region (type: insertion | deletion | format-change) with
    # change info. Options: -author (dc:creator), -date (dc:date, ISO 8601, default
    # now), -comment (a text:p in the change-info), and for deletion -content (the
    # deleted text as a text:p). The id is referenced by the inline markers.
    method AddChangedRegion {id type args} {
        set author ""; set comment ""; set content ""
        set date [clock format [clock seconds] -format %Y-%m-%dT%H:%M:%S]
        foreach {k v} $args {
            switch -- $k {
                -author  { set author $v }
                -date    { set date $v }
                -comment { set comment $v }
                -content { set content $v }
                default  { error "unknown option: $k" }
            }
        }
        set region [$Doc createElement text:changed-region]
        $region setAttribute xml:id $id
        $region setAttribute text:id $id
        set ch [$Doc createElement text:$type]
        set ci [$Doc createElement office:change-info]
        set c [$Doc createElement dc:creator]; $c appendChild [$Doc createTextNode $author]; $ci appendChild $c
        set d [$Doc createElement dc:date];    $d appendChild [$Doc createTextNode $date];   $ci appendChild $d
        if {$comment ne ""} {
            set cp [$Doc createElement text:p]; $cp appendChild [$Doc createTextNode $comment]; $ci appendChild $cp
        }
        $ch appendChild $ci
        if {$type eq "deletion" && $content ne ""} {
            set p [$Doc createElement text:p]; $p appendChild [$Doc createTextNode $content]; $ch appendChild $p
        }
        $region appendChild $ch
        [my TrackedChanges] appendChild $region
        return $region
    }
    method addInsertion   {id args} { return [my AddChangedRegion $id insertion {*}$args] }
    method addDeletion    {id args} { return [my AddChangedRegion $id deletion {*}$args] }
    method addFormatChange {id args} { return [my AddChangedRegion $id format-change {*}$args] }

    # Inline change markers in a paragraph. text:change is a point (used for a
    # deletion's position); text:change-start / -end bracket an inserted or
    # format-changed range. text:change-id references the changed-region id.
    method addChange      {node id} { set e [$Doc createElement text:change];       $e setAttribute text:change-id $id; $node appendChild $e; return $e }
    method addChangeStart {node id} { set e [$Doc createElement text:change-start]; $e setAttribute text:change-id $id; $node appendChild $e; return $e }
    method addChangeEnd   {node id} { set e [$Doc createElement text:change-end];   $e setAttribute text:change-id $id; $node appendChild $e; return $e }

    # Change-tracking readers.
    method changedRegions {} {
        set tc [lindex [$Body getElementsByTagName text:tracked-changes] 0]
        if {$tc eq ""} { return {} }
        return [$tc getElementsByTagName text:changed-region]
    }
    method changeId   {region} {
        set v [$region getAttribute xml:id ""]
        return [expr {$v ne "" ? $v : [$region getAttribute text:id ""]}]
    }
    method changeType {region} {
        foreach t {insertion deletion format-change} {
            if {[llength [$region getElementsByTagName text:$t]]} { return $t }
        }
        return ""
    }
    method changeAuthor {region} {
        set c [lindex [$region getElementsByTagName dc:creator] 0]
        return [expr {$c eq "" ? "" : [$c asText]}]
    }
    method changeDate {region} {
        set d [lindex [$region getElementsByTagName dc:date] 0]
        return [expr {$d eq "" ? "" : [$d asText]}]
    }
    method changeComment {region} {
        set ci [lindex [$region getElementsByTagName office:change-info] 0]
        if {$ci eq ""} { return "" }
        set ps {}
        foreach para [$ci getElementsByTagName text:p] { lappend ps [$para asText] }
        return [join $ps "\n"]
    }

    # ---- embedded math (math:math via draw:object) ----------------------------
    # Embed a MathML formula inline as draw:frame > draw:object > math:math. The
    # ODF RNG permits math:math directly inside draw:object, so no separate
    # sub-document or manifest entry is needed. $mathml is presentation MathML:
    # either the body (e.g. "<mrow><mi>E</mi><mo>=</mo>...</mrow>"), which is
    # wrapped in a namespaced math:math, or a complete "<math:math ...>...". The
    # frame is appended to $node (a paragraph). Options: -anchor (default as-char),
    # -width, -height (LibreOffice recomputes the formula size on load).
    method addFormula {node mathml args} {
        set anchor as-char; set width "2.5cm"; set height "0.8cm"
        foreach {k v} $args {
            switch -- $k {
                -anchor { set anchor $v }
                -width  { set width $v }
                -height { set height $v }
                default { error "unknown option: $k" }
            }
        }
        set frame [$Doc createElement draw:frame]
        $frame setAttribute text:anchor-type $anchor
        $frame setAttribute svg:width  $width
        $frame setAttribute svg:height $height
        set obj [$Doc createElement draw:object]
        $frame appendChild $obj
        set body $mathml
        if {![string match {*<math:math*} $body]} {
            set ns "http://www.w3.org/1998/Math/MathML"
            set body "<math:math xmlns:math=\"$ns\" xmlns=\"$ns\">$body</math:math>"
        }
        $obj appendXML $body
        $node appendChild $frame
        return $frame
    }
    # All embedded formula objects (draw:object carrying a math:math).
    method formulas {} {
        set res {}
        foreach o [$Body getElementsByTagName draw:object] {
            if {[llength [$o getElementsByTagName math:math]]} { lappend res $o }
        }
        return $res
    }
    # The MathML markup of a formula object (as serialized XML), "" if none.
    method formulaMathML {obj} {
        set m [lindex [$obj getElementsByTagName math:math] 0]
        return [expr {$m eq "" ? "" : [$m asXML]}]
    }

    # ---- embedded objects (draw:frame > draw:object -> sub-document) ----------
    # Generic embedding / pass-through primitive: store a sub-document in the
    # package as "Object N/content.xml" with media type $mediatype and reference
    # it from the body via draw:frame > draw:object. Per the ODF 1.3 RNG,
    # draw:object carries the xlink href group (type=simple, href, show=embed,
    # actuate=onLoad); the sub-document's media type lives on the "Object N/"
    # manifest directory entry. Used for charts, OLE, etc.
    #   mediatype  the object's root media type (e.g.
    #              application/vnd.oasis.opendocument.chart)
    #   content    the object's content.xml as a UTF-8 string (a complete
    #              office:document-content document)
    # Options: -name N, -anchor A (default paragraph), -width W (default 12cm),
    #   -height H (default 8cm), -style S (frame graphic style), -styles X
    #   (optional styles.xml for the object), -dir D (object dir, default auto).
    # Returns the draw:frame node.
    method appendObject {mediatype content args} {
        set name ""; set anchor paragraph; set width 12cm; set height 8cm
        set style ""; set styles ""; set dir ""
        foreach {k v} $args {
            switch -- $k {
                -name   { set name $v }
                -anchor { set anchor $v }
                -width  { set width $v }
                -height { set height $v }
                -style  { set style $v }
                -styles { set styles $v }
                -dir    { set dir $v }
                default { error "unknown option: $k" }
            }
        }
        if {$dir eq ""} {
            # next free "Object N": count distinct existing object directories
            # (a single object may have several parts, e.g. content.xml + styles.xml).
            set seen {}
            foreach p [$Pkg parts] { if {[regexp {^(Object [0-9]+)/} $p -> d]} { dict set seen $d 1 } }
            set dir "Object [expr {[dict size $seen] + 1}]"
        }
        # object parts: content.xml (+ optional styles.xml); the directory entry
        # carries the object media type.
        $Pkg addpart "$dir/content.xml" [encoding convertto utf-8 $content] text/xml
        if {$styles ne ""} { $Pkg addpart "$dir/styles.xml" [encoding convertto utf-8 $styles] text/xml }
        set md [$Pkg tree META-INF/manifest.xml]
        set fe [$md createElement manifest:file-entry]
        $fe setAttribute manifest:full-path "$dir/"
        $fe setAttribute manifest:media-type $mediatype
        [$md documentElement] appendChild $fe
        $Pkg settree META-INF/manifest.xml $md
        $md delete
        # body reference
        set p  [$Doc createElement text:p]
        set fr [$Doc createElement draw:frame]
        if {$name ne ""}  { $fr setAttribute draw:name $name }
        if {$style ne ""} { $fr setAttribute draw:style-name $style }
        $fr setAttribute text:anchor-type $anchor
        $fr setAttribute svg:width  $width
        $fr setAttribute svg:height $height
        set obj [$Doc createElement draw:object]
        $obj setAttribute xlink:href "./$dir"
        $obj setAttribute xlink:type simple
        $obj setAttribute xlink:show embed
        $obj setAttribute xlink:actuate onLoad
        $fr appendChild $obj
        $p appendChild $fr
        $Body appendChild $p
        return $fr
    }

    # ---- embedded charts (a minimal, valid office:chart sub-document) ----------
    # Build a chart from simple data and embed it via appendObject. The chart
    # carries its own data in a local-table (the standard ODF convention) so it
    # is self-contained and editable; series/categories reference that table by
    # cell range. A minimal chart model (bar/column/line/pie, one category axis,
    # one value axis) with optional styling via office:automatic-styles.
    #   categories  list of category labels (the x-axis tick labels)
    #   series      a flat list {name1 {v1 v2 ...} name2 {v1 v2 ...} ...}; every
    #               value list must have [llength $categories] entries
    # Options: -type bar|column|line|pie (default column), -title T,
    #   -colors {hex ...} (per-series fill, e.g. "#1A56DB"; "" keeps default),
    #   -stacked 0|1, -percent 0|1 (100% stacked), -legend none|start|end|top|
    #   bottom (default none), -vertical 0|1 (bar orientation; default from -type:
    #   bar=horizontal, column=vertical), -labels none|value|percentage|value-and-
    #   percentage (data labels), -xtitle T / -ytitle T (axis titles). All chart
    #   options are owned and validated by odf::chart::buildContent; any frame
    #   option (-name/-anchor/-width/-height/-style) goes to appendObject.
    # Returns the draw:frame node.
    method appendChart {categories series args} {
        if {[catch {package require odf::chart}]} {
            error "appendChart requires the odf::chart package"
        }
        # Route the frame/appendObject options to the embedding; forward every
        # other option to odf::chart::buildContent. New chart options therefore
        # need no change here -- the chart model owns and validates them.
        set frameOpts {-name -anchor -width -height -style -styles -dir}
        set chartArgs {}; set pass {}
        foreach {k v} $args {
            if {$k in $frameOpts} { lappend pass $k $v } else { lappend chartArgs $k $v }
        }
        set content [odf::chart::buildContent $categories $series {*}$chartArgs]
        return [my appendObject application/vnd.oasis.opendocument.chart $content {*}$pass]
    }

    # All embedded objects (draw:object that reference a sub-document via
    # xlink:href): list of dicts name/href/mediatype. mediatype is resolved from
    # the manifest directory entry when available.
    method objects {} {
        set man [$Pkg manifest]
        set res {}
        foreach o [$Body getElementsByTagName draw:object] {
            set href [$o getAttribute xlink:href ""]
            if {$href eq ""} continue
            set dir [string trimleft $href "./"]
            set mt ""
            if {[dict exists $man "$dir/"]} { set mt [dict get $man "$dir/"] }
            set fr [$o parentNode]
            lappend res [dict create \
                name [$fr getAttribute draw:name ""] href $href mediatype $mt]
        }
        return $res
    }
    # Subset of objects that are charts (chart media type).
    method charts {} {
        set res {}
        foreach o [my objects] {
            if {[dict get $o mediatype] eq "application/vnd.oasis.opendocument.chart"} { lappend res $o }
        }
        return $res
    }

    # ---- embedded spreadsheet (an editable .ods object in the text body) -------
    # Build a small spreadsheet with odf::sheet and embed it as an OLE object via
    # appendObject (Object N/, media type ...opendocument.spreadsheet). The
    # spreadsheet stays editable in a consumer such as LibreOffice. Requires the
    # odf::sheet package, loaded on demand (skip-on-missing with a clear error).
    #   rows  a list of rows; each row is a list of cell specs in the odf::sheet
    #         format: {string TEXT} | {float N} | {percentage N} | {currency N ?CUR?}
    #         | {date ISO} | {time DUR} | {boolean B} | {formula OF INNER-SPEC}.
    #         Cell types are explicit (no auto-typing): missing things show
    #         themselves.
    # Options: -sheet NAME (table:name, default "Table1"), plus any appendObject
    #   option (-name/-anchor/-width/-height/-style for the frame).
    # Returns the draw:frame node.
    method appendSpreadsheet {rows args} {
        if {[catch {package require odf::sheet}]} {
            error "appendSpreadsheet requires the odf::sheet package"
        }
        set sheet Table1; set pass {}
        foreach {k v} $args {
            switch -- $k {
                -sheet  { set sheet $v }
                default { lappend pass $k $v }
            }
        }
        # build a throwaway spreadsheet document, then lift its content/styles
        set spkg [odf::newSheetDoc]
        set sh   [odf::Sheet new $spkg]
        set tbl  [$sh addTable $sheet]
        foreach row $rows { $sh addRow $tbl $row }
        $sh flush
        set content [encoding convertfrom utf-8 [$spkg part content.xml]]
        set styles  [encoding convertfrom utf-8 [$spkg part styles.xml]]
        $sh destroy; $spkg destroy
        return [my appendObject application/vnd.oasis.opendocument.spreadsheet $content -styles $styles {*}$pass]
    }

    # Subset of objects that are embedded spreadsheets (spreadsheet media type).
    method spreadsheets {} {
        set res {}
        foreach o [my objects] {
            if {[dict get $o mediatype] eq "application/vnd.oasis.opendocument.spreadsheet"} { lappend res $o }
        }
        return $res
    }
    # Note readers.
    method noteClass {run} { return [$run getAttribute text:note-class ""] }
    method noteCitation {run} {
        set c [lindex [$run getElementsByTagName text:note-citation] 0]
        return [expr {$c eq "" ? "" : [$c asText]}]
    }
    method noteText {run} {
        set b [lindex [$run getElementsByTagName text:note-body] 0]
        if {$b eq ""} { return "" }
        set ps {}
        foreach para [$b getElementsByTagName text:p] { lappend ps [$para asText] }
        return [join $ps "\n"]
    }

    # ---- Bearbeiten (Block-Ebene) ----
    # Coarse: replaces ALL children with one text node (runs are lost).
    # For inline-preserving edits use setRunText/addSpan.
    method setText {node newtext} {
        foreach c [$node childNodes] { $c delete }
        $node appendChild [$Doc createTextNode $newtext]
        return $node
    }
    method appendParagraph {text {style ""}}      { return [my Append text:p $text $style ""] }
    method appendHeading   {text level {style ""}} { return [my Append text:h $text $style $level] }


    # ---- forms (office:forms / form:form + controls) --------------------------
    # A form lives in the office:text prelude: <office:forms> is the FIRST child
    # of office:text and holds one or more <form:form>. Every control is TWO
    # nodes sharing an id: the logical control inside form:form (carries the ID
    # via xml:id) and a visible <draw:control draw:control="<xml:id>"> placed in
    # the text flow. The form: prefix is bound on the content.xml root on demand
    # (xml:id needs no declaration -- built-in XML namespace).
    # v1 controls: text, checkbox, button, fixed-text (label), listbox.

    method Forms {} {
        # office:forms container as the FIRST child of office:text. Always
        # (re)bind the form: prefix on the root -- idempotent, cheap.
        [$Doc documentElement] setAttribute xmlns:form \
            urn:oasis:names:tc:opendocument:xmlns:form:1.0
        [$Doc documentElement] setAttribute xmlns:ooo \
            http://openoffice.org/2004/office
        set f [lindex [$Body getElementsByTagName office:forms] 0]
        if {$f ne ""} { return $f }
        set f [$Doc createElement office:forms]
        $f setAttribute form:automatic-focus false
        $f setAttribute form:apply-design-mode false
        set first [lindex [$Body childNodes] 0]
        if {$first eq ""} { $Body appendChild $f } else { $Body insertBefore $f $first }
        return $f
    }

    # Create a <form:form> in office:forms. Option: -name NAME (form:name).
    # form:control-implementation matches LibreOffice's convention so the form
    # is recognised as a UNO Form component (needed for DB-bound forms).
    method newForm {args} {
        set name Form
        foreach {k v} $args {
            switch -- $k {
                -name   { set name $v }
                default { error "unknown option: $k" }
            }
        }
        set form [$Doc createElement form:form]
        $form setAttribute form:name $name
        $form setAttribute form:control-implementation ooo:com.sun.star.form.component.Form
        [my Forms] appendChild $form
        return $form
    }

    # Next free control id "ctrlN". Scans every control xml:id under office:forms
    # (visible and hidden), so hidden controls -- which have an xml:id but no
    # draw:control -- cannot collide with later visible ones.
    method NextControlId {} {
        set max 0
        set forms [lindex [$Body getElementsByTagName office:forms] 0]
        if {$forms eq ""} { return ctrl1 }
        set stack [list $forms]
        while {[llength $stack]} {
            set n [lindex $stack end]; set stack [lrange $stack 0 end-1]
            foreach c [$n childNodes] {
                if {[$c nodeType] ne "ELEMENT_NODE"} continue
                if {[regexp {^ctrl([0-9]+)$} [$c getAttribute xml:id ""] -> num] && $num > $max} {
                    set max $num
                }
                lappend stack $c
            }
        }
        return "ctrl[expr {$max + 1}]"
    }

    # ---- generic form:property API + hidden control ----
    # office:value-type -> the office:* value attribute that carries the value.
    method ValueAttr {type} {
        switch -- $type {
            string                        { return office:string-value }
            float - percentage - currency { return office:value }
            boolean                       { return office:boolean-value }
            date                          { return office:date-value }
            time                          { return office:time-value }
            void                          { return "" }
            default { error "unknown value-type: $type" }
        }
    }
    # the control's own <form:properties> (direct child), created if absent. It
    # must precede form:option/form:item/text:p, so it is inserted as first child.
    method EnsureProps {ctrl} {
        foreach c [$ctrl childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "form:properties"} { return $c }
        }
        set props [$Doc createElement form:properties]
        set first [lindex [$ctrl childNodes] 0]
        if {$first eq ""} { $ctrl appendChild $props } else { $ctrl insertBefore $props $first }
        return $props
    }
    # attach a single <form:property> (e.g. an LO/UNO setting) to a control.
    method controlProperty {ctrl name value {type string}} {
        set props [my EnsureProps $ctrl]
        # dedup: a property is identified by its name, so an explicit call replaces
        # any prior (including auto-emitted) form:property of the same name.
        foreach pr [$props childNodes] {
            if {[$pr nodeType] eq "ELEMENT_NODE" && [$pr nodeName] eq "form:property" \
                && [$pr getAttribute form:property-name ""] eq $name} { $pr delete }
        }
        set pr [$Doc createElement form:property]
        $pr setAttribute form:property-name $name
        $pr setAttribute office:value-type  $type
        set va [my ValueAttr $type]
        if {$va ne ""} { $pr setAttribute $va $value }
        $props appendChild $pr
        return $pr
    }
    # attach a <form:list-property> with one <form:list-value> per value (e.g.
    # StringItemList / DefaultSelection that LO uses to drive listbox display).
    method controlListProperty {ctrl name values {type string}} {
        set props [my EnsureProps $ctrl]
        # dedup: list-property is identified by its name; replace any prior one.
        foreach lp [$props childNodes] {
            if {[$lp nodeType] eq "ELEMENT_NODE" && [$lp nodeName] eq "form:list-property" \
                && [$lp getAttribute form:property-name ""] eq $name} { $lp delete }
        }
        set lp [$Doc createElement form:list-property]
        $lp setAttribute form:property-name $name
        $lp setAttribute office:value-type  $type
        set va [my ValueAttr $type]
        foreach v $values {
            set lv [$Doc createElement form:list-value]
            if {$va ne ""} { $lv setAttribute $va $v }
            $lp appendChild $lv
        }
        $props appendChild $lp
        return $lp
    }
    method controlPropertyValue {ctrl name} {
        foreach c [$ctrl childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE" || [$c nodeName] ne "form:properties"} continue
            foreach pr [$c childNodes] {
                if {[$pr nodeType] ne "ELEMENT_NODE"} continue
                if {[$pr getAttribute form:property-name ""] eq $name} {
                    set va [my ValueAttr [$pr getAttribute office:value-type string]]
                    return [expr {$va eq "" ? "" : [$pr getAttribute $va ""]}]
                }
            }
        }
        return ""
    }
    # Symmetric reader for controlListProperty: returns the list of values from
    # a <form:list-property>. Empty list if the property is absent or has no
    # <form:list-value> children. Returns "" if no list-property of that name.
    method controlListPropertyValue {ctrl name} {
        foreach c [$ctrl childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE" || [$c nodeName] ne "form:properties"} continue
            foreach lp [$c childNodes] {
                if {[$lp nodeType] ne "ELEMENT_NODE" || [$lp nodeName] ne "form:list-property"} continue
                if {[$lp getAttribute form:property-name ""] eq $name} {
                    set va [my ValueAttr [$lp getAttribute office:value-type string]]
                    set r {}
                    foreach lv [$lp childNodes] {
                        if {[$lv nodeType] ne "ELEMENT_NODE" || [$lv nodeName] ne "form:list-value"} continue
                        lappend r [expr {$va eq "" ? "" : [$lv getAttribute $va ""]}]
                    }
                    return $r
                }
            }
        }
        return ""
    }
    # hidden control: carries a value, no visible shape (no draw:control).
    method addFormHidden {form args} {
        set name ""; set value ""
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -value {set value $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:hidden $name] ctrl id
        if {$value ne ""} { $ctrl setAttribute form:value $value }
        return $ctrl
    }

    # Visible <draw:control> for control id $id, appended to paragraph $node.
    method PlaceControl {node id width height anchor name} {
        set dc [$Doc createElement draw:control]
        $dc setAttribute draw:control $id
        $dc setAttribute draw:style-name [my ControlStyle]
        $dc setAttribute text:anchor-type $anchor
        $dc setAttribute svg:width  $width
        $dc setAttribute svg:height $height
        if {$name ne ""} { $dc setAttribute draw:name $name }
        $node appendChild $dc
        return $dc
    }

    # Ensure (once) a graphic style for form controls in office:automatic-styles
    # and return its name. A draw:control WITHOUT a graphic style is schema-valid
    # but LibreOffice does not render it -- the visible shape needs appearance and
    # an as-char vertical position (ODF 1.3 part 3, 10.3.13 draw:control + 16/
    # graphic). draw:fill/stroke = appearance, style:vertical-pos/-rel = inline
    # placement so the control is not collapsed to nothing.
    method ControlStyle {} {
        set name FormCtl
        set as [my AutoStylesEl 1]
        foreach s [$as getElementsByTagName style:style] {
            if {[$s getAttribute style:name ""] eq $name} { return $name }
        }
        my defineAutoGraphic $name {
            style:wrap                       run-through
            style:number-wrapped-paragraphs  no-limit
            style:vertical-pos               middle
            style:vertical-rel               line
            style:horizontal-pos             from-left
            style:horizontal-rel             paragraph
        }
        return $name
    }

    # Logical control scaffold: create element, assign shared id (xml:id = the
    # ID, form:id = NCName mirror for LO), set form:name, append to form.
    # Returns {ctrlNode id}.
    # tag -> {control-implementation default-control}. LibreOffice writes both on
    # every control; they bind the ODF element to a concrete UNO component so LO
    # instantiates (and renders) it. Verified against a real LO fillable .odt.
    method ControlImpl {tag} {
        set m {
            form:text           {ooo:com.sun.star.form.component.TextField     com.sun.star.form.control.TextField}
            form:textarea       {ooo:com.sun.star.form.component.TextField     com.sun.star.form.control.TextField}
            form:password       {ooo:com.sun.star.form.component.TextField     com.sun.star.form.control.TextField}
            form:formatted-text {ooo:com.sun.star.form.component.NumericField  com.sun.star.form.control.NumericField}
            form:date           {ooo:com.sun.star.form.component.DateField     com.sun.star.form.control.DateField}
            form:time           {ooo:com.sun.star.form.component.TimeField     com.sun.star.form.control.TimeField}
            form:checkbox       {ooo:com.sun.star.form.component.CheckBox      com.sun.star.form.control.CheckBox}
            form:radio          {ooo:com.sun.star.form.component.RadioButton   com.sun.star.form.control.RadioButton}
            form:listbox        {ooo:com.sun.star.form.component.ListBox       com.sun.star.form.control.ListBox}
            form:combobox       {ooo:com.sun.star.form.component.ComboBox      com.sun.star.form.control.ComboBox}
            form:button         {ooo:com.sun.star.form.component.CommandButton com.sun.star.form.control.CommandButton}
            form:fixed-text     {ooo:com.sun.star.form.component.FixedText     com.sun.star.form.control.FixedText}
        }
        if {[dict exists $m $tag]} { return [dict get $m $tag] }
        return [list "" ""]
    }
    method NewControl {form tag name} {
        set id   [my NextControlId]
        set ctrl [$Doc createElement $tag]
        $ctrl setAttribute xml:id  $id
        $ctrl setAttribute form:id $id
        if {$name ne ""} { $ctrl setAttribute form:name $name }
        lassign [my ControlImpl $tag] impl defctl
        if {$impl ne ""} { $ctrl setAttribute form:control-implementation $impl }
        if {$defctl ne ""} {
            set props [$Doc createElement form:properties]
            set pr    [$Doc createElement form:property]
            $pr setAttribute form:property-name DefaultControl
            $pr setAttribute office:value-type string
            $pr setAttribute office:string-value $defctl
            $props appendChild $pr
            $ctrl appendChild $props
        }
        $form appendChild $ctrl
        return [list $ctrl $id]
    }

    # text input field.  Options: -name -value -maxlength -width -height -anchor
    method addFormText {form node args} {
        set name ""; set value ""; set maxlen ""
        set width 4cm; set height 0.5cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -value {set value $v} -maxlength {set maxlen $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:text $name] ctrl id
        if {$value ne ""} {
            $ctrl setAttribute form:value $value
            $ctrl setAttribute form:current-value $value
        }
        if {$maxlen ne ""} { $ctrl setAttribute form:max-length $maxlen }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }

    # checkbox.  Options: -name -label -checked 0|1 -value -width -height -anchor
    method addFormCheckbox {form node args} {
        set name ""; set label ""; set checked 0; set value ""
        set width 4cm; set height 0.5cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -label {set label $v} -checked {set checked $v}
            -value {set value $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:checkbox $name] ctrl id
        if {$label ne ""} { $ctrl setAttribute form:label $label }
        set st [expr {$checked ? "checked" : "unchecked"}]
        $ctrl setAttribute form:current-state $st
        $ctrl setAttribute form:state $st
        if {$value ne ""} { $ctrl setAttribute form:value $value }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }

    # push button.  Options: -name -label -width -height -anchor
    method addFormButton {form node args} {
        set name ""; set label ""
        set width 3cm; set height 0.6cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -label {set label $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:button $name] ctrl id
        $ctrl setAttribute form:button-type push
        if {$label ne ""} { $ctrl setAttribute form:label $label }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }

    # fixed text (a form label).  -for = xml:id of the control it labels.
    method addFormLabel {form node args} {
        set name ""; set label ""; set for ""
        set width 4cm; set height 0.5cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -label {set label $v} -for {set for $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:fixed-text $name] ctrl id
        if {$label ne ""} { $ctrl setAttribute form:label $label }
        if {$for ne ""}   { $ctrl setAttribute form:for $for }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }

    # listbox.  items = list of option labels. Options: -values (parallel list
    # of form:value), -selected INDEX (0-based), -dropdown 0|1, -width -height
    # -anchor -name.
    method addFormListbox {form node items args} {
        set name ""; set values ""; set selected ""; set dropdown 1
        set size ""; set boundCol ""
        set width 4cm; set height 0.6cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -values {set values $v} -selected {set selected $v}
            -dropdown {set dropdown $v} -size {set size $v} -bound-column {set boundCol $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:listbox $name] ctrl id
        $ctrl setAttribute form:dropdown [expr {$dropdown ? "true" : "false"}]
        if {$size     ne ""} { $ctrl setAttribute form:size         $size }
        if {$boundCol ne ""} { $ctrl setAttribute form:bound-column $boundCol }
        # -selected accepts INDEX (integer) or VALUE (string)
        set selIdx -1
        if {$selected ne ""} {
            if {[string is integer -strict $selected]} {
                set selIdx $selected
            } else {
                set selIdx [lsearch -exact $items $selected]
            }
        }
        set i 0
        foreach lbl $items {
            set opt [$Doc createElement form:option]
            # form:value defaults to the label (LO's canonical pattern); -values
            # overrides this with explicit per-option values when needed.
            if {$values ne ""} {
                set val [lindex $values $i]
            } else {
                set val $lbl
            }
            if {$val ne ""} { $opt setAttribute form:value $val }
            if {$i == $selIdx} {
                $opt setAttribute form:current-selected true
                $opt setAttribute form:selected         true
            }
            $opt appendChild [$Doc createTextNode $lbl]
            $ctrl appendChild $opt
            incr i
        }
        # LO mirrors the dropdown entries in a UNO StringItemList property and uses
        # that for rendering -- without it LO shows an empty listbox. We emit it
        # parallel to the form:option children (schema-correct, office:string-value).
        if {[llength $items] > 0} {
            my controlListProperty $ctrl StringItemList $items string
        }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }

    # multi-line text area.  Options: -name -value -maxlength -width -height -anchor
    method addFormTextarea {form node args} {
        set name ""; set value ""; set maxlen ""
        set width 6cm; set height 2cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -value {set value $v} -maxlength {set maxlen $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:textarea $name] ctrl id
        if {$value ne ""} {
            $ctrl setAttribute form:value $value
            $ctrl setAttribute form:current-value $value
        }
        if {$maxlen ne ""} { $ctrl setAttribute form:max-length $maxlen }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }

    # password field.  Options: -name -value -maxlength -echochar (default *)
    #                            -width -height -anchor
    method addFormPassword {form node args} {
        set name ""; set value ""; set maxlen ""; set echo "*"
        set width 4cm; set height 0.5cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -value {set value $v} -maxlength {set maxlen $v}
            -echochar {set echo $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:password $name] ctrl id
        if {$value ne ""}  { $ctrl setAttribute form:value $value }
        if {$maxlen ne ""} { $ctrl setAttribute form:max-length $maxlen }
        if {$echo ne ""}   { $ctrl setAttribute form:echo-char $echo }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }

    # numeric / date / time fields share one builder. value/min/max are passed
    # through verbatim (double for number; ISO date YYYY-MM-DD; ISO time for time).
    # ---- ODF strict vs LibreOffice-compatibility mode --------------------------
    # NOTE: LibreOffice writes several form attributes that are NOT in the ODF
    # schema. These are emitted only in LO-compat mode, never silently in strict:
    #   1) form:time value -- LO uses ISO 8601 durations (PT12H30M0S); the schema
    #      type is xsd:time (HH:MM:SS). Render evidence (0.55) shows this is an
    #      LibreOffice display limit, not bridgeable from the document side: LO
    #      computes the time field's displayed text from form:current-value, and
    #      only PT.. parses; xsd:time HH:MM:SS leaves the field visually empty
    #      even with form:property Text=... attached (Text is parallel UNO state,
    #      not a display override). Strict mode therefore stays validator-clean
    #      but invisible-in-LO for time; lo-compat is the only path to display.
    #      addFormTime still emits the Text property (matches LO's own output and
    #      is schema-OK), but does not claim to solve display anymore.
    #   2) form:input-required -- a LibreOffice extension on form controls; not
    #      in any form-*-attlist. LO writes it on every control; the validator
    #      rejects it. (controlBind silently skips it in strict mode.)
    #   3) form:validation -- in the schema only on form:formatted-text. LO writes
    #      it on form:time, form:listbox, form:date too. In strict mode controlBind
    #      restricts it to form:formatted-text; lo emits on any.
    #   4) form:listbox / form:combobox dropdown contents -- LO does NOT render
    #      listbox entries or the selected value in static print/PDF (even with
    #      form:current-selected, form:selected, and StringItemList all set).
    #      form:combobox shows form:current-value in the input area but its
    #      dropdown opens only on interactive click. Verified against LO's own
    #      reference output -- same blank listbox there. The library emits the
    #      full structure (auto-StringItemList in 0.56), matching LO's own
    #      output; the static-render gap is an LO interactive-only behaviour.
    # Switch:
    #   $t formCompat lo            ;# document-wide default
    #   $t addFormTime ... -lo-compat 1   ;# per-call override for time
    # form:date uses xsd:date YYYY-MM-DD and renders in both modes -- no toggle.
    # Listbox entry display is the analogous case: form:option is ODF-near; LO
    # populates the visible list from form:property StringItemList -- to be added
    # from a populated LO reference (color.odt is SQL-bound, not a value list).
    method formCompat {{mode ""}} {
        if {$mode eq ""} { return $FormCompat }
        if {$mode ni {strict lo}} { error "formCompat: mode must be strict or lo" }
        set FormCompat $mode
        return $FormCompat
    }
    method CompatLO {compat} {
        if {$compat eq ""} { return [expr {$FormCompat eq "lo"}] }
        return [expr {$compat ? 1 : 0}]
    }
    # HH:MM[:SS] -> ISO 8601 duration PT..H..M..S (LO time format). Pass through if
    # already a duration or an unrecognised string.
    method TimeToDuration {t} {
        if {[string match PT* $t]} { return $t }
        if {[regexp {^([0-9]{1,2}):([0-9]{2})(?::([0-9]{2}))?$} $t -> h m sec]} {
            if {$sec eq ""} { set sec 0 }
            return "PT[scan $h %d]H[scan $m %d]M[scan $sec %d]S"
        }
        return $t
    }
    method NumericField {form node tag args} {
        set name ""; set value ""; set min ""; set max ""; set compat ""
        set width 4cm; set height 0.5cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -value {set value $v} -min {set min $v} -max {set max $v}
            -lo-compat {set compat $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        # Capture the original (pre-conversion) value for the LO Text property below.
        set humanValue $value
        # form:time only: in LO-compat mode, rewrite values to ISO durations.
        if {$tag eq "form:time" && [my CompatLO $compat]} {
            if {$value ne ""} { set value [my TimeToDuration $value] }
            if {$min ne ""}   { set min   [my TimeToDuration $min] }
            if {$max ne ""}   { set max   [my TimeToDuration $max] }
        }
        lassign [my NewControl $form $tag $name] ctrl id
        if {$value ne ""} {
            $ctrl setAttribute form:value $value
            $ctrl setAttribute form:current-value $value
        }
        if {$min ne ""} { $ctrl setAttribute form:min-value $min }
        if {$max ne ""} { $ctrl setAttribute form:max-value $max }
        # form:time only: emit a schema-conformant Text UNO property to mirror
        # LO's own output for populated time fields (see test01.odt). NOTE: render
        # evidence shows this does NOT make LO display the value in strict mode --
        # LO needs PT.. in form:current-value (lo-compat). The Text property is
        # kept for parity / interactive-edit support, not as a display fix.
        if {$tag eq "form:time" && $humanValue ne ""} {
            my controlProperty $ctrl Text $humanValue
        }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }
    method addFormNumber {form node args} { return [my NumericField $form $node form:formatted-text {*}$args] }
    method addFormDate   {form node args} { return [my NumericField $form $node form:date   {*}$args] }
    method addFormTime   {form node args} { return [my NumericField $form $node form:time   {*}$args] }

    # combobox (editable dropdown). items = list of entry labels (-> form:item).
    # Options: -name -value (form:current-value) -dropdown 0|1 -maxlength
    #          -width -height -anchor
    method addFormCombobox {form node items args} {
        set name ""; set value ""; set dropdown 1; set maxlen ""; set size ""
        set width 4cm; set height 0.6cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -value {set value $v} -dropdown {set dropdown $v}
            -maxlength {set maxlen $v} -size {set size $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:combobox $name] ctrl id
        $ctrl setAttribute form:dropdown [expr {$dropdown ? "true" : "false"}]
        if {$value ne ""} {
            # combobox is the only control where common-current-value-attlist applies;
            # both form:value and form:current-value are in scope and schema-OK here.
            $ctrl setAttribute form:current-value $value
            $ctrl setAttribute form:value         $value
        }
        if {$maxlen ne ""} { $ctrl setAttribute form:max-length $maxlen }
        if {$size   ne ""} { $ctrl setAttribute form:size       $size }
        foreach lbl $items {
            set it [$Doc createElement form:item]
            $it setAttribute form:label $lbl
            $ctrl appendChild $it
        }
        # Parallel UNO StringItemList -- LO uses this to render the dropdown entries
        # (without it the combobox shows an empty list even though form:item exists).
        if {[llength $items] > 0} {
            my controlListProperty $ctrl StringItemList $items string
        }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }

    # one radio button. Radios that share the same -name form a group; the chosen
    # one carries form:current-selected/selected = true. Options:
    #   -name (group) -label -value -checked 0|1 -width -height -anchor
    method addFormRadio {form node args} {
        set name ""; set label ""; set value ""; set checked 0
        set width 4cm; set height 0.5cm; set anchor as-char
        foreach {k v} $args { switch -- $k {
            -name {set name $v} -label {set label $v} -value {set value $v} -checked {set checked $v}
            -width {set width $v} -height {set height $v} -anchor {set anchor $v}
            default {error "unknown option: $k"} } }
        lassign [my NewControl $form form:radio $name] ctrl id
        if {$label ne ""} { $ctrl setAttribute form:label $label }
        if {$value ne ""} { $ctrl setAttribute form:value $value }
        if {$checked} {
            $ctrl setAttribute form:current-selected true
            $ctrl setAttribute form:selected true
        }
        return [my PlaceControl $node $id $width $height $anchor $name]
    }

    # ---- DB binding + geometry (slice 1: foundation) ----
    # Lazy-create graphic style for PARAGRAPH-anchored controls. Different from
    # FormCtl: vertical-pos=from-top (not middle), vertical-rel=paragraph (not
    # line) -- mirrors LO's gr1/gr3 style for positioned form controls.
    method ControlStyleParagraph {} {
        set name FormCtlP
        set as [my AutoStylesEl 1]
        foreach s [$as getElementsByTagName style:style] {
            if {[$s getAttribute style:name ""] eq $name} { return $name }
        }
        my defineAutoGraphic $name {
            style:wrap                       run-through
            style:number-wrapped-paragraphs  no-limit
            style:vertical-pos               from-top
            style:vertical-rel               paragraph
            style:horizontal-pos             from-left
            style:horizontal-rel             paragraph
        }
        return $name
    }
    # Find the logical form:* control for a given <draw:control> by xml:id.
    method controlLogical {drawctrl} {
        set id [$drawctrl getAttribute draw:control ""]
        if {$id eq ""} { return "" }
        set forms [lindex [$Body getElementsByTagName office:forms] 0]
        if {$forms eq ""} { return "" }
        set stack [list $forms]
        while {[llength $stack]} {
            set n [lindex $stack end]; set stack [lrange $stack 0 end-1]
            foreach c [$n childNodes] {
                if {[$c nodeType] ne "ELEMENT_NODE"} continue
                if {[$c getAttribute xml:id ""] eq $id} { return $c }
                lappend stack $c
            }
        }
        return ""
    }
    # DB attrs on the form (form:form). -datasource accepts a registered LO
    # database name OR an IRI to an .odb file (both go into form:datasource).
    method formDatasource {form args} {
        foreach {k v} $args { switch -- $k {
            -datasource     { $form setAttribute form:datasource $v }
            -command-type   { $form setAttribute form:command-type $v }
            -command        { $form setAttribute form:command $v }
            -apply-filter   { $form setAttribute form:apply-filter   [expr {$v ? "true" : "false"}] }
            -allow-deletes  { $form setAttribute form:allow-deletes  [expr {$v ? "true" : "false"}] }
            -allow-inserts  { $form setAttribute form:allow-inserts  [expr {$v ? "true" : "false"}] }
            -allow-updates  { $form setAttribute form:allow-updates  [expr {$v ? "true" : "false"}] }
            -navigation-mode { $form setAttribute form:navigation-mode $v }
            -tab-cycle      { $form setAttribute form:tab-cycle $v }
            default         { error "formDatasource: unknown option: $k" }
        } }
        return $form
    }
    # Bind DB attrs on the LOGICAL form control (looked up via xml:id from the
    # given <draw:control>). Use after the addForm* call:
    #   set dc [$t addFormText $f $p -name txtName]
    #   $t controlBind $dc -data-field NAME -input-required 1
    method controlBind {drawctrl args} {
        set ctrl [my controlLogical $drawctrl]
        if {$ctrl eq ""} { error "controlBind: no logical control found for [$drawctrl getAttribute draw:control ?]" }
        foreach {k v} $args { switch -- $k {
            -data-field     { $ctrl setAttribute form:data-field $v }
            -input-required {
                # form:input-required is a LibreOffice extension, not in the ODF
                # schema -- silently emitted only in LO-compat mode (strict skips).
                if {[my CompatLO ""]} {
                    $ctrl setAttribute form:input-required [expr {$v ? "true" : "false"}]
                }
            }
            -list-source-type      { $ctrl setAttribute form:list-source-type      $v }
            -list-source           { $ctrl setAttribute form:list-source           $v }
            -bound-column          { $ctrl setAttribute form:bound-column          $v }
            -size                  { $ctrl setAttribute form:size                  $v }
            -auto-complete         { $ctrl setAttribute form:auto-complete         [expr {$v ? "true" : "false"}] }
            -convert-empty-to-null { $ctrl setAttribute form:convert-empty-to-null [expr {$v ? "true" : "false"}] }
            -validation {
                # form:validation is in the schema only on form:formatted-text;
                # LO writes it on other controls too (form:time, form:listbox, ...).
                # In strict mode, restrict to form:formatted-text; lo emits on any.
                if {[my CompatLO ""] || [$ctrl nodeName] eq "form:formatted-text"} {
                    $ctrl setAttribute form:validation [expr {$v ? "true" : "false"}]
                }
            }
            default         { error "controlBind: unknown option: $k" }
        } }
        return $ctrl
    }
    # Geometry on the VISIBLE control (<draw:control>). When -anchor switches to
    # paragraph, draw:style-name is auto-swapped to FormCtlP; back to as-char
    # restores FormCtl. -x/-y require -anchor paragraph (otherwise LO ignores).
    method controlPlace {drawctrl args} {
        set wantXY 0
        foreach {k v} $args { switch -- $k {
            -anchor   {
                $drawctrl setAttribute text:anchor-type $v
                if {$v eq "paragraph"} {
                    $drawctrl setAttribute draw:style-name [my ControlStyleParagraph]
                } elseif {$v eq "as-char"} {
                    $drawctrl setAttribute draw:style-name [my ControlStyle]
                }
            }
            -x        { $drawctrl setAttribute svg:x        $v; set wantXY 1 }
            -y        { $drawctrl setAttribute svg:y        $v; set wantXY 1 }
            -z-index  { $drawctrl setAttribute draw:z-index $v }
            -width    { $drawctrl setAttribute svg:width    $v }
            -height   { $drawctrl setAttribute svg:height   $v }
            -name     { $drawctrl setAttribute draw:name    $v }
            -data-style {
                # Attach a number:*-style to the control's graphic style. Creates
                # (lazily) a per-data-style variant of FormCtl/FormCtlP carrying
                # style:data-style-name, matching color.odt's gr2->C60 pattern.
                set base [$drawctrl getAttribute draw:style-name ""]
                if {$base eq ""} { set base [my ControlStyle] }
                $drawctrl setAttribute draw:style-name [my ControlStyleWithData $base $v]
            }
            default   { error "controlPlace: unknown option: $k" }
        } }
        if {$wantXY} {
            set at [$drawctrl getAttribute text:anchor-type ""]
            if {$at eq "" || $at eq "as-char"} {
                error "controlPlace: -x/-y require -anchor paragraph (or page/frame); current anchor is '$at' which makes LO ignore absolute coordinates"
            }
        }
        return $drawctrl
    }

    # ---- number-format data styles (slice 3 of DB-bound forms) ----
    # Java-style format tokens: y/yy/yyyy=year, M/MM/MMM/MMMM=month (numeric/textual),
    # d/dd=day, H/HH=hours (24h), m/mm=minutes, s/ss=seconds; everything else is text.
    method ParseFormat {fmt} {
        set parts {}
        set i 0; set n [string length $fmt]
        while {$i < $n} {
            set c [string index $fmt $i]; set rest [string range $fmt $i end]
            if {[string match yyyy* $rest]} { lappend parts {y long};      incr i 4; continue }
            if {[string match yy*   $rest]} { lappend parts {y short};     incr i 2; continue }
            if {[string match MMMM* $rest]} { lappend parts {Mtext long};  incr i 4; continue }
            if {[string match MMM*  $rest]} { lappend parts {Mtext short}; incr i 3; continue }
            if {[string match MM*   $rest]} { lappend parts {M long};      incr i 2; continue }
            if {$c eq "M"}                  { lappend parts {M short};     incr i;   continue }
            if {[string match dd*   $rest]} { lappend parts {d long};      incr i 2; continue }
            if {$c eq "d"}                  { lappend parts {d short};     incr i;   continue }
            if {[string match HH*   $rest]} { lappend parts {H long};      incr i 2; continue }
            if {$c eq "H"}                  { lappend parts {H short};     incr i;   continue }
            if {[string match mm*   $rest]} { lappend parts {m long};      incr i 2; continue }
            if {$c eq "m"}                  { lappend parts {m short};     incr i;   continue }
            if {[string match ss*   $rest]} { lappend parts {s long};      incr i 2; continue }
            if {$c eq "s"}                  { lappend parts {s short};     incr i;   continue }
            lappend parts [list text $c]; incr i
        }
        return $parts
    }
    method EmitFormatChildren {styleNode parts} {
        foreach p $parts {
            lassign $p kind val
            switch -- $kind {
                y     { set e [$Doc createElement number:year];    $e setAttribute number:style $val }
                M     { set e [$Doc createElement number:month];   $e setAttribute number:style $val }
                Mtext { set e [$Doc createElement number:month];   $e setAttribute number:style $val
                        $e setAttribute number:textual true }
                d     { set e [$Doc createElement number:day];     $e setAttribute number:style $val }
                H     { set e [$Doc createElement number:hours];   $e setAttribute number:style $val }
                m     { set e [$Doc createElement number:minutes]; $e setAttribute number:style $val }
                s     { set e [$Doc createElement number:seconds]; $e setAttribute number:style $val }
                text  { set e [$Doc createElement number:text]; $e appendChild [$Doc createTextNode $val] }
            }
            $styleNode appendChild $e
        }
    }
    method DefineNumStyle {tag name args} {
        set fmt ""; set dn ""
        foreach {k v} $args { switch -- $k {
            -format       { set fmt $v }
            -display-name { set dn $v }
            default       { error "unknown option: $k" }
        } }
        if {$fmt eq ""} { error "$tag needs -format" }
        # number:* prefix is not bound on the content.xml root by default -- bind
        # it here (idempotent), parallel to the form:/ooo:/xlink: fixes.
        [$Doc documentElement] setAttribute xmlns:number urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0
        set as [my AutoStylesEl 1]
        foreach n [$as getElementsByTagName $tag] {
            if {[$n getAttribute style:name ""] eq $name} { $n delete }
        }
        set st [$Doc createElement $tag]
        $st setAttribute style:name $name
        if {$dn ne ""} { $st setAttribute style:display-name $dn }
        my EmitFormatChildren $st [my ParseFormat $fmt]
        $as appendChild $st
        return $name
    }
    method defineDateStyle {name args} { return [my DefineNumStyle number:date-style $name {*}$args] }
    method defineTimeStyle {name args} { return [my DefineNumStyle number:time-style $name {*}$args] }
    method defineNumberStyle {name args} {
        set decimals 2; set grouping 0; set minInt 1; set dn ""
        foreach {k v} $args { switch -- $k {
            -decimals     { set decimals $v }
            -grouping     { set grouping $v }
            -min-integer  { set minInt   $v }
            -display-name { set dn       $v }
            default       { error "unknown option: $k" }
        } }
        [$Doc documentElement] setAttribute xmlns:number urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0
        set as [my AutoStylesEl 1]
        foreach n [$as getElementsByTagName number:number-style] {
            if {[$n getAttribute style:name ""] eq $name} { $n delete }
        }
        set st [$Doc createElement number:number-style]
        $st setAttribute style:name $name
        if {$dn ne ""} { $st setAttribute style:display-name $dn }
        set num [$Doc createElement number:number]
        $num setAttribute number:decimal-places     $decimals
        $num setAttribute number:min-integer-digits $minInt
        if {$grouping} { $num setAttribute number:grouping true }
        $st appendChild $num
        $as appendChild $st
        return $name
    }
    # Lazy-create a graphic-style variant carrying style:data-style-name. Cloned
    # from FormCtl or FormCtlP so anchor/wrap/positioning is preserved.
    method ControlStyleWithData {base dataStyle} {
        set varName "${base}_${dataStyle}"
        set as [my AutoStylesEl 1]
        foreach s [$as getElementsByTagName style:style] {
            if {[$s getAttribute style:name ""] eq $varName} { return $varName }
        }
        if {$base eq "FormCtl"}  { my ControlStyle }
        if {$base eq "FormCtlP"} { my ControlStyleParagraph }
        set baseStyle ""
        foreach s [$as getElementsByTagName style:style] {
            if {[$s getAttribute style:name ""] eq $base} { set baseStyle $s; break }
        }
        if {$baseStyle eq ""} { error "ControlStyleWithData: base style $base not found" }
        set newSt [$Doc createElement style:style]
        $newSt setAttribute style:name $varName
        $newSt setAttribute style:family graphic
        $newSt setAttribute style:data-style-name $dataStyle
        set baseProps [lindex [$baseStyle getElementsByTagName style:graphic-properties] 0]
        if {$baseProps ne ""} { $newSt appendChild [$baseProps cloneNode -deep] }
        $as appendChild $newSt
        return $varName
    }

    # ---- forms readers ----
    method dateStyles {} {
        set as [my AutoStylesEl 1]; set r {}
        foreach n [$as getElementsByTagName number:date-style] { lappend r [$n getAttribute style:name ""] }
        return $r
    }
    method timeStyles {} {
        set as [my AutoStylesEl 1]; set r {}
        foreach n [$as getElementsByTagName number:time-style] { lappend r [$n getAttribute style:name ""] }
        return $r
    }
    method numberStyles {} {
        set as [my AutoStylesEl 1]; set r {}
        foreach n [$as getElementsByTagName number:number-style] { lappend r [$n getAttribute style:name ""] }
        return $r
    }
    method forms {} { return [$Body getElementsByTagName form:form] }
    method formName {form} { return [$form getAttribute form:name ""] }
    method formControls {form} {
        set skip {form:properties form:form form:connection-resource}
        set res {}
        foreach c [$form childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE"} { continue }
            set n [$c nodeName]
            if {[string match form:* $n] && $n ni $skip} { lappend res $c }
        }
        return $res
    }
    method controlKind  {ctrl} { set n [$ctrl nodeName]; regsub {^form:} $n "" n; return $n }
    method controlName  {ctrl} { return [$ctrl getAttribute form:name ""] }
    method controlId    {ctrl} { return [$ctrl getAttribute xml:id ""] }
    method controlLabel {ctrl} { return [$ctrl getAttribute form:label ""] }
    method controlValue {ctrl} { return [$ctrl getAttribute form:value ""] }
    method controlState {ctrl} { return [$ctrl getAttribute form:current-state ""] }
    method listboxOptions {ctrl} {
        set res {}
        foreach o [$ctrl getElementsByTagName form:option] { lappend res [$o asText] }
        return $res
    }
    method comboboxItems {ctrl} {
        set res {}
        foreach it [$ctrl getElementsByTagName form:item] {
            set lbl [$it getAttribute form:label ""]
            if {$lbl eq ""} { set lbl [$it asText] }
            lappend res $lbl
        }
        return $res
    }

    # ---- lists ----
    method listItems {list} {
        set res {}
        foreach c [$list childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:list-item"} { lappend res $c }
        }
        return $res
    }
    # An item's own text (direct text:p only, without the nested list)
    method itemText {item} {
        set parts {}
        foreach c [$item childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:p"} { lappend parts [$c asText] }
        }
        return [join $parts " "]
    }
    # An item's nested list (or "")
    method itemSublist {item} {
        foreach c [$item childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:list"} { return $c }
        }
        return ""
    }
    method addListItem {list text {style ""}} {
        set item [$Doc createElement text:list-item]
        set p [$Doc createElement text:p]
        if {$style ne ""} { $p setAttribute text:style-name $style }
        $p appendChild [$Doc createTextNode $text]
        $item appendChild $p
        $list appendChild $item
        return $item
    }
    # Create a nested list inside an item (text:list in the text:list-item).
    # Then fill it with addListItem. Arbitrarily deep nesting.
    method addSublist {item {style ""}} {
        set l [$Doc createElement text:list]
        if {$style ne ""} { $l setAttribute text:style-name $style }
        $item appendChild $l
        return $l
    }
    method setItemText {item text} {
        foreach c [$item childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:p"} {
                foreach k [$c childNodes] { $k delete }
                $c appendChild [$Doc createTextNode $text]
                return $item
            }
        }
        set p [$Doc createElement text:p]; $p appendChild [$Doc createTextNode $text]; $item appendChild $p
        return $item
    }

    # ---- tables ----
    # rows (incl. table:table-header-rows), direct children
    method tableRows {table} {
        set rows {}
        foreach c [$table childNodes] {
            if {[$c nodeType] ne "ELEMENT_NODE"} continue
            switch -- [$c nodeName] {
                table:table-row { lappend rows $c }
                table:table-header-rows {
                    foreach r [$c childNodes] {
                        if {[$r nodeType] eq "ELEMENT_NODE" && [$r nodeName] eq "table:table-row"} { lappend rows $r }
                    }
                }
            }
        }
        return $rows
    }
    method rowCells {row} {
        set cells {}
        foreach c [$row childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] in {table:table-cell table:covered-table-cell}} { lappend cells $c }
        }
        return $cells
    }
    method cellText  {cell} { return [$cell asText] }
    method cellStyle {cell} { return [$cell getAttribute table:style-name ""] }
    # Assign (or, with "", remove) a cell style on an existing cell.
    method setCellStyle {cell style} {
        if {$style eq ""} {
            if {[$cell getAttribute table:style-name ""] ne ""} { $cell removeAttribute table:style-name }
        } else {
            $cell setAttribute table:style-name $style
        }
        return $cell
    }
    method setCellText {cell text} {
        foreach c [$cell childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:p"} {
                foreach k [$c childNodes] { $k delete }
                $c appendChild [$Doc createTextNode $text]
                return $cell
            }
        }
        set p [$Doc createElement text:p]; $p appendChild [$Doc createTextNode $text]; $cell appendChild $p
        return $cell
    }
    # New row at the end; cells = list of cell texts
    method BuildRow {cells {cellStyles ""}} {
        set row [$Doc createElement table:table-row]
        set i 0
        foreach v $cells {
            set cell [$Doc createElement table:table-cell]
            set cs [lindex $cellStyles $i]
            if {$cs ne ""} { $cell setAttribute table:style-name $cs }
            set p [$Doc createElement text:p]
            $p appendChild [$Doc createTextNode $v]
            $cell appendChild $p
            $row appendChild $cell
            incr i
        }
        return $row
    }
    # New row at the end; cells = list of cell texts. Optional cellStyles =
    # list of per-cell table:style-name (parallel to cells).
    method addRow {table cells {cellStyles ""}} {
        set row [my BuildRow $cells $cellStyles]
        $table appendChild $row
        return $row
    }
    # Header row: wrapped in table:table-header-rows (created before the first
    # body row if absent). Same cells/cellStyles as addRow.
    method addHeaderRow {table cells {cellStyles ""}} {
        set hdr ""
        foreach c [$table childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:table-header-rows"} {
                set hdr $c; break
            }
        }
        if {$hdr eq ""} {
            set hdr [$Doc createElement table:table-header-rows]
            set ref ""
            foreach c [$table childNodes] {
                if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:table-row"} {
                    set ref $c; break
                }
            }
            if {$ref ne ""} { $table insertBefore $hdr $ref } else { $table appendChild $hdr }
        }
        set row [my BuildRow $cells $cellStyles]
        $hdr appendChild $row
        return $row
    }
    # Column style-names of a table (one per table:table-column).
    method tableColumns {table} {
        set res {}
        foreach c [$table childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "table:table-column"} {
                lappend res [$c getAttribute table:style-name ""]
            }
        }
        return $res
    }
    # Is this row inside table:table-header-rows?
    method isHeaderRow {row} {
        set p [$row parentNode]
        return [expr {$p ne "" && [$p nodeName] eq "table:table-header-rows"}]
    }
    # ---- cell spanning (merge) ----
    # Span the cell at (rowIdx, colIdx) over -columns C and/or -rows R cells.
    # The covered positions become <table:covered-table-cell/>. Indices count
    # all cell-like children (table-cell + covered-table-cell) = visual columns.
    method spanCell {table rowIdx colIdx args} {
        set cols 1; set rows 1
        foreach {k v} $args {
            switch -- $k {
                -columns { set cols $v }
                -rows    { set rows $v }
                default  { error "unknown option: $k" }
            }
        }
        if {![string is integer -strict $cols] || $cols < 1} { error "-columns must be a positive integer" }
        if {![string is integer -strict $rows] || $rows < 1} { error "-rows must be a positive integer" }
        set allRows [my tableRows $table]
        if {$rowIdx < 0 || $rowIdx >= [llength $allRows]} { error "row index out of range: $rowIdx" }
        if {$rowIdx + $rows > [llength $allRows]} { error "row span exceeds table height" }
        set anchorRow [lindex $allRows $rowIdx]
        set anchorCells [my rowCells $anchorRow]
        if {$colIdx < 0 || $colIdx >= [llength $anchorCells]} { error "column index out of range: $colIdx" }
        if {$colIdx + $cols > [llength $anchorCells]} { error "column span exceeds row width" }
        set anchor [lindex $anchorCells $colIdx]
        if {$cols > 1} { $anchor setAttribute table:number-columns-spanned $cols }
        if {$rows > 1} { $anchor setAttribute table:number-rows-spanned $rows }
        # cover the remaining columns of the anchor row
        for {set c [expr {$colIdx + 1}]} {$c < $colIdx + $cols} {incr c} {
            my CoverCell $anchorRow [lindex $anchorCells $c]
        }
        # cover the spanned columns in the following rows
        for {set r [expr {$rowIdx + 1}]} {$r < $rowIdx + $rows} {incr r} {
            set rrow  [lindex $allRows $r]
            set rcells [my rowCells $rrow]
            if {[llength $rcells] < $colIdx + $cols} { error "row $r is too narrow for the span" }
            for {set c $colIdx} {$c < $colIdx + $cols} {incr c} {
                my CoverCell $rrow [lindex $rcells $c]
            }
        }
        return $anchor
    }
    method CoverCell {row cell} {
        set cov [$Doc createElement table:covered-table-cell]
        $row insertBefore $cov $cell
        $cell delete
        return $cov
    }
    # Read the span of the cell at (rowIdx, colIdx): dict {columns C rows R}.
    method cellSpan {table rowIdx colIdx} {
        set anchorRow [lindex [my tableRows $table] $rowIdx]
        if {$anchorRow eq ""} { error "row index out of range: $rowIdx" }
        set cell [lindex [my rowCells $anchorRow] $colIdx]
        if {$cell eq ""} { error "column index out of range: $colIdx" }
        return [dict create \
            columns [$cell getAttribute table:number-columns-spanned 1] \
            rows    [$cell getAttribute table:number-rows-spanned 1]]
    }


    # ---- building (new nodes on the body) ----
    method appendList {{style ""}} {
        set l [$Doc createElement text:list]
        if {$style ne ""} { $l setAttribute text:style-name $style }
        $Body appendChild $l
        return $l
    }
    method appendTable {ncols {style ""}} {
        set tab [$Doc createElement table:table]
        if {$style ne ""} { $tab setAttribute table:style-name $style }
        for {set i 0} {$i < $ncols} {incr i} { $tab appendChild [$Doc createElement table:table-column] }
        $Body appendChild $tab
        return $tab
    }
    # Table with explicit column styles (column widths come from those styles).
    # colStyles = list of column style-names; tableStyle = optional table style.
    method appendTableCols {colStyles {tableStyle ""}} {
        set tab [$Doc createElement table:table]
        if {$tableStyle ne ""} { $tab setAttribute table:style-name $tableStyle }
        foreach cs $colStyles {
            set col [$Doc createElement table:table-column]
            if {$cs ne ""} { $col setAttribute table:style-name $cs }
            $tab appendChild $col
        }
        $Body appendChild $tab
        return $tab
    }
    # Image as text:p > draw:frame > draw:image. The bytes must be present
    # separately as a package part: $pkg addpart $href $bytes image/png
    method appendImage {href width height {name Image}} {
        return [my ImageFrame $href $width $height [dict create name $name]]
    }
    # A captioned figure (LibreOffice pattern): an outer draw:frame > draw:text-box
    # holding the image (inner as-char draw:frame) above a caption text:p. The
    # outer frame omits svg:height (auto-grow). <caption> is plain text the caller
    # supplies (e.g. "Figure 1: ..."); -caption-style only set if given (so we do
    # not reference an undefined style). Returns the outer frame. The image must
    # already be embedded (svg width/height are explicit -- works for SVG too).
    method appendCaptionedImage {href width height caption args} {
        set name "Figure"; set capstyle ""; set anchor paragraph; set framestyle ""
        foreach {k v} $args {
            switch -- $k {
                -name          { set name $v }
                -caption-style { set capstyle $v }
                -anchor        { set anchor $v }
                -style         { set framestyle $v }
                default        { error "unknown option: $k" }
            }
        }
        if {![$Pkg has $href]} { error "image part missing in package: $href (embed it first)" }
        set host  [$Doc createElement text:p]
        set outer [$Doc createElement draw:frame]
        $outer setAttribute draw:name "${name}-caption"
        $outer setAttribute text:anchor-type $anchor
        $outer setAttribute svg:width $width
        if {$framestyle ne ""} { $outer setAttribute draw:style-name $framestyle }
        set tb [$Doc createElement draw:text-box]
        set ip [$Doc createElement text:p]
        set imgfr [$Doc createElement draw:frame]
        $imgfr setAttribute draw:name $name
        $imgfr setAttribute text:anchor-type as-char
        $imgfr setAttribute svg:width  $width
        $imgfr setAttribute svg:height $height
        set img [$Doc createElement draw:image]
        $img setAttribute xlink:href $href
        $img setAttribute xlink:type simple
        $img setAttribute xlink:show embed
        $img setAttribute xlink:actuate onLoad
        $imgfr appendChild $img
        $ip appendChild $imgfr
        $tb appendChild $ip
        set cp [$Doc createElement text:p]
        if {$capstyle ne ""} { $cp setAttribute text:style-name $capstyle }
        $cp appendChild [$Doc createTextNode $caption]
        $tb appendChild $cp
        $outer appendChild $tb
        $host appendChild $outer
        $Body appendChild $host
        return $outer
    }
    # Outer caption frames: a draw:frame with a direct draw:text-box child that
    # contains an image (selects the outer container, not the inner image frame).
    method captionFrames {} {
        set r {}
        foreach fr [[$Doc documentElement] getElementsByTagName draw:frame] {
            set hastb 0
            foreach c [$fr childNodes] {
                if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "draw:text-box"} { set hastb 1 }
            }
            if {$hastb && [llength [$fr getElementsByTagName draw:image]]} { lappend r $fr }
        }
        return $r
    }
    # Caption text (last text:p inside the frame's text-box) and the image href.
    method captionText {frame} {
        set tb [lindex [$frame getElementsByTagName draw:text-box] 0]
        if {$tb eq ""} { return "" }
        set ps {}
        foreach c [$tb childNodes] {
            if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:p"} { lappend ps $c }
        }
        if {![llength $ps]} { return "" }
        return [[lindex $ps end] asText]
    }
    method captionImage {frame} {
        set img [lindex [$frame getElementsByTagName draw:image] 0]
        return [expr {$img eq "" ? "" : [$img getAttribute xlink:href ""]}]
    }

    # ---- sections (text:section) ----
    # A named body container. ?-style S? ?-protected 0/1?. With ?-blocks {n ...}?
    # the section is placed where the first listed block sits and those blocks are
    # moved into it (they must be current body children); otherwise an empty
    # section is appended. Returns the text:section node.
    method appendSection {name args} {
        set style ""; set protected ""; set blocks {}
        foreach {k v} $args {
            switch -- $k {
                -style     { set style $v }
                -protected { set protected $v }
                -blocks    { set blocks $v }
                default    { error "unknown option: $k" }
            }
        }
        set sec [$Doc createElement text:section]
        $sec setAttribute text:name $name
        if {$style ne ""}     { $sec setAttribute text:style-name $style }
        if {$protected ne ""} { $sec setAttribute text:protected [expr {$protected ? "true" : "false"}] }
        if {[llength $blocks]} {
            set first [lindex $blocks 0]
            [$first parentNode] insertBefore $sec $first
            foreach b $blocks { $sec appendChild $b }   ;# appendChild moves the node
        } else {
            $Body appendChild $sec
        }
        return $sec
    }

    # ---- master-document subdocuments (text:section > text:section-source) ----
    # Link an external document into a master document (.odm) as a protected,
    # linked section. A master document body IS a normal office:text (no
    # office:text-master element exists); its "master" nature is the package
    # media type (set by odf::newMasterDoc) plus these linked sections. Per the
    # ODF 1.3 RNG, text:section-source must be the FIRST child of text:section.
    #   name  section name, unique within the master
    #   href  IRI of the linked document (e.g. "chapter1.odt"); it is an external
    #         sibling file, NOT embedded in this package, so it is not validated.
    # Options:
    #   -section-name S  import only the named section from the linked file
    #   -filter-name F   import filter (default "writer8", the ODF text filter
    #                    LibreOffice uses for linked .odt; pass "" to omit)
    #   -protected B     protect the master copy from editing (default 1)
    #   -style S         section style name
    # Returns the text:section node.
    method appendSubdocument {name href args} {
        set secname ""; set filter "writer8"; set protected 1; set style ""
        foreach {k v} $args {
            switch -- $k {
                -section-name { set secname $v }
                -filter-name  { set filter $v }
                -protected    { set protected $v }
                -style        { set style $v }
                default       { error "unknown option: $k" }
            }
        }
        set sec [$Doc createElement text:section]
        $sec setAttribute text:name $name
        if {$style ne ""} { $sec setAttribute text:style-name $style }
        $sec setAttribute text:protected [expr {$protected ? "true" : "false"}]
        set src [$Doc createElement text:section-source]
        $src setAttribute xlink:href $href
        $src setAttribute xlink:type simple
        $src setAttribute xlink:show embed
        if {$secname ne ""} { $src setAttribute text:section-name $secname }
        if {$filter ne ""}  { $src setAttribute text:filter-name $filter }
        $sec appendChild $src
        $Body appendChild $sec
        return $sec
    }

    # Linked subdocuments of a master document: a list of dicts (one per
    # text:section that carries a text:section-source as a direct child) with
    # keys name, href, filter-name, section-name, protected.
    method subdocuments {} {
        set r {}
        foreach sec [$Body getElementsByTagName text:section] {
            set src ""
            foreach c [$sec childNodes] {
                if {[$c nodeType] eq "ELEMENT_NODE" && [$c nodeName] eq "text:section-source"} { set src $c; break }
            }
            if {$src eq ""} continue
            lappend r [dict create \
                name         [$sec getAttribute text:name ""] \
                href         [$src getAttribute xlink:href ""] \
                filter-name  [$src getAttribute text:filter-name ""] \
                section-name [$src getAttribute text:section-name ""] \
                protected    [expr {[$sec getAttribute text:protected ""] eq "true"}]]
        }
        return $r
    }
    # Append a table of contents. It is a field: the source defines how it is
    # built (outline levels 1..N, with an entry template per level = entry text +
    # a right tab stop with a dot leader + the page number); the index-body is
    # left empty and the consumer (LibreOffice: Tools > Update > Indexes, or F9)
    # regenerates the visible entries from the document's headings.
    #   -title T     index title       (default "Table of Contents")
    #   -levels N    outline levels    (default 10)
    #   -name NAME   index name         (default "Table of Contents1")
    #   -protected B protect from edits (default 1)
    #   -links B     make entries clickable (link-start/-end, default 1)
    #   -chapter B   prefix a chapter number per entry (default 0)
    method appendTOC {args} {
        set title "Table of Contents"; set levels 10
        set name "Table of Contents1"; set protected 1
        set links 1; set chapter 0
        foreach {k v} $args {
            switch -- $k {
                -title     { set title $v }
                -levels    { set levels $v }
                -name      { set name $v }
                -protected { set protected $v }
                -links     { set links $v }
                -chapter   { set chapter $v }
                default    { error "unknown option: $k" }
            }
        }
        if {![string is integer -strict $levels] || $levels < 1} {
            error "levels must be a positive integer: $levels"
        }
        set toc [$Doc createElement text:table-of-content]
        $toc setAttribute text:name $name
        if {$protected} { $toc setAttribute text:protected true }
        set src [$Doc createElement text:table-of-content-source]
        $src setAttribute text:outline-level $levels
        $src setAttribute text:use-outline-level true
        set tt [$Doc createElement text:index-title-template]
        $tt setAttribute text:style-name Contents_20_Heading
        $tt appendChild [$Doc createTextNode $title]
        $src appendChild $tt
        for {set L 1} {$L <= $levels} {incr L} {
            set et [$Doc createElement text:table-of-content-entry-template]
            $et setAttribute text:outline-level $L
            $et setAttribute text:style-name Contents_20_$L
            if {$links} { $et appendChild [$Doc createElement text:index-entry-link-start] }
            if {$chapter} {
                set ch [$Doc createElement text:index-entry-chapter]
                $ch setAttribute text:display number
                $et appendChild $ch
            }
            $et appendChild [$Doc createElement text:index-entry-text]
            set tab [$Doc createElement text:index-entry-tab-stop]
            $tab setAttribute style:type right
            $tab setAttribute style:leader-char "."
            $et appendChild $tab
            $et appendChild [$Doc createElement text:index-entry-page-number]
            if {$links} { $et appendChild [$Doc createElement text:index-entry-link-end] }
            $src appendChild $et
        }
        $toc appendChild $src
        $toc appendChild [$Doc createElement text:index-body]
        $Body appendChild $toc
        return $toc
    }
    # Names of the tables of contents in the document.
    method tableOfContents {} {
        set names {}
        foreach toc [[$Doc documentElement] getElementsByTagName text:table-of-content] {
            lappend names [$toc getAttribute text:name ""]
        }
        return $names
    }
    # Populate a TOC's index-body from the document's current headings, so the
    # entries are visible without a consumer regenerating the field. Reads the
    # title and level limit back from the TOC source, then emits a text:index-title
    # followed by one Contents_N paragraph per text:h (in document order) whose
    # outline level is within range. Page numbers are left to the consumer (F9);
    # this provides the visible entry text/structure. Call after the headings
    # exist. Returns the index-body.
    method fillTOC {toc} {
        set src [lindex [$toc getElementsByTagName text:table-of-content-source] 0]
        set levels [expr {$src eq "" ? 10 : [$src getAttribute text:outline-level 10]}]
        if {![string is integer -strict $levels]} { set levels 10 }
        set tt [expr {$src eq "" ? "" : [lindex [$src getElementsByTagName text:index-title-template] 0]}]
        set title [expr {$tt eq "" ? "" : [$tt asText]}]
        set name [$toc getAttribute text:name ""]
        set body [lindex [$toc getElementsByTagName text:index-body] 0]
        if {$body eq ""} { set body [$Doc createElement text:index-body]; $toc appendChild $body }
        foreach ch [$body childNodes] { $body removeChild $ch; $ch delete }
        if {$title ne ""} {
            set it [$Doc createElement text:index-title]
            $it setAttribute text:name "${name}_Head"
            set tp [$Doc createElement text:p]
            $tp setAttribute text:style-name Contents_20_Heading
            $tp appendChild [$Doc createTextNode $title]
            $it appendChild $tp
            $body appendChild $it
        }
        foreach h [$Body getElementsByTagName text:h] {
            set lvl [$h getAttribute text:outline-level 1]
            if {![string is integer -strict $lvl]} { set lvl 1 }
            if {$lvl > $levels} { continue }
            set p [$Doc createElement text:p]
            $p setAttribute text:style-name Contents_20_$lvl
            $p appendChild [$Doc createTextNode [$h asText]]
            $body appendChild $p
        }
        return $body
    }

    # ---- admonitions (Note / Tip / Caution / Warning callouts) ----------------
    # A callout rendered as a 1x1 framed table: a per-kind background tint + border,
    # a bold coloured label paragraph, then the body paragraph(s). Usage:
    #   appendAdmonition tip "First paragraph." "Second paragraph."
    #   appendAdmonition note -title "Achtung" "..."
    # kind is note|tip|caution|warning (case-insensitive). Trailing args are body
    # paragraphs (one text:p each). Returns the table.
    method appendAdmonition {kind args} {
        set palette {
            note    {#1A56DB #E8F0FE #C6D4F2}
            tip     {#137333 #E6F4EA #C3E2CC}
            caution {#B06000 #FEF7E0 #F2E2B0}
            warning {#C5221F #FCE8E6 #F2C7C4}
        }
        set k [string tolower $kind]
        if {![dict exists $palette $k]} {
            error "kind must be one of: [dict keys $palette]"
        }
        set title ""
        if {[lindex $args 0] eq "-title"} {
            set title [lindex $args 1]
            set bodies [lrange $args 2 end]
        } else {
            set bodies $args
        }
        if {$title eq ""} { set title [string totitle $k] }
        lassign [dict get $palette $k] labelColor bg border
        set Kc [string totitle $k]
        set cellStyle  Admon_${Kc}_Cell
        set labelStyle Admon_${Kc}_Label
        if {![my autoHas $cellStyle]} {
            my defineAutoCellStyle $cellStyle -background $bg \
                -border "0.5pt solid $border" -padding 0.15cm -valign top
        }
        if {![my autoHas $labelStyle]} {
            my defineAutoText $labelStyle [list fo:font-weight bold fo:color $labelColor]
        }
        set tab  [my appendTable 1]
        set row  [$Doc createElement table:table-row]
        set cell [$Doc createElement table:table-cell]
        $cell setAttribute table:style-name $cellStyle
        set lp [$Doc createElement text:p]
        my addSpan $lp $title $labelStyle
        $cell appendChild $lp
        foreach para $bodies {
            set bp [$Doc createElement text:p]
            $bp appendChild [$Doc createTextNode $para]
            $cell appendChild $bp
        }
        $row appendChild $cell
        $tab appendChild $row
        return $tab
    }
    # Admonition tables in the body (table:table whose cell carries an Admon_*_Cell
    # style), as {table kind} pairs.
    method admonitions {} {
        set res {}
        foreach tab [$Body getElementsByTagName table:table] {
            set cell [lindex [$tab getElementsByTagName table:table-cell] 0]
            if {$cell eq ""} { continue }
            set st [$cell getAttribute table:style-name ""]
            if {[regexp {^Admon_([A-Za-z]+)_Cell$} $st -> kc]} {
                lappend res [list $tab [string tolower $kc]]
            }
        }
        return $res
    }

    # ---- bibliography (inline citations + index) ----
    # Inline citation: text:bibliography-mark. -type is required (one of the ODF
    # bibliography types: article book ... www). Field options map to text:<field>
    # attributes (-author, -title, -year, -identifier, -publisher, ...). -text is
    # the displayed citation text (defaults to the identifier, else "[?]").
    method addBibliographyMark {node args} {
        set types {article book booklet conference custom1 custom2 custom3 custom4 custom5 \
            email inbook incollection inproceedings journal manual mastersthesis misc \
            phdthesis proceedings techreport unpublished www}
        set fields {address annote author booktitle chapter custom1 custom2 custom3 custom4 \
            custom5 edition editor howpublished identifier institution isbn issn journal \
            month note number organizations pages publisher report-type school series \
            title url volume year}
        set type ""; set disp ""; set attrs {}
        foreach {k v} $args {
            if {$k eq "-type"} { set type $v; continue }
            if {$k eq "-text"} { set disp $v; continue }
            set opt [string range $k 1 end]
            if {$opt ni $fields} { error "unknown option: $k" }
            lappend attrs text:$opt $v
        }
        if {$type ni $types} { error "bibliography-type must be one of the ODF types: $type" }
        if {$disp eq ""} {
            set disp [expr {[dict exists $attrs text:identifier] ? [dict get $attrs text:identifier] : "\[?\]"}]
        }
        set m [$Doc createElement text:bibliography-mark]
        $m setAttribute text:bibliography-type $type
        foreach {a v} $attrs { $m setAttribute $a $v }
        $m appendChild [$Doc createTextNode $disp]
        $node appendChild $m
        return $m
    }
    # Append a bibliography index (text:bibliography). Like the TOC it is a field:
    # the index-body is left empty and the consumer regenerates the entry list
    # from the document's bibliography marks on index update (F9).
    #   -title T (default "Bibliography")  -name NAME  -protected B (default 1)
    method appendBibliography {args} {
        set title "Bibliography"; set name "Bibliography1"; set protected 1
        foreach {k v} $args {
            switch -- $k {
                -title     { set title $v }
                -name      { set name $v }
                -protected { set protected $v }
                default    { error "unknown option: $k" }
            }
        }
        set bib [$Doc createElement text:bibliography]
        $bib setAttribute text:name $name
        if {$protected} { $bib setAttribute text:protected true }
        set src [$Doc createElement text:bibliography-source]
        set tt [$Doc createElement text:index-title-template]
        $tt setAttribute text:style-name Bibliography_20_Heading
        $tt appendChild [$Doc createTextNode $title]
        $src appendChild $tt
        $bib appendChild $src
        $bib appendChild [$Doc createElement text:index-body]
        $Body appendChild $bib
        return $bib
    }
    # One {type ?identifier?} entry per bibliography mark in the document.
    method bibliographyMarks {} {
        set res {}
        foreach m [[$Doc documentElement] getElementsByTagName text:bibliography-mark] {
            set e [list [$m getAttribute text:bibliography-type ""]]
            if {[$m hasAttribute text:identifier]} { lappend e [$m getAttribute text:identifier] }
            lappend res $e
        }
        return $res
    }
    # Names of the bibliography indexes in the document.
    method bibliographies {} {
        set names {}
        foreach b [[$Doc documentElement] getElementsByTagName text:bibliography] {
            lappend names [$b getAttribute text:name ""]
        }
        return $names
    }
    # A field value of a bibliography-mark run (e.g. author, title, year).
    method markField {run field} { return [$run getAttribute text:$field ""] }

    # ---- alphabetical index (keyword index) ----
    # Inline index entry: text:alphabetical-index-mark (an empty marker). value is
    # the entry text (text:string-value). Options:
    #   -key1 K        text:key1        (first-level grouping key)
    #   -key2 K        text:key2        (second-level grouping key)
    #   -main-entry B  text:main-entry  (boolean; emphasise this occurrence)
    method addIndexMark {node value args} {
        set m [$Doc createElement text:alphabetical-index-mark]
        $m setAttribute text:string-value $value
        foreach {k v} $args {
            switch -- $k {
                -key1       { $m setAttribute text:key1 $v }
                -key2       { $m setAttribute text:key2 $v }
                -main-entry {
                    if {![string is boolean -strict $v]} { error "main-entry must be boolean: $v" }
                    $m setAttribute text:main-entry [expr {$v ? "true" : "false"}]
                }
                default     { error "unknown option: $k" }
            }
        }
        $node appendChild $m
        return $m
    }
    # Append an alphabetical index (text:alphabetical-index). Like the TOC it is a
    # field: the index-body is left empty and the consumer regenerates the entry
    # list from the document's index marks on index update (F9).
    #   -title T (default "Index")  -name NAME  -protected B (default 1)
    method appendIndex {args} {
        set title "Index"; set name "Alphabetical Index1"; set protected 1
        foreach {k v} $args {
            switch -- $k {
                -title     { set title $v }
                -name      { set name $v }
                -protected { set protected $v }
                default    { error "unknown option: $k" }
            }
        }
        set idx [$Doc createElement text:alphabetical-index]
        $idx setAttribute text:name $name
        if {$protected} { $idx setAttribute text:protected true }
        set src [$Doc createElement text:alphabetical-index-source]
        set tt [$Doc createElement text:index-title-template]
        $tt setAttribute text:style-name Index_20_Heading
        $tt appendChild [$Doc createTextNode $title]
        $src appendChild $tt
        $idx appendChild $src
        $idx appendChild [$Doc createElement text:index-body]
        $Body appendChild $idx
        return $idx
    }
    # The entry strings of the alphabetical index marks in the document.
    method indexMarks {} {
        set res {}
        foreach m [[$Doc documentElement] getElementsByTagName text:alphabetical-index-mark] {
            lappend res [$m getAttribute text:string-value ""]
        }
        return $res
    }
    # Names of the alphabetical indexes in the document.
    method alphabeticalIndexes {} {
        set names {}
        foreach i [[$Doc documentElement] getElementsByTagName text:alphabetical-index] {
            lappend names [$i getAttribute text:name ""]
        }
        return $names
    }

    # ---- captions (text:sequence) + figure/table indexes ----
    # office:text > text:sequence-decls (prelude), created on first use.
    method EnsureSequenceDecls {} {
        set d [lindex [$Body getElementsByTagName text:sequence-decls] 0]
        if {$d eq ""} {
            set d [$Doc createElement text:sequence-decls]
            if {[$Body hasChildNodes]} {
                $Body insertBefore $d [lindex [$Body childNodes] 0]
            } else {
                $Body appendChild $d
            }
        }
        return $d
    }
    method EnsureSequenceDecl {name} {
        set decls [my EnsureSequenceDecls]
        foreach e [$decls getElementsByTagName text:sequence-decl] {
            if {[$e getAttribute text:name ""] eq $name} { return $e }
        }
        set e [$Doc createElement text:sequence-decl]
        $e setAttribute text:name $name
        $e setAttribute text:display-outline-level 0
        $decls appendChild $e
        return $e
    }
    # Inline sequence number field (text:sequence) named `name` (e.g. Illustration,
    # Table). The cached value is the running count; the consumer recomputes it.
    method addSequenceField {node name {numformat 1}} {
        my EnsureSequenceDecl $name
        set n 0
        foreach s [[$Doc documentElement] getElementsByTagName text:sequence] {
            if {[$s getAttribute text:name ""] eq $name} { incr n }
        }
        incr n
        set seq [$Doc createElement text:sequence]
        $seq setAttribute text:name $name
        $seq setAttribute text:formula "ooow:$name+1"
        $seq setAttribute style:num-format $numformat
        $seq appendChild [$Doc createTextNode $n]
        $node appendChild $seq
        return $seq
    }
    # A caption paragraph "<label> <N>: <text>" where N is an auto sequence for
    # `name` (use "Illustration" for figures, "Table" for tables, so the matching
    # index collects it). ?-style S? sets the paragraph style (default "Caption").
    method appendCaption {name label text args} {
        set style "Caption"
        foreach {k v} $args {
            switch -- $k { -style { set style $v } default { error "unknown option: $k" } }
        }
        set p [$Doc createElement text:p]
        if {$style ne ""} { $p setAttribute text:style-name $style }
        $p appendChild [$Doc createTextNode "$label "]
        my addSequenceField $p $name
        $p appendChild [$Doc createTextNode ": $text"]
        $Body appendChild $p
        return $p
    }
    # Append an illustration index (list of figures) / table index (list of tables).
    # Like the TOC they are fields; the consumer regenerates the entry list from the
    # captions (Illustration / Table sequences) on index update.
    #   -title T   -name NAME   -protected B (default 1)
    method appendIllustrationIndex {args} { return [my IndexField text:illustration-index text:illustration-index-source "Illustration Index" "Illustration Index1" $args] }
    method appendTableIndex {args}        { return [my IndexField text:table-index        text:table-index-source        "Index of Tables"   "Table Index1"        $args] }
    method IndexField {tag srctag deftitle defname optargs} {
        set title $deftitle; set name $defname; set protected 1
        foreach {k v} $optargs {
            switch -- $k {
                -title { set title $v } -name { set name $v } -protected { set protected $v }
                default { error "unknown option: $k" }
            }
        }
        set idx [$Doc createElement $tag]
        $idx setAttribute text:name $name
        if {$protected} { $idx setAttribute text:protected true }
        set src [$Doc createElement $srctag]
        set tt [$Doc createElement text:index-title-template]
        $tt appendChild [$Doc createTextNode $title]
        $src appendChild $tt
        $idx appendChild $src
        $idx appendChild [$Doc createElement text:index-body]
        $Body appendChild $idx
        return $idx
    }
    # Captions in the document: a list of {sequence-name cached-number} per
    # text:sequence field.
    method captions {} {
        set res {}
        foreach s [[$Doc documentElement] getElementsByTagName text:sequence] {
            lappend res [list [$s getAttribute text:name ""] [$s text]]
        }
        return $res
    }
    method illustrationIndexes {} {
        set names {}
        foreach i [[$Doc documentElement] getElementsByTagName text:illustration-index] { lappend names [$i getAttribute text:name ""] }
        return $names
    }
    method tableIndexes {} {
        set names {}
        foreach i [[$Doc documentElement] getElementsByTagName text:table-index] { lappend names [$i getAttribute text:name ""] }
        return $names
    }

    # ---- document fields (inline) ----
    method FieldBool {v} {
        if {[string is boolean -strict $v]} { return [expr {$v ? "true" : "false"}] }
        return $v
    }
    # text:page-number. ?-select previous|current|next? ?-format? ?-adjust N?
    # ?-fixed B? ?-text DISPLAY? (cached value, default "1").
    method addPageNumber {node args} {
        set el [$Doc createElement text:page-number]; set disp 1
        foreach {k v} $args {
            switch -- $k {
                -select { if {$v ni {previous current next}} { error "select must be previous|current|next: $v" }
                          $el setAttribute text:select-page $v }
                -format { $el setAttribute style:num-format $v }
                -adjust { $el setAttribute text:page-adjust $v }
                -fixed  { $el setAttribute text:fixed [my FieldBool $v] }
                -text   { set disp $v }
                default { error "unknown option: $k" }
            }
        }
        $el appendChild [$Doc createTextNode $disp]
        $node appendChild $el
        return $el
    }
    # text:page-count. ?-format? ?-text DISPLAY? (default "1").
    method addPageCount {node args} {
        set el [$Doc createElement text:page-count]; set disp 1
        foreach {k v} $args {
            switch -- $k {
                -format { $el setAttribute style:num-format $v }
                -text   { set disp $v }
                default { error "unknown option: $k" }
            }
        }
        $el appendChild [$Doc createTextNode $disp]
        $node appendChild $el
        return $el
    }
    # text:date / text:time. ?-value V (date/time-value)? ?-fixed B? ?-style DATASTYLE?
    # ?-text DISPLAY?
    method addDate {node args} { return [my DateTimeField text:date text:date-value $node $args] }
    method addTime {node args} { return [my DateTimeField text:time text:time-value $node $args] }
    method DateTimeField {tag valueAttr node optargs} {
        set el [$Doc createElement $tag]; set disp ""
        foreach {k v} $optargs {
            switch -- $k {
                -value { $el setAttribute $valueAttr $v }
                -fixed { $el setAttribute text:fixed [my FieldBool $v] }
                -style { $el setAttribute style:data-style-name $v }
                -text  { set disp $v }
                default { error "unknown option: $k" }
            }
        }
        $el appendChild [$Doc createTextNode $disp]
        $node appendChild $el
        return $el
    }
    # text:title / text:subject / text:author-name. ?-fixed B? ?-text DISPLAY?
    method addTitle   {node args} { return [my FixedField text:title       $node $args] }
    method addSubject {node args} { return [my FixedField text:subject     $node $args] }
    method addAuthor  {node args} { return [my FixedField text:author-name $node $args] }
    method FixedField {tag node optargs} {
        set el [$Doc createElement $tag]; set disp ""
        foreach {k v} $optargs {
            switch -- $k {
                -fixed { $el setAttribute text:fixed [my FieldBool $v] }
                -text  { set disp $v }
                default { error "unknown option: $k" }
            }
        }
        $el appendChild [$Doc createTextNode $disp]
        $node appendChild $el
        return $el
    }
    # text:chapter. -display name|number|number-and-name|plain-number|plain-number-and-name
    # (default name), -level N (default 1). ?-text DISPLAY?
    method addChapter {node args} {
        set display name; set level 1; set disp ""
        foreach {k v} $args {
            switch -- $k {
                -display { if {$v ni {name number number-and-name plain-number plain-number-and-name}} { error "invalid chapter display: $v" }
                           set display $v }
                -level   { set level $v }
                -text    { set disp $v }
                default  { error "unknown option: $k" }
            }
        }
        set el [$Doc createElement text:chapter]
        $el setAttribute text:display $display
        $el setAttribute text:outline-level $level
        $el appendChild [$Doc createTextNode $disp]
        $node appendChild $el
        return $el
    }
    # text:file-name. ?-display full|path|name|name-and-extension (default name)?
    # ?-fixed B? ?-text DISPLAY?
    method addFileName {node args} {
        set display name; set disp ""; set el [$Doc createElement text:file-name]
        foreach {k v} $args {
            switch -- $k {
                -display { if {$v ni {full path name name-and-extension}} { error "invalid file-name display: $v" }
                           set display $v }
                -fixed   { $el setAttribute text:fixed [my FieldBool $v] }
                -text    { set disp $v }
                default  { error "unknown option: $k" }
            }
        }
        $el setAttribute text:display $display
        $el appendChild [$Doc createTextNode $disp]
        $node appendChild $el
        return $el
    }
    # --- database / mail-merge fields (text:database-*) --------------------
    # The data source is referenced by registered NAME (text:database-name);
    # the actual data (a spreadsheet/CSV/etc.) lives outside the document, so
    # no .odb is involved. text:table-name is required. The embedded-connection
    # variant (form:connection-resource) is out of scope by design.

    # Set the common-field-database-table reference on a field element.
    # table is required; source (text:database-name) and type are optional.
    method DbTableRef {el source table type} {
        if {$table eq ""} { error "database field requires -table" }
        $el setAttribute text:table-name $table
        if {$type ne ""} {
            if {$type ni {table query command}} { error "table-type must be table|query|command: $type" }
            $el setAttribute text:table-type $type
        }
        if {$source ne ""} { $el setAttribute text:database-name $source }
        return
    }

    # text:database-display -- show one column value of the current row.
    # -table T -column C (required); ?-source NAME? ?-type table|query|command?
    # ?-style DATASTYLE? ?-text CACHED?
    method addDatabaseDisplay {node args} {
        set source ""; set table ""; set type ""; set column ""; set style ""; set disp ""
        foreach {k v} $args {
            switch -- $k {
                -source { set source $v }
                -table  { set table  $v }
                -type   { set type   $v }
                -column { set column $v }
                -style  { set style  $v }
                -text   { set disp   $v }
                default { error "unknown option: $k" }
            }
        }
        if {$column eq ""} { error "addDatabaseDisplay requires -column" }
        set el [$Doc createElement text:database-display]
        my DbTableRef $el $source $table $type
        $el setAttribute text:column-name $column
        if {$style ne ""} { $el setAttribute style:data-style-name $style }
        $el appendChild [$Doc createTextNode $disp]
        $node appendChild $el
        return $el
    }

    # text:database-next -- advance to the next row (label "next record").
    # -table T (required); ?-source NAME? ?-type ...? ?-condition EXPR?
    method addDatabaseNext {node args} {
        set source ""; set table ""; set type ""; set cond ""
        foreach {k v} $args {
            switch -- $k {
                -source    { set source $v }
                -table     { set table  $v }
                -type      { set type   $v }
                -condition { set cond   $v }
                default    { error "unknown option: $k" }
            }
        }
        set el [$Doc createElement text:database-next]
        my DbTableRef $el $source $table $type
        if {$cond ne ""} { $el setAttribute text:condition $cond }
        $node appendChild $el
        return $el
    }

    # text:database-row-select -- select a specific row.
    # -table T (required); ?-source NAME? ?-type ...? ?-condition EXPR? ?-row N?
    method addDatabaseRowSelect {node args} {
        set source ""; set table ""; set type ""; set cond ""; set row ""
        foreach {k v} $args {
            switch -- $k {
                -source    { set source $v }
                -table     { set table  $v }
                -type      { set type   $v }
                -condition { set cond   $v }
                -row       { set row    $v }
                default    { error "unknown option: $k" }
            }
        }
        set el [$Doc createElement text:database-row-select]
        my DbTableRef $el $source $table $type
        if {$cond ne ""} { $el setAttribute text:condition $cond }
        if {$row  ne ""} { $el setAttribute text:row-number $row }
        $node appendChild $el
        return $el
    }

    # text:database-row-number -- current row number.
    # -table T (required); ?-source NAME? ?-type ...? ?-numformat 1? ?-value N?
    # ?-text CACHED?
    method addDatabaseRowNumber {node args} {
        set source ""; set table ""; set type ""; set fmt ""; set val ""; set disp ""
        foreach {k v} $args {
            switch -- $k {
                -source    { set source $v }
                -table     { set table  $v }
                -type      { set type   $v }
                -numformat { set fmt    $v }
                -value     { set val    $v }
                -text      { set disp   $v }
                default    { error "unknown option: $k" }
            }
        }
        set el [$Doc createElement text:database-row-number]
        my DbTableRef $el $source $table $type
        if {$fmt ne ""} { $el setAttribute style:num-format $fmt }
        if {$val ne ""} { $el setAttribute text:value $val }
        $el appendChild [$Doc createTextNode $disp]
        $node appendChild $el
        return $el
    }

    # All text:database-display fields in the document as {source table column}.
    method databaseFields {} {
        set res {}
        foreach f [[$Doc documentElement] getElementsByTagName text:database-display] {
            lappend res [list \
                [$f getAttribute text:database-name ""] \
                [$f getAttribute text:table-name ""] \
                [$f getAttribute text:column-name ""]]
        }
        return $res
    }

    # All document-field runs in the document as {kind cached-text}.
    method fields {} {
        set kinds {text:page-number text:page-count text:date text:time \
            text:title text:subject text:author-name text:chapter text:file-name}
        set res {}
        foreach tag $kinds {
            foreach f [[$Doc documentElement] getElementsByTagName $tag] {
                lappend res [list [my runKind $f] [$f text]]
            }
        }
        return $res
    }
    # A section style (style:family=section). -columns N (>1 adds style:columns
    # with fo:column-count) and -column-gap LEN. Lives in content automatic-styles.
    method defineSectionStyle {name args} {
        set cols 1; set gap ""
        foreach {k v} $args {
            switch -- $k {
                -columns    { set cols $v }
                -column-gap { set gap $v }
                default     { error "unknown option: $k" }
            }
        }
        set as [my AutoStylesEl 1]
        foreach st [$as getElementsByTagName style:style] {
            if {[$st getAttribute style:name ""] eq $name} { $st delete }
        }
        set st [$Doc createElement style:style]
        $st setAttribute style:name $name
        $st setAttribute style:family section
        set sp [$Doc createElement style:section-properties]
        if {$cols > 1} {
            set co [$Doc createElement style:columns]
            $co setAttribute fo:column-count $cols
            if {$gap ne ""} { $co setAttribute fo:column-gap $gap }
            $sp appendChild $co
        }
        $st appendChild $sp
        $as appendChild $st
        return $name
    }
    # ---- section readers ----
    method sections {} {
        set r {}
        foreach sec [$Body getElementsByTagName text:section] { lappend r [$sec getAttribute text:name ""] }
        return $r
    }
    method sectionName      {node} { return [$node getAttribute text:name ""] }
    method sectionStyleName {node} { return [$node getAttribute text:style-name ""] }
    method sectionProtected {node} { return [expr {[$node getAttribute text:protected ""] eq "true"}] }
    method sectionBlocks    {node} {
        set res {}
        foreach c [$node childNodes] { if {[$c nodeType] eq "ELEMENT_NODE"} { lappend res $c } }
        return $res
    }
    # Build text:p > draw:frame > (draw:image, svg:title? svg:desc?). opts keys:
    # name, anchor (paragraph|char|as-char|page|frame), anchor-page, style
    # (graphic style-name), align (left|center|right), title, desc.
    # ODF 1.3 RNG: the frame content (draw:image) must precede svg:title/svg:desc.
    method ImageFrame {href width height opts} {
        set name   [expr {[dict exists $opts name]   ? [dict get $opts name]   : "Image"}]
        # -align targets an inline (as-char) image in its own centered paragraph;
        # a "paragraph"-anchored frame floats and is NOT moved by text-align.
        set anchor [expr {[dict exists $opts anchor] ? [dict get $opts anchor] : \
                          ([dict exists $opts align] ? "as-char" : "paragraph")}]
        set p [$Doc createElement text:p]
        if {[dict exists $opts align]} { $p setAttribute text:style-name [my AlignParaStyle [dict get $opts align]] }
        set fr [$Doc createElement draw:frame]
        $fr setAttribute draw:name $name
        $fr setAttribute text:anchor-type $anchor
        if {$anchor eq "page" && [dict exists $opts anchor-page]} {
            $fr setAttribute text:anchor-page-number [dict get $opts anchor-page]
        }
        if {[dict exists $opts style]} { $fr setAttribute draw:style-name [dict get $opts style] }
        $fr setAttribute svg:width  $width
        $fr setAttribute svg:height $height
        set img [$Doc createElement draw:image]
        $img setAttribute xlink:href $href
        $img setAttribute xlink:type simple
        $img setAttribute xlink:show embed
        $img setAttribute xlink:actuate onLoad
        $fr appendChild $img
        if {[dict exists $opts title]} {
            set tt [$Doc createElement svg:title]; $tt appendChild [$Doc createTextNode [dict get $opts title]]; $fr appendChild $tt
        }
        if {[dict exists $opts desc]} {
            set dd [$Doc createElement svg:desc]; $dd appendChild [$Doc createTextNode [dict get $opts desc]]; $fr appendChild $dd
        }
        $p appendChild $fr
        $Body appendChild $p
        return $p
    }
    # reuse/create an automatic paragraph style for image alignment
    method AlignParaStyle {align} {
        if {$align ni {left center right}} { error "-align must be left|center|right" }
        set name "ImgAlign[string totitle $align]"
        set as [my AutoStylesEl 1]
        foreach st [$as getElementsByTagName style:style] {
            if {[$st getAttribute style:name ""] eq $name} { return $name }
        }
        my defineAutoParagraph $name -paragraph [list fo:text-align $align]
        return $name
    }

    # Insert image fit to page: size from the PNG (in the package under $href),
    # px->cm bei -dpi (Standard 96), bei Ueberbreite auf -maxwidth herunterskaliert
    # (aspect ratio kept). -maxwidth 0 = no limit.
    # Insert an already-embedded image, sized from its pixels. Options: -name,
    # -maxwidth <len>, -dpi <n>, plus frame options -anchor/-anchor-page/-align/
    # -style/-title/-desc (see ImageFrame).
    method appendImageFit {href args} {
        set maxw 17.0; set dpi 96.0; set opts [dict create name Image]
        foreach {k v} $args {
            switch -- $k {
                -name        { dict set opts name $v }
                -maxwidth    { set maxw [my Cm2num $v] }
                -dpi         { set dpi  [expr {double($v)}] }
                -anchor      { dict set opts anchor $v }
                -anchor-page { dict set opts anchor-page $v }
                -align       { dict set opts align $v }
                -style       { dict set opts style $v }
                -title       { dict set opts title $v }
                -desc        { dict set opts desc $v }
                default      { error "unknown option: $k" }
            }
        }
        if {![$Pkg has $href]} { error "image part missing in package: $href (embed it first with \$t embedImage / \$pkg addpart)" }
        lassign [my ImageSize [$Pkg part $href]] pw ph
        set wcm [expr {$pw / $dpi * 2.54}]
        set hcm [expr {$ph / $dpi * 2.54}]
        if {$maxw > 0 && $wcm > $maxw} {
            set sc [expr {$maxw / $wcm}]; set wcm $maxw; set hcm [expr {$hcm * $sc}]
        }
        return [my ImageFrame $href [format %.2fcm $wcm] [format %.2fcm $hcm] $opts]
    }
    # Embed an image FILE into the package (Pictures/<name>.<ext>) and return its
    # href. Media type detected from the bytes (PNG/JPEG/GIF) or the extension.
    method embedImage {path args} {
        set name ""
        foreach {k v} $args { if {$k eq "-name"} { set name $v } else { error "unknown option: $k" } }
        if {![file isfile $path]} { error "no such file: $path" }
        set fh [open $path rb]; set bytes [read $fh]; close $fh
        set mt  [my ImageMediaType $bytes $path]
        set ext [my ImageExt $mt]
        if {$name eq ""} { set name [file rootname [file tail $path]] }
        set href "Pictures/$name$ext"
        $Pkg addpart $href $bytes $mt
        return $href
    }
    # Embed a file AND insert it sized to fit. -name sets both the part and frame
    # name; remaining options pass to appendImageFit.
    method appendImageFile {path args} {
        set name [file rootname [file tail $path]]; set rest {}
        foreach {k v} $args { if {$k eq "-name"} { set name $v } else { lappend rest $k $v } }
        set href [my embedImage $path -name $name]
        return [my appendImageFit $href -name $name {*}$rest]
    }
    method ImageMediaType {bytes path} {
        if {[string range $bytes 1 3] eq "PNG"}      { return image/png }
        if {[string range $bytes 0 1] eq "\xFF\xD8"} { return image/jpeg }
        if {[string range $bytes 0 2] eq "GIF"}      { return image/gif }
        if {[string range $bytes 0 3] eq "RIFF" && [string range $bytes 8 11] eq "WEBP"} { return image/webp }
        if {([string range $bytes 0 1] eq "II" && [string index $bytes 2] eq "\x2A") ||
            ([string range $bytes 0 1] eq "MM" && [string index $bytes 3] eq "\x2A")} { return image/tiff }
        if {[string range $bytes 0 1] eq "BM"}       { return image/bmp }
        if {[string first "<svg" [string range $bytes 0 2048]] >= 0} { return image/svg+xml }
        switch -- [string tolower [file extension $path]] {
            .png         { return image/png }
            .jpg - .jpeg { return image/jpeg }
            .gif         { return image/gif }
            .webp        { return image/webp }
            .tif - .tiff { return image/tiff }
            .bmp         { return image/bmp }
            .svg         { return image/svg+xml }
            default      { error "unsupported image type: $path (PNG/JPEG/GIF/WebP/TIFF/BMP/SVG)" }
        }
    }
    method ImageExt {mt} {
        switch -- $mt {
            image/png     { return .png }
            image/jpeg    { return .jpg }
            image/gif     { return .gif }
            image/webp    { return .webp }
            image/tiff    { return .tif }
            image/bmp     { return .bmp }
            image/svg+xml { return .svg }
            default       { return "" }
        }
    }
    # Graphic style (draw:style-name) for frames: wrap, position, border, etc.
    method defineFrameStyle {name args} {
        set g {}
        foreach {k v} $args {
            switch -- $k {
                -wrap         { lappend g style:wrap $v }
                -run-through  { lappend g style:run-through $v }
                -hpos         { lappend g style:horizontal-pos $v }
                -hrel         { lappend g style:horizontal-rel $v }
                -vpos         { lappend g style:vertical-pos $v }
                -vrel         { lappend g style:vertical-rel $v }
                -border       { lappend g fo:border $v }
                -padding      { lappend g fo:padding $v }
                -background   { lappend g fo:background-color $v }
                -mirror       { lappend g style:mirror $v }
                -attr         { foreach {a b} $v { lappend g $a $b } }
                default       { error "unknown option: $k" }
            }
        }
        return [my defineAutoGraphic $name $g]
    }
    # Image readers
    method images {} {
        set res {}
        foreach fr [$Body getElementsByTagName draw:frame] {
            if {[llength [$fr getElementsByTagName draw:image]] == 0} continue
            lappend res [$fr getAttribute draw:name ""]
        }
        return $res
    }
    method imageInfo {name} {
        foreach fr [$Body getElementsByTagName draw:frame] {
            if {[$fr getAttribute draw:name ""] ne $name} continue
            set img [lindex [$fr getElementsByTagName draw:image] 0]
            if {$img eq ""} continue
            set tt [lindex [$fr getElementsByTagName svg:title] 0]
            set dd [lindex [$fr getElementsByTagName svg:desc] 0]
            return [dict create href [$img getAttribute xlink:href ""] \
                width [$fr getAttribute svg:width ""] height [$fr getAttribute svg:height ""] \
                anchor [$fr getAttribute text:anchor-type ""] style [$fr getAttribute draw:style-name ""] \
                title [expr {$tt ne "" ? [$tt asText] : ""}] desc [expr {$dd ne "" ? [$dd asText] : ""}]]
        }
        return {}
    }

    # Absolutely positioned text frame (draw:frame/draw:text-box), e.g. for a
    # window-envelope address field. x/y/width as ODF measures (e.g. 2.0cm).
    # lines = list of {text ?style?}. -style references a graphic
    # automatic style (e.g. borderless). -anchor page (default) -> page-absolute
    # auf -page (Standard 1). -height optional.
    method addTextFrame {name x y width lines args} {
        set height ""; set page 1; set anchor page; set gstyle ""
        foreach {k v} $args {
            switch -- $k {
                -height { set height $v }
                -page   { set page $v }
                -anchor { set anchor $v }
                -style  { set gstyle $v }
                default { error "unknown option: $k" }
            }
        }
        set fr [$Doc createElement draw:frame]
        $fr setAttribute draw:name $name
        $fr setAttribute text:anchor-type $anchor
        if {$anchor eq "page"} { $fr setAttribute text:anchor-page-number $page }
        if {$gstyle ne ""} { $fr setAttribute draw:style-name $gstyle }
        $fr setAttribute svg:x $x
        $fr setAttribute svg:y $y
        $fr setAttribute svg:width $width
        if {$height ne ""} { $fr setAttribute svg:height $height }
        set tb [$Doc createElement draw:text-box]
        foreach spec $lines {
            set txt [lindex $spec 0]
            set sty [lindex $spec 1]
            set p [$Doc createElement text:p]
            if {$sty ne ""} { $p setAttribute text:style-name $sty }
            if {$txt ne ""} { $p appendChild [$Doc createTextNode $txt] }
            $tb appendChild $p
        }
        $fr appendChild $tb
        set anchorP [lindex [$Body getElementsByTagName text:p] 0]
        if {$anchorP eq ""} { set anchorP [$Doc createElement text:p]; $Body appendChild $anchorP }
        $anchorP appendChild $fr
        return $fr
    }
    # Names of all text frames (draw:frame with draw:text-box; image frames don't count).
    method textFrames {} {
        set res {}
        foreach fr [$Body getElementsByTagName draw:frame] {
            if {[llength [$fr getElementsByTagName draw:text-box]] == 0} continue
            lappend res [$fr getAttribute draw:name ""]
        }
        return $res
    }
    method frameInfo {name} {
        foreach fr [$Body getElementsByTagName draw:frame] {
            if {[$fr getAttribute draw:name ""] ne $name} continue
            set tb [lindex [$fr getElementsByTagName draw:text-box] 0]
            set lines {}
            if {$tb ne ""} { foreach p [$tb getElementsByTagName text:p] { lappend lines [$p asText] } }
            return [dict create x [$fr getAttribute svg:x ""] y [$fr getAttribute svg:y ""] \
                width [$fr getAttribute svg:width ""] height [$fr getAttribute svg:height ""] \
                anchor [$fr getAttribute text:anchor-type ""] lines $lines]
        }
        return {}
    }

    # Line at an absolute position (draw:line), e.g. fold marks. Coordinates as
    # ODF measures. Visibility/stroke come from a graphic style (-style).
    method addLine {name x1 y1 x2 y2 args} {
        set page 1; set anchor page; set gstyle ""
        foreach {k v} $args {
            switch -- $k {
                -page   { set page $v }
                -anchor { set anchor $v }
                -style  { set gstyle $v }
                default { error "unknown option: $k" }
            }
        }
        set ln [$Doc createElement draw:line]
        $ln setAttribute draw:name $name
        $ln setAttribute text:anchor-type $anchor
        if {$anchor eq "page"} { $ln setAttribute text:anchor-page-number $page }
        if {$gstyle ne ""} { $ln setAttribute draw:style-name $gstyle }
        $ln setAttribute svg:x1 $x1
        $ln setAttribute svg:y1 $y1
        $ln setAttribute svg:x2 $x2
        $ln setAttribute svg:y2 $y2
        set anchorP [lindex [$Body getElementsByTagName text:p] 0]
        if {$anchorP eq ""} { set anchorP [$Doc createElement text:p]; $Body appendChild $anchorP }
        $anchorP appendChild $ln
        return $ln
    }
    method drawLines {} {
        set res {}
        foreach ln [$Body getElementsByTagName draw:line] { lappend res [$ln getAttribute draw:name ""] }
        return $res
    }
    method lineInfo {name} {
        foreach ln [$Body getElementsByTagName draw:line] {
            if {[$ln getAttribute draw:name ""] ne $name} continue
            return [dict create x1 [$ln getAttribute svg:x1 ""] y1 [$ln getAttribute svg:y1 ""] \
                x2 [$ln getAttribute svg:x2 ""] y2 [$ln getAttribute svg:y2 ""] \
                anchor [$ln getAttribute text:anchor-type ""]]
        }
        return {}
    }


    # ---- automatic styles (document-local, in content.xml/office:automatic-styles) ----
    # Structurally identical to odf::Styles, but in content.xml instead of styles.xml.
    method autoNames {{family ""}} {
        set as [my AutoStylesEl 0]
        if {$as eq ""} { return {} }
        set res {}
        foreach s [$as getElementsByTagName style:style] {
            if {$family eq "" || [$s getAttribute style:family ""] eq $family} { lappend res [$s getAttribute style:name ""] }
        }
        return $res
    }
    method autoHas {name} { return [expr {$name in [my autoNames]}] }

    method defineAutoText {name props} {
        my AutoDefine $name text [list style:text-properties $props]
    }
    method defineAutoParagraph {name args} {
        my AutoDefine $name paragraph [my AutoGroups $args {-paragraph style:paragraph-properties -text style:text-properties}]
    }
    method defineAutoCell {name args} {
        my AutoDefine $name table-cell [my AutoGroups $args {-cell style:table-cell-properties -text style:text-properties -paragraph style:paragraph-properties}]
    }
    # Automatic table/column styles in content.xml (body tables need automatic
    # styles -- LibreOffice does not apply common table styles from styles.xml).
    method defineAutoTable {name props} {
        my AutoDefine $name table [list style:table-properties $props]
    }
    method defineAutoColumn {name props} {
        my AutoDefine $name table-column [list style:table-column-properties $props]
    }
    # Automatic cell style with named options (same set as odf::style
    # defineCellStyle), placed in content.xml so it renders in body tables.
    method defineAutoCellStyle {name args} {
        set cell {}; set text {}; set para {}; set parent ""
        foreach {k v} $args {
            switch -- $k {
                -border         { lappend cell fo:border $v }
                -border-top     { lappend cell fo:border-top $v }
                -border-bottom  { lappend cell fo:border-bottom $v }
                -border-left    { lappend cell fo:border-left $v }
                -border-right   { lappend cell fo:border-right $v }
                -padding        { lappend cell fo:padding $v }
                -padding-top    { lappend cell fo:padding-top $v }
                -padding-bottom { lappend cell fo:padding-bottom $v }
                -padding-left   { lappend cell fo:padding-left $v }
                -padding-right  { lappend cell fo:padding-right $v }
                -background     { lappend cell fo:background-color $v }
                -valign         { lappend cell style:vertical-align $v }
                -wrap           { lappend cell fo:wrap-option [expr {$v ? "wrap" : "no-wrap"}] }
                -bold           { if {$v} { lappend text fo:font-weight bold } }
                -italic         { if {$v} { lappend text fo:font-style italic } }
                -color          { lappend text fo:color $v }
                -font-size      { lappend text fo:font-size $v }
                -align          { lappend para fo:text-align $v }
                -cell           { foreach {a b} $v { lappend cell $a $b } }
                -text           { foreach {a b} $v { lappend text $a $b } }
                -paragraph      { foreach {a b} $v { lappend para $a $b } }
                -parent         { set parent $v }
                default         { error "unknown option: $k" }
            }
        }
        set groups {}
        if {[llength $cell]} { lappend groups style:table-cell-properties $cell }
        if {[llength $text]} { lappend groups style:text-properties $text }
        if {[llength $para]} { lappend groups style:paragraph-properties $para }
        set st [my AutoDefine $name table-cell $groups]
        if {$parent ne ""} { $st setAttribute style:parent-style-name $parent }
        return $st
    }
    method defineAutoGraphic {name props} {
        my AutoDefine $name graphic [list style:graphic-properties $props]
    }
    # Declare a font in content.xml (office:font-face-decls), so that
    # style:font-name in automatic styles points at a declared font.
    # -family (default = name), -generic roman|swiss|modern|..., -pitch fixed|variable
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

    # ---- style resolution (read) ----
    # Registry: name -> {family F parent P props {group -> {attr value ...} ...}}
    # from styles.xml (office:styles) AND content.xml (office:automatic-styles).
    method styleRegistry {} {
        set reg [dict create]
        if {[$Pkg has styles.xml]} {
            set sd [$Pkg tree styles.xml]
            set os [lindex [[$sd documentElement] getElementsByTagName office:styles] 0]
            if {$os ne ""} { my ScanStyles $os reg }
            $sd delete
        }
        set as [my AutoStylesEl 0]
        if {$as ne ""} { my ScanStyles $as reg }
        return $reg
    }
    # Effective properties of a style name (inheritance resolved).
    # Optionally pass a prebuilt registry (saves rebuilds for many nodes).
    method resolveStyle {name {reg ""}} {
        if {$reg eq ""} { set reg [my styleRegistry] }
        return [my MergeChain $name $reg {}]
    }
    # Effective properties of a node (style name from text:/table:style-name).
    method effectiveProps {node {reg ""}} {
        set name [$node getAttribute text:style-name ""]
        if {$name eq ""} { set name [$node getAttribute table:style-name ""] }
        return [my resolveStyle $name $reg]
    }
    # Single value: group (e.g. style:text-properties) + attribute (e.g. fo:color).
    method effectiveProp {node group attr {reg ""}} {
        set p [my effectiveProps $node $reg]
        if {[dict exists $p $group $attr]} { return [dict get $p $group $attr] }
        return ""
    }

    method flush {} { $Pkg settree content.xml $Doc; return }

    # ---- internal ----

    # get office:font-face-decls (or create, before automatic-styles / body)
    method FontDeclsEl {} {
        set root [$Doc documentElement]
        set el [lindex [$root getElementsByTagName office:font-face-decls] 0]
        if {$el eq ""} {
            set el [$Doc createElement office:font-face-decls]
            set as [lindex [$root getElementsByTagName office:automatic-styles] 0]
            set ref [expr {$as ne "" ? $as : [lindex [$root getElementsByTagName office:body] 0]}]
            if {$ref ne ""} { $root insertBefore $el $ref } else { $root appendChild $el }
        }
        return $el
    }
    # get office:automatic-styles (or create, before office:body)
    method AutoStylesEl {{create 1}} {
        set root [$Doc documentElement]
        set el [lindex [$root getElementsByTagName office:automatic-styles] 0]
        if {$el eq "" && $create} {
            set el [$Doc createElement office:automatic-styles]
            set body [lindex [$root getElementsByTagName office:body] 0]
            $root insertBefore $el $body
        }
        return $el
    }
    method AutoGroups {argList map} {
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
    method AutoDefine {name family groups} {
        set as [my AutoStylesEl 1]
        foreach s [$as getElementsByTagName style:style] {
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
        $as appendChild $st
        return $st
    }
    method Cm2num {s} { if {[regexp {([0-9]+(?:\.[0-9]+)?)} $s -> n]} { return [expr {double($n)}] }; return 0.0 }
    # Image size from the bytes: PNG (fixed header) or JPEG (SOF marker).
    method ImageSize {bytes} {
        if {[string range $bytes 1 3] eq "PNG"}        { return [my PngSize $bytes] }
        if {[string range $bytes 0 1] eq "\xFF\xD8"} { return [my JpegSize $bytes] }
        if {[string range $bytes 0 2] eq "GIF"} {
            binary scan [string range $bytes 6 9] ss w h
            return [list [expr {$w & 0xffff}] [expr {$h & 0xffff}]]
        }
        error "image format not recognized (PNG/JPEG/GIF only)"
    }
    method PngSize {bytes} {
        binary scan [string range $bytes 16 23] II w h
        return [list $w $h]
    }
    method JpegSize {bytes} {
        set n [string length $bytes]
        set i 2
        while {$i < $n - 1} {
            binary scan [string index $bytes $i] c b; set b [expr {$b & 0xff}]
            if {$b != 0xFF} { incr i; continue }
            binary scan [string index $bytes [expr {$i+1}]] c m; set m [expr {$m & 0xff}]
            incr i 2
            while {$m == 0xFF && $i < $n} { binary scan [string index $bytes $i] c m; set m [expr {$m & 0xff}]; incr i }
            if {($m >= 0xD0 && $m <= 0xD9) || $m == 0x01} { continue }   ;# ohne Laenge
            binary scan [string range $bytes $i [expr {$i+1}]] S len; set len [expr {$len & 0xffff}]
            if {($m >= 0xC0 && $m <= 0xCF) && $m != 0xC4 && $m != 0xC8 && $m != 0xCC} {
                binary scan [string range $bytes [expr {$i+3}] [expr {$i+6}]] SS h w
                return [list [expr {$w & 0xffff}] [expr {$h & 0xffff}]]
            }
            incr i $len
        }
        error "JPEG: no SOF marker found"
    }
    method ScanStyles {parentEl regName} {
        upvar 1 $regName reg
        foreach st [$parentEl getElementsByTagName style:style] {
            set name [$st getAttribute style:name ""]
            if {$name eq ""} continue
            set props [dict create]
            foreach c [$st childNodes] {
                if {[$c nodeType] ne "ELEMENT_NODE"} continue
                set grp [$c nodeName]
                set ad [dict create]
                foreach a [$c attributes] {
                    lassign $a ln prefix uri
                    set key [expr {$prefix ne "" ? "$prefix:$ln" : $ln}]
                    dict set ad $key [$c getAttribute $key ""]
                }
                if {[dict exists $props $grp]} { set ad [dict merge [dict get $props $grp] $ad] }
                dict set props $grp $ad
            }
            dict set reg $name [dict create \
                family [$st getAttribute style:family ""] \
                parent [$st getAttribute style:parent-style-name ""] \
                props  $props]
        }
    }
    method MergeChain {name reg seen} {
        if {$name eq "" || ![dict exists $reg $name] || $name in $seen} { return [dict create] }
        set e [dict get $reg $name]
        set merged [my MergeChain [dict get $e parent] $reg [linsert $seen end $name]]
        dict for {grp attrs} [dict get $e props] {
            set base [expr {[dict exists $merged $grp] ? [dict get $merged $grp] : [dict create]}]
            dict set merged $grp [dict merge $base $attrs]
        }
        return $merged
    }
    method HasImage {node} { return [expr {[llength [$node getElementsByTagName draw:image]] > 0}] }
    method Append {tag text style level} {
        set el [$Doc createElement $tag]
        if {$style ne ""} { $el setAttribute text:style-name $style }
        if {$level ne ""} { $el setAttribute text:outline-level $level }
        $el appendChild [$Doc createTextNode $text]
        $Body appendChild $el
        return $el
    }
}


# ---- Neues, leeres ODT-Textdokument als odf::Package erzeugen ----
proc odf::newTextDoc {} {
    set NS_O urn:oasis:names:tc:opendocument:xmlns:office:1.0
    set mimetype "application/vnd.oasis.opendocument.text"
    set manifest "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<manifest:manifest xmlns:manifest=\"urn:oasis:names:tc:opendocument:xmlns:manifest:1.0\" manifest:version=\"1.3\"><manifest:file-entry manifest:full-path=\"/\" manifest:media-type=\"$mimetype\"/><manifest:file-entry manifest:full-path=\"content.xml\" manifest:media-type=\"text/xml\"/><manifest:file-entry manifest:full-path=\"styles.xml\" manifest:media-type=\"text/xml\"/><manifest:file-entry manifest:full-path=\"meta.xml\" manifest:media-type=\"text/xml\"/></manifest:manifest>"
    set content "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-content xmlns:office=\"$NS_O\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:meta=\"urn:oasis:names:tc:opendocument:xmlns:meta:1.0\" xmlns:style=\"urn:oasis:names:tc:opendocument:xmlns:style:1.0\" xmlns:text=\"urn:oasis:names:tc:opendocument:xmlns:text:1.0\" xmlns:table=\"urn:oasis:names:tc:opendocument:xmlns:table:1.0\" xmlns:draw=\"urn:oasis:names:tc:opendocument:xmlns:drawing:1.0\" xmlns:fo=\"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0\" xmlns:svg=\"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" office:version=\"1.3\"><office:body><office:text/></office:body></office:document-content>"
    set styles "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-styles xmlns:office=\"$NS_O\" xmlns:style=\"urn:oasis:names:tc:opendocument:xmlns:style:1.0\" xmlns:fo=\"urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0\" xmlns:text=\"urn:oasis:names:tc:opendocument:xmlns:text:1.0\" xmlns:svg=\"urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0\" office:version=\"1.3\"><office:styles/><office:automatic-styles/><office:master-styles/></office:document-styles>"
    set meta "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-meta xmlns:office=\"$NS_O\" xmlns:meta=\"urn:oasis:names:tc:opendocument:xmlns:meta:1.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" office:version=\"1.3\"><office:meta><meta:generator>odf-tcl</meta:generator></office:meta></office:document-meta>"
    set pkg [odf::Package new]
    $pkg setpart mimetype $mimetype
    $pkg setpart META-INF/manifest.xml [encoding convertto utf-8 $manifest]
    $pkg setpart content.xml [encoding convertto utf-8 $content]
    $pkg setpart styles.xml  [encoding convertto utf-8 $styles]
    $pkg setpart meta.xml    [encoding convertto utf-8 $meta]
    return $pkg
}

# A text template (.ott): same content model as a text document, only the media
# type differs (application/vnd.oasis.opendocument.text-template).
proc odf::newTextTemplate {} {
    set pkg [odf::newTextDoc]
    $pkg setMimetype "application/vnd.oasis.opendocument.text-template"
    return $pkg
}

# A master document (.odm): a normal text body (office:text) whose content links
# external documents as protected text:section elements (see appendSubdocument).
# Only the package media type differs from a plain text document.
proc odf::newMasterDoc {} {
    set pkg [odf::newTextDoc]
    $pkg setMimetype "application/vnd.oasis.opendocument.text-master"
    return $pkg
}

# A master-document template (.otm): same content model as a master document,
# only the media type differs.
proc odf::newMasterTemplate {} {
    set pkg [odf::newTextDoc]
    $pkg setMimetype "application/vnd.oasis.opendocument.text-master-template"
    return $pkg
}

package provide odf::text 0.57
