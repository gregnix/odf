#!/bin/sh
# Faehrt die odf-Test-Suite unter Tcl 8.6 UND Tcl 9 und zeigt beide Bilanzen.
# Interpreter ueberschreibbar:  TCLSH8=tclsh8.6 TCLSH9=tclsh9.0 ./run-both.sh
HERE=$(cd "$(dirname "$0")" && pwd)
RUNNER="$HERE/tests/run-all.tcl"
RC=0
for sh in "${TCLSH8:-tclsh}" "${TCLSH9:-tclsh9.0}"; do
    if command -v "$sh" >/dev/null 2>&1; then
        echo "######## $sh ($($sh <<'V'
puts [info patchlevel]
V
)) ########"
        "$sh" "$RUNNER" || RC=1
        echo
    else
        echo "######## $sh nicht gefunden -> uebersprungen ########"; echo
    fi
done
exit $RC
