## ClockMu
[![Licence: GPL-3.0 with NC Exception](https://shields.io/badge/license-GPL--3.0_--_Non--Commercial-red?logo=github)](./LICENSE)

An alarm clock for **[muOS](https://muos.dev/) Andromeda** on the **Anbernic RG35XX family** (all Allwinner H700 - Pro, Plus, H, SP, 2024).
Built with LÖVE2D on the shared **[fskit](#-built-on-fskit)** kit. Jacaranda-compatible.

Drew inspiration from [BitMuos](https://github.com/nvcuong1312/bltMuos) by [nvcuong1312](https://github.com/nvcuong1312).


### 🚀 Features
- Up to 5 alarms: daily, specific weekdays, or once
- Snooze per alarm (5 / 10 / 15 min); a snoozed alarm rings again when it runs out
- Preset time picker (every 15 minutes) and a label picker with a full on-screen
  keyboard (letters and symbols) for custom labels
- Ten themes (Mustard, Crimson, Ocean, Funky, Andromeda, each dark and light)
- Layouts for 640x480 (RG35XX family), 720x480 and 720x720 (the last two are
  checked by screenshots only)
- Data persistence across reboots, independent of LÖVE's save-dir

### 📥 Installation
1. Download the latest `.muxapp` from [Releases](https://github.com/fragilesilver/ClockMu/releases).
2. Copy it to `ARCHIVE/` on your SD card.
3. On the device: **Applications → Archive Manager**, select the file.
4. Launch from **Applications → ClockMu**.

### 🎮 Controls

Same button contract as BatteryMu, SwapMu and JarMu: **A** confirm, **B** back
(and "Quit?" on the first screen), **X** second action, **Y** add / option,
**L1/R1** one page, **L2/R2** jump 100, **SELECT** settings.

#### Alarm list
| Button | Action |
|--------|--------|
| Up/Down, **L1/R1**, **L2/R2** | Move / page / jump |
| **A** | Edit selected alarm |
| **X** | Toggle alarm on/off |
| **Y** | Add new alarm (asks to delete one when 5 exist) |
| **START** | Delete selected alarm (asks first) |
| **SELECT** | Theme (Y toggles dark / light) |
| **B** | Quit (asks first) |

#### Edit alarm
| Button | Action |
|--------|--------|
| Up/Down | Move between fields (Hour / Minute / Label / Repeat days / Snooze / Enabled) |
| Left/Right | Change value (±1 for hour/min, cycle options for others) |
| **L1 / R1** | Hour: ±1 h. Minute: ±10 min |
| **A** on Label | Open the label picker |
| **A** on Repeat days | Toggle the selected day |
| **X** on Repeat days | Clear all days (Once) |
| **A** on other fields, **START** | Save |
| **Y** | Preset time picker |
| **B** | Cancel |

#### Pickers
Preset times and labels are lists: Up/Down, **L1/R1** page, **L2/R2** jump,
**A** select, **B** cancel. "Custom..." in the label picker opens the keyboard:
d-pad moves, **A** types, **X** deletes, **Y** shift, **L1/R1** letters / symbols,
**START** done, **B** cancel.

#### When an alarm rings
| Button | Action |
|--------|--------|
| **A** | Snooze (per alarm setting) |
| **B** | Dismiss |

An alarm outranks everything: it takes over the screen even if a dialog or the
keyboard is open. (A and B are ignored for the first third of a second so a
button pressed just as it rings cannot dismiss it.)

### 💾 Data Persistence

Alarms and settings are written to `save/` under the app directory (via the
`CLOCKMU_DATA` path the launcher exports) whenever you add, edit, delete, or
dismiss an alarm. They persist across reboots and app updates, and don't depend
on LÖVE's save-dir resolution under muOS bind-storage.

### 📝 Notes

- Alarms only fire while ClockMu is the muOS foreground app.
- One-shot alarms (Repeat: Once) disable themselves after firing.
- Snoozed alarms resume ringing after the chosen snooze duration.
- The launcher maxes system volume on entry and restores your previous level on exit.

### 🎨 Themes

Eight in-app colour themes (this is ClockMu's own picker, not a muOS theme):
Bloody Red, Forest Green, Funky Purple, Intense Orange, Midnight Black,
Ocean Blue, Yoga White, and the default Mustard.


### 🧩 Built on fskit

ClockMu, [JarMu](https://github.com/fragilesilver/JarMu) and
[BatteryMu](https://github.com/fragilesilver/BatteryMu) share **fskit** - a small
LÖVE2D kit providing the letterboxed 640×480 screen, the theme model and palette,
fonts, glyphs, input abstraction and the header/footer chrome - so the three apps
look, feel and behave the same on every RG35XX variant.

### 🙏 Credits

- LÖVE2D aarch64 runtime by [Cebion/love2d_aarch64](https://github.com/Cebion/love2d_aarch64)
- Built for the muOS community

### 📄 Licence

This project is licensed under the **GNU General Public License v3.0 (or later)** with a strict **Non-Commercial Exception**. 

* **For Users & Devs:** You are completely free to use, share, study, and modify this app for personal, non-commercial use.
* **For Commercial Sellers:** You are **STRICTLY PROHIBITED** from selling this app, charging a fee for it, or pre-loading it onto commercial handheld consoles, SD cards, or devices sold for profit. 

See the [LICENSE](./LICENSE) file for the full legal terms.

---

Part of the **fragilesilver** muOS app family - [ClockMu](https://github.com/fragilesilver/ClockMu) · [JarMu](https://github.com/fragilesilver/JarMu) · [BatteryMu](https://github.com/fragilesilver/BatteryMu).
