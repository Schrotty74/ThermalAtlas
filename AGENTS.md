# ThermalAtlas – Arbeitsregeln

- Vor jeder Projektarbeit zuerst `PROJECT_CONTEXT.md` und `NEXT_STEPS.md` vollständig lesen.
- `PROJECT_CONTEXT.md` ist die dauerhafte Quelle für den aktuellen Projektkontext.
- `NEXT_STEPS.md` enthält ausschließlich tatsächlich offene Aufgaben, bestätigte Bugs und nächste Schritte.
- Bei relevanten Änderungen an Funktionen, Architektur, Datenformaten, Datenschutz, Build-/Release-Abläufen oder offenen Aufgaben die betroffenen Kontextdateien im selben Auftrag aktualisieren.
- Erledigte Punkte aus `NEXT_STEPS.md` entfernen oder nach vorhandenen Projektregeln archivieren. Historische Informationen niemals ersatzlos löschen.
- Keine Projektzustände, Testergebnisse oder offenen Punkte erfinden.
- Anschließend nur die für den Auftrag relevanten Projektdateien und zusätzlichen Dokumente lesen. Den aktuellen Repository-Stand höher gewichten als frühere Chats.
- Weitere projektspezifische Regeln und Dokumente beachten.

## Projektkontext pflegen

Bei relevanten Änderungen an Funktionen, Architektur, Datenformaten, Kompatibilität, Datenschutz, Build-/Release-Abläufen, wichtigen Design- oder Projektentscheidungen, bekannten Problemen oder offenen Aufgaben:

- `PROJECT_CONTEXT.md` und `NEXT_STEPS.md` gegen den tatsächlichen aktuellen Projektstand prüfen und vollständig aktualisieren.
- Neue oder geänderte Funktionen, Architekturentscheidungen, Datenformate, Kompatibilität, Datenschutz- sowie Build-/Release-Änderungen berücksichtigen.
- Offene Aufgaben in `NEXT_STEPS.md` pflegen und erledigte Punkte daraus entfernen.
- Historische Informationen nach den vorhandenen Projektregeln archivieren, niemals ersatzlos löschen.
- Keine Testergebnisse, Funktionsstände oder sonstigen Informationen dokumentieren, die nicht tatsächlich geprüft beziehungsweise belegt sind.

Reine kleine Codebereinigungen ohne Änderung von Verhalten, Architektur oder Projektstatus müssen die Kontextdateien nicht unnötig verändern.

Die Anweisung **„Projektkontext aktualisieren“** bedeutet stets, diesen vollständigen Abgleich durchzuführen.

## Projektgrenzen

- ThermalAtlas ist eine reine, lokale Temperaturanzeige. Keine Lüfter-, Energie- oder sonstigen Systemeinstellungen verändern.
- Sensorzugriffe defensiv kapseln; fehlende oder nicht lesbare Sensoren stets korrekt als `Nicht verfügbar` behandeln.
- Dev bleibt lokal und ist von Beta und Final getrennt. Keine Commits, Tags, Releases, Pushes oder Veröffentlichungen ohne ausdrücklichen Auftrag.
- Beta-Quellstände und Beta-Veröffentlichungen gehören auf den Git-Branch `beta`. Finale Quellstände und finale Veröffentlichungen gehören auf `main`. Dev wird niemals gepusht.
- Für einen Dev-Auftrag weder Datenschutz-/Sicherheitsprüfungen für öffentliche Artefakte ausführen noch README, Handbücher oder Handbuch-PDFs ergänzen oder neu erzeugen. Diese Schritte erfolgen ausschließlich im Rahmen eines ausdrücklich beauftragten Beta- oder Final-Builds, der anschließend auf Git gepusht wird.
- Keine Drittanbieter-Abhängigkeiten oder globalen Entwicklungswerkzeuge automatisch hinzufügen oder aktualisieren.
- Bei App-Arbeit Projektmanifest, Build-Skript und relevante Konfigurationen lesen, bevor Abhängigkeiten oder Build-Annahmen getroffen werden.
