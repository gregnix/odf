## odf/base-0.1.tm  --  odf::base (phase 1): file-based database document (.odb)
##
## A thin .odb generator for FILE-BASED data sources (CSV / flat text). The
## .odb is a connection descriptor only -- it points at an external folder of
## delimited files; the data lives outside (no embedded engine, no queries /
## forms / reports). This is exactly what a mail-merge data source needs:
## register the .odb under a name in LibreOffice, then a Writer template's
## text:database-display fields resolve against it.
##
## The structure mirrors what LibreOffice itself writes for a Text/CSV source
## (verified against a real LO 26.2 Addresses.odb that merges correctly):
##   office:database > db:data-source
##     > db:connection-data > db:database-description > db:file-based-database
##       (xlink:href -> folder, db:media-type, db:extension) + db:login
##     > db:driver-settings  (empty by default; LO relies on defaults comma/")
##     > db:application-connection-settings (table-filter %, Extension setting)
## Container parts: mimetype, settings.xml, content.xml, manifest (no styles/meta).
##
## "no magic": delimiters are NOT written unless given explicitly (-field/...);
## the proven default is LO's empty driver-settings. Out of scope by design:
## server databases, embedded engines, queries/forms/reports.
##
## 0.1: initial -- odf::newBaseDoc + odf::base::buildContent + reader
##      odf::base::source. file-based text/CSV source only.

package require Tcl 8.6-
package require tdom
package require odf

namespace eval odf::base {}

# XML-escape an attribute / text value.
proc odf::base::E {s} {
    return [string map {& &amp; < &lt; > &gt; \" &quot; ' &apos;} $s]
}

# Build the content.xml of a file-based database document.
# Options (all optional):
#   -href DIR        folder with the text files, relative to the .odb (default ../)
#   -extension EXT   file extension that becomes the tables (default csv)
#   -media-type MT   driver media type (default text/csv)
#   -maxrows N       db:max-row-count (default 100)
#   -field C -string C -decimal C -thousand C   explicit delimiters (default: none,
#                    i.e. LO defaults). If any is given, a db:delimiter is written.
#   -encoding ENC    if given, a db:character-set is written.
proc odf::base::buildContent {args} {
    set href ../; set ext csv; set mediatype text/csv; set maxrows 100
    set field ""; set string ""; set decimal ""; set thousand ""; set encoding ""
    foreach {k v} $args {
        switch -- $k {
            -href       { set href $v }
            -extension  { set ext $v }
            -media-type { set mediatype $v }
            -maxrows    { set maxrows $v }
            -field      { set field $v }
            -string     { set string $v }
            -decimal    { set decimal $v }
            -thousand   { set thousand $v }
            -encoding   { set encoding $v }
            default     { error "unknown option: $k" }
        }
    }
    set NS_O     urn:oasis:names:tc:opendocument:xmlns:office:1.0
    set NS_DB    urn:oasis:names:tc:opendocument:xmlns:database:1.0
    set NS_XLINK http://www.w3.org/1999/xlink

    # driver-settings: mirror LO's empty element unless delimiters/encoding given
    set hasDelim [expr {$field ne "" || $string ne "" || $decimal ne "" || $thousand ne ""}]
    if {$hasDelim || $encoding ne ""} {
        set drv "<db:driver-settings db:system-driver-settings=\"\" db:base-dn=\"\" db:parameter-name-substitution=\"false\">"
        if {$hasDelim} {
            set da ""
            if {$field    ne ""} { append da " db:field=\"[E $field]\"" }
            if {$string   ne ""} { append da " db:string=\"[E $string]\"" }
            if {$decimal  ne ""} { append da " db:decimal=\"[E $decimal]\"" }
            if {$thousand ne ""} { append da " db:thousand=\"[E $thousand]\"" }
            append drv "<db:delimiter$da/>"
        }
        if {$encoding ne ""} { append drv "<db:character-set db:encoding=\"[E $encoding]\"/>" }
        append drv "</db:driver-settings>"
    } else {
        set drv "<db:driver-settings db:system-driver-settings=\"\" db:base-dn=\"\" db:parameter-name-substitution=\"false\"/>"
    }

    set h  [E $href]
    set mt [E $mediatype]
    set ex [E $ext]
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-content xmlns:office=\"$NS_O\" xmlns:db=\"$NS_DB\" xmlns:xlink=\"$NS_XLINK\" office:version=\"1.3\"><office:scripts/><office:font-face-decls/><office:automatic-styles/><office:body><office:database><db:data-source><db:connection-data><db:database-description><db:file-based-database xlink:type=\"simple\" xlink:href=\"$h\" db:media-type=\"$mt\" db:extension=\"$ex\"/></db:database-description><db:login db:is-password-required=\"false\"/></db:connection-data>$drv<db:application-connection-settings db:is-table-name-length-limited=\"false\" db:append-table-alias-name=\"false\" db:max-row-count=\"$maxrows\"><db:table-filter><db:table-include-filter><db:table-filter-pattern>%</db:table-filter-pattern></db:table-include-filter></db:table-filter><db:data-source-settings><db:data-source-setting db:data-source-setting-is-list=\"false\" db:data-source-setting-name=\"Extension\" db:data-source-setting-type=\"string\"><db:data-source-setting-value>$ex</db:data-source-setting-value></db:data-source-setting></db:data-source-settings></db:application-connection-settings></db:data-source></office:database></office:body></office:document-content>"
}

# Read back the file-based source descriptor of a database package.
# Returns a dict: href media-type extension.
proc odf::base::source {pkg} {
    set doc [$pkg tree content.xml]
    set fb  [lindex [$doc getElementsByTagName db:file-based-database] 0]
    if {$fb eq ""} { $doc delete; error "not a file-based database document" }
    set res [dict create \
        href       [$fb getAttribute xlink:href ""] \
        media-type [$fb getAttribute db:media-type ""] \
        extension  [$fb getAttribute db:extension ""]]
    $doc delete
    return $res
}

# Factory: a file-based (CSV/text) database document. Returns an odf::Package.
# Accepts the same options as odf::base::buildContent.
proc odf::newBaseDoc {args} {
    set mimetype application/vnd.oasis.opendocument.base
    set content  [odf::base::buildContent {*}$args]
    set settings "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<office:document-settings xmlns:office=\"urn:oasis:names:tc:opendocument:xmlns:office:1.0\" xmlns:config=\"urn:oasis:names:tc:opendocument:xmlns:config:1.0\" office:version=\"1.3\"/>"
    set manifest "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<manifest:manifest xmlns:manifest=\"urn:oasis:names:tc:opendocument:xmlns:manifest:1.0\" manifest:version=\"1.3\"><manifest:file-entry manifest:full-path=\"/\" manifest:version=\"1.3\" manifest:media-type=\"$mimetype\"/><manifest:file-entry manifest:full-path=\"settings.xml\" manifest:media-type=\"text/xml\"/><manifest:file-entry manifest:full-path=\"content.xml\" manifest:media-type=\"text/xml\"/></manifest:manifest>"
    set pkg [odf::Package new]
    $pkg setpart mimetype $mimetype
    $pkg setpart META-INF/manifest.xml [encoding convertto utf-8 $manifest]
    $pkg setpart settings.xml          [encoding convertto utf-8 $settings]
    $pkg setpart content.xml           [encoding convertto utf-8 $content]
    return $pkg
}

package provide odf::base 0.1
