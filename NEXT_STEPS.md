# ThermalAtlas – Nächste Schritte

## Priorität 1

- Den sporadischen GPU-Ausfall gezielt in einem Debug-Dev-Lauf erfassen: IOKit-Rückgabecodes und pro GPU-Schlüssel verfügbare Antworten protokollieren, ohne die produktive Anzeige mit erfundenen Ersatzwerten zu verändern.
- Vor dem ersten Final-Release die auf `beta` vorhandenen Release-Paket- und Datenschutzskripte auf `main` bereitstellen und dort mit einem ausdrücklich beauftragten Final-Paketlauf verifizieren. Bis dahin keinen Final-Release erstellen.

## Priorität 2

- CPU-Sensorzuordnung auf dem Ziel-Mac weiter gegen die in Stats sichtbaren Quellsensoren prüfen und nur mit belegbarer Zuordnung anpassen.
- Alle vier Themes manuell in Hell- und Dunkelmodus sowie mit aktivierter Bewegungs- und Transparenzreduktion prüfen.
- Temperaturverlauf nach mindestens zwei Minuten Laufzeit sowie die macOS-Warnberechtigung, die Ein-Minuten-Schwelle, die erneute Warnung erst nach einer Abkühlung, Sensor-Details, Klartext-/CSV-Export, Systemkontext (CPU-Last, Stromquelle/Akku, Energiesparmodus) und Menüleistenanzeige (Alle Werte/Nur Symbol) in einem echten Dev-Lauf manuell prüfen.

## Priorität 3

- Mit ausdrücklicher Freigabe entscheiden, ob das ältere lokale Bundle `Build/Dev/Thermal View Dev.app` entfernt oder als Legacy-Artefakt dokumentiert werden soll.
