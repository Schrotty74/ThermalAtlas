# Datenschutzbericht

**Deutsch** · [English](PRIVACY.md)

ThermalAtlas hält die Temperaturanzeige lokal und verkauft keine personenbezogenen Daten. Optionale GitHub-Updateprüfungen machen GitHub die IP-Adresse der Verbindung zugänglich.

## Gelesene Daten

- Lokale Apple-Silicon-SMC-Temperaturwerte über rein lesende IOKit-Aufrufe.
- Lokale Laufwerksmetadaten und SMART-Temperaturen über `diskutil info -plist`.
- Öffentliche macOS-CPU-Tick-Daten, rein lesende SMC-Lüfterdrehzahlen und lokale virtuelle Speicherstatistiken für den angezeigten CPU-Last-, Lüfter- und Speicherkontext sowie aktuelle Stromquelle/Akkustand und Energiesparmodus.
- Beim Öffnen der Systeminformationen liest die App die angezeigten Werte für Mac-Modell, Chip, CPU-/GPU-Kerne, Arbeitsspeicher, Kapazität des internen Speichers, macOS-Version und den thermischen macOS-Zustand über gezielte lokale Systemabfragen. Seriennummern und UUIDs werden nicht abgefragt, angezeigt oder gespeichert.

## Speicherung

Lokale `UserDefaults` speichern das gewählte Theme, Scan-Refresh-Intervall, die Anzeigesprache, sichtbare Sensorgruppen, den Menüleistenmodus, die Fenstergröße, den Mini-Anzeigemodus, die Auswahl „Immer im Vordergrund“ und Temperaturwarn-Einstellungen. Die optionale Registrierung **Bei Anmeldung starten** verwaltet macOS über `SMAppService`; sie wird nicht in `UserDefaults` gespeichert. Zusätzlich speichert ThermalAtlas je Sensor minutenweise gemittelte Temperaturverläufe für höchstens 24 Stunden, damit das Diagramm in der App dargestellt werden kann. Jeder gespeicherte Verlaufspunkt enthält nur eine lokale Sensor-ID, Zeitstempel, Temperaturmittelwert und Anzahl der Messungen. Lüfterverläufe werden getrennt unter `thermalatlas.fanHistory` gespeichert: Jeder Punkt enthält den lokalen SMC-Lüfterindex, Zeitstempel, RPM-Mittelwert und die Anzahl der Messungen. Die Speicherung ist auf 24 Stunden und höchstens einen Schreibvorgang pro Minute begrenzt. CPU-Last, RAM-Nutzung, Stromquelle/Akku, Energiesparmodus und Systeminformationen werden angezeigt, aber nicht gespeichert. Dev, Beta und Final besitzen getrennte Bundle-Kennungen, Einstellungen und Caches.

Updateintervalle, Zeitpunkte der letzten erfolgreichen und versuchten Prüfung sowie bereits gemeldete Release-Tags werden ebenfalls lokal in `UserDefaults` gespeichert.

## Netzwerk und Systemänderungen

Die App enthält keine Telemetrie, Analyse-Dienste, Konten, Cloud-Synchronisation, Werbung oder Drittanbieter-Abhängigkeiten. Sie besitzt keine Lüftersteuerung, Energiesteuerung oder schreibenden Sensorpfade. Ein Text- oder CSV-Export entsteht nur nach deiner Auswahl und an einem lokal gewählten Speicherort. Die Aktivitätsanzeige sowie die optionalen Links zu GitHub, Homepage und Handbüchern öffnen sich nur nach einem Klick auf den jeweiligen Menüeintrag.

## Grenzen

Einige Laufwerke und externe Gehäuse geben keine SMART-Temperatur aus. Private Apple-Silicon-SMC-Schlüssel können sich mit macOS-Updates ändern oder fehlen. ThermalAtlas zeigt dann „Nicht verfügbar“, statt Werte zu schätzen.

## Optionale Updateprüfungen

Die optionale Funktion App-Updates prüft GitHub auf neuere Final- und Beta-Versionen. Jetzt prüfen startet sofort; automatische Prüfungen sind zunächst aus und können täglich, wöchentlich oder monatlich erfolgen. Dabei werden keine Sensor-, Laufwerks-, Geräte- oder installierten Versionsdaten gesendet. GitHub erhält die IP-Adresse der Verbindung. Gespeicherte Cookies oder Zugangsdaten werden nicht verwendet; Updates werden nicht automatisch heruntergeladen oder installiert.
