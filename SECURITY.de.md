# Sicherheitsrichtlinie

[English](SECURITY.md)

## Sicherheitsmodell

ThermalAtlas ist eine ausschließlich lesende Monitoring-App für Apple-Silicon-Macs. Sie liest verfügbare SMC-Temperaturwerte, Laufwerks-/SMART-Informationen und lokalen Systemkontext, bietet aber keine Schreibzugriffe für Lüfter, SMC, Energie- oder Hardwaresteuerung. Administrator- oder Root-Rechte sind nicht erforderlich. Es gibt keine Telemetrie, Analytics oder Benutzerkonten. Die optionale Funktion App-Updates prüft GitHub auf neuere Final- und Beta-Versionen. Jetzt prüfen startet sofort; automatische Prüfungen sind zunächst aus und können täglich, wöchentlich oder monatlich erfolgen. Dabei werden keine Sensor-, Laufwerks-, Geräte- oder installierten Versionsdaten gesendet. GitHub erhält die IP-Adresse der Verbindung. Gespeicherte Cookies oder Zugangsdaten werden nicht verwendet; Updates werden nicht automatisch heruntergeladen oder installiert.

Der Apple-Silicon-SMC-Zugriff verwendet private macOS-Schnittstellen. Fehlende Schlüssel und IOKit-Fehler werden als nicht verfügbare Messwerte behandelt. Die Kompatibilität kann sich mit macOS-Updates ändern.

## Sicherheitslücke melden

Bitte veröffentliche sensible Details zu Sicherheitslücken nicht in einem öffentlichen GitHub-Issue. Kontaktiere den Repository-Inhaber privat. Nenne die ThermalAtlas- und macOS-Version, gegebenenfalls Mac-Modell/Chip, Schritte zum Reproduzieren und bereinigte Logs oder Screenshots. Seriennummern, UUIDs oder andere unnötige Gerätekennungen sollten nicht enthalten sein.

## Geltungsbereich

Relevante Meldungen umfassen unter anderem den ausschließlich lesenden SMC-/IOKit-Sensorzugriff, Laufwerks- und SMART-Abfragen, Systeminformationen, lokale Temperatur- und Lüfterverläufe, Warnungen, CSV-/Diagnoseexporte, Start-at-Login-Verhalten, lokale Einstellungen, GitHub-Updateprüfungen und jede unbeabsichtigte Möglichkeit, Hardware- oder Systemzustände zu verändern.

Vielen Dank, dass du dabei hilfst, ThermalAtlas und seine Nutzer sicher zu halten.
