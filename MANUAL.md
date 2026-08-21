# ThermalAtlas – User Manual

<p align="center">
  <img src="Resources/IconSource/ThermalAtlas-LiquidGlass.png" width="150" alt="ThermalAtlas app icon">
</p>

<p align="center">
  <strong>Lightweight, privacy-friendly temperature monitoring for Apple silicon</strong><br>
  CPU · GPU · internal SSD · external SSD
</p>

<p align="center">
  <a href="MANUAL.de.md">Deutsches Handbuch</a> · <a href="README.md">Back to the English home page</a>
</p>

---

## 1. What is ThermalAtlas?

ThermalAtlas is a compact macOS menu bar app for Apple-silicon Macs. It shows real temperature readings for CPU, GPU, the internal SSD and – when macOS or the drive controller exposes them – a detected external SSD.

The app is deliberately focused on monitoring. It changes **no fan control, performance parameter, power setting or system setting**. Temperature values are not estimated: when no real sensor or SMART value is available, ThermalAtlas displays **Not available**.

### Key characteristics

| Area | Behavior |
| --- | --- |
| CPU | Read-only access to Apple-silicon SMC sensors |
| GPU | Read-only access to Apple-silicon SMC sensors |
| Internal SSD | SMART temperature when macOS exposes it |
| External SSD | SMART temperature when drive and enclosure pass it through |
| Refresh | Normally every 2 seconds |
| Storage | Only the selected theme is stored locally |
| Network | No network feature is required for temperature monitoring |
| Telemetry | No telemetry or analytics services |

---

## 2. The app interface

The screenshot below comes directly from the ThermalAtlas project home page and shows the app's **Liquid Glass theme**.

<p align="center">
  <img src="Resources/Screenshots/liquid-glass.png" width="520" alt="ThermalAtlas Liquid Glass showing CPU, GPU and SSD temperatures">
</p>

### What you see in the window

**Temperature cards**  
Each card represents one measurement group: CPU, GPU, internal SSD and external SSD. The current temperature is shown on the right. The text below the name identifies the source or current status of the reading.

**Color status indicator**

| Color | Temperature range | Meaning |
| --- | ---: | --- |
| 🟢 Green | below 55 °C | cool / normal range |
| 🟠 Orange | 55 to below 75 °C | elevated temperature |
| 🔴 Red | 75 °C and above | high temperature range |
| ⚪ Gray | no reading | no real temperature value available |

The colors are a quick visual guide only. ThermalAtlas does not change anything on the Mac because of these indicators.

**Updated time**  
The bottom of the window shows the time of the latest accepted sensor snapshot. Normal refresh runs every two seconds.

---

## 3. Menu bar display

After launch, ThermalAtlas appears as a thermometer in the macOS menu bar. Next to it, the app shows the **highest currently available temperature** as a whole number.

This is not a separate sensor. ThermalAtlas simply selects the highest available value from the current measurement groups. Clicking the menu bar item opens the ThermalAtlas window.

---

## 4. Buttons and controls

### Theme

The **Theme** button opens the four available appearances:

- **Classic** – restrained, system-like appearance
- **Liquid Glass** – transparent glass surfaces with a static glow
- **Aurora** – dark blue and purple tones
- **Ember** – warm red and orange tones

Changing the theme affects appearance only, not sensor logic. The selected theme is stored locally in `UserDefaults`.

> The former continuously pulsing Liquid Glass glow animation has been removed. The glass appearance remains, but the glow is static.

### Activity Monitor button

The button with the **activity/waveform symbol** opens macOS **Activity Monitor**.

This is useful when you also want to inspect which processes are using CPU, memory, energy or other system resources. ThermalAtlas does not replace Activity Monitor and does not duplicate those measurements through this button.

### Quit button

The button with the **power symbol** quits ThermalAtlas completely. Periodic sensor refresh stops as well. Launch the app again when you want to use it later.

---

## 5. CPU and GPU temperatures

ThermalAtlas uses read-only Apple-silicon SMC access through IOKit for CPU and GPU temperature data.

### CPU

For CPU temperature, ThermalAtlas calculates the arithmetic mean of the readable CPU sensors. This provides one compact average instead of a long list of individual cores.

### GPU

The GPU value is likewise calculated as an average of available GPU zones.

If the private SMC transport briefly fails to return a GPU value during a single refresh, ThermalAtlas may temporarily preserve the **last previously verified real GPU reading**. The interface explicitly marks it as the last real value and it expires after a short period; it is not an estimate.

---

## 6. SSD temperatures and “Not available”

ThermalAtlas uses drive information exposed by macOS through `diskutil`.

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
4. If macOS still blocks it: **System Settings → Privacy & Security → Open Anyway**.

Only approve such an exception for an app downloaded from the official ThermalAtlas repository.

---

## 8. Theme overview

| Classic | Liquid Glass |
| --- | --- |
| <img src="Resources/Screenshots/classic.png" width="330" alt="ThermalAtlas Classic"> | <img src="Resources/Screenshots/liquid-glass.png" width="330" alt="ThermalAtlas Liquid Glass"> |
| **Aurora** | **Ember** |
| <img src="Resources/Screenshots/aurora.png" width="330" alt="ThermalAtlas Aurora"> | <img src="Resources/Screenshots/ember.png" width="330" alt="ThermalAtlas Ember"> |

All four themes display the same measurements. Their differences are visual only.

---

## 9. Privacy

ThermalAtlas is privacy-friendly and local by design:

- no user accounts
- no telemetry
- no analytics services
- no cloud synchronization
- no advertising SDKs
- no persistent storage of temperature readings
- no network feature required for temperature monitoring
- no third-party dependencies

Only the selected theme is stored locally. See the [privacy report](PRIVACY.md) and [security review](SECURITY.md) for more detail.

---

## 10. Resource usage

ThermalAtlas is architecturally compact: a menu bar app, one sensor snapshot every two seconds, and read-only sensor access. The former continuous Liquid Glass glow animation has also been removed.

This manual deliberately does **not** claim “extremely low CPU/GPU usage” until that statement has been backed by a reproducible runtime measurement with recorded values.

---

## 11. Requirements and project status

- macOS 14 or later
- Apple silicon
- For local builds: Xcode Command Line Tools including Swift and `actool`

ThermalAtlas is in active development. Public prerelease builds are published through [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases).

---

## 12. More information

- [ThermalAtlas home page](README.md)
- [Releases and downloads](https://github.com/Schrotty74/ThermalAtlas/releases)
- [Privacy report](PRIVACY.md)
- [Security review](SECURITY.md)
- [Source code](https://github.com/Schrotty74/ThermalAtlas)
- [Deutsches Benutzerhandbuch](MANUAL.de.md)
