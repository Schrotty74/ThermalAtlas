# ThermalAtlas – Funktionsübersicht

[English](FEATURES.md)

Diese Seite beschreibt die Funktionen dieses Builds ausführlich. Installation und tägliche Nutzung erklärt das [Benutzerhandbuch](MANUAL.de.md).

## Temperaturüberwachung

- Zeigt verfügbare Temperaturen von CPU, GPU, interner SSD und jeder erkannten physischen externen SSD.
- Nutzt getrennte Apple-Silicon-Sensor-Schlüsselfamilien für CPU und GPU von M1 bis M5 einschließlich bekannter Pro-, Max- und Ultra-Varianten. Nicht unterstützte spätere Generationen bleiben nicht verfügbar, statt geschätzt zu werden.
- Verwendet einen defensiven, rein lesenden SMC-Adapter. Fehlende oder unplausible Werte erscheinen als `Nicht verfügbar`.
- Ermöglicht ein Temperaturintervall von 1, 2, 3 oder 4 Sekunden; Standard sind zwei Sekunden.
- Zeigt Quelle, letzten gültigen Wert und Aktualisierungszeit in den Sensor-Details.
- Zeigt in den CPU-/GPU-Sensor-Details den gemessenen Hotspot und die Anzahl gültiger Sensoren. Karten, Menüleiste und Verlauf zeigen weiterhin den Durchschnitt.

## Laufwerke und SMART

- Listet die interne SSD und jede eingebundene physische externe SSD getrennt, mit dem eingebundenen Volume-Namen, falls verfügbar.
- Ignoriert virtuelle Disk-Images und blendet ein ausgeworfenes externes Laufwerk aus, auch wenn es weiter verkabelt bleibt.
- Aktualisiert die Laufwerkstopologie beim Start, nach macOS-Mount-/Unmount-Ereignissen und zusätzlich im Hintergrund.
- Liest Temperaturen bekannter SSDs jede Minute für Verlauf und Warnungen.
- Zeigt den von macOS gemeldeten SMART-Status und die aus NVMe-`PERCENTAGE_USED` abgeleitete verbleibende Gesundheit, falls vorhanden; fehlende Werte werden nicht geschätzt.
- Aktualisiert SMART-Status und Gesundheit beim Start, nach einer Topologieänderung und höchstens einmal täglich.

## Systemkontext

- Zeigt getrennt CPU- und GPU-Gesamtlast, belegten Arbeitsspeicher im Verhältnis zum installierten RAM mit dem Status Normal, Erhöht oder Hoch, Stromquelle/Akku und Energiesparmodus.
- Aktualisiert CPU-/GPU-Last und belegten Speicher alle 0,5 Sekunden, unabhängig vom gewählten Temperaturintervall.
- Behandelt diese Werte als rein lesenden Kontext, niemals als Temperaturmessungen oder Systemsteuerung.

## Systeminformationen

- Öffnen sich über das Thermometer im App-Kopf in einem eigenen lokalen Fenster.
- Zeigen Mac-Modell und Apple-Chip neben dem macOS-Wert für den thermischen Zustand. Darunter folgen CPU- und GPU-Kernzahlen, Arbeitsspeicher, interner Speicher sowie macOS-Version und Buildnummer.
- Kennzeichnen den thermischen Zustand als macOS-Systembewertung und nicht als zusätzlichen Temperatursensor.
- Liest ausschließlich die angezeigten lokalen Werte und fragt, zeigt oder speichert keine Seriennummern oder UUIDs.

## Verlauf, Warnungen und Export

- Öffnet von jeder Temperaturkarte einen lokalen Verlauf für 1, 6 oder 24 Stunden.
- Speichert nur lokale Minutenmittelwerte für höchstens 24 Stunden; vorübergehend gehaltene GPU-Werte werden nicht als neue Messung aufgezeichnet.
- Bietet getrennte Warnschwellen für CPU, GPU, interne SSD und externe SSDs. CPU-/GPU-Warnungen verwenden den gemessenen Hotspot; SSD-Warnungen die angezeigte Temperatur. Eine Mitteilung benötigt mindestens 60 Sekunden über der Schwelle und wird erst nach einer Abkühlung erneut gesendet.
- Exportiert einen kopierbaren aktuellen Snapshot, einen kopierbaren Diagnosebericht mit Mac-Modell, macOS-Version, Chipbezeichnung und Sensorstatus oder lokalen Verlauf plus aktuellen Snapshot als CSV; CSV entsteht erst nach der Auswahl eines Speicherorts.

## Oberfläche und Anzeige

- Bietet Standard- und Kompaktgröße für das Fenster; Kompakt ist rund 40 % schmaler und hält die Bedienelemente lesbar.
- Lässt CPU-, GPU-, interne SSD- und externe SSD-Gruppen für Popover und Menüleiste wählen.
- Bietet Menüleistenmodi für **Alle Werte** oder **Nur Symbol**.
- Trennt CPU-, GPU- und SSD-Werte im Modus **Alle Werte** farblich und ergänzt eine kontrastreiche Statusfläche: grün im Normalbereich, gelb nahe einer Schwelle und rot ab der gewählten Warnschwelle.
- Enthält vier native Themes: Adaptiv, Liquid Glass, Aurora und Ember.
- Temperaturkarten geben ihren Verlaufsstatus an VoiceOver aus und beachten die macOS-Einstellung „Bewegung reduzieren“.
- Startet auf Englisch und bietet eine lokale deutsche Oberfläche.
- Bietet eine optionale macOS-Registrierung für **Bei Anmeldung starten**.
- Kann das Fenster mit der optionalen Einstellung **Immer im Vordergrund** über anderen Apps halten.
- Bündelt Erscheinungsbild, Aktualisierung, Anzeige, Warnungen, Sprache, Export, Immer im Vordergrund, Bei Anmeldung starten, Handbücher, Links, Aktivitätsanzeige und Beenden in einem Footer-Menü.

## Datenschutz und Sicherheit

- Liest nur lokale Sensor- und Laufwerksinformationen; Lüfter, Energieoptionen und andere Systemeinstellungen werden niemals verändert.
- Enthält keine Konten, Telemetrie, Analysedienste, Cloud-Synchronisation, Werbe-SDKs oder Drittanbieter-Abhängigkeiten.
- Speichert ausschließlich gewählte Anzeigeeinstellungen, Warnschwellen und den lokalen Temperaturverlauf in `UserDefaults`.
- Öffnet öffentliche Links oder erstellt Exporte nur nach einer ausdrücklichen Nutzeraktion.

## Hardware-Kompatibilität

Die CPU- und GPU-Erkennung ist auf M4 Max, M5 und M5 Pro auf echter Hardware bestätigt. Weitere M1- bis M5-Varianten und ihre Rohsensoren sind defensiv implementiert, müssen aber noch auf echter Hardware geprüft werden.
