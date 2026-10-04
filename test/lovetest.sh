#!/bin/sh
# Run the REAL ClockMu in LÖVE 11.5 on this PC (minimised window) with a fake clock
# and a throwaway data dir. Needs ~/.local/bin/love11 (see apps/fskit/tools/README.md).
#   sh test/lovetest.sh shots [OUT_DIR]     screenshots: sizes x themes (SIZES=, THEMES=)
#   sh test/lovetest.sh persist             the theme survives a restart (+ 1.0 "6" / "7" settings files)
set -eu
APP="$(cd "$(dirname "$0")/.." && pwd)"
LOVE="${LOVE:-$HOME/.local/bin/love11}"
[ -x "$LOVE" ] || { echo "SKIP: no LÖVE at $LOVE"; exit 0; }
MODE="${1:-shots}"; OUT="${2:-/tmp/clockmu-shots}"
PROJ="$(mktemp -d)"; DATA="$(mktemp -d)"
trap 'rm -rf "$PROJ" "$DATA"' EXIT
( cd "$APP" && tar --exclude=./.git --exclude=./dist --exclude=./test -cf - . ) | tar -C "$PROJ" -xf -
mv "$PROJ/main.lua" "$PROJ/app_main.lua"
cp "$APP/test/love/main.lua" "$PROJ/main.lua"
seed() {   # 5 alarms: weekdays, a long label, a disabled one-shot, weekends, every day
    cat > "$DATA/alarms.txt" <<AL
7|30|Wake Up|31|1|2
8|0|School run with a very long label|31|1|1
12|15|Lunch|0|0|1
18|45|Gym|96|1|3
22|0|Bedtime|127|1|1
AL
}
run() { env CLOCKMU_DATA="$DATA" CLOCKMU_WINDOWED="$SZ" "$@" timeout 120 "$LOVE" "$PROJ" 2>&1; }
case "$MODE" in
  shots)
    mkdir -p "$OUT"; runs=0; done_=0
    for SZ in ${SIZES:-640x480 720x480 720x720}; do
        for TH in ${THEMES:-mustard-dark}; do
            for H in shots empty; do
                rm -f "$DATA/settings.txt" "$DATA/alarms.txt"
                [ "$H" = shots ] && seed
                D="$(mktemp -d)"; runs=$((runs+1)); LOG="$D/log.txt"
                run HARNESS=$H SHOT_OUT="$D" SHOT_THEME="$TH" > "$LOG" || true
                if grep -q '^HARNESS DONE' "$LOG"; then done_=$((done_+1)); else sed "s/^/[$SZ $TH $H] /" "$LOG" | head -20; fi
                for f in "$D"/*_"$SZ".png; do
                    [ -f "$f" ] || continue
                    b="$(basename "$f" "_$SZ.png")"; mv "$f" "$OUT/${b}_${TH}_$SZ.png"
                done
                rm -rf "$D"
            done
        done
    done
    echo "$(ls "$OUT" | wc -l) images; $done_ of $runs runs completed every screen"
    [ "$done_" -eq "$runs" ] ;;
  persist)
    SZ=640x480; pass=0; fail=0
    ck() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 (got '$2', want '$3')"; fi; }
    rm -f "$DATA/settings.txt"; seed
    o=$(run HARNESS=persist1 | grep '^THEME'); ck "picker keeps Ocean Light" "$o" "THEME ocean-light scene main"
    ck "the id is saved to settings.txt" "$(cat "$DATA/settings.txt")" "ocean-light"
    o=$(run HARNESS=persist2 | grep '^THEME'); ck "a restart comes back on Ocean Light" "$o" "THEME ocean-light"
    printf '7' > "$DATA/settings.txt"
    o=$(run HARNESS=legacy | grep '^THEME'); ck "a 1.0 settings file '7' migrates to Andromeda White" "$o" "THEME andromeda-light"
    printf '6' > "$DATA/settings.txt"
    o=$(run HARNESS=legacy | grep '^THEME'); ck "a 1.0 settings file '6' (Funky) migrates to Funky Dark" "$o" "THEME funky-dark"
    ck "alarms were not touched" "$(wc -l < "$DATA/alarms.txt")" "5"
    echo "$pass passed, $fail failed"; [ "$fail" -eq 0 ] ;;
  *) echo "usage: $0 shots [out] | persist"; exit 2 ;;
esac
