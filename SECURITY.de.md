# Sicherheitsrichtlinie

[English](SECURITY.md)

## Sicherheitsmodell

ThermalAtlas ist eine ausschließlich lesende Monitoring-App für Apple-Silicon-Macs. Sie liest verfügbare SMC-Temperaturwerte, Laufwerks-/SMART-Informationen und lokalen Systemkontext, bietet aber keine Schreibzugriffe für Lüfter, SMC, Energie- oder Hardwaresteuerung. Administrator- oder Root-Rechte sind nicht erforderlich. Es gibt keine Telemetrie, Analytics, Benutzerkonten oder Netzwerkkommunikation im Hintergrund.

Der Apple-Silicon-SMC-Zugriff verwendet private macOS-Schnittstellen. Fehlende Schlüssel und IOKit-Fehler werden als nicht verfügbare Messwerte behandelt. Die Kompatibilität kann sich mit macOS-Updates ändern.

## Sicherheitslücke melden

Bitte veröffentliche sensible Details zu Sicherheitslücken nicht in einem öffentlichen GitHub-Issue. Kontaktiere den Repository-Inhaber privat. Nenne die ThermalAtlas- und macOS-Version, gegebenenfalls Mac-Modell/Chip, Schritte zum Reproduzieren und bereinigte Logs oder Screenshots. Seriennummern, UUIDs oder andere unnötige Gerätekennungen sollten nicht enthalten sein.

## Geltungsbereich

Relevante Meldungen umfassen unter anderem den ausschließlich lesenden SMC-/IOKit-Sensorzugriff, Laufwerks- und SMART-Abfragen, Systeminformationen, lokalen Temperaturverlauf, Warnungen, CSV-/Diagnoseexporte, Start-at-Login-Verhalten, lokale Einstellungen und jede unbeabsichtigte Möglichkeit, Hardware- oder Systemzustände zu verändern.

Vielen Dank, dass du dabei hilfst, ThermalAtlas und seine Nutzer sicher zu halten.
