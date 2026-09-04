# Datenschutzbericht

**Deutsch** · [English](PRIVACY.md)

ThermalAtlas ist eine ausschließlich lokale Temperaturanzeige. Die App erhebt, überträgt oder verkauft keine personenbezogenen Daten.

## Gelesene Daten

- Lokale Apple-Silicon-SMC-Temperaturwerte über rein lesende IOKit-Aufrufe.
- Lokale Laufwerksmetadaten und SMART-Temperaturen über `diskutil info -plist`.
- Öffentliche macOS-CPU-Tick-Daten, die aktuell vom Apple-Grafiktreiber veröffentlichte GPU-Gesamtauslastung und lokale virtuelle Speicherstatistiken für den angezeigten CPU-/GPU-Last- und Speicherkontext sowie aktuelle Stromquelle/Akkustand und Energiesparmodus.
- Beim Öffnen der Systeminformationen verarbeitet der aktuelle Build die lokalen `system_profiler`-Hardware- und Anzeigeprofile, um Mac-Modell, Chip, CPU-/GPU-Kerne, Arbeitsspeicher, Kapazität des internen Speichers und macOS-Version anzuzeigen. Der sichtbare Snapshot zeigt oder speichert keine Seriennummern oder UUIDs; das Hardwareprofil kann sie jedoch enthalten. Das Ersetzen dieser breiten Profilabfrage durch gezielte Systemwerte ist in `NEXT_STEPS.md` festgehalten.

## Speicherung

Lokale `UserDefaults` speichern das gewählte Theme, Scan-Refresh-Intervall, die Anzeigesprache, sichtbare Sensorgruppen, den Menüleistenmodus, die Fenstergröße und Temperaturwarn-Einstellungen. Die optionale Registrierung **Bei Anmeldung starten** verwaltet macOS über `SMAppService`; sie wird nicht in `UserDefaults` gespeichert. Zusätzlich speichert ThermalAtlas je Sensor minutenweise gemittelte Temperaturverläufe für höchstens 24 Stunden, damit das Diagramm in der App dargestellt werden kann. Jeder gespeicherte Verlaufspunkt enthält nur eine lokale Sensor-ID, Zeitstempel, Temperaturmittelwert und Anzahl der Messungen. CPU-/GPU-Last, RAM-Nutzung, Stromquelle/Akku, Energiesparmodus und Systeminformationen werden angezeigt, aber nicht gespeichert. Dev, Beta und Final besitzen getrennte Bundle-Kennungen, Einstellungen und Caches.

## Netzwerk und Systemänderungen

Die App enthält keine Hintergrundnetzwerkfunktionen, Telemetrie, Analyse-Dienste, Konten, Cloud-Synchronisation, Werbung oder Drittanbieter-Abhängigkeiten. Sie besitzt keine Lüftersteuerung, Energiesteuerung oder schreibenden Sensorpfade. Ein Text- oder CSV-Export entsteht nur nach deiner Auswahl und an einem lokal gewählten Speicherort. Die Aktivitätsanzeige sowie die optionalen Links zu GitHub, Homepage und Handbüchern öffnen sich nur nach einem Klick auf den jeweiligen Menüeintrag.

## Grenzen

Einige Laufwerke und externe Gehäuse geben keine SMART-Temperatur aus. Private Apple-Silicon-SMC-Schlüssel können sich mit macOS-Updates ändern oder fehlen. ThermalAtlas zeigt dann „Nicht verfügbar“, statt Werte zu schätzen.
