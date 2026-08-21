# ThermalAtlas

<p align="center"><img src="Resources/IconSource/ThermalAtlas-LiquidGlass.png" width="180" alt="ThermalAtlas Liquid-Glass-Thermometer-Icon"></p>

[English](README.md) · **Deutsch**

ThermalAtlas ist eine native macOS-Menüleisten-App für Apple-Silicon-Macs. Sie zeigt CPU-, GPU-, interne SSD- und externe SSD-Temperaturen, wenn macOS echte Werte bereitstellt. Die App steuert niemals Lüfter, Energieoptionen oder Systemeinstellungen.

## Funktionen

- Aktualisierung alle zwei Sekunden.
- **Nicht verfügbar** statt geschätzter Werte.
- SSD-SMART-Temperaturen nur, wenn macOS sie bereitstellt.
- Defensiver, rein lesender Apple-Silicon-SMC-Adapter für CPU und GPU.
- Vier native Themes, darunter adaptives Liquid Glass.
- Keine Drittanbieter-Abhängigkeiten, Netzwerkkommunikation, Telemetrie oder Konten.

## Voraussetzungen

- macOS 14 oder neuer auf Apple Silicon
- Xcode Command Line Tools mit Swift und `actool`

## Build-Kanäle

Jeder Kanal hat eine eigene Bundle-Kennung, eigene `UserDefaults`, ein eigenes App-Bundle und einen eigenen Swift-Build-Cache.

| Kanal | Build-Befehl | Bundle-Kennung | Ausgabe |
| --- | --- | --- | --- |
| Dev | `./build_dev_app.sh` | `io.github.schrotty74.thermalatlas.dev` | `Build/Dev/ThermalAtlas Dev.app` |
| Beta | `./build_beta_app.sh` | `io.github.schrotty74.thermalatlas.beta` | `Build/Beta/ThermalAtlas Beta.app` |
| Final | `./build_final_app.sh` | `io.github.schrotty74.thermalatlas` | `Build/Final/ThermalAtlas.app` |

Alle Builds werden lokal ad-hoc signiert. Ein Build veröffentlicht nichts.

## Datenschutz und Sicherheit

Siehe [Datenschutzbericht](PRIVACY.de.md), [Privacy report](PRIVACY.md), die [Sicherheitsprüfung](SECURITY.md) und das [Änderungsprotokoll](CHANGELOG.de.md).
