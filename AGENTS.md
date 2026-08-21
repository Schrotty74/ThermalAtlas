# ThermalAtlas – Arbeitsregeln

- Vor jeder Projektarbeit zuerst `PROJECT_CONTEXT.md` und `NEXT_STEPS.md` vollständig lesen.
- `PROJECT_CONTEXT.md` ist die dauerhafte Quelle für den aktuellen Projektkontext.
- `NEXT_STEPS.md` enthält ausschließlich tatsächlich offene Aufgaben, bestätigte Bugs und nächste Schritte.
- Bei relevanten Änderungen an Funktionen, Architektur, Datenformaten, Datenschutz, Build-/Release-Abläufen oder offenen Aufgaben die betroffenen Kontextdateien im selben Auftrag aktualisieren.
- Erledigte Punkte aus `NEXT_STEPS.md` entfernen oder nach vorhandenen Projektregeln archivieren. Historische Informationen niemals ersatzlos löschen.
- Keine Projektzustände, Testergebnisse oder offenen Punkte erfinden.
- Anschließend nur die für den Auftrag relevanten Projektdateien und zusätzlichen Dokumente lesen. Den aktuellen Repository-Stand höher gewichten als frühere Chats.
- Weitere projektspezifische Regeln und Dokumente beachten.

## Projektgrenzen

- ThermalAtlas ist eine reine, lokale Temperaturanzeige. Keine Lüfter-, Energie- oder sonstigen Systemeinstellungen verändern.
- Sensorzugriffe defensiv kapseln; fehlende oder nicht lesbare Sensoren stets korrekt als `Nicht verfügbar` behandeln.
- Dev bleibt lokal und ist von Beta und Final getrennt. Keine Commits, Tags, Releases, Pushes oder Veröffentlichungen ohne ausdrücklichen Auftrag.
- Keine Drittanbieter-Abhängigkeiten oder globalen Entwicklungswerkzeuge automatisch hinzufügen oder aktualisieren.
- Bei App-Arbeit Projektmanifest, Build-Skript und relevante Konfigurationen lesen, bevor Abhängigkeiten oder Build-Annahmen getroffen werden.
