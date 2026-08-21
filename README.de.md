# ThermalAtlas – Datenschutzorientierte macOS-Menüleisten-Temperaturanzeige für Apple Silicon

<p align="center"><img src="Resources/IconSource/ThermalAtlas-LiquidGlass.png" width="180" alt="ThermalAtlas Liquid-Glass-Thermometer-Icon für die macOS-Menüleisten-App"></p>

[English](README.md) · **Deutsch**

## Überblick

ThermalAtlas ist eine native, lokale macOS-Menüleisten-App zur Temperaturanzeige für Apple-Silicon-Macs. Sie zeigt CPU-, GPU-, interne SSD- und erkannte externe SSD-Temperaturen kompakt an, wenn macOS echte Sensor- oder SMART-Werte bereitstellt.

Die App richtet sich an Menschen, die die thermische Auslastung ihres Macs ohne Hardwaresteuerung prüfen möchten: Sie aktualisiert sich alle zwei Sekunden, zeigt nicht verfügbare Messwerte klar statt sie zu schätzen und verändert niemals Lüfter, Energieoptionen oder Systemeinstellungen. ThermalAtlas funktioniert offline und enthält keine Konten, Telemetrie oder Netzwerkkommunikation.

## Funktionen

- Aktualisierung alle zwei Sekunden.
- **Nicht verfügbar** statt geschätzter Werte.
- SSD-SMART-Temperaturen nur, wenn macOS sie bereitstellt.
- Defensiver, rein lesender Apple-Silicon-SMC-Adapter für CPU und GPU.
- Vier native Themes, darunter adaptives Liquid Glass.
- Keine Drittanbieter-Abhängigkeiten, Netzwerkkommunikation, Telemetrie oder Konten.

## Screenshots und Themes

| Klassisch | Liquid Glass |
| --- | --- |
| <img src="Resources/Screenshots/classic.png" width="330" alt="Klassisches ThermalAtlas-macOS-Theme mit Temperaturkarten für CPU, GPU, interne SSD und externe SSD"> | <img src="Resources/Screenshots/liquid-glass.png" width="330" alt="ThermalAtlas-Liquid-Glass-macOS-Theme mit Temperaturkarten für CPU, GPU, interne SSD und externe SSD"> |
| Aurora | Ember |
| <img src="Resources/Screenshots/aurora.png" width="330" alt="ThermalAtlas-Aurora-macOS-Theme mit Temperaturkarten für CPU, GPU, interne SSD und externe SSD"> | <img src="Resources/Screenshots/ember.png" width="330" alt="ThermalAtlas-Ember-macOS-Theme mit Temperaturkarten für CPU, GPU, interne SSD und externe SSD"> |

## Voraussetzungen

- macOS 14 oder neuer auf Apple Silicon
- Xcode Command Line Tools mit Swift und `actool`

## Download, Installation und Nutzung

Lade verfügbare macOS-Vorabpakete über die [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases) herunter. Öffne das DMG und ziehe ThermalAtlas zur Installation auf den `Applications`-Alias.

Nach dem Öffnen der App zeigt das Thermometer in der macOS-Menüleiste die aktuellen Temperaturen an und ermöglicht die Auswahl eines Themes. Wenn ein Sensor, eine SSD oder ein externes Gehäuse keinen echten Temperaturwert bereitstellt, zeigt die App `Nicht verfügbar`.

### Gatekeeper-Bestätigung

Öffentliche Vorab-Builds sind ad-hoc signiert und nicht mit einer Apple-Developer-Program-Signatur notarisiert. macOS Gatekeeper kann deshalb beim ersten Start eine Bestätigung verlangen. Bestätige die App nur, wenn du sie aus dem offiziellen [ThermalAtlas-GitHub-Release](https://github.com/Schrotty74/ThermalAtlas/releases) geladen hast.

1. Klicke im Finder bei gedrückter Control-Taste (oder per Rechtsklick) auf `ThermalAtlas.app` und wähle **Öffnen**.
2. Bestätige **Öffnen** im macOS-Dialog.
3. Falls macOS die App weiterhin blockiert, öffne **Systemeinstellungen → Datenschutz & Sicherheit**, wähle bei ThermalAtlas **Dennoch öffnen** und bestätige den nächsten Dialog.

## Build-Kanäle

Jeder Kanal hat eine eigene Bundle-Kennung, eigene `UserDefaults`, ein eigenes App-Bundle und einen eigenen Swift-Build-Cache.

| Kanal | Build-Befehl | Bundle-Kennung | Ausgabe |
| --- | --- | --- | --- |
| Dev | `./build_dev_app.sh` | `io.github.schrotty74.thermalatlas.dev` | `Build/Dev/ThermalAtlas Dev.app` |
| Beta | `./build_beta_app.sh` | `io.github.schrotty74.thermalatlas.beta` | `Build/Beta/ThermalAtlas Beta.app` |
| Final | `./build_final_app.sh` | `io.github.schrotty74.thermalatlas` | `Build/Final/ThermalAtlas.app` |

Alle Builds werden lokal ad-hoc signiert. Ein Build veröffentlicht nichts.

## Datenschutz, Datenverarbeitung und Sicherheit

ThermalAtlas liest lokale Apple-Silicon-SMC-Temperaturen, lokale Laufwerksmetadaten und SMART-Temperaturen nur dann, wenn macOS sie bereitstellt. Lokal gespeichert wird ausschließlich das gewählte Theme in `UserDefaults`; Temperaturwerte werden nicht dauerhaft gespeichert. Die App enthält keine Netzwerkfunktionen, Telemetrie, Analyse-Dienste, Konten, Cloud-Synchronisation, Werbe-SDKs oder Drittanbieter-Abhängigkeiten.

Siehe [Datenschutzbericht](PRIVACY.de.md), [Privacy report](PRIVACY.md) und die [Sicherheitsprüfung](SECURITY.md).

## Projektstatus

ThermalAtlas befindet sich in aktiver Entwicklung. Herunterladbare Vorab-Builds werden über die [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases) veröffentlicht; Dev-Builds bleiben lokal.

## Lizenz

ThermalAtlas steht unter der [GNU General Public License v3.0](LICENSE).

## Links

- [Releases und Downloads](https://github.com/Schrotty74/ThermalAtlas/releases)
- [Datenschutzbericht](PRIVACY.de.md)
- [Sicherheitsprüfung](SECURITY.md)
- [Quellcode](https://github.com/Schrotty74/ThermalAtlas)

## Entwicklung

```zsh
swift test -c debug
./build_dev_app.sh
```

`Build/` und `.build/` werden absichtlich ignoriert.
