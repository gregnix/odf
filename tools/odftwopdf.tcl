#!/usr/bin/env tclsh
#
# Batch-render + validate the ODF documents in a directory.
#
# Hardened against the LibreOffice headless hang (the ".odc never returns"
# problem and its follow-on "every later convert hangs too"):
#
#   1. Each soffice call runs under `timeout --kill-after`, so one stuck file
#      can never block the whole batch -- it is force-killed and REPORTED.
#   2. Each soffice call gets its own throwaway user profile
#      (-env:UserInstallation=file://...). A lingering / locked soffice.bin
#      from a previous file can no longer poison the rest via the
#      single-instance lock.
#
# Two PNG variants are produced on purpose, as two independent attempts:
#   - soffice direct  -> <base>.png      (first page; Draw/Impress are fine)
#   - PDF via pdftocairo -> <base>-N.png  (all pages; the reliable route for Writer)
# They have different names and do not clash.
#
# Philosophy: a failed or timed-out conversion is reported (FAIL / TIMEOUT),
# never silently swallowed. Standalone chart documents (.odc) are the usual
# TIMEOUT candidate -- a bare chart is not a page document; for charts the
# odfvalidator run below is the reliable check, and a visual render is best
# done by embedding the chart into a throwaway .odt.
#
# Args:  inDir  pdfDir  pngDir  timeoutSeconds
# Defaults: ../out ../out ../out 30
#
# Requires GNU coreutils `timeout` (Linux / macOS-with-coreutils).

package require Tcl 8.6-

# Resolve the default out/ relative to THIS script (tools/ -> repo/out),
# not relative to the current working directory -- so the tool works from
# any cwd, not only from inside tools/.
set repo   [file dirname [file dirname [file normalize [info script]]]]
set outDef [file join $repo out]
set inDir    [expr {[llength $argv] >= 1 ? [lindex $argv 0] : $outDef}]
set pdfDir   [expr {[llength $argv] >= 2 ? [lindex $argv 1] : $outDef}]
set pngDir   [expr {[llength $argv] >= 3 ? [lindex $argv 2] : $outDef}]
set timeoutS [expr {[llength $argv] >= 4 ? [lindex $argv 3] : 30}]

file mkdir $pdfDir
file mkdir $pngDir

# Documents the project emits; .odc/.odm are included.
# Add template globs if your out/ holds them: *.ott *.ots *.otg *.otc *.otm
set patterns [list *.odt *.ods *.odg *.odc *.odm *.ott *.ots *.otg *.otm]

# Resolve external commands once; skip-on-missing with a clear message.
set soffice [auto_execok soffice]
if {$soffice eq ""} { set soffice [auto_execok libreoffice] }
if {$soffice eq ""} {
    puts stderr "WARN: soffice/libreoffice not on PATH -- skipping all LibreOffice steps"
}
set timeoutBin [auto_execok timeout]
if {$timeoutBin eq "" && $soffice ne ""} {
    puts stderr "WARN: GNU `timeout` not on PATH -- soffice calls run UNGUARDED (may hang)"
}

# Run a command, classifying the outcome. Returns 1 on success, 0 otherwise.
# timeout(1) exits 124 on TERM-timeout, 128+9=137 when it had to SIGKILL.
proc run {label cmd} {
    puts "RUN ($label): $cmd"
    if {[catch {exec {*}$cmd} err opts]} {
        set code [dict get $opts -errorcode]
        if {[lindex $code 0] eq "CHILDSTATUS"
            && [lindex $code 2] in {124 137}} {
            puts stderr "TIMEOUT ($label): killed after ${::timeoutS}s"
        } else {
            puts stderr "FAIL ($label): $err"
        }
        return 0
    }
    return 1
}

# One isolated, time-boxed soffice conversion.
proc sofficeConvert {fmt outdir file} {
    if {$::soffice eq ""} { return 0 }
    # Unique throwaway profile so a stuck/locked instance can't carry over.
    set tmpRoot [expr {[info exists ::env(TMPDIR)] ? $::env(TMPDIR) : "/tmp"}]
    set prof [file normalize \
                  [file join $tmpRoot .lo_prof_[pid]_[clock clicks -milliseconds]]]
    set inner [list {*}$::soffice --headless --norestore --nologo \
                   --nofirststartwizard \
                   -env:UserInstallation=file://$prof \
                   --convert-to $fmt --outdir $outdir $file]
    if {$::timeoutBin ne ""} {
        set cmd [list {*}$::timeoutBin --kill-after=10s ${::timeoutS}s {*}$inner]
    } else {
        set cmd $inner
    }
    set ok [run "soffice $fmt" $cmd]
    catch {file delete -force $prof}
    return $ok
}

foreach pattern $patterns {
    foreach f [glob -nocomplain -directory $inDir $pattern] {
        puts "\n=== $f ==="

        # Disambiguate outputs by source format: soffice names its output after
        # the input ROOTNAME only (tpl.ott -> tpl.pdf), so two sources sharing a
        # stem (tpl.ott / tpl.ots / tpl.otg, or master.odg / master.odm) would
        # overwrite each other's PDF/PNG/TXT. We append the source extension to
        # the stem (tpl-ott, tpl-ots, ...) and rename soffice's output to match.
        set stem [file rootname [file tail $f]]
        set ext  [string range [file extension $f] 1 end]
        set tag  "${stem}-${ext}"
        set loPdf   [file join $pdfDir "${stem}.pdf"]   ;# what soffice writes
        set loPng   [file join $pngDir "${stem}.png"]
        set pdfFile [file join $pdfDir "${tag}.pdf"]    ;# disambiguated target
        set pngBase [file join $pngDir $tag]

        # PDF via LibreOffice (time-boxed, isolated profile).
        set pdfOk [sofficeConvert pdf $pdfDir $f]
        if {$pdfOk && [file exists $loPdf]} { file rename -force $loPdf $pdfFile }

        # PNG direct via LibreOffice (independent attempt).
        sofficeConvert png $pngDir $f
        if {[file exists $loPng]} { file rename -force $loPng [file join $pngDir "${tag}.png"] }

        # PNG from the produced PDF -- only if the PDF actually exists.
        if {$pdfOk && [file exists $pdfFile]} {
            run "pdftocairo" [list pdftocairo -png $pdfFile $pngBase]
        } else {
            puts stderr "SKIP (pdftocairo): no PDF for $tag"
        }

        # Schema validation -- independent of soffice, so it always runs.
        # This is the reliable conformance check, incl. for .odc charts.
        run "odfval" \
            [list tclodfval.tcl $f [file join $pdfDir "${tag}.txt"]]
    }
}
