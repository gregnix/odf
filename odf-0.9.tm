## odf-0.4.tm  --  ODF container as a TclOO class (phase 1 + manifest helpers)
##
## 0.9: flush-hook registry. The library has a long-standing footgun: an
##      odf::Text / odf::Draw / odf::Sheet / odf::Style instance keeps its
##      DOM in memory (\$Doc) and only syncs back to the container's part
##      buffer when its flush method is explicitly called. \$pkg save
##      serialises whatever is in the part buffer, so without an explicit
##      \$d flush before save, the user ships stale bytes -- the file
##      writes successfully, validates clean, but LO opens it empty. This
##      happened in two demos in a row (stromstoss-demo, chart-types-demo)
##      before the pattern was visible.
##      0.9 fix: Package gains registerFlushHook {script} -- helpers (Draw,
##      Text, Sheet, Style) register [list [self] flush] in their
##      constructor. \$pkg save calls every hook (catch-wrapped so a dead
##      instance does not crash the save) before serialising. Demos and
##      external callers can now write \$pkg save without \$d flush;
##      explicit flush still works and remains harmless.
## 0.8: container ground-floor: settings.xml API + thumbnail convenience +
##      validate. setSetting PATH VALUE TYPE writes config:config-item under
##      a nested config:config-item-set tree, creating ancestors as needed;
##      setting reads back; removeSetting / settings list. Path syntax:
##      'set:name/setting-name' or 'set:name/sub:nested-set/setting-name'.
##      Types: string|boolean|short|int|long|double|datetime|base64Binary.
##      setThumbnail BYTES sets Thumbnails/thumbnail.png (the preview LO
##      shows in file dialogs) and its manifest entry in one call.
##      validate returns a list of {kind detail} pairs for issues -- parts
##      missing manifest entries, manifest entries with no part, and the
##      mimetype-must-be-first rule. Empty list means clean container.
## 0.7: setMimetype -- set the document media type on the mimetype part AND
##      the manifest root entry coherently (basis for templates: .ott/.ots/.otg
##      differ from their document only in this media type).
## 0.6: setVersion now also sets manifest:version on META-INF/manifest.xml,
##      so an explicit version is declared consistently across the package
##      (office:version + manifest:version). save() still never normalises.
## 0.5: setVersion / version -- read and explicitly set office:version on all
##      document parts (content/styles/meta/settings). Created documents are
##      already 1.3; a loaded document keeps its declared version (pass-through)
##      until setVersion is called -- no silent version rewriting.
## 0.4: document metadata API on the package (meta.xml): setMeta / meta
##      (dc:title/subject/description/creator/date/language, meta:generator,
##       initial-creator, creation-date, editing-cycles/-duration, keywords,
##       and meta:user-defined fields with an optional value-type).
##
## Runs on Tcl 8.6 and 9.x with a pure Tcl/zlib ZIP reader (no zipfs
## -> one code path for all versions, independent of zipfs API changes).
## ODF-correct writing: mimetype first entry, STORED; rest deflated.
##
## PASS-THROUGH: unchanged parts keep their original bytes.
##
## Class:
##   set pkg [odf::Package new $pfad]   ;# oeffnen
##   $pkg parts                         ;# part names (mimetype first)
##   $pkg part  $name                   ;# bytes
##   $pkg has   $name
##   $pkg setpart $name $bytes          ;# in-place
##   set doc [$pkg tree $name]          ;# part as a tdom document (caller deletes)
##   $pkg settree $name $doc
##   $pkg save  $path
##   --- Manifest ---
##   $pkg manifest                      ;# dict full-path -> media-type
##   $pkg addpart  $name $bytes $mediatype   ;# part + manifest entry
##   $pkg dropfile $name                     ;# remove part + manifest entry
##   --- Metadata (meta.xml) ---
##   $pkg setMeta -title T -creator C -keywords {a b} -user-defined {{Project odf}}
##   $pkg meta                          ;# dict of set metadata fields
##   $pkg destroy

package require Tcl 8.6 9
package require tdom

namespace eval odf {
    variable MANIFEST META-INF/manifest.xml
}

oo::class create odf::Package {
    variable Path Order Parts FlushHooks

    constructor {{path ""}} {
        set Path ""; set Order {}; set Parts [dict create]
        set FlushHooks {}
        if {$path ne ""} { my load $path }
    }

    method load {path} {
        set Path  $path
        set Parts [odf::_readParts $path]
        set Order {}
        if {[dict exists $Parts mimetype]} { lappend Order mimetype }
        foreach n [lsort [dict keys $Parts]] {
            if {$n ne "mimetype"} { lappend Order $n }
        }
        return
    }

    # ---- parts ----
    method parts {}        { return $Order }
    method has   {name}    { return [dict exists $Parts $name] }
    method part  {name}    { return [dict get $Parts $name] }
    method mimetype {}     { return [expr {[my has mimetype] ? [my part mimetype] : ""}] }

    method setpart {name bytes} {
        dict set Parts $name $bytes
        if {$name ni $Order} { lappend Order $name }
        return
    }
    method removepart {name} {
        dict unset Parts $name
        set Order [lsearch -all -inline -not -exact $Order $name]
        return
    }

    # ---- tdom bridge ----
    method tree {name} {
        return [dom parse [encoding convertfrom utf-8 [my part $name]]]
    }
    method settree {name doc} {
        set xml "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n[[$doc documentElement] asXML -indent none]"
        my setpart $name [encoding convertto utf-8 $xml]
        return
    }

    # ---- manifest helpers ----
    # dict: full-path -> media-type
    method manifest {} {
        if {![my has $::odf::MANIFEST]} { return {} }
        set doc [my tree $::odf::MANIFEST]
        set res [dict create]
        foreach fe [[$doc documentElement] getElementsByTagName manifest:file-entry] {
            dict set res [$fe getAttribute manifest:full-path ""] \
                         [$fe getAttribute manifest:media-type ""]
        }
        $doc delete
        return $res
    }

    # add/replace a part + set its manifest entry.
    # mediatype is mandatory (no guessing -- no magic).
    method addpart {name bytes mediatype} {
        my setpart $name $bytes
        my ManifestSet $name $mediatype
        return
    }

    # remove a part and its manifest entry.
    method dropfile {name} {
        my removepart $name
        my ManifestRemove $name
        return
    }

    # ---- document metadata (meta.xml) ----
    # Set metadata fields. Each option replaces only the field it names (other
    # fields are untouched), so setMeta may be called repeatedly. Single-value
    # options map 1:1 to ODF elements:
    #   -generator        meta:generator
    #   -title            dc:title
    #   -description      dc:description
    #   -subject          dc:subject
    #   -creator          dc:creator               (last modified by)
    #   -initial-creator  meta:initial-creator     (author)
    #   -creation-date    meta:creation-date       (dateTime)
    #   -date             dc:date                  (last modification, dateTime)
    #   -print-date       meta:print-date          (dateTime)
    #   -printed-by       meta:printed-by
    #   -language         dc:language
    #   -editing-cycles   meta:editing-cycles
    #   -editing-duration meta:editing-duration    (duration, e.g. PT1H30M)
    # -keywords <list> replaces all meta:keyword elements (one per item).
    # -user-defined takes a list of entries {name value ?value-type?}; value-type
    # is one of float|date|time|boolean|string. Each entry replaces any existing
    # user-defined field with the same name.
    method setMeta {args} {
        set single {
            -generator        meta:generator
            -title            dc:title
            -description      dc:description
            -subject          dc:subject
            -creator          dc:creator
            -initial-creator  meta:initial-creator
            -creation-date    meta:creation-date
            -date             dc:date
            -print-date       meta:print-date
            -printed-by       meta:printed-by
            -language         dc:language
            -editing-cycles   meta:editing-cycles
            -editing-duration meta:editing-duration
        }
        set vtypes {float date time boolean string}
        set sets {}; set keywords {}; set haveKw 0; set userDefs {}
        foreach {k v} $args {
            switch -- $k {
                -keywords     { set keywords $v; set haveKw 1 }
                -user-defined { set userDefs $v }
                default {
                    if {![dict exists $single $k]} { error "unknown option: $k" }
                    lappend sets [dict get $single $k] $v
                }
            }
        }
        # validate user-defined value-types up front (no partial mutation on error)
        foreach entry $userDefs {
            set t [lindex $entry 2]
            if {$t ne "" && $t ni $vtypes} { error "invalid value-type: $t" }
        }
        set doc  [my tree meta.xml]
        set meta [my MetaEl $doc]
        foreach {tag val} $sets {
            foreach e [$meta getElementsByTagName $tag] { $e delete }
            set el [$doc createElement $tag]
            $el appendChild [$doc createTextNode $val]
            $meta appendChild $el
        }
        if {$haveKw} {
            foreach e [$meta getElementsByTagName meta:keyword] { $e delete }
            foreach kw $keywords {
                set el [$doc createElement meta:keyword]
                $el appendChild [$doc createTextNode $kw]
                $meta appendChild $el
            }
        }
        foreach entry $userDefs {
            lassign $entry name val type
            foreach e [$meta getElementsByTagName meta:user-defined] {
                if {[$e getAttribute meta:name ""] eq $name} { $e delete }
            }
            set el [$doc createElement meta:user-defined]
            $el setAttribute meta:name $name
            if {$type ne ""} { $el setAttribute meta:value-type $type }
            $el appendChild [$doc createTextNode $val]
            $meta appendChild $el
        }
        my settree meta.xml $doc
        $doc delete
        return
    }
    # Read metadata as a dict of set fields (keys without prefix, e.g. title,
    # creator, creation-date). keywords -> a list; user-defined -> a list of
    # {name value ?value-type?}. Empty dict if meta.xml or office:meta is absent.
    method meta {} {
        if {![my has meta.xml]} { return {} }
        set doc  [my tree meta.xml]
        set meta [lindex [[$doc documentElement] getElementsByTagName office:meta] 0]
        if {$meta eq ""} { $doc delete; return {} }
        set rev {meta:generator generator dc:title title dc:description description \
            dc:subject subject meta:initial-creator initial-creator dc:creator creator \
            meta:creation-date creation-date dc:date date meta:print-date print-date \
            meta:printed-by printed-by dc:language language \
            meta:editing-cycles editing-cycles meta:editing-duration editing-duration}
        set d {}
        foreach {tag key} $rev {
            set e [lindex [$meta getElementsByTagName $tag] 0]
            if {$e ne ""} { dict set d $key [$e text] }
        }
        set kw {}
        foreach e [$meta getElementsByTagName meta:keyword] { lappend kw [$e text] }
        if {[llength $kw]} { dict set d keywords $kw }
        set ud {}
        foreach e [$meta getElementsByTagName meta:user-defined] {
            set entry [list [$e getAttribute meta:name ""] [$e text]]
            if {[$e hasAttribute meta:value-type]} { lappend entry [$e getAttribute meta:value-type] }
            lappend ud $entry
        }
        if {[llength $ud]} { dict set d user-defined $ud }
        $doc delete
        return $d
    }

    # ---- ODF version ----
    # Read office:version from content.xml (the document's declared ODF version).
    method version {} {
        if {![my has content.xml]} { return "" }
        set doc [my tree content.xml]
        set v [[$doc documentElement] getAttribute office:version ""]
        $doc delete
        return $v
    }
    # Explicitly set office:version on every present document part. Documents this
    # library creates are already "1.3"; a loaded document keeps its source version
    # until this is called (no silent rewriting). Returns the version set.
    method setVersion {{ver 1.3}} {
        foreach part {content.xml styles.xml meta.xml settings.xml} {
            if {![my has $part]} { continue }
            set doc [my tree $part]
            [$doc documentElement] setAttribute office:version $ver
            my settree $part $doc
            $doc delete
        }
        # The manifest declares the package version too; an explicit setVersion
        # must bump it as well, otherwise the document is internally inconsistent
        # (office:version says $ver but manifest:version is absent/older -> not
        # conformant). This is explicit, opt-in -- save() still never normalises.
        if {[my has $::odf::MANIFEST]} {
            set doc [my tree $::odf::MANIFEST]
            [$doc documentElement] setAttribute manifest:version $ver
            my settree $::odf::MANIFEST $doc
            $doc delete
        }
        return $ver
    }

    # Set the document media type coherently: the "mimetype" part AND the
    # manifest root ("/") media-type. This is how a document becomes a template
    # (e.g. application/vnd.oasis.opendocument.text-template) -- structurally a
    # template is identical to its document, only these two strings differ.
    method setMimetype {mime} {
        my setpart mimetype $mime
        if {[my has $::odf::MANIFEST]} {
            set doc [my tree $::odf::MANIFEST]
            foreach fe [[$doc documentElement] getElementsByTagName manifest:file-entry] {
                if {[$fe getAttribute manifest:full-path ""] eq "/"} {
                    $fe setAttribute manifest:media-type $mime
                }
            }
            my settree $::odf::MANIFEST $doc
            $doc delete
        }
        return $mime
    }

    # ---- internal ----
    # office:meta inside meta.xml (created if missing).
    method MetaEl {doc} {
        set root [$doc documentElement]
        set meta [lindex [$root getElementsByTagName office:meta] 0]
        if {$meta eq ""} {
            set meta [$doc createElement office:meta]
            $root appendChild $meta
        }
        return $meta
    }
    method ManifestSet {name mediatype} {
        if {![my has $::odf::MANIFEST]} { error "no $::odf::MANIFEST present" }
        set doc  [my tree $::odf::MANIFEST]
        set root [$doc documentElement]
        set found 0
        foreach fe [$root getElementsByTagName manifest:file-entry] {
            if {[$fe getAttribute manifest:full-path ""] eq $name} {
                $fe setAttribute manifest:media-type $mediatype
                set found 1; break
            }
        }
        if {!$found} {
            set fe [$doc createElement manifest:file-entry]
            $fe setAttribute manifest:full-path  $name
            $fe setAttribute manifest:media-type $mediatype
            $root appendChild $fe
        }
        my settree $::odf::MANIFEST $doc
        $doc delete
        return
    }
    method ManifestRemove {name} {
        if {![my has $::odf::MANIFEST]} return
        set doc [my tree $::odf::MANIFEST]
        foreach fe [[$doc documentElement] getElementsByTagName manifest:file-entry] {
            if {[$fe getAttribute manifest:full-path ""] eq $name} { $fe delete }
        }
        my settree $::odf::MANIFEST $doc
        $doc delete
        return
    }

    # ---- writing (ODF-correct) ----
    # ---- 0.8: settings.xml API -------------------------------------------
    # Path is "set-name/item-name" or "set-name/sub-set-name/item-name" etc.
    # Top-level config-item-set names typically follow LO's convention like
    # "ooo:view-settings", "ooo:configuration-settings".

    method SettingsDoc {} {
        # Return the parsed settings.xml document, creating an empty shell if
        # absent. Caller must NOT delete; we manage the lifecycle.
        variable SettingsDocCache
        if {[info exists SettingsDocCache] && $SettingsDocCache ne ""} {
            return $SettingsDocCache
        }
        if {[my has settings.xml]} {
            set doc [dom parse [encoding convertfrom utf-8 [my part settings.xml]]]
        } else {
            set NS_O urn:oasis:names:tc:opendocument:xmlns:office:1.0
            set NS_C urn:oasis:names:tc:opendocument:xmlns:config:1.0
            set xml "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            append xml "<office:document-settings xmlns:office=\"$NS_O\" "
            append xml "xmlns:config=\"$NS_C\" office:version=\"1.3\">"
            append xml "<office:settings/></office:document-settings>"
            set doc [dom parse $xml]
        }
        set SettingsDocCache $doc
        return $doc
    }
    method FlushSettings {} {
        variable SettingsDocCache
        if {![info exists SettingsDocCache] || $SettingsDocCache eq ""} return
        set bytes [encoding convertto utf-8 [$SettingsDocCache asXML]]
        if {[my has settings.xml]} {
            my setpart settings.xml $bytes
        } else {
            my addpart settings.xml $bytes text/xml
        }
    }
    # Walk a path "a/b/c", creating config-item-set elements as needed; return
    # the parent element where the last segment should live.
    method SettingsWalk {path create} {
        set segs [split $path /]
        if {[llength $segs] < 2} {
            error "setting path needs at least set-name/item-name (got: $path)"
        }
        set leaf [lindex $segs end]
        set sets [lrange $segs 0 end-1]
        set doc [my SettingsDoc]
        set root [$doc documentElement]
        set ofs [lindex [$root getElementsByTagName office:settings] 0]
        if {$ofs eq ""} {
            error "settings.xml missing office:settings"
        }
        set parent $ofs
        foreach seg $sets {
            set found ""
            foreach child [$parent childNodes] {
                if {[$child nodeType] eq "ELEMENT_NODE" \
                    && [$child nodeName] eq "config:config-item-set" \
                    && [$child getAttribute config:name ""] eq $seg} {
                    set found $child; break
                }
            }
            if {$found eq ""} {
                if {!$create} { return [list "" $leaf] }
                set found [$doc createElement config:config-item-set]
                $found setAttribute config:name $seg
                $parent appendChild $found
            }
            set parent $found
        }
        return [list $parent $leaf]
    }
    # setSetting PATH VALUE ?TYPE? -- type defaults to "string".
    method setSetting {path value {type string}} {
        switch -- $type {
            string - boolean - short - int - long - double - datetime - base64Binary {}
            default {
                error "bad type: $type (string|boolean|short|int|long|double|datetime|base64Binary)"
            }
        }
        lassign [my SettingsWalk $path 1] parent leaf
        # Remove existing item with the same name (overwrite semantics)
        foreach child [$parent childNodes] {
            if {[$child nodeType] eq "ELEMENT_NODE" \
                && [$child nodeName] eq "config:config-item" \
                && [$child getAttribute config:name ""] eq $leaf} {
                $parent removeChild $child
            }
        }
        set doc [my SettingsDoc]
        set ci [$doc createElement config:config-item]
        $ci setAttribute config:name $leaf
        $ci setAttribute config:type $type
        $ci appendChild [$doc createTextNode $value]
        $parent appendChild $ci
        my FlushSettings
        return $path
    }
    # setting PATH -- return the value or "" if absent.
    method setting {path} {
        lassign [my SettingsWalk $path 0] parent leaf
        if {$parent eq ""} { return "" }
        foreach child [$parent childNodes] {
            if {[$child nodeType] eq "ELEMENT_NODE" \
                && [$child nodeName] eq "config:config-item" \
                && [$child getAttribute config:name ""] eq $leaf} {
                return [$child text]
            }
        }
        return ""
    }
    # removeSetting PATH -- returns 1 if removed, 0 if not found.
    method removeSetting {path} {
        lassign [my SettingsWalk $path 0] parent leaf
        if {$parent eq ""} { return 0 }
        foreach child [$parent childNodes] {
            if {[$child nodeType] eq "ELEMENT_NODE" \
                && [$child nodeName] eq "config:config-item" \
                && [$child getAttribute config:name ""] eq $leaf} {
                $parent removeChild $child
                my FlushSettings
                return 1
            }
        }
        return 0
    }
    # settings -- return a flat list of all defined "path = value" entries.
    method settings {} {
        if {![my has settings.xml]} { return {} }
        set doc [my SettingsDoc]
        set root [$doc documentElement]
        set ofs [lindex [$root getElementsByTagName office:settings] 0]
        if {$ofs eq ""} { return {} }
        set res {}
        my SettingsCollect $ofs {} res
        return $res
    }
    method SettingsCollect {node prefix listVar} {
        upvar 1 $listVar res
        foreach child [$node childNodes] {
            if {[$child nodeType] ne "ELEMENT_NODE"} continue
            set nm [$child getAttribute config:name ""]
            switch -- [$child nodeName] {
                config:config-item-set {
                    set newPrefix [expr {$prefix eq "" ? $nm : "$prefix/$nm"}]
                    my SettingsCollect $child $newPrefix res
                }
                config:config-item {
                    set path [expr {$prefix eq "" ? $nm : "$prefix/$nm"}]
                    lappend res $path [$child text]
                }
            }
        }
    }

    # ---- 0.8: thumbnail --------------------------------------------------
    # Convenience: write Thumbnails/thumbnail.png plus its manifest entry in
    # one call. LO uses this preview in file-open dialogs / file managers.
    method setThumbnail {bytes} {
        set path Thumbnails/thumbnail.png
        if {[my has $path]} {
            my setpart $path $bytes
        } else {
            my addpart $path $bytes image/png
        }
        return $path
    }
    method thumbnail {} {
        if {[my has Thumbnails/thumbnail.png]} {
            return [my part Thumbnails/thumbnail.png]
        }
        return ""
    }

    # ---- 0.8: container validate -----------------------------------------
    # Return a list of {kind detail} pairs for any inconsistencies. Empty
    # list means clean. Three checks:
    #   * mimetype must be the FIRST entry (ODF requirement for ZIP container)
    #   * every actual part has a manifest:file-entry (or is itself the
    #     mimetype / manifest / signature stream which are exempt)
    #   * every manifest entry refers to an existing part
    method validate {} {
        set issues {}
        set order [my parts]
        if {[llength $order] && [lindex $order 0] ne "mimetype"} {
            lappend issues [list mimetype-not-first \
                "first part is '[lindex $order 0]', expected 'mimetype'"]
        }
        set manifest [my manifest]
        set exempt {mimetype META-INF/manifest.xml META-INF/documentsignatures.xml \
                    META-INF/macrosignatures.xml}
        foreach part $order {
            if {[lsearch -exact $exempt $part] >= 0} continue
            if {![dict exists $manifest $part]} {
                lappend issues [list part-without-manifest-entry $part]
            }
        }
        foreach part [dict keys $manifest] {
            if {$part eq "/"} continue
            if {![my has $part]} {
                lappend issues [list manifest-entry-without-part $part]
            }
        }
        return $issues
    }

    # 0.9: helpers register a flush callback here in their constructor; save
    # invokes every callback before serialising so the user does not have to
    # remember "\$d flush" before "\$pkg save".
    method registerFlushHook {script} {
        lappend FlushHooks $script
        return [llength $FlushHooks]
    }
    method flushHooks {} { return $FlushHooks }

    method save {path} {
        # Run registered flush hooks first; catch-wrap so an already-destroyed
        # helper instance does not blow up the save.
        foreach hook $FlushHooks { catch {uplevel #0 $hook} }
        set entries {}
        if {[my has mimetype]} { lappend entries [list mimetype 0 [my part mimetype]] }
        foreach n $Order {
            if {$n eq "mimetype"} continue
            lappend entries [list $n 8 [my part $n]]
        }
        set fh [::open $path wb]
        puts -nonewline $fh [odf::_zip $entries]
        close $fh
        return $path
    }
}

# ================= pure functions (stateless) =================

# ---- ZIP writing (deflate/stored, CRC32) ----
proc odf::_zip {entries} {
    set out ""; set central ""; set offset 0
    # fixed, valid DOS timestamp (1980-01-01 00:00) -- deterministic, and avoids
    # the invalid all-zero date that some validators reject.
    set dtime 0
    set ddate 33
    foreach e $entries {
        lassign $e name method data
        set usize [string length $data]
        set crc   [expr {[zlib crc32 $data] & 0xffffffff}]
        if {$method == 8} { set cdata [zlib deflate $data] } else { set cdata $data }
        set csize [string length $cdata]
        set nameb [encoding convertto utf-8 $name]
        set nlen  [string length $nameb]
        set lh [binary format a4sssssiiiss \
            "PK\x03\x04" 20 0 $method $dtime $ddate $crc $csize $usize $nlen 0]
        append out $lh $nameb $cdata
        set cd [binary format a4ssssssiiisssssii \
            "PK\x01\x02" 20 20 0 $method $dtime $ddate $crc $csize $usize $nlen 0 0 0 0 0 $offset]
        append central $cd $nameb
        incr offset [expr {[string length $lh] + $nlen + $csize}]
    }
    set n [llength $entries]
    set eocd [binary format a4ssssiis "PK\x05\x06" 0 0 $n $n [string length $central] $offset 0]
    return $out$central$eocd
}

# ---- ZIP reading: a pure Tcl/zlib reader for all versions ----
# (Deliberately NO zipfs: the pure reader behaves identically on 8.6 and 9.0 and
#  is independent of the zipfs mount-arg order, which changed between 9.0/9.1.)
proc odf::_readParts {path} {
    if {![file isfile $path]} { error "no such file: $path" }
    return [odf::_readZip $path]
}

proc odf::_readZip {path} {
    set fh [open $path rb]; set raw [read $fh]; close $fh
    set n [string length $raw]
    set eocd -1
    for {set i [expr {$n-22}]} {$i >= 0} {incr i -1} {
        if {[string range $raw $i [expr {$i+3}]] eq "PK\x05\x06"} { set eocd $i; break }
    }
    if {$eocd < 0} { error "not a ZIP (EOCD not found): $path" }
    binary scan [string range $raw [expr {$eocd+10}] [expr {$eocd+11}]] s total
    binary scan [string range $raw [expr {$eocd+16}] [expr {$eocd+19}]] i cdoff
    set total [expr {$total & 0xffff}]
    set cdoff [expr {$cdoff & 0xffffffff}]
    set parts {}; set p $cdoff
    for {set k 0} {$k < $total} {incr k} {
        if {[string range $raw $p [expr {$p+3}]] ne "PK\x01\x02"} { error "central directory entry expected" }
        binary scan [string range $raw [expr {$p+10}] [expr {$p+11}]] s method
        binary scan [string range $raw [expr {$p+20}] [expr {$p+27}]] ii csize usize
        binary scan [string range $raw [expr {$p+28}] [expr {$p+33}]] sss nlen elen clen
        binary scan [string range $raw [expr {$p+42}] [expr {$p+45}]] i lhoff
        set method [expr {$method & 0xffff}]
        set nlen [expr {$nlen & 0xffff}]; set elen [expr {$elen & 0xffff}]; set clen [expr {$clen & 0xffff}]
        set csize [expr {$csize & 0xffffffff}]
        set name [encoding convertfrom utf-8 [string range $raw [expr {$p+46}] [expr {$p+46+$nlen-1}]]]
        binary scan [string range $raw [expr {$lhoff+26}] [expr {$lhoff+29}]] ss lnlen lelen
        set lnlen [expr {$lnlen & 0xffff}]; set lelen [expr {$lelen & 0xffff}]
        set dstart [expr {$lhoff + 30 + $lnlen + $lelen}]
        set comp [string range $raw $dstart [expr {$dstart+$csize-1}]]
        if {$method == 0} { set data $comp } else { set data [zlib inflate $comp] }
        dict set parts $name $data
        incr p [expr {46 + $nlen + $elen + $clen}]
    }
    return $parts
}

package provide odf 0.9
