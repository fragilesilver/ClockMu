# Changelog

All notable changes to ClockMu are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project follows [Semantic Versioning](https://semver.org/).

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
