#!/bin/sh
# Everything ClockMu has: the alarm logic, the headless UI smoke, the real app in
# LÖVE (theme persistence + migration, every screen at three sizes), and the
# package contents.   sh test/all.sh
cd "$(dirname "$0")/.." || exit 1
fail=0
run() { label=$1; shift; out=$("$@" 2>&1); rc=$?; printf '%-30s %s\n' "$label" "$(printf '%s\n' "$out" | tail -1)"
        [ $rc -eq 0 ] || { fail=1; printf '%s\n' "$out" | grep -E "FAIL|rror" | head -10 | sed 's/^/    /'; }; }
run "alarm logic"               luajit test/alarm_test.lua
run "headless UI smoke"         sh test/run.sh
run "theme persistence (LÖVE)"  sh test/lovetest.sh persist
run "all screens x 3 sizes"     sh test/lovetest.sh shots "${SHOT_OUT:-/tmp/clockmu-shots}"
run "package contents"          sh test/build_check.sh
[ $fail -eq 0 ] && echo "ALL PASSED" || echo "SOMETHING FAILED"
exit $fail
