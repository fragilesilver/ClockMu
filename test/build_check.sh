#!/bin/sh
# The .muxapp must carry every file the app reads at runtime, and nothing that is
# only for development or the user's own data.   sh test/build_check.sh
set -u
APP="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP"
sh build.sh >/dev/null || { echo "build failed"; exit 1; }
PKG="dist/ClockMu-$(cat VERSION).muxapp"
LIST="$(unzip -Z1 "$PKG")"
B="ClockMu"                       # the app folder at the root of the archive
pass=0; fail=0
need() { if printf '%s\n' "$LIST" | grep -qx "$B/$1"; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: missing $1"; fi; }
for f in main.lua alarm.lua config.lua conf.lua mux_launch.sh mux_lang.ini bin/love Assets/Sound/alarm.ogg \
         fskit/VERSION fskit/init.lua fskit/screen.lua fskit/themes.lua fskit/ui/osk.lua fskit/ui/themepicker.lua \
         fskit/ui/card.lua fskit/ui/textview.lua \
         fskit/assets/font/Barlow-SemiBold.ttf fskit/assets/font/Barlow-Medium.ttf \
         fskit/assets/font/BarlowCondensed-ExtraBold.ttf fskit/assets/font/Barlow-OFL.txt fskit/assets/font/NotoSans-OFL.txt \
         fskit/assets/font/Bold.ttf fskit/assets/font/Regular.ttf \
         fskit/assets/glyph/a.png fskit/assets/glyph/start.png fskit/assets/glyph/select.png fskit/assets/glyph/l1.png glyph/clockmu.png glyph/clockmu-logo.png; do need "$f"; done
# layout: everything under the app folder (no mnt/mmc/... prefix: muOS extracts the archive INTO application/)
if printf '%s\n' "$LIST" | awk -v b="$B/" 'index($0, b) != 1 { bad = 1 } END { exit !bad }'; then
    fail=$((fail+1)); echo "  FAIL: entries outside the $B/ folder (old mnt/mmc/... layout?)"
else pass=$((pass+1)); fi
# muOS refuses archives with links or special files
if unzip -Zl "$PKG" | awk '$1 ~ /^[-dbclps]/ { t = substr($1, 1, 1); if (t != "-" && t != "d") bad = 1 } END { exit !bad }'; then
    fail=$((fail+1)); echo "  FAIL: links or special files in the package"
else pass=$((pass+1)); fi
if printf '%s\n' "$LIST" | grep -qE "^$B/(test|save|data|dist|fskit/(tools|test))/|\.git/"; then
    fail=$((fail+1)); echo "  FAIL: dev-only files or runtime data in the package"
else pass=$((pass+1)); fi
[ "$(unzip -p "$PKG" "$B/fskit/VERSION" | tr -d '\n ')" = "$(tr -d '\n ' < fskit/VERSION)" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "  FAIL: fskit version mismatch"; }
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
