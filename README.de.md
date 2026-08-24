# ThermalAtlas – Datenschutzfreundliche macOS-Menüleisten-Temperaturanzeige für Apple Silicon

[![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](Package.swift)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](#voraussetzungen)
[![Lizenz GPL-3.0](https://img.shields.io/badge/Lizenz-GPL--3.0-3DA639?logo=gnu&logoColor=white)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Schrotty74/ThermalAtlas?display_name=tag&include_prereleases&sort=semver&label=release)](https://github.com/Schrotty74/ThermalAtlas/releases)
[![Downloads](https://img.shields.io/github/downloads/Schrotty74/ThermalAtlas/total?label=downloads)](https://github.com/Schrotty74/ThermalAtlas/releases)
[![Datenschutz: lokal](https://img.shields.io/badge/Datenschutz-Lokal-2EA043?logo=shield&logoColor=white)](PRIVACY.de.md)

<p align="center"><img src="Resources/IconSource/ThermalAtlas-LiquidGlass.png" width="180" alt="ThermalAtlas Liquid-Glass-Thermometer-Icon für die macOS-Menüleisten-App"></p>

[English](README.md) · **Deutsch**

📘 **[Benutzerhandbuch (PDF)](Documentation/ThermalAtlas-Handbuch-DE.pdf)** – Oberfläche, Buttons, Sensoren, Themes, Installation und Datenschutz ausführlich erklärt.

## Überblick

ThermalAtlas ist eine schlanke, datenschutzfreundliche und lokale macOS-Menüleisten-App für Apple Silicon. Sie zeigt echte Sensorwerte für CPU, GPU, interne SSD und jede erkannte physische externe SSD, sobald macOS sie bereitstellt – ohne Telemetrie, Konten oder Hardwaresteuerung. Die Oberfläche startet auf Englisch und bietet Deutsch als optional wählbare Anzeigesprache.

Die App richtet sich an Menschen, die die thermische Auslastung ihres Macs ohne Hardwaresteuerung prüfen möchten: Sie aktualisiert sich standardmäßig alle zwei Sekunden, zeigt nicht verfügbare Messwerte klar statt sie zu schätzen und verändert niemals Lüfter, Energieoptionen oder Systemeinstellungen. ThermalAtlas funktioniert offline und enthält keine Konten, Telemetrie oder Netzwerkkommunikation.

Weder Administrator- noch Root-Rechte sind nötig. ThermalAtlas verfolgt einen rein lesenden Ansatz und liest ausschließlich von macOS bereitgestellte Sensordaten.

## Funktionen

- Überwacht verfügbare Temperaturen von CPU, GPU, interner SSD und physischen externen SSDs, ohne fehlende Werte zu schätzen.
- Zeigt SMART-Status und verbleibende SSD-Gesundheit, sobald macOS diese Werte bereitstellt.
- Trennt schnellen, rein lesenden Systemkontext für CPU-/GPU-Last und belegten Arbeitsspeicher von der Temperaturüberwachung.
- Führt lokale Temperaturverläufe, bietet optionale Temperaturwarnungen und exportiert Snapshot oder CSV nur auf Wunsch.
- Bietet Standard- und Kompaktansicht, wählbare sichtbare Sensorgruppen sowie Menüleistenmodi für alle Werte oder nur das Symbol.
- Enthält vier native Themes und eine lokale Sprachwahl zwischen Englisch und Deutsch.
- Nutzt defensiven Apple-Silicon-Sensorzugriff und getrennte Laufwerkszyklen, damit langsame Laufwerksabfragen CPU-/GPU-Temperaturen nicht verzögern.
- Funktioniert lokal ohne Konten, Telemetrie, Analysedienste, Drittanbieter-Abhängigkeiten oder Hardwaresteuerung.

Die vollständige, gegliederte [Funktionsübersicht](FEATURES.de.md) enthält alle Details.

## Screenshots und Themes

| Klassisch | Liquid Glass |
| --- | --- |
| <img src="Resources/Screenshots/classic.png?v=20260823-monitoring" width="330" alt="Klassisches ThermalAtlas-macOS-Theme mit Temperaturkarten und separatem Systemkontext"> | <img src="Resources/Screenshots/liquid-glass.png?v=20260823-monitoring" width="330" alt="ThermalAtlas-Liquid-Glass-macOS-Theme mit Temperaturkarten und separatem Systemkontext"> |
| Aurora | Ember |
| <img src="Resources/Screenshots/aurora.png?v=20260823-monitoring" width="330" alt="ThermalAtlas-Aurora-macOS-Theme mit Temperaturkarten und separatem Systemkontext"> | <img src="Resources/Screenshots/ember.png?v=20260823-monitoring" width="330" alt="ThermalAtlas-Ember-macOS-Theme mit Temperaturkarten und separatem Systemkontext"> |

## Gemeinsames Menü und Anzeigeoptionen

Der Dreipunkt-Button im Footer öffnet ein gemeinsames Menü und hält die Temperaturansicht bewusst ruhig. Es enthält vier Darstellungen, **Scan Refresh** (1, 2, 3 oder 4 Sekunden; Standard: 2 Sekunden), **Fenstergröße** (Standard oder Kompakt), **Sichtbare Temperaturen**, **Menüleistenanzeige** (Alle Werte oder Nur Symbol), **Temperaturwarnungen**, **Sprache** und **Export**. Das Häkchen markiert die aktive Auswahl.

<p align="center"><img src="Resources/ManualScreenshots/shared-menu.png" width="300" alt="ThermalAtlas-Hauptmenü mit Themes, Scan Refresh, Fenstergröße, Sichtbaren Temperaturen, Menüleistenanzeige, Temperaturwarnungen, Sprache, Export, Links, Handbüchern, Aktivitätsanzeige und Beenden"></p>

Über **Sichtbare Temperaturen** legst du fest, welche Sensorgruppen gleichzeitig im Popover und in der Menüleiste erscheinen. **Export** kopiert den aktuellen Snapshot oder speichert den lokalen Temperaturverlauf plus Snapshot als CSV. Das Menü verlinkt außerdem zu GitHub, der Projekt-Homepage und beiden Handbüchern. **Aktivitätsanzeige öffnen** startet die gleichnamige macOS-App erst nach deiner Auswahl; **ThermalAtlas beenden** beendet die App und die regelmäßige rein lesende Aktualisierung.

## Voraussetzungen

- macOS 14 oder neuer auf Apple Silicon
- Xcode Command Line Tools mit Swift und `actool`

## Download, Installation und Nutzung

Lade verfügbare macOS-Vorabpakete über die [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases) herunter. Öffne das DMG und ziehe ThermalAtlas zur Installation auf den `Applications`-Alias.

Nach dem Öffnen der App zeigt das Thermometer in der macOS-Menüleiste die aktuellen Temperaturen an. Über den Dreipunkt-Button im Footer stehen Themes, Scan Refresh, Anzeigeoptionen, Warnungen, Export, die optionale deutsche Oberfläche, Handbücher, Links, Aktivitätsanzeige und Beenden bereit. Ein Klick auf eine Karte öffnet ihren lokalen Temperaturverlauf; das Info-Symbol zeigt die Sensor-Details. Wenn ein Sensor, eine SSD oder ein externes Gehäuse keinen echten Temperaturwert bereitstellt, zeigt die App `Nicht verfügbar`.

### Gatekeeper-Bestätigung

Öffentliche Vorab-Builds sind ad-hoc signiert und nicht mit einer Apple-Developer-Program-Signatur notarisiert. macOS Gatekeeper kann deshalb beim ersten Start eine Bestätigung verlangen. Bestätige die App nur, wenn du sie aus dem offiziellen [ThermalAtlas-GitHub-Release](https://github.com/Schrotty74/ThermalAtlas/releases) geladen hast.

1. Klicke im Finder bei gedrückter Control-Taste (oder per Rechtsklick) auf `ThermalAtlas.app` und wähle **Öffnen**.
2. Bestätige **Öffnen** im macOS-Dialog.
3. Falls macOS die App weiterhin blockiert, öffne **Systemeinstellungen → Datenschutz & Sicherheit**, wähle bei ThermalAtlas **Dennoch öffnen** und bestätige den nächsten Dialog.

## Veröffentlichte Build-Kanäle

Jeder veröffentlichte Kanal hat eine eigene Bundle-Kennung, eigene `UserDefaults`, ein eigenes App-Bundle und einen eigenen Swift-Build-Cache.

| Kanal | Build-Befehl | Bundle-Kennung | Ausgabe |
| --- | --- | --- | --- |
| Beta | `./build_beta_app.sh` | `io.github.schrotty74.thermalatlas.beta` | `Build/Beta/ThermalAtlas Beta.app` |
| Final | `./build_final_app.sh` | `io.github.schrotty74.thermalatlas` | `Build/Final/ThermalAtlas.app` |

Veröffentlichte Builds werden lokal ad-hoc signiert. Ein Build veröffentlicht nichts.

## Datenschutz, Datenverarbeitung und Sicherheit

ThermalAtlas liest lokale Apple-Silicon-SMC-Temperaturen, lokale Laufwerksmetadaten, SMART-Temperaturen, CPU-/GPU-Last, belegten Arbeitsspeicher, Stromquelle/Akku und Energiesparmodus nur dann, wenn macOS sie bereitstellt. Lokal gespeichert werden Anzeigeneinstellungen, Warnschwellen und lokale Temperatur-Minutenmittelwerte für höchstens 24 Stunden in `UserDefaults`; Systemkontextwerte werden angezeigt, aber nicht gespeichert. Die App enthält keine Hintergrundnetzwerkfunktionen, Telemetrie, Analyse-Dienste, Konten, Cloud-Synchronisation, Werbe-SDKs oder Drittanbieter-Abhängigkeiten. Ein Text- oder CSV-Export entsteht nur nach einer ausdrücklichen Auswahl und an einem lokal gewählten Speicherort. Die optionalen Menüeinträge GitHub, Homepage und Handbücher öffnen die gewählte öffentliche Seite nur nach einem Klick im Standardbrowser.

Siehe [Datenschutzbericht](PRIVACY.de.md), [Privacy report](PRIVACY.md) und die [Sicherheitsprüfung](SECURITY.md).

## Hardware-Kompatibilität

Die CPU- und GPU-Erkennung ist auf M4 Max, M5 und M5 Pro auf echter Hardware bestätigt. Die weiteren M1- bis M5-Varianten und ihre Rohsensoren sind defensiv implementiert, müssen aber noch auf echter Hardware geprüft werden. Wenn macOS oder ein Gerät keinen verwendbaren Sensorwert bereitstellt, zeigt ThermalAtlas `Nicht verfügbar`, statt einen Wert zu schätzen.

## Projektstatus

ThermalAtlas befindet sich in aktiver Entwicklung. Herunterladbare Vorab-Builds werden über die [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases) veröffentlicht.

## Lizenz

ThermalAtlas steht unter der [GNU General Public License v3.0](LICENSE).

## Links

- [Benutzerhandbuch (PDF)](Documentation/ThermalAtlas-Handbuch-DE.pdf)
- [Funktionsübersicht](FEATURES.de.md)
- [Releases und Downloads](https://github.com/Schrotty74/ThermalAtlas/releases)
- [Changelog (English)](CHANGELOG.md)
- [Datenschutzbericht](PRIVACY.de.md)
- [Sicherheitsprüfung](SECURITY.md)
- [Quellcode](https://github.com/Schrotty74/ThermalAtlas)

## Entwicklung

```zsh
swift test -c debug
```

`Build/` und `.build/` werden absichtlich ignoriert.
