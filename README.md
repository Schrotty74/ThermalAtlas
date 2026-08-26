# ThermalAtlas – Privacy-Friendly macOS Menu Bar Temperature Monitor for Apple Silicon

[![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](Package.swift)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](#requirements)
[![License GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-3DA639?logo=gnu&logoColor=white)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Schrotty74/ThermalAtlas?display_name=tag&include_prereleases&sort=semver&label=release)](https://github.com/Schrotty74/ThermalAtlas/releases)
[![Downloads](https://img.shields.io/github/downloads/Schrotty74/ThermalAtlas/total?label=downloads)](https://github.com/Schrotty74/ThermalAtlas/releases)
[![Privacy: local only](https://img.shields.io/badge/Privacy-Local%20only-2EA043?logo=shield&logoColor=white)](PRIVACY.md)

<p align="center"><img src="Resources/IconSource/ThermalAtlas-LiquidGlass.png" width="180" alt="ThermalAtlas Liquid Glass thermometer icon for the macOS menu bar app"></p>

**English** · [Deutsch](README.de.md)

📘 **[User Manual (PDF)](Documentation/ThermalAtlas-User-Manual-EN.pdf)** – interface, buttons, sensors, themes, installation and privacy explained in detail.

> [!IMPORTANT]
> **ThermalAtlas v1.0.0 is the first stable release.** The `main` branch contains the final source status; newer features may appear first on the [`beta` branch](https://github.com/Schrotty74/ThermalAtlas/tree/beta).

## Overview

ThermalAtlas is a lightweight, privacy-friendly, local-first macOS menu bar temperature monitor for Apple silicon. It shows real CPU, GPU, internal SSD, and every detected physical external SSD sensor value whenever macOS exposes it, without telemetry, accounts, or hardware control.

The app is designed for people who want to check Mac thermal conditions without a hardware-control tool: it defaults to a two-second refresh interval, clearly shows unavailable measurements instead of estimating them, and never changes fan, power, or system settings. Its interface defaults to English and includes an optional German display language. ThermalAtlas works offline and has no accounts, analytics, or network communication.

No admin/root access is required. ThermalAtlas uses a read-only approach and only reads sensor data exposed by macOS.

## Features

- Monitors available CPU, GPU, internal-SSD, and physical external-SSD temperatures without estimating missing readings.
- Shows SMART status and remaining SSD health whenever macOS supplies those values.
- Separates fast, read-only CPU/GPU load and used-memory context from temperature monitoring.
- Keeps local temperature history, provides optional temperature alerts, and exports a snapshot or CSV only on request.
- Offers Standard and Compact views, selectable visible sensor groups, and menu-bar modes for all values or just the symbol.
- Includes four native themes and a local English/German interface choice.
- Uses defensive Apple-silicon sensor access and independent drive refresh cycles, so slow drive queries do not delay CPU/GPU temperatures.
- Works locally without accounts, telemetry, analytics, third-party dependencies, or hardware control.

See the complete, grouped [feature overview](FEATURES.md).

## Screenshots and themes

| Adaptive | Liquid Glass |
| --- | --- |
| <img src="Resources/Screenshots/classic.png?v=20260823-monitoring" width="330" alt="ThermalAtlas Adaptive macOS theme showing temperature cards and a separate System Context area"> | <img src="Resources/Screenshots/liquid-glass.png?v=20260823-monitoring" width="330" alt="ThermalAtlas Liquid Glass macOS theme showing temperature cards and a separate System Context area"> |
| Aurora | Ember |
| <img src="Resources/Screenshots/aurora.png?v=20260823-monitoring" width="330" alt="ThermalAtlas Aurora macOS theme showing temperature cards and a separate System Context area"> | <img src="Resources/Screenshots/ember.png?v=20260823-monitoring" width="330" alt="ThermalAtlas Ember macOS theme showing temperature cards and a separate System Context area"> |

## Requirements

- macOS 14 or later
- Apple silicon Mac

### Building from source

- Xcode Command Line Tools, including Swift and `actool`

## Download, installation, and usage

Download the stable macOS package from [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases). Open the DMG and drag ThermalAtlas to the `Applications` alias to install it.

After opening the app, use the thermometer in the macOS menu bar to view the current temperatures. Open the footer ellipsis for visual themes, Scan Refresh, display options, alerts, export, the optional German interface, manuals, links, Activity Monitor, and Quit. Select a card for its local temperature history; use its info button for sensor details. The app displays `Not available` when a sensor, SSD, or external enclosure does not provide a real temperature.

### Gatekeeper confirmation

Public builds are ad-hoc signed and are not notarized with an Apple Developer Program signing identity. macOS Gatekeeper can therefore ask you to confirm the first launch. Only approve the app after downloading it from the official [ThermalAtlas GitHub Release](https://github.com/Schrotty74/ThermalAtlas/releases).

1. In Finder, Control-click (or right-click) `ThermalAtlas.app` and choose **Open**.
2. Confirm **Open** in the macOS dialog.
3. If macOS still blocks the app, open **System Settings → Privacy & Security**, then choose **Open Anyway** for ThermalAtlas and confirm the next dialog.

## Published build channels

Each published channel has its own bundle identifier, `UserDefaults` domain, app bundle, and Swift build cache.

| Channel | Build command | Bundle identifier | Output |
| --- | --- | --- | --- |
| Beta | `./build_beta_app.sh` | `io.github.schrotty74.thermalatlas.beta` | `Build/Beta/ThermalAtlas Beta.app` |
| Final | `./build_final_app.sh` | `io.github.schrotty74.thermalatlas` | `Build/Final/ThermalAtlas.app` |

Published builds are ad-hoc signed locally. Building does not publish a release.

## Privacy, data handling, and security

ThermalAtlas reads local Apple-silicon SMC temperatures, local drive metadata, SMART temperature data, CPU/GPU load, used memory, power source/battery, and Low Power Mode only when macOS provides them. It stores selected display preferences, alert thresholds, and local per-minute temperature averages for up to 24 hours in local `UserDefaults`; system-context values are displayed but not stored. The app has no background network features, telemetry, analytics, accounts, cloud sync, advertising SDKs, or third-party dependencies. A text or CSV export is created only after you explicitly choose it and a local save location. Its optional GitHub, Homepage, and manual menu actions open the selected public page in your default browser only after you select them.

See [Privacy report](PRIVACY.md), [Datenschutzbericht](PRIVACY.de.md), and the [security review](SECURITY.md).

## Hardware compatibility

CPU and GPU recognition is hardware-confirmed on M4 Max, M5, and M5 Pro. The other M1 through M5 variants and their raw sensors are implemented defensively, but still need verification on real hardware. When macOS or a device does not expose a usable sensor value, ThermalAtlas shows `Not available` rather than estimating one.

## Project status

ThermalAtlas v1.0.0 is the first stable release. Future stable releases and prereleases are published through [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases).

## Repo activity

![Alt](https://repobeats.axiom.co/api/embed/d6af5f522976c979d056c181fc9c59f85da59e78.svg "Repobeats analytics image")

## License

ThermalAtlas is licensed under the [GNU General Public License v3.0](LICENSE).

## Links

- [User Manual (PDF)](Documentation/ThermalAtlas-User-Manual-EN.pdf)
- [Feature overview](FEATURES.md)
- [Releases and downloads](https://github.com/Schrotty74/ThermalAtlas/releases)
- [Changelog](CHANGELOG.md)
- [Privacy report](PRIVACY.md)
- [Security review](SECURITY.md)
- [Source code](https://github.com/Schrotty74/ThermalAtlas)

## Development

```zsh
swift test -c debug
```

`Build/` and `.build/` are intentionally ignored.
