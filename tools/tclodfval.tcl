#!/usr/bin/env tclsh
##
## tclodfval.tcl -- validate one ODF file with the odfvalidator jar that sits
## next to this script, and write the full report to a file.
##
## Designed to live in the PATH: the jar is located relative to THIS script
## (resolving symlinks), not relative to the current working directory.
##
## Usage:
##   tclodfval.tcl <odffile> ?outfile?
##
## Writes the validator report (generator + conformance verdict + errors +
## warnings) to <outfile> (default: "<odffile-without-ext>-odfval.txt" beside
## the input) and prints that report path. Exit code: 0 if the document is
## conformant, 1 if not, 2 on usage / setup errors.
##

if {[llength $argv] < 1} {
    puts stderr "usage: tclodfval.tcl <odffile> ?outfile?"
    exit 2
}
set inFile [lindex $argv 0]
if {![file exists $inFile]} {
    puts stderr "file not found: $inFile"
    exit 2
}

# This script's own directory, with symlinks resolved -- so it works when the
# script is reached via the PATH (possibly as a symlink) from any directory.
proc scriptDir {} {
    set self [file normalize [info script]]
    for {set i 0} {[file type $self] eq "link" && $i < 32} {incr i} {
        set link [file readlink $self]
        set self [file normalize [expr {[file pathtype $link] eq "relative"
                                        ? [file join [file dirname $self] $link]
                                        : $link}]]
    }
    return [file dirname $self]
}

# The bundled jar sits next to the script. Glob to tolerate version bumps.
set jars [lsort [glob -nocomplain -directory [scriptDir] \
                     odfvalidator-*-jar-with-dependencies.jar]]
if {![llength $jars]} {
    puts stderr "odfvalidator jar not found next to script in [scriptDir]"
    exit 2
}
set jar [lindex $jars end]

# Report path: 2nd argument, else "<input>-odfval.txt" beside the input.
set outFile [expr {[llength $argv] >= 2
                   ? [lindex $argv 1]
                   : "[file rootname $inFile]-odfval.txt"}]

# Java runtime: clear message instead of a cryptic exec error if missing.
set java [auto_execok java]
if {$java eq ""} {
    puts stderr "java not on PATH -- the odfvalidator jar needs a Java runtime."
    exit 2
}

# Run the validator verbose and capture stdout+stderr into the report file.
# The validator exits non-zero on non-conformance; that is captured, not fatal.
catch {exec {*}$java -jar $jar -v $inFile >& $outFile}

# Read the report back to derive the verdict + exit code.
set ch [open $outFile]; set report [read $ch]; close $ch
set conformant [expr {![string match {*NOT conformant*} $report]}]

puts $outFile
exit [expr {$conformant ? 0 : 1}]
