# ThermalAtlas – Privacy-First macOS Menu Bar Temperature Monitor for Apple Silicon

<p align="center"><img src="Resources/IconSource/ThermalAtlas-LiquidGlass.png" width="180" alt="ThermalAtlas Liquid Glass thermometer icon for the macOS menu bar app"></p>

**English** · [Deutsch](README.de.md)

## Overview

ThermalAtlas is a native, local-first macOS menu bar temperature monitor for Apple-silicon Macs. It gives you a compact view of CPU, GPU, internal SSD, and detected external SSD temperatures whenever macOS exposes real sensor or SMART values.

The app is designed for people who want to check Mac thermal conditions without a hardware-control tool: it refreshes every two seconds, clearly shows unavailable measurements instead of estimating them, and never changes fan, power, or system settings. ThermalAtlas works offline and has no accounts, analytics, or network communication.

## Features

- Refreshes every two seconds.
- Shows **Not available** rather than estimating missing values.
- Reads SSD SMART temperatures only when macOS exposes them.
- Uses a defensive, read-only Apple-silicon SMC adapter for CPU and GPU.
- Provides four native themes, including adaptive Liquid Glass.
- Has no third-party dependencies, network communication, analytics, or accounts.

## Screenshots and themes

| Classic | Liquid Glass |
| --- | --- |
| <img src="Resources/Screenshots/classic.png" width="330" alt="ThermalAtlas Classic macOS theme showing CPU, GPU, internal SSD, and external SSD temperature cards"> | <img src="Resources/Screenshots/liquid-glass.png" width="330" alt="ThermalAtlas Liquid Glass macOS theme showing CPU, GPU, internal SSD, and external SSD temperature cards"> |
| Aurora | Ember |
| <img src="Resources/Screenshots/aurora.png" width="330" alt="ThermalAtlas Aurora macOS theme showing CPU, GPU, internal SSD, and external SSD temperature cards"> | <img src="Resources/Screenshots/ember.png" width="330" alt="ThermalAtlas Ember macOS theme showing CPU, GPU, internal SSD, and external SSD temperature cards"> |

## Requirements

- macOS 14 or later on Apple silicon
- Xcode command-line tools, including Swift and `actool`

## Download, installation, and usage

Download the available macOS prerelease packages from [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases). Open the DMG and drag ThermalAtlas to the `Applications` alias to install it.

After opening the app, use the thermometer in the macOS menu bar to view the current temperatures and choose a visual theme. The app displays `Not available` when a sensor, SSD, or external enclosure does not provide a real temperature.

### Gatekeeper confirmation

Public prerelease builds are ad-hoc signed and are not notarized with an Apple Developer Program signing identity. macOS Gatekeeper can therefore ask you to confirm the first launch. Only approve the app after downloading it from the official [ThermalAtlas GitHub Release](https://github.com/Schrotty74/ThermalAtlas/releases).

1. In Finder, Control-click (or right-click) `ThermalAtlas.app` and choose **Open**.
2. Confirm **Open** in the macOS dialog.
3. If macOS still blocks the app, open **System Settings → Privacy & Security**, then choose **Open Anyway** for ThermalAtlas and confirm the next dialog.

## Build channels

Each channel has its own bundle identifier, `UserDefaults` domain, app bundle, and Swift build cache.

| Channel | Build command | Bundle identifier | Output |
| --- | --- | --- | --- |
| Dev | `./build_dev_app.sh` | `io.github.schrotty74.thermalatlas.dev` | `Build/Dev/ThermalAtlas Dev.app` |
| Beta | `./build_beta_app.sh` | `io.github.schrotty74.thermalatlas.beta` | `Build/Beta/ThermalAtlas Beta.app` |
| Final | `./build_final_app.sh` | `io.github.schrotty74.thermalatlas` | `Build/Final/ThermalAtlas.app` |

All builds are ad-hoc signed locally. Building does not publish a release.

## Privacy, data handling, and security

ThermalAtlas reads local Apple-silicon SMC temperatures, local drive metadata, and SMART temperature data only when macOS provides them. It stores only the selected visual theme in local `UserDefaults`; temperature readings are not persisted. The app has no network features, telemetry, analytics, accounts, cloud sync, advertising SDKs, or third-party dependencies.

See [Privacy report](PRIVACY.md), [Datenschutzbericht](PRIVACY.de.md), and the [security review](SECURITY.md).

## Project status

ThermalAtlas is in active development. Downloadable prerelease builds are published through [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases); Dev builds remain local.

## License

ThermalAtlas is licensed under the [GNU General Public License v3.0](LICENSE).

## Links

- [Releases and downloads](https://github.com/Schrotty74/ThermalAtlas/releases)
- [Privacy report](PRIVACY.md)
- [Security review](SECURITY.md)
- [Source code](https://github.com/Schrotty74/ThermalAtlas)

## Development

```zsh
swift test -c debug
./build_dev_app.sh
```

`Build/` and `.build/` are intentionally ignored.
