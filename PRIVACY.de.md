# Datenschutzbericht

**Deutsch** · [English](PRIVACY.md)

ThermalAtlas ist eine ausschließlich lokale Temperaturanzeige. Die App erhebt, überträgt oder verkauft keine personenbezogenen Daten.

## Gelesene Daten

- Lokale Apple-Silicon-SMC-Temperaturwerte über rein lesende IOKit-Aufrufe.
- Lokale Laufwerksmetadaten und SMART-Temperaturen über `diskutil info -plist`.
- Das lokal gewählte Theme und Scan-Refresh-Intervall.

## Speicherung

Nur das gewählte Theme und Scan-Refresh-Intervall werden in lokalen `UserDefaults` gespeichert. Dev, Beta und Final besitzen getrennte Bundle-Kennungen, Einstellungen und Caches. Temperaturwerte werden nicht dauerhaft gespeichert.

## Netzwerk und Systemänderungen

Die App enthält keine Netzwerkfunktionen, Telemetrie, Analyse-Dienste, Konten, Cloud-Synchronisation, Werbung oder Drittanbieter-Abhängigkeiten. Sie besitzt keine Lüftersteuerung, Energiesteuerung oder schreibenden Sensorpfade. Die Aktivitätsanzeige öffnet sich nur nach einem Klick.

## Grenzen

Einige Laufwerke und externe Gehäuse geben keine SMART-Temperatur aus. Private Apple-Silicon-SMC-Schlüssel können sich mit macOS-Updates ändern oder fehlen. ThermalAtlas zeigt dann „Nicht verfügbar“, statt Werte zu schätzen.
