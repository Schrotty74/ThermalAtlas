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

- Standardmäßig Aktualisierung alle zwei Sekunden.
- Lokales Scan-Refresh-Intervall von 1 bis 4 Sekunden in ganzen Sekunden wählbar.
- Der separate Systemkontext aktualisiert CPU- und GPU-Gesamtlast sowie belegten Arbeitsspeicher unabhängig alle 0,5 Sekunden; das gewählte Temperaturintervall bleibt davon unberührt.
- **Nicht verfügbar** statt geschätzter Werte.
- SSD-SMART-Temperaturen nur, wenn macOS sie bereitstellt.
- Listet jede erkannte physische externe SSD separat mit ihrem eingebundenen Volume-Namen, wenn vorhanden, auf und ignoriert virtuelle Disk-Images.
- Zeigt den von macOS gemeldeten SSD-SMART-Status neben dem Laufwerksnamen.
- Zeigt die verbleibende SSD-Gesundheit, wenn macOS NVMe-`PERCENTAGE_USED` bereitstellt; ohne dieses Feld wird kein Prozentwert geschätzt.
- Defensiver, rein lesender Apple-Silicon-SMC-Adapter für CPU und GPU.
- Lässt wählen, welche CPU-, GPU-, internen SSD- und externen SSD-Gruppen im Popover und in der Menüleiste erscheinen.
- Bietet **Alle Werte** in der Menüleiste oder die platzsparende Anzeige **Nur Symbol**; die gewählten Sensorgruppen bleiben dabei erhalten.
- Bietet Standard- und Kompaktgröße für das Popover; Kompakt ist rund 40 % schmaler und hält die Verlaufssteuerung gut lesbar.
- Zeigt beim Öffnen einer Karte einen lokalen Temperaturverlauf für 1, 6 oder 24 Stunden. Gespeichert werden ausschließlich lokale Minutenmittelwerte für höchstens 24 Stunden.
- Bietet getrennte Temperaturwarnungen je Gruppe nach einer anhaltenden Schwellenüberschreitung, mit eigenen CPU/GPU- und SSD-Schwellen.
- Zeigt Quelle, letzten gültigen Wert und Aktualisierungszeit in den Sensor-Details, ohne den Temperaturverlauf zu ersetzen.
- Exportiert die aktuellen Werte als kopierbaren Text oder den lokalen Verlauf plus aktuellen Snapshot als CSV – nur nach Auswahl eines Speicherorts.
- Trennt CPU-Last, GPU-Last, belegten Arbeitsspeicher, Stromquelle/Akku und Energiesparmodus als rein lesenden **Systemkontext** klar von Temperatursensoren.
- Erkennt getrennte CPU- und GPU-Sensor-Schlüsselfamilien für Apple Silicon von M1 bis M5 einschließlich bekannter Pro-, Max- und Ultra-Varianten. Die CPU-/GPU-Erkennung ist derzeit nur auf M4 Max, M5 und M5 Pro auf echter Hardware bestätigt; alle anderen Varianten stehen noch zur Prüfung aus. Unbekannte spätere Generationen bleiben klar als nicht verfügbar ausgewiesen, statt geschätzt zu werden.
- Aktualisiert die Topologie externer Laufwerke beim Start und wenn macOS Einbinden oder Auswerfen meldet. Eingebundene physische SSDs bleiben getrennte Karten; ein ausgeworfenes, aber weiter verbundenes Laufwerk wird ausgeblendet.
- Liest die Temperatur bekannter SSDs jede Minute für Verlauf und Warnungen; SMART-Status und verbleibende Gesundheit werden beim Start, nach einer tatsächlichen Topologieänderung und höchstens einmal täglich aktualisiert.
- Vier native Themes, darunter adaptives Liquid Glass.
- Bündelt Themes, Scan Refresh, Fenstergröße, Sichtbare Temperaturen, Menüleistenanzeige, Temperaturwarnungen, Sprache, Export, öffentliche Links, Handbücher, Aktivitätsanzeige und Beenden in einem kompakten gemeinsamen Menü.
- Startet auf Englisch und erlaubt die lokale Umstellung der sichtbaren App-Oberfläche auf Deutsch.
- Keine Drittanbieter-Abhängigkeiten, Netzwerkkommunikation, Telemetrie oder Konten.

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

## Projektstatus

ThermalAtlas befindet sich in aktiver Entwicklung. Herunterladbare Vorab-Builds werden über die [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases) veröffentlicht.

## Lizenz

ThermalAtlas steht unter der [GNU General Public License v3.0](LICENSE).

## Links

- [Benutzerhandbuch (PDF)](Documentation/ThermalAtlas-Handbuch-DE.pdf)
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
