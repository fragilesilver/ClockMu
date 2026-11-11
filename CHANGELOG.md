# Changelog

All notable changes to ClockMu are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project follows [Semantic Versioning](https://semver.org/).

## [3.0.0] - 2026-11-12

The muOS **Supernova (2612)** line, built from the same code as 2.0.0 (Andromeda 2606.0).
What was checked against the Supernova source (`repos/*` main, 2026-11-11), not yet on a device:
- **Install and launch unchanged**: a `.muxapp` still extracts to `MUOS/application` (now behind a
  storage-write lock), and the app is still started as `mux_launch.sh <app folder>`.
  `func.sh`, `GET_VAR` keys and the storage binds are the same.
- **CPU governors became performance levels**: this app never sets a governor, so muOS's
  per-app Performance setting applies as normal.
- No code change beyond 2.0.0.

## [2.0.0] - 2026-10-04

The muOS **Andromeda (2606.0)** line. The 3.x line, built from the same code, is for Supernova (2612).

The Andromeda release look, and a fix to snooze.

### Fixed
- **Launcher finds its own folder first.** muOS starts every app as `<app folder>/mux_launch.sh <app folder>` (the same on Andromeda 2606.0 and Supernova 2612). The launcher now uses that argument, then its own location, and only then probes the storage bind paths as before. An app installed somewhere the probe did not expect now still starts.
- **Snooze never rang again.** When the snooze ran out, 1.0 reset the alarm and
  then required the clock to equal the alarm's own time again, which it is not
  N minutes later; a snoozed alarm stayed silent until the same time the next
  day (a one-shot: never). It now rings the moment its snooze runs out.
- The theme is saved as an id; a 1.0 settings file (a bare number) is migrated.
  (`love.quit` now saves the id too.)

### Changed
- **Package layout**: the app folder is now at the **root of the `.muxapp`** (`ClockMu/...`), as current muOS expects (Archive Manager extracts the archive into `application/`); the old `mnt/mmc/MUOS/application/` prefix is gone. `test/build_check.sh` fails on any entry outside the app folder, and on links or special files, which muOS rejects.
- **UI rebuilt on fskit 0.3.0** (Bold muOS-style): solid accent header and focus
  block, Barlow type, a glyph footer that reacts to the buttons, a clock card with
  the date, and the alarm screen with a big flashing time.
- **Three screen sizes**: 640x480, 720x480 and 720x720; the launcher's `WxH` is
  honoured and every layout derives from the screen.
- **Ten themes** with the shared picker (5 colours, Y toggles dark / light).
- **Buttons follow the shared contract.** Delete moved from L1 to **START** (and
  asks first); Theme moved from R1 to **SELECT**; **L1/R1** now page, **L2/R2**
  jump 100, in every list. In the editor L1/R1 still step hour / minute.
- The editor, pickers and keyboard are full screens instead of modals; the
  preset time and label pickers are scrolling lists.
- **Keyboard**: the shared `fskit.ui.osk` with a symbols page (every ASCII
  symbol) replaces the built-in one; labels are limited to 20 characters as before.
- The alarm **takes over** if a dialog or the keyboard is open (it used to hide
  behind the Quit? dialog), and ignores A/B for 0.35 s.
- Adding a sixth alarm now explains the limit instead of doing nothing.

- **Alarm audio is re-asserted at every ring** (device only, `CLOCKMU_ASSERT_VOLUME`
  from the launcher): a fresh sound source, the PipeWire sink put back to 100 % and
  unmuted, and one line in `clockmu.log` (sink state, source playing) per ring. A
  silent snooze re-ring was reported; the logic plays in LÖVE on a PC, so this
  covers the volume / stale-stream causes and records what the device sees.

### Added
- **Hold a direction to keep moving** in lists, pickers and the keyboard (fskit 0.3.1): it repeats after 0.4 s; a held direction stops at the ends of a list instead of wrapping.
- `test/alarm_test.lua` (the alarm logic against a fake clock), a rewritten
  `test/ui_smoke.lua` (every scene, ringing, snooze, dialogs, persistence),
  `test/lovetest.sh` (the real app in LÖVE at 3 sizes, theme persistence and
  migration), `test/build_check.sh`, `test/all.sh`, `test/REGRESSION.md`.

## [1.0.0] - 2026-09-06

Reprogrammed for **muOS Andromeda 2606.0** and the full **RG35XX family**
(all Allwinner H700), Jacaranda-compatible. Feature-identical to the previous
release — this is a plumbing and consistency pass.

### Added
- Shared **fskit** kit: letterboxed 640×480 virtual canvas, theme model and
  palette, fonts, glyphs, input abstraction, header/footer chrome — shared with
  JarMu and BatteryMu.
- `love.resize` handling; render letterboxes instead of stretching, so every
  RG35XX panel variant (and HDMI-out) is correct.
- Andromeda launcher (`mux_launch.sh`): bind-storage app-dir resolution with a
  Jacaranda fallback, `HOME`/`XDG_*` export, `CAFFEINE` on/off with a cleanup
  trap, resolution passed from `GET_VAR device mux/width`.
- Volume: launcher maxes the PipeWire sink on entry and restores the previous
  level and mute state on exit (`wpctl`, trap-based).
- `CLOCKMU_DATA` persistence path: alarms and settings written via plain `io`,
  independent of LÖVE's save-dir under muOS bind-storage.
- `VERSION`, `.gitignore`, `build.sh`, this changelog.

### Fixed
- `snooze_idx` was written to disk but dropped on load — snooze duration now
  round-trips per alarm.
- `love.quit` was defined nested and never fired; moved to top level.

### Changed
- `Alarm.New` signature is now
  `New(hour, minute, label, repeat_days, enabled, snooze_idx)`.
- `mux_launch.ini` replaced with `mux_lang.ini`; launch metadata moved to
  `# HELP:` / `# ICON:` / `# GRID:` header comments (Andromeda convention).
- Removed the dead pre-LÖVE `src/*.c` scaffold.
