## validator-jar.tcl -- shared helpers for locating the odfvalidator jar and
## the Java runtime. Sourced by odfvalidate.tcl (the repo/CI batch validator).
##
## tclodfval.tcl deliberately does NOT source this: it is meant to be a single
## self-contained command on the PATH (script + jar copied together), so it
## keeps its own small copy of the symlink-resolving lookup. If a third
## validator consumer appears, prefer this module over copying again.

namespace eval vjar {}

## Directory of $script, with symlinks resolved -- so lookups work when the
## script is reached via the PATH (possibly as a symlink) from any cwd.
proc vjar::scriptDir {script} {
    set self [file normalize $script]
    for {set i 0} {[file type $self] eq "link" && $i < 32} {incr i} {
        set link [file readlink $self]
        set self [file normalize [expr {[file pathtype $link] eq "relative"
                                        ? [file join [file dirname $self] $link]
                                        : $link}]]
    }
    return [file dirname $self]
}

## Locate the odfvalidator jar. Order: explicit arg, ODFVALIDATOR_JAR env,
## then glob beside the script / in ./validator/ / in the parent dir.
## Errors out (does not silently skip) when nothing is found.
proc vjar::find {script explicit} {
    if {$explicit ne ""} {
        if {![file exists $explicit]} { error "jar not found: $explicit" }
        return $explicit
    }
    if {[info exists ::env(ODFVALIDATOR_JAR)] && [file exists $::env(ODFVALIDATOR_JAR)]} {
        return $::env(ODFVALIDATOR_JAR)
    }
    set here [vjar::scriptDir $script]
    foreach dir [list $here [file join $here validator] [file join $here ..]] {
        set hits [lsort [glob -nocomplain -directory $dir \
                             odfvalidator*jar-with-dependencies.jar]]
        if {[llength $hits]} { return [lindex $hits end] }
    }
    error "odfvalidator jar not found.\
        \n  Set ODFVALIDATOR_JAR, pass the jar path as an argument,\
        \n  or place odfvalidator-*-jar-with-dependencies.jar in [file join $here validator]/"
}

## Resolve the Java launcher; error out with a clear message if missing
## (skip-on-missing parity with odftwopdf's soffice/timeout checks).
proc vjar::java {} {
    set j [auto_execok java]
    if {$j eq ""} {
        error "java not on PATH -- the odfvalidator jar needs a Java runtime.\
            \n  Install a JRE/JDK, or put java on the PATH."
    }
    return $j
}
