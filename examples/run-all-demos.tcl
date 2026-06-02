## examples/run-all-demos.tcl -- run every example that generates a document,
## populating out/ for a subsequent render/validate pass (tools/odftwopdf.tcl,
## tools/odfvalidate.tcl). Skips itself and read-only demos. Reports OK/FAIL
## per demo and a summary; exits non-zero if any demo fails.
##
## Each demo resolves its own output path via [info script], so this runner
## works from any cwd. Demos run in separate interpreters (exec), so one
## crashing demo cannot take down the rest.
##
## Usage:  tclsh run-all-demos.tcl ?-q?      (-q: only print failures + summary)

fconfigure stdout -encoding utf-8
set here  [file dirname [file normalize [info script]]]
set self  [file tail [info script]]
set tclsh [info nameofexecutable]
set quiet [expr {[lindex $argv 0] eq "-q"}]

# Collect generating demos: every *.tcl here except ourselves and readers.
set demos {}
foreach f [lsort [glob -nocomplain -directory $here *.tcl]] {
    set name [file tail $f]
    if {$name eq $self}              continue   ;# never run the runner itself
    if {[string match read-* $name]} continue   ;# readers need an existing file
    lappend demos $f
}

set ok 0; set fail 0; set failed {}
foreach demo $demos {
    set name [file tail $demo]
    if {[catch {exec $tclsh $demo} out]} {
        puts "FAIL  $name"
        if {[string trim $out] ne ""} {
            puts "        [string map [list \n "\n        "] [string trim $out]]"
        }
        incr fail; lappend failed $name
    } else {
        if {!$quiet} { puts "ok    $name" }
        incr ok
    }
}

puts "\n[string repeat - 60]"
puts "demos: [llength $demos]   ok $ok   FAIL $fail"
if {$fail} { puts "failed: [join $failed {, }]" }
exit [expr {$fail ? 1 : 0}]
