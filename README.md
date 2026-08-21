# ThermalAtlas

<p align="center"><img src="Resources/IconSource/ThermalAtlas-LiquidGlass.png" width="180" alt="ThermalAtlas liquid-glass thermometer icon"></p>

**English** · [Deutsch](README.de.md)

ThermalAtlas is a native macOS menu-bar app for Apple-silicon Macs. It shows CPU, GPU, internal SSD, and external SSD temperatures when macOS provides real values. It never controls fans, power settings, or system configuration.

## Highlights

- Refreshes every two seconds.
- Shows **Not available** rather than estimating missing values.
- Reads SSD SMART temperatures only when macOS exposes them.
- Uses a defensive, read-only Apple-silicon SMC adapter for CPU and GPU.
- Provides four native themes, including adaptive Liquid Glass.
- Has no third-party dependencies, network communication, analytics, or accounts.

## Requirements

- macOS 14 or later on Apple silicon
- Xcode command-line tools, including Swift and `actool`

## Build channels

Each channel has its own bundle identifier, `UserDefaults` domain, app bundle, and Swift build cache.

| Channel | Build command | Bundle identifier | Output |
| --- | --- | --- | --- |
| Dev | `./build_dev_app.sh` | `io.github.schrotty74.thermalatlas.dev` | `Build/Dev/ThermalAtlas Dev.app` |
| Beta | `./build_beta_app.sh` | `io.github.schrotty74.thermalatlas.beta` | `Build/Beta/ThermalAtlas Beta.app` |
| Final | `./build_final_app.sh` | `io.github.schrotty74.thermalatlas` | `Build/Final/ThermalAtlas.app` |

All builds are ad-hoc signed locally. Building does not publish a release.

## Privacy and security

See [Privacy report](PRIVACY.md), [Datenschutzbericht](PRIVACY.de.md), [security review](SECURITY.md), and the [changelog](CHANGELOG.md).

## Development

```zsh
swift test -c debug
./build_dev_app.sh
```

`Build/` and `.build/` are intentionally ignored.
