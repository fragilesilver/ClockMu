## ClockMu

An alarm clock for **[muOS](https://muos.dev/) Andromeda** on the **Anbernic RG35XX family** (all Allwinner H700 — Pro, Plus, H, SP, 2024).
Built with LÖVE2D on the shared **[fskit](#-built-on-fskit)** kit. Jacaranda-compatible.

Drew inspiration from [BitMuos](https://github.com/nvcuong1312/bltMuos) by [nvcuong1312](https://github.com/nvcuong1312).

<img width="640" height="480" alt="Main Screen" src="https://github.com/user-attachments/assets/f20cbf92-68a0-4413-8677-75872a1069dd" />

### 🚀 Features
- Set and manage multiple alarms
- Repeat options: daily, weekly (specific days), or once
- Snooze with custom durations (per alarm)
- Preset time picker (every 15 minutes)
- 8-colour in-app theme picker with light/dark balance
- Data persistence across reboots, independent of LÖVE's save-dir
- Letterboxed 640×480 render — safe on every RG35XX panel variant, and on HDMI-out

### 📥 Installation
1. Download the latest `.muxapp` from [Releases](https://github.com/fragilesilver/ClockMu/releases).
2. Copy it to `ARCHIVE/` on your SD card.
3. On the device: **Applications → Archive Manager**, select the file.
4. Launch from **Applications → ClockMu**.

### 🎮 Controls

#### Main Screen
| Button | Action |
|--------|--------|
| D-pad Up/Down | Navigate alarm list |
| **A** | Edit selected alarm |
| **X** | Toggle alarm on/off |
| **Y** | Add new alarm |
| **L1** | Delete selected alarm |
| **B** | Quit |

#### Edit Alarm
| Button | Action |
|--------|--------|
| Up/Down | Move between fields (Hour / Minute / Label / Repeat / Snooze / Enabled) |
| Left/Right | Change value (±1 for hour/min, cycle options for others) |
| **L1 / R1** | Change minute by ±10 |
| **A** (on Repeat field) | Toggle selected day on/off |
| **X** (on Repeat field) | Clear all days → set to "Once" |
| **Y** | Open preset time picker (every 15 min) |
| **A** (other fields) | Save alarm |
| **B** | Cancel |

<img width="640" height="480" alt="Edit Alarm" src="https://github.com/user-attachments/assets/3588e73f-14de-4fd9-9de6-1929ad093cdd" />
<br>
<img width="640" height="480" alt="Keyboard" src="https://github.com/user-attachments/assets/fd8f3256-7145-45cc-89b9-a87eae28d600" />

#### Preset Time Picker
| Button | Action |
|--------|--------|
| Up/Down | Scroll times |
| Left/Right | Jump page |
| **A** | Select time |
| **B** | Cancel |

#### When Alarm Rings
| Button | Action |
|--------|--------|
| **A** | Snooze (per alarm setting) |
| **B** | Dismiss |

<img width="640" height="480" alt="Alert" src="https://github.com/user-attachments/assets/a23ddbfa-3645-41f5-b1fa-833c9d0de528" />

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

<img width="640" height="480" alt="Bloody Red Theme" src="https://github.com/user-attachments/assets/ac3266be-8f14-422f-a66d-714d422908c6" />
<img width="640" height="480" alt="Forest Green Theme" src="https://github.com/user-attachments/assets/60808220-5e4b-4c50-8254-a30426a2b306" />
<img width="640" height="480" alt="Ocean Blue Theme" src="https://github.com/user-attachments/assets/4dc2f7f2-ad23-435c-ad97-cda530dda675" />

### 🧩 Built on fskit

ClockMu, [JarMu](https://github.com/fragilesilver/JarMu) and
[BatteryMu](https://github.com/fragilesilver/BatteryMu) share **fskit** — a small
LÖVE2D kit providing the letterboxed 640×480 screen, the theme model and palette,
fonts, glyphs, input abstraction and the header/footer chrome — so the three apps
look, feel and behave the same on every RG35XX variant.

### 🙏 Credits

- LÖVE2D aarch64 runtime by [Cebion/love2d_aarch64](https://github.com/Cebion/love2d_aarch64)
- Built for the muOS community

### 📄 Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).

---

Part of the **fragilesilver** muOS app family — [ClockMu](https://github.com/fragilesilver/ClockMu) · [JarMu](https://github.com/fragilesilver/JarMu) · [BatteryMu](https://github.com/fragilesilver/BatteryMu).
