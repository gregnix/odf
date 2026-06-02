#!/usr/bin/env tclsh
##
## odfvalidate.tcl -- validate ODF files with the ODF Toolkit odfvalidator.
##
## Sibling of odftwopdf.tcl: validates the documents in a directory (default
## ../out) against their declared ODF version using the official odfvalidator
## (java -jar). Prints a PASS/FAIL line per file and a summary; exits non-zero
## if any file is non-conformant (usable in CI / a check target).
##
## Usage:
##   tclsh odfvalidate.tcl ?inDir? ?jarPath?
##
## The validator jar is located, in order:
##   1. the jarPath argument, if given
##   2. the ODFVALIDATOR_JAR environment variable
##   3. odfvalidator-*-jar-with-dependencies.jar in this script's dir,
##      in ./validator/ beside it, or in the repo root
## If none is found the tool stops with a clear message (no silent skip).
##

# Shared jar/java lookup (P6): one source of truth, also used by future tools.
source [file join [file dirname [file normalize [info script]]] validator-jar.tcl]

# Default out/ is resolved relative to THIS script (tools/ -> repo/out),
# not to the current working directory (P2).
set repo   [file dirname [file dirname [file normalize [info script]]]]
set inDir  [expr {[llength $argv] >= 1 ? [lindex $argv 0] : [file join $repo out]}]
set jarArg [expr {[llength $argv] >= 2 ? [lindex $argv 1] : ""}]

set patterns [list *.odt *.ods *.odg *.odc *.odm *.ott *.ots *.otg *.otm]


# Run the validator on one file; return its combined stdout+stderr.
proc validate {java jar f} {
    set tmp [file join [file dirname $f] ".odfval-[pid].tmp"]
    catch {exec {*}$java -jar $jar -w $f >& $tmp}
    set ch [open $tmp]; set out [read $ch]; close $ch
    file delete -- $tmp
    return $out
}

# Classify validator output: {conformant errors warnings}. Conformance is the
# absence of a "NOT conformant" verdict; counts come from the last summary line.
proc classify {out} {
    set conformant [expr {![string match {*NOT conformant*} $out]}]
    set errs "?"; set warns "?"
    foreach line [split $out \n] {
        if {[regexp {Info: (no errors|[0-9]+ error[s]?), (no warnings|[0-9]+ warning[s]?)} \
                 $line -> e w]} {
            set errs  [expr {$e eq "no errors"   ? 0 : [lindex $e 0]}]
            set warns [expr {$w eq "no warnings" ? 0 : [lindex $w 0]}]
        }
    }
    return [list $conformant $errs $warns]
}

if {[catch {vjar::find [info script] $jarArg} jar]} {
    puts stderr $jar
    exit 2
}
if {[catch {vjar::java} java]} { puts stderr $java; exit 2 }
puts "validator: $jar"
puts "directory: $inDir\n"

set files {}
foreach pattern $patterns {
    foreach f [glob -nocomplain -directory $inDir $pattern] { lappend files $f }
}
set files [lsort -unique $files]
if {![llength $files]} { puts "no ODF files in $inDir"; exit 0 }

set okCount 0; set badCount 0
foreach f $files {
    lassign [classify [validate $java $jar $f]] conformant errs warns
    if {$conformant} {
        incr okCount
        puts [format "PASS  %-32s (errors=%s warnings=%s)" [file tail $f] $errs $warns]
    } else {
        incr badCount
        puts [format "FAIL  %-32s (errors=%s warnings=%s)" [file tail $f] $errs $warns]
    }
}

puts "\n[expr {$okCount + $badCount}] files: $okCount conformant, $badCount non-conformant"
exit [expr {$badCount ? 1 : 0}]
