#!/bin/sh
# HELP: Alarm clock with up to 5 alarms and snooze, for the whole RG35XX family
# ICON: clockmu
# GRID: ClockMu

. /opt/muos/script/var/func.sh

APP_NAME="ClockMu"

# ---------------------------------------------------------------------------
# Locate the app directory. On Andromeda the "application" location is bind-
# mounted from SD1/SD2, so prefer $MUOS_SHARE_DIR; fall back to the store and
# finally to the legacy rom-mount path so this launcher also works on Jacaranda.
# ---------------------------------------------------------------------------
APP_SUBPATH="application/$APP_NAME"
APP_DIR="$MUOS_SHARE_DIR/$APP_SUBPATH"
[ -d "$APP_DIR" ] || APP_DIR="$MUOS_STORE_DIR/$APP_SUBPATH"
[ -d "$APP_DIR" ] || APP_DIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/$APP_SUBPATH"

BIN_DIR="$APP_DIR/bin"
LOVE_BIN="$BIN_DIR/love"
LOG_FILE="$APP_DIR/clockmu.log"

# Persistent, always-writable store for alarms + settings. Written from Lua with
# plain io (see config.lua) so persistence never depends on LÖVE's save-dir
# resolution or bind-mount behaviour.
DATA_DIR="$APP_DIR/save"
mkdir -p "$DATA_DIR"
export CLOCKMU_DATA="$DATA_DIR"

# Render target: whatever muOS is driving (internal 640x480, or 1280x720 on
# HDMI). Passed to LÖVE as an argument; the app letterboxes a 640x480 canvas
# onto it, so every RG35XX variant and HDMI-out are covered.
SCREEN_W="$(GET_VAR device mux/width)"
SCREEN_H="$(GET_VAR device mux/height)"
SCREEN_RES="${SCREEN_W:-640}x${SCREEN_H:-480}"

CAFFEINE="$(command -v CAFFEINE 2>/dev/null || true)"

# ---------------------------------------------------------------------------
# System volume: an alarm must be audible. Force the PipeWire sink to 100% and
# unmuted while ClockMu runs, then restore the user's level/mute on exit. We
# talk to wpctl directly so muOS's own saved-volume config is never touched.
# ---------------------------------------------------------------------------
HAVE_WPCTL=0
command -v wpctl >/dev/null 2>&1 && HAVE_WPCTL=1
PREV_VOL=""
PREV_MUTE=0

VOL_READ() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '
        { for (i = 1; i <= NF; i++) if ($i ~ /^[0-9.]+$/) { print int($i * 100 + 0.5); exit } }'
}
VOL_MUTED() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED" && echo 1 || echo 0
}

VOLUME_MAX() {
    [ "$HAVE_WPCTL" = "1" ] || return 0
    PREV_VOL="$(VOL_READ)"
    PREV_MUTE="$(VOL_MUTED)"
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 100% >/dev/null 2>&1
    wpctl set-mute   @DEFAULT_AUDIO_SINK@ 0     >/dev/null 2>&1
}

VOLUME_RESTORE() {
    [ "$HAVE_WPCTL" = "1" ] || return 0
    [ -n "$PREV_VOL" ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ "${PREV_VOL}%" >/dev/null 2>&1
    [ "$PREV_MUTE" = "1" ] && wpctl set-mute @DEFAULT_AUDIO_SINK@ 1 >/dev/null 2>&1
    [ -n "$CAFFEINE" ] && "$CAFFEINE" off
}

# Restore volume (and caffeine) however the app ends -- clean quit or signal.
trap 'VOLUME_RESTORE' EXIT INT TERM HUP

SET_ENV() {
    export HOME="$APP_DIR"
    export XDG_DATA_HOME="$APP_DIR/.local/share"
    export XDG_CONFIG_HOME="$APP_DIR/.local/config"
    export SDL_GAMECONTROLLERCONFIG_FILE="/usr/lib/gamecontrollerdb.txt"
    export LD_LIBRARY_PATH="$BIN_DIR/libs.aarch64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
}

RUN() {
    [ -n "$CAFFEINE" ] && "$CAFFEINE" on
    SET_VAR "system" "foreground_process" "love"
    "$LOVE_BIN" . "$SCREEN_RES" >"$LOG_FILE" 2>&1
}

# Stop background music if muOS is playing any.
command -v STOP_MUSIC >/dev/null 2>&1 && STOP_MUSIC
killall -q playbgm.sh mpg123 2>/dev/null || true

echo app >/tmp/act_go

chmod +x "$LOVE_BIN" 2>/dev/null || true
cd "$APP_DIR" || exit 1

SET_ENV
VOLUME_MAX
RUN
# VOLUME_RESTORE runs via the trap
