# ThermalAtlas – Nächste Schritte

## Priorität 1

- Falls der sporadische GPU-Ausfall erneut auftritt, ihn gezielt in einem Debug-Dev-Lauf erfassen: IOKit-Rückgabecodes und pro GPU-Schlüssel verfügbare Antworten protokollieren, ohne die produktive Anzeige mit erfundenen Ersatzwerten zu verändern. Seit der letzten Änderung am GPU-Fix zeigte der lokale Dev-Lauf durchgehend GPU-Werte.
- Vor dem ersten Final-Release die auf `beta` vorhandenen Release-Paket- und Datenschutzskripte auf `main` bereitstellen und dort mit einem ausdrücklich beauftragten Final-Paketlauf verifizieren. Den freigegebenen Beta-Stand der kurzen README sowie der ausführlichen, gleichwertigen `FEATURES.md`- und `FEATURES.de.md`-Seiten dabei auf `main` übernehmen. Bis dahin keinen Final-Release erstellen.

## Priorität 2

- Die M1- bis M5-CPU- und GPU-Schlüsselgruppen auf repräsentativer Hardware gegen tatsächlich lesbare Rohsensoren prüfen und nur mit belegbarer Zuordnung ergänzen oder anpassen. CPU- und GPU-Erkennung sind bislang nur auf M4 Max lokal sowie auf M5 und M5 Pro extern bestätigt; alle übrigen Varianten und ihre Rohsensoren bleiben offen.
- Die getrennten Laufwerkstopologie-, minütlichen SSD-Temperatur- und täglichen SMART-Zyklen in einem längeren echten Dev-Lauf mit vielen `diskutil`-Kennungen prüfen; insbesondere tägliche SMART-Aktualisierung, SSD-Verlauf und Warnungen beobachten. Mount-/Unmount-Erkennung, SSD-Karteninhalt sowie der sichtbare 1-Sekunden-Takt für CPU/GPU wurden lokal erfolgreich geprüft.
- Alle vier Themes manuell in Hell- und Dunkelmodus sowie mit aktivierter Bewegungs- und Transparenzreduktion prüfen.
- Temperaturverlauf nach mindestens zwei Minuten Laufzeit sowie die macOS-Warnberechtigung, die Ein-Minuten-Schwelle, die erneute Warnung erst nach einer Abkühlung, Sensor-Details, Klartext-/CSV-Export, den unabhängigen 0,5-Sekunden-Systemkontext (CPU-/GPU-Last, RAM-Auslastung, Stromquelle/Akku, Energiesparmodus) und Menüleistenanzeige (Alle Werte/Nur Symbol) in einem echten Dev-Lauf manuell prüfen.

## Priorität 3

- Mit ausdrücklicher Freigabe entscheiden, ob das ältere lokale Bundle `Build/Dev/Thermal View Dev.app` entfernt oder als Legacy-Artefakt dokumentiert werden soll.
