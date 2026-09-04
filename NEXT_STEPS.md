# ThermalAtlas – Nächste Schritte

## Vor dem nächsten Beta- oder Final-Build erledigen

- Die Systeminfo-Abfrage in `Sources/ThermalView/SystemInformation.swift` technisch auf gezielte lokale Systemwerte umstellen. Der aktuelle `system_profiler SPHardwareDataType`-Aufruf verarbeitet eine vollständige Hardwareprofilantwort, die Seriennummern oder UUIDs enthalten kann, obwohl ThermalAtlas sie weder anzeigt noch speichert. Die Ersatzabfrage darf nur die tatsächlich sichtbaren Werte (Mac-Modell, Chip, CPU-/GPU-Kernzahlen, RAM, interner Speicher und macOS-Version) in die App übernehmen. Danach gezielt testen und die Datenschutzbeschreibung gegen den Code prüfen.
- Nach dieser Codekorrektur die Aussagen zu Systeminformationen in `MANUAL.md`, `MANUAL.de.md` und gegebenenfalls weiteren öffentlichen Funktionsbeschreibungen abschließend auf „gezielte Werte, keine Seriennummern oder UUIDs“ aktualisieren. Danach beide PDFs unter `Documentation/` neu erzeugen und visuell prüfen, bevor ein Beta- oder Final-Build veröffentlicht wird. Die aktuellen PDFs gehören zu Final v1.1.0 und werden in diesem reinen Dokumentations-Commit nicht verändert.

## Weiter beobachten

- Falls der sporadische GPU-Ausfall erneut auftritt, ihn gezielt in einem Debug-Dev-Lauf erfassen: IOKit-Rückgabecodes und pro GPU-Schlüssel verfügbare Antworten protokollieren, ohne die produktive Anzeige mit erfundenen Ersatzwerten zu verändern. Seit der letzten Änderung am GPU-Fix zeigte der lokale Dev-Lauf durchgehend GPU-Werte.
