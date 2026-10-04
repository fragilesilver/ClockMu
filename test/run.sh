#!/bin/sh
# Headless: alarm logic, then the UI smoke against a throwaway data dir.
cd "$(dirname "$0")/.." || exit 1
luajit test/alarm_test.lua || exit 1
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT
CLOCKMU_DATA="$D" DATA="$D" exec luajit test/ui_smoke.lua
