# ThermalAtlas - User Manual

<p align="center">
  <img src="Resources/IconSource/ThermalAtlas-LiquidGlass.png" width="150" alt="ThermalAtlas app icon">
</p>

<p align="center">
  <strong>Lightweight, privacy-friendly temperature monitoring for Apple silicon</strong><br>
  CPU - GPU - internal SSD - external SSDs
</p>

<p align="center">
  <a href="MANUAL.de.md">Deutsches Handbuch</a> - <a href="README.md">Back to the English home page</a>
</p>

---

## 1. What is ThermalAtlas?

ThermalAtlas is a compact macOS menu bar app for Apple-silicon Macs. It shows genuine temperature readings for CPU, GPU, the internal SSD and every detected physical external SSD when macOS or the drive controller exposes them.

The app is deliberately focused on monitoring. It changes **no fan control, performance parameter, power setting or system setting**. Values are never estimated: when no real sensor or SMART value is available, ThermalAtlas displays **Not available**.

### Key characteristics

| Area | Behavior |
| --- | --- |
| CPU | Read-only Apple-silicon SMC sensors; readable sensors are averaged |
| GPU | Read-only Apple-silicon SMC sensors; readable zones are averaged |
| Internal SSD | SMART temperature, status and health only when macOS exposes real data |
| External SSDs | Each physical external SSD is shown separately when macOS identifies it |
| Refresh | User-selectable every 1, 2, 3 or 4 seconds; default: 2 seconds |
| Storage | The chosen theme, refresh interval and display language are stored locally |
| Network | No network feature is required for temperature monitoring |
| Telemetry | No telemetry or analytics services |

---

## 2. The app interface

The screenshots in this manual show the current ThermalAtlas interface. The displayed SSD names, temperatures and health figures are examples from the captured Mac; the number and names of external SSD cards vary by connected hardware.

<p align="center">
  <img src="Resources/Screenshots/classic.png" width="430" alt="ThermalAtlas Classic interface with CPU, GPU, internal SSD and two external SSD cards">
</p>

### What you see in the window

**Temperature cards**  
CPU and GPU cards show the average of the readable matching sensors. Each SSD card shows the real drive or mounted-volume name. The current temperature is shown on the right.

**SSD status and health**
When macOS supplies it, an SSD card shows `SMART: Verified` and a separate remaining-health percentage. The percentage is derived only from the drive's NVMe `PERCENTAGE_USED` data. If SMART data or that field is absent, ThermalAtlas does not invent a status or percentage.

**Last real GPU value**
If a short GPU SMC read fails, ThermalAtlas can retain the last previously verified real GPU reading briefly. The orange label in the Liquid Glass screenshot makes this explicit; it is not an estimate and expires after a short period.

<p align="center">
  <img src="Resources/Screenshots/liquid-glass.png" width="430" alt="ThermalAtlas Liquid Glass interface marking a last verified real GPU value">
</p>

**Color status indicator**

| Color | Temperature range | Meaning |
| --- | ---: | --- |
| Green | below 55 C | cool / normal range |
| Orange | 55 to below 75 C | elevated temperature |
| Red | 75 C and above | high temperature range |
| Gray | no reading | no real temperature value available |

The colors are a quick visual guide only. ThermalAtlas does not change anything on the Mac because of these indicators.

**Updated time**  
The bottom of the window shows the time of the latest accepted sensor snapshot.

---

## 3. Menu bar display

After launch, ThermalAtlas appears as a thermometer in the macOS menu bar. Next to it, the app shows the **highest currently available temperature** as a whole number.

This is not a separate sensor. ThermalAtlas selects the highest available value from the currently displayed measurement groups. Clicking the menu bar item opens the ThermalAtlas window.

---

## 4. Controls and shared menu

The circular **ellipsis** button in the footer opens one shared menu. It keeps all secondary actions together without adding extra buttons to the temperature display.

<p align="center">
  <img src="Resources/ManualScreenshots/shared-menu.png" width="360" alt="ThermalAtlas shared menu in English with Themes, Scan Refresh, Language, links, manuals, Activity Monitor and quit">
</p>

### Themes

Choose **Themes** in the shared menu to select an appearance. The selected item has a checkmark.

<p align="center">
  <img src="Resources/ManualScreenshots/themes-menu.png" width="232" alt="ThermalAtlas Themes menu with Classic, Liquid Glass, Aurora and Ember">
</p>

- **Classic** - restrained, system-like appearance
- **Liquid Glass** - adaptive system material with glass surfaces; it follows macOS light and dark appearance and uses an opaque fallback when Reduce Transparency is enabled
- **Aurora** - dark blue and purple tones
- **Ember** - warm red and orange tones

Changing the theme affects appearance only, not sensor logic. The selection is stored locally. All four appearances show the same sensor data.

| Classic | Liquid Glass |
| --- | --- |
| <img src="Resources/Screenshots/classic.png" width="300" alt="ThermalAtlas Classic theme"> | <img src="Resources/Screenshots/liquid-glass.png" width="300" alt="ThermalAtlas Liquid Glass theme"> |
| **Aurora** | **Ember** |
| <img src="Resources/Screenshots/aurora.png" width="300" alt="ThermalAtlas Aurora theme"> | <img src="Resources/Screenshots/ember.png" width="300" alt="ThermalAtlas Ember theme"> |

### Scan Refresh

Choose **Scan Refresh** to select 1, 2, 3 or 4 seconds. The default is 2 seconds and the current choice has a checkmark.

<p align="center">
  <img src="Resources/ManualScreenshots/scan-refresh-menu.png" width="238" alt="ThermalAtlas Scan Refresh menu with one to four second options">
</p>

A shorter interval makes the display react sooner to real changes, but asks the read-only sensor sources more often. A longer interval reduces those checks. The interval affects only how often ThermalAtlas asks for new readings; it does not alter the Mac's cooling, power settings or hardware behavior.

### Language

ThermalAtlas starts in **English**. Choose **Language** in the shared menu, then select **English** or **Deutsch**. The selection changes the visible app text and is stored locally; it does not translate drive names or alter sensor data.

<p align="center">
  <img src="Resources/ManualScreenshots/language-menu.png" width="198" alt="ThermalAtlas Language submenu with English selected and Deutsch available">
</p>

### Links, manuals, Activity Monitor and quit

The same menu provides direct links to the public **GitHub repository**, the **ThermalAtlas homepage**, and both manuals. Choosing **Open Activity Monitor** opens the macOS Activity Monitor app. Choosing **Quit ThermalAtlas** stops the app and periodic sensor refresh.

<p align="center">
  <img src="Resources/ManualScreenshots/manuals-menu.png" width="324" alt="ThermalAtlas Manuals submenu with English Manual and Deutsches Handbuch">
</p>

Opening a public link happens only after you select it and hands its public URL to your default browser. Temperature monitoring itself has no network feature.

---

## 5. CPU and GPU temperatures

ThermalAtlas uses read-only Apple-silicon SMC access through IOKit for CPU and GPU temperature data.

### CPU

For CPU temperature, ThermalAtlas calculates the arithmetic mean of the readable CPU sensors. This provides one compact average instead of a long list of individual cores.

### GPU

The GPU value is likewise calculated as an average of available GPU zones. If all matching GPU zones are temporarily unavailable, the app follows the clearly labeled last-real-value behavior described above and then correctly returns to **Not available** when that value expires.

---

## 6. SSD temperatures, SMART and “Not available”

ThermalAtlas uses drive information exposed by macOS through `diskutil`. It shows the actual internal-drive name and each detected physical external SSD's mounted volume or drive name as a separate card. Virtual disk images are ignored.

An SSD temperature is shown only when a genuine SMART value is present. For external SSDs in particular, this depends on whether the drive, USB/Thunderbolt controller and enclosure pass temperature information through to macOS.

### When “Not available” appears

This does not automatically mean that anything is wrong with the drive. Possible reasons include:

- macOS does not expose a temperature value for the device.
- The external enclosure does not pass SMART information through.
- A sensor is not available through the read-only path used on this Mac model.
- No matching external solid-state drive was detected.

In these cases ThermalAtlas deliberately shows **no invented or estimated value**.

---

## 7. Installation

### Download

Download an available macOS package only from the official [ThermalAtlas Releases](https://github.com/Schrotty74/ThermalAtlas/releases).

1. Open the DMG.
2. Drag `ThermalAtlas.app` to Applications.
3. Launch ThermalAtlas.

### Gatekeeper on first launch

Public prerelease builds are currently ad-hoc signed and are not notarized with an Apple Developer Program identity. macOS may therefore show a warning on first launch.

1. In Finder, right-click or Control-click `ThermalAtlas.app`.
2. Choose **Open**.
3. Confirm **Open** in the macOS dialog.
4. If macOS still blocks it: **System Settings -> Privacy & Security -> Open Anyway**.

Only approve such an exception for an app downloaded from the official ThermalAtlas repository.

---

## 8. Privacy

ThermalAtlas is privacy-friendly and local by design:

- no user accounts
- no telemetry
- no analytics services
- no cloud synchronization
- no advertising SDKs
- no persistent storage of temperature readings
- no network feature required for temperature monitoring
- no third-party dependencies

Only the selected theme, scan-refresh interval and display language are stored locally. See the [privacy report](PRIVACY.md) and [security review](SECURITY.md) for more detail.

---

## 9. Resource usage

ThermalAtlas is architecturally compact: a menu bar app, one sensor snapshot at the selected interval, and read-only sensor access. This manual deliberately does **not** claim “extremely low CPU/GPU usage” until that statement has been backed by a reproducible runtime measurement with recorded values.

---

## 10. Requirements and project status

- macOS 14 or later
- Apple silicon
- For local builds: Xcode Command Line Tools including Swift and `actool`

ThermalAtlas is in active development. Public prerelease builds are published through [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases).

---

## 11. More information

- [ThermalAtlas home page](README.md)
- [Releases and downloads](https://github.com/Schrotty74/ThermalAtlas/releases)
- [Privacy report](PRIVACY.md)
- [Security review](SECURITY.md)
- [Source code](https://github.com/Schrotty74/ThermalAtlas)
- [Deutsches Benutzerhandbuch](MANUAL.de.md)
