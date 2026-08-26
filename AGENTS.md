# AGENTS.md

Vor jeder Projektarbeit zuerst `PROJECT_CONTEXT.md` und `NEXT_STEPS.md` lesen.

## Verbindliche Arbeitsregeln

Vor jeder weiteren Projektarbeit `PROJECT_CONTEXT.md` und `NEXT_STEPS.md` vollständig lesen.

## Verbindliche Arbeitsregeln

- `PROJECT_CONTEXT.md` ist die dauerhafte Quelle für den aktuellen Projektkontext dieses Branches.
- `NEXT_STEPS.md` enthält ausschließlich tatsächlich offene Aufgaben, bestätigte Bugs und konkrete nächste Schritte.
- Bei relevanten Änderungen an Funktionen, Architektur, Datenformaten, Datenschutz, Build-/Release-Abläufen oder offenen Aufgaben die betroffenen Kontextdateien im selben Auftrag aktualisieren.
- Erledigte Punkte aus `NEXT_STEPS.md` entfernen oder nach vorhandenen Projektregeln archivieren. Historische Informationen niemals ersatzlos löschen.
- Keine Projektzustände, Testergebnisse, Builds, Prüfungen oder offenen Punkte erfinden. Einen Erfolg nur behaupten, wenn die betreffende Prüfung tatsächlich ausgeführt wurde.
- Anschließend nur die für den Auftrag relevanten Projektdateien und zusätzlichen Dokumente lesen. Den aktuellen Repository-Stand höher gewichten als frühere Chats.
- Weitere projektspezifische Regeln und Dokumente beachten.
- Bestehende Architektur, Datenformate, Einstellungen und Benutzerabläufe erhalten, sofern eine Änderung nicht ausdrücklich verlangt oder technisch notwendig ist.
- Keine unnötigen Refactorings, neuen Abhängigkeiten oder Funktionsentfernungen ohne klaren Auftrag.
- Fragen nicht automatisch als Änderungsauftrag behandeln. Dateien, Builds, Tests oder Veröffentlichungsaktionen nur ausführen, wenn der Auftrag dies verlangt oder sie für die ausdrücklich beauftragte Änderung notwendig sind.
- Erklärungen verständlich formulieren und keine besonderen technischen Vorkenntnisse voraussetzen. Keine persönlichen Aussagen über Fähigkeiten, Kenntnisse, Gewohnheiten oder Arbeitsweise des Entwicklers dokumentieren.
- Keine Regeln zur Vorbereitung oder Fortsetzung eines neuen Chats aufnehmen. Solche Anweisungen gehören ausschließlich in `CHAT_TEMPLATE.md` beziehungsweise in einen separaten Start-Prompt.
- Projektweite Arbeitsregeln und Kontextvorgaben werden bei relevanten Änderungen im selben Auftrag aktualisiert. Commits und Pushes dieser Änderungen erfolgen jedoch ausschließlich auf ausdrücklichen Auftrag. Ohne ausdrücklichen Auftrag bleiben Änderungen lokal und werden nicht automatisch auf `beta` oder `main` übertragen.

## Projektkontext pflegen

Bei relevanten Änderungen an Funktionen, Architektur, Datenformaten, Kompatibilität, Datenschutz, Build-/Release-Abläufen, wichtigen Design- oder Projektentscheidungen, bekannten Problemen oder offenen Aufgaben:

- `PROJECT_CONTEXT.md` und `NEXT_STEPS.md` gegen den tatsächlichen aktuellen Projektstand prüfen und vollständig aktualisieren.
- Neue oder geänderte Funktionen, Architekturentscheidungen, Datenformate, Kompatibilität, Datenschutz- sowie Build-/Release-Änderungen berücksichtigen.
- Offene Aufgaben in `NEXT_STEPS.md` pflegen und erledigte Punkte daraus entfernen.
- Historische Informationen nach den vorhandenen Projektregeln archivieren, niemals ersatzlos löschen.
- Keine Testergebnisse, Funktionsstände oder sonstigen Informationen dokumentieren, die nicht tatsächlich geprüft beziehungsweise belegt sind.

Reine kleine Codebereinigungen ohne Änderung von Verhalten, Architektur oder Projektstatus müssen die Kontextdateien nicht unnötig verändern.

Die Anweisung **„Projektkontext aktualisieren“** bedeutet stets, diesen vollständigen Abgleich durchzuführen.

## Projekt- und Branchgrenzen

- ThermalAtlas ist eine reine, lokale Temperaturanzeige. Keine Lüfter-, Energie- oder sonstigen Systemeinstellungen verändern.
- Sensorzugriffe defensiv kapseln; fehlende oder nicht lesbare Sensoren stets korrekt als `Nicht verfügbar` behandeln.
- Dev bleibt lokal und ist von Beta und Final getrennt.
- Beta-Quellstände und Beta-Veröffentlichungen gehören auf den Git-Branch `beta`. Finale Quellstände und finale Veröffentlichungen gehören auf `main`. Dev wird niemals gepusht.
- Nach einem ausdrücklich beauftragten Final-Build wird der Handbuchstand auf `main` mit `beta` verglichen. Sind die Final-Handbücher aktueller, werden ausschließlich `MANUAL.md`, `MANUAL.de.md`, die zugehörigen PDFs unter `Documentation/`, `Documentation/build_manuals.py` sowie dessen unmittelbar verwendete Bildressourcen nach `beta` übernommen und gepusht. Diese ausdrücklich erlaubte Dokumentationssynchronisierung überträgt weder Final-Quellcode noch Version, Tag oder Release nach `beta`.
- Keine Versionen, Buildnummern, Commits, Tags, Releases, Pushes oder Veröffentlichungen ohne ausdrücklichen Auftrag erstellen oder ändern.
- Für einen Dev-Auftrag weder Datenschutz-/Sicherheitsprüfungen für öffentliche Artefakte ausführen noch README, Handbücher oder Handbuch-PDFs ergänzen oder neu erzeugen. Diese Schritte erfolgen ausschließlich im Rahmen eines ausdrücklich beauftragten Beta- oder Final-Builds, der anschließend auf Git gepusht wird.
- Bei jedem ausdrücklich beauftragten Beta- oder Final-Build vor Commit, Tag und Veröffentlichung alle betroffenen Markdown-Dokumente gegen den tatsächlichen Stand aktualisieren: insbesondere `README.md` und `README.de.md`, `FEATURES.md` und `FEATURES.de.md`, `MANUAL.md` und `MANUAL.de.md`, `PRIVACY.md` und `PRIVACY.de.md`, `CHANGELOG.md`, `PROJECT_CONTEXT.md` sowie `NEXT_STEPS.md`. Englische und deutsche Gegenstücke bleiben inhaltlich gleichwertig. Der englische Changelog ist vor der Veröffentlichung zu ergänzen und seine Abschnitte werden als GitHub-Release-Notes verwendet; automatisch generierte Release-Notes reichen nicht aus.
- Keine Drittanbieter-Abhängigkeiten oder globalen Entwicklungswerkzeuge automatisch hinzufügen oder aktualisieren.
- Bei App-Arbeit Projektmanifest, Build-Skript und relevante Konfigurationen lesen, bevor Abhängigkeiten oder Build-Annahmen getroffen werden.

## Datenschutzregel für das öffentliche Repository
Dieses Repository und seine Git-Historie sind öffentlich. Jeder eingecheckte Inhalt muss deshalb ohne weitere Bereinigung öffentlich vertretbar sein.

Nicht veröffentlicht oder dokumentiert werden dürfen insbesondere:

- private, personenbezogene oder vertrauliche Daten
- reale Namen oder private Kontaktdaten; für öffentliche Entwicklerangaben ausschließlich `Schrotty74`
- Informationen über persönliche Fähigkeiten, Kenntnisse, Gewohnheiten oder Arbeitsweise des Entwicklers
- lokale Benutzernamen, Home-Verzeichnisse sowie konkrete lokale Benutzer-, Volume- oder Backup-Pfade
- private Hostnamen, interne Netzwerkadressen oder interne URLs
- Gerätekennungen, Seriennummern, Hardware-IDs oder vergleichbare Identifikatoren
- Passwörter, API-Keys, Tokens, Secrets, Zugangsdaten oder private Accountdaten
- private Signing-Informationen, Zertifikatsgeheimnisse oder andere vertrauliche Release-Zugangsdaten
- Lizenzschlüssel oder private Lizenzdaten
- echte Benutzer-, Gesundheits-, Finanz-, Katalog-, Scan-, Mess-, Export- oder sonstige Nutzerdaten
- echte Backups, Datenbanken oder private Arbeitsdateien
- Logs, Crashreports oder Diagnoseausgaben mit privaten oder identifizierenden Informationen
- Screenshots oder Medien mit realen Nutzerdaten oder identifizierenden Informationen
- Metadaten, aus denen private Informationen rekonstruiert werden können
- Inhalte aus privaten Chats, E-Mails oder anderen nicht öffentlichen Quellen

Beispiele, Testdaten, Demo-Dateien, Screenshots und Dokumentation müssen ausschließlich synthetische, anonymisierte oder eindeutig fiktive Daten verwenden.

Pfade in öffentlicher Dokumentation müssen neutral sein, zum Beispiel `/Users/example/...` oder `~/Library/Application Support/AppName/`. Echte lokale Benutzernamen oder persönliche Volume-Namen dürfen nicht verwendet werden.

Informationen über die lokale Entwicklungsumgebung werden nur dokumentiert, wenn sie technisch für das Projekt erforderlich sind. Persönliche oder gerätespezifische Details werden nach Möglichkeit durch allgemeine technische Anforderungen ersetzt.

Vor Commit, Push oder Veröffentlichung ist zu prüfen, dass keine privaten oder sensiblen Daten enthalten sind. Vor finalen Veröffentlichungen gelten zusätzlich die im Projekt dokumentierten erweiterten Datenschutz- und Release-Prüfungen.

Wenn unklar ist, ob eine Information öffentlich sein darf, wird sie nicht veröffentlicht, bis dies eindeutig geklärt ist.
