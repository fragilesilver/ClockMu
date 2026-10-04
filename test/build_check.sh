#!/bin/sh
# The .muxapp must carry every file the app reads at runtime, and nothing that is
# only for development or the user's own data.   sh test/build_check.sh
set -u
APP="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP"
sh build.sh >/dev/null || { echo "build failed"; exit 1; }
PKG="dist/ClockMu-$(cat VERSION).muxapp"
LIST="$(unzip -Z1 "$PKG")"
B="mnt/mmc/MUOS/application/ClockMu"
pass=0; fail=0
need() { if printf '%s\n' "$LIST" | grep -qx "$B/$1"; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: missing $1"; fi; }
for f in main.lua alarm.lua config.lua conf.lua mux_launch.sh mux_lang.ini bin/love Assets/Sound/alarm.ogg \
         fskit/VERSION fskit/init.lua fskit/screen.lua fskit/themes.lua fskit/ui/osk.lua fskit/ui/themepicker.lua \
         fskit/ui/card.lua fskit/ui/textview.lua \
         fskit/assets/font/Barlow-SemiBold.ttf fskit/assets/font/Barlow-Medium.ttf \
         fskit/assets/font/BarlowCondensed-ExtraBold.ttf fskit/assets/font/Barlow-OFL.txt \
         fskit/assets/font/Bold.ttf fskit/assets/font/Regular.ttf \
         fskit/assets/glyph/a.png fskit/assets/glyph/start.png fskit/assets/glyph/select.png fskit/assets/glyph/l1.png glyph/clockmu.png glyph/clockmu-logo.png; do need "$f"; done
if printf '%s\n' "$LIST" | grep -qE "^$B/(test|save|data|dist|fskit/(tools|test))/|\.git/"; then
    fail=$((fail+1)); echo "  FAIL: dev-only files or runtime data in the package"
else pass=$((pass+1)); fi
[ "$(unzip -p "$PKG" "$B/fskit/VERSION" | tr -d '\n ')" = "$(tr -d '\n ' < fskit/VERSION)" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "  FAIL: fskit version mismatch"; }
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
