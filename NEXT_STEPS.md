# ThermalAtlas – Nächste Schritte

## Weiter beobachten

- Die aus Beta.7 übernommenen Korrekturen in Final 1.2.0 praktisch in EN/DE prüfen: Temperaturkarten mit Tastatur öffnen/schließen, Diagrammpunkte mit Pfeiltasten und den neuen Schaltflächen wählen und die Auswahl mit Escape löschen. VoiceOver für Menüleiste, Mini-Anzeige und Diagramme prüfen; außerdem die Mini-Fenstergrößenwahl per Tastatur, den macOS-Einstellungsbefehl, die verständlichere Erklärung zum Systemkontext hinter der Info-Schaltfläche in beiden Sprachen sowie den CSV-Export über App-Menü und echten Speichern-Dialog. Fehlerdialog, Wiederholung und Abbruch sind in EN/DE mit echten Schreibfehlern und nativen Fehlerdialogen isoliert geprüft; die Speicherortwahl war dabei vorgegeben. Die spezielle Einstellung „Bewegung reduzieren“ beim Öffnen/Schließen von Verläufen separat prüfen. Quellcode, Regressionstests, synthetische Werte-/Kurvenbilder und Dev-Build sind geprüft; native macOS-Bedienelemente werden vom verwendeten Bildrenderer nur als Platzhalter dargestellt.

- Weitere Leistungsänderungen erst nach einer gezielten Instruments-Messung beurteilen, besonders bei geöffneten 24-Stunden-Verläufen und aktiver Mini-Anzeige. Synthetische Benchmarks bestätigen weniger Aufwand für Verlaufsbereinigung und Punktwahl; die Gesamt-CPU-Last, Energie und tatsächlichen Renderzeiten der laufenden App wurden nicht gemessen.

- Temperatur- und Lüfterverläufe manuell in EN/DE prüfen: Lüfterwert anklicken, alle fünf Zeiträume (1/3/6/12/24 h), Punktwahl und Min/Max/Ø in Standard- und Kompaktansicht. Bei einem erneuten GPU-Ausfall die sichtbare Altersangabe und den Übergang nach 15 Sekunden zu „Nicht verfügbar“ prüfen. Speicherung und Zeitfilter sind automatisiert geprüft. Die bereitgestellte Aufnahme bestätigt die sichtbare englische Lüfteransicht; weitere Bedienprüfungen bleiben offen.

- Die aktuell betrachtete Darstellung passt laut Rückmeldung vom 6. Oktober 2026 soweit. Ergänzend bleiben gezielte Prüfungen für erhöhte Kontraste, „Transparenz reduzieren“ und bislang nicht bestätigte Theme-/Ansichtswechsel offen. Die Rückmeldung nennt keine einzelnen geprüften Varianten.

- Die in Beta.5 veröffentlichte und lokal vorhandene Updatefunktion weiter manuell in EN/DE prüfen: Menübedienung, Hinweisfenster, Release-Link und automatische Meldung bei geschlossenem Hauptfenster beziehungsweise aktiver Mini-Anzeige. Die bereitgestellte englische Menüaufnahme zeigt die neuen Optionen und steht in beiden lokalen Handbüchern; eine vollständige Bedienprüfung ersetzt sie nicht.

- GPU-Verfügbarkeit weiter beobachten: Laut Rückmeldung vom 6. Oktober 2026 sind aktuell keine weiteren Ausfälle aufgefallen. Nur bei einem erneuten Ausfall gezielt in einem Debug-Dev-Lauf die IOKit-Rückgabecodes und verfügbaren Antworten je GPU-Schlüssel erfassen; keine erfundenen Ersatzwerte anzeigen.
- Falls wiederholbare SwiftUI-Previews für die Temperaturansicht benötigt werden, zuerst ausdrücklich entscheiden, ob das Xcode-Build-Layout des Executable-Targets mit `ENABLE_DEBUG_DYLIB=YES` angepasst werden darf. Ohne diese Änderung kann Xcode die Previews nicht ausführen.

- Öffentlichen Final-/Beta-Status im Schrotty74-Profil und Portfolio nach der Veröffentlichung abgleichen; die Prüfung am 11. Oktober 2026 nach der Veröffentlichung nennt dort noch Final 1.1.0 und Beta 1.2.0-beta.7.

## Spätere Wartungsaufgabe

- `ThermalPopover.swift` bei einem späteren ausdrücklichen Auftrag schrittweise in zusammengehörige SwiftUI-Ansichten aufteilen, etwa Temperaturkarten, Systemkontext und Menüs. `HistoryChart.swift` ist bereits getrennt. Verhalten, Gestaltung und Datenfluss erhalten; jeweils nur einen Bereich auslagern und anschließend Build sowie betroffene Bedienung, Popover und Fenstergrößen prüfen. Die Aufteilung ist nicht dringend und wird jetzt nicht umgesetzt.
