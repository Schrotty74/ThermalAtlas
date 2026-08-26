# ThermalAtlas – Projektkontext

## Repository

- Repository-Root: `ThermalAtlas`.
- Öffentliches Repository: https://github.com/Schrotty74/ThermalAtlas

## Ziel und Zweck

ThermalAtlas ist eine native macOS-Menüleisten-App für Apple-Silicon-Macs. Sie zeigt ausschließlich Temperaturen für CPU, GPU, interne SSD und jede erkannte physische externe SSD an. Die App liest Daten nur aus und nimmt keine Änderungen an Lüftern, Energieoptionen oder anderen Systemeinstellungen vor.

## Architektur und technische Entscheidungen

- Swift Package mit SwiftUI, Mindestplattform macOS 14; keine Drittanbieter-Abhängigkeiten.
- `SensorService` aktualisiert CPU- und GPU-Temperatur unabhängig im lokal wählbaren Intervall von 1 bis 4 Sekunden in ganzen Sekunden. Parallel ankommende CPU-/GPU-, Laufwerkstopologie-, SMART- und SSD-Temperaturzyklen werden je Kategorie zusammengeführt, damit sie weder konkurrierende Sensorabfragen noch veraltete Zwischenergebnisse veröffentlichen. Laufwerkstopologie wird getrennt beim Start, bei öffentlichen macOS-Mount-/Unmount-Ereignissen und zusätzlich stündlich ermittelt. Die Temperatur jeder bekannten physischen SSD wird jede Minute gelesen, damit Verlauf und Warnungen funktionieren; SMART-Status und -Gesundheit werden beim Start, danach höchstens täglich sowie nach einer tatsächlichen Topologieänderung übernommen. `diskutil`-Prozesse laufen außerhalb des Main Actors und werden nach acht Sekunden beendet, damit eine fehlerhafte externe Verbindung die App nicht festhält. Dadurch verzögern viele von `diskutil` gelistete Kennungen nicht den schnellen CPU-/GPU-Refresh. Es führt außerdem die rein lokale Verlaufserfassung und die Schwellenprüfung aus.
- `SystemContext` liest die CPU-Gesamtauslastung als Differenz zweier öffentlicher Mach-CPU-Tick-Samples, die aktuelle GPU-Auslastung aus der vom integrierten Apple-Grafiktreiber veröffentlichten Geräteauslastung, die belegten RAM-Seiten für Apps, System und komprimierten Speicher sowie Stromquelle/Akku und Energiesparmodus. Die Abfrage läuft in einem eigenen Actor außerhalb des Main Actors; nur ein tatsächlich geänderter Kontext wird an die Oberfläche veröffentlicht. Der RAM-Wert enthält keinen wieder freigebbaren Dateicache; sein sichtbarer Status „Normal“, „Erhöht“ oder „Hoch“ leitet sich transparent aus diesem belegten Anteil ab und behauptet keinen nicht verfügbaren macOS-Kernel-Druckwert. Fehlt ein GPU-Treiberwert auf einem Mac oder macOS-Stand, erscheint korrekt `Nicht verfügbar`. Diese Kontextwerte werden nicht als Temperatursensoren behandelt und ändern keine Systemeinstellungen.
- Temperaturkarten, sichtbarer Aktualisierungszeitpunkt und Menüleistenbeschriftung beobachten den Sensorstand isoliert. Der äußere `MenuBarExtra` selbst bleibt vom Scan-Refresh unabhängig, damit ein geöffnetes Footer-Untermenü nicht durch den laufenden Scan-Refresh geschlossen wird.
- Die Handbuch-Menüpunkte öffnen im Dev- und Beta-Bundle die veröffentlichte Dokumentation vom Branch `beta`; das Final-Bundle öffnet weiterhin den Final-Stand vom Branch `main`.
- `AppleSiliconSMCTemperatureBackend` kapselt private, lesende Apple-Silicon-SMC-Zugriffe defensiv. Es erkennt den Apple-Silicon-Chipnamen lokal und verwendet getrennte, zur Laufzeit einzeln validierte CPU- und GPU-Schlüsselgruppen für M1 bis M5 einschließlich ihrer bekannten Pro-, Max- und Ultra-Varianten. Fehlerhafte oder geänderte Schlüssel führen zu einem sicheren Fallback statt zu einem Absturz. Liefert ein kompletter GPU-Sensorbatch keine Werte, wird der ausschließlich lesende SMC-Client einmal neu geöffnet und derselbe GPU-Batch erneut abgefragt – auch wenn macOS keinen IOKit-Transportfehler meldet. CPU behält die bestehende Wiederverbindung nur bei einem IOKit-Transportfehler.
- `AppLanguage` kapselt sichtbare EN/DE-Texte und typisierte Verfügbarkeits- beziehungsweise SMART-Statuswerte. Die App startet auf Englisch; Deutsch ist eine lokale, persistierte Wahl.
- CPU- und GPU-Gesamtwerte werden aus passenden verfügbaren Rohsensoren als arithmetischer Mittelwert gebildet. Die ausgewählten Sensorfamilien und die Zuordnung sind im Backend dokumentiert.
- Interne und externe Laufwerke werden über `diskutil info -plist` erkannt. Jede externe physische SSD erhält eine eigene Karte; virtuelle Disk-Images werden ignoriert. Bei APFS-Laufwerken wird der physische Store über den Container zum eingebundenen Volume-Namen aufgelöst. SMART-Temperaturen werden nur bei tatsächlich gelieferten Daten von Kelvin in Celsius umgerechnet; der von macOS gelieferte SMART-Status und die verbleibende Gesundheit aus NVMe-`PERCENTAGE_USED` werden als eigene Zeile auf SSD-Karten dargestellt. Ohne dieses Feld gibt es keinen geschätzten Prozentwert.
- Kurzzeitige GPU-SMC-Ausfälle werden höchstens 15 Sekunden mit einem zuletzt echten, sichtbar als solcher markierten Messwert überbrückt; anschließend erscheint korrekt `Nicht verfügbar`.

## Relevante Dateistruktur und Einstiegspunkte

- `Package.swift` – Swift-Package-Konfiguration und Zielnamen.
- `Sources/ThermalView/ThermalViewApp.swift` – SwiftUI-App-Einstieg und Menüleisten-Szene.
- `Sources/ThermalView/SensorService.swift` – Aktualisierung, Datenbeschaffung und Fehlerbehandlung.
- `Sources/ThermalView/SystemContext.swift` – rein lesender CPU-/GPU-Last-, RAM- und Energie-/Stromkontext.
- `Sources/ThermalView/AppleSiliconSMCTemperatureBackend.swift` – isolierter Apple-Silicon-SMC-Adapter.
- `Sources/ThermalView/TemperatureAggregation.swift` – nachvollziehbare Temperaturaggregation.
- `Sources/ThermalView/Models.swift` – Temperatur- und Sensordatenmodelle.
- `Sources/ThermalView/AppLanguage.swift` – Sprachwahl sowie lokalisierte Status- und Oberflächentexte.
- `Sources/ThermalView/ThermalPopover.swift` – Popup und Sensor-Karten.
- `Sources/ThermalView/ThermalTheme.swift` – Themes und visueller Stil.
- `Tests/ThermalViewTests/TemperatureAggregationTests.swift` – Tests der Aggregationslogik.
- `build_dev_app.sh` – lokaler Dev-Build als App-Bundle.
- `build_beta_app.sh` und `build_final_app.sh` – lokale Builds für die getrennten Beta- und Final-Bundles.
- `Scripts/build-release-package.sh` und `Scripts/privacy-check.sh` – versionierte Release-Paketierung beziehungsweise Quellenprüfung für Beta und Final.
- `Resources/Dev-Info.plist` – Dev-Bundle-Metadaten.

## Umgesetzte Funktionen

- Die Menüleiste kann wahlweise alle aktuell verfügbaren Temperaturen der ausgewählten CPU-, GPU- und SSD-Gruppen mit kompakten, farblich getrennten Sensorsymbolen und Temperaturwerten oder nur das ThermalAtlas-Symbol zeigen. CPU ist goldgelb, GPU blau, die interne SSD türkis und externe SSDs grün; eine dezente dunkle, abgerundete Fläche hinter der Temperaturzeile hält die Farben auf transparenten hellen Menüleisten lesbar. Ihr Rahmen ist grün im Normalbereich, gelb bei Annäherung bis zehn Grad unter die gewählte Warnschwelle und rot ab der Warnschwelle. Nicht lesbare Sensoren erhalten keine Ersatzwerte. Im Footer-Menü lässt sich pro Sensorgruppe wählen, ob ihre Temperaturen gleichzeitig in der Menüleiste und im aufgeklappten Fenster sichtbar sind; externe SSDs werden gemeinsam geschaltet.
- Im Footer-Menü lässt sich die Popover-Größe zwischen Standard und einer rund 40 % schmaleren, auch in Abständen und Karten dichter gesetzten Kompaktansicht wechseln.
- Das Popover wächst oder schrumpft mit seinem Karteninhalt. Wird ein Temperaturverlauf aufgeklappt, bleiben alle Karten direkt sichtbar und die äußere Fensterhöhe passt sich ohne einen zusätzlichen Scrollbereich an.
- Temperaturkarten öffnen per Klick einen lokalen Verlauf mit 1, 6 oder 24 Stunden. Gespeichert werden pro lesbarem Sensor Minutenmittelwerte für höchstens 24 Stunden; kurzfristig überbrückte GPU-Werte werden nicht als neue Messung aufgezeichnet.
- Temperaturkarten öffnen per Klick ihren lokalen Verlauf; die von `diskutil` gemeldete Schnittstelle einer externen SSD erscheint, falls verfügbar, nur in ihren Sensor-Details hinter dem Info-Symbol, nicht als zusätzliche Kartenzeile.
- Jede Temperaturkarte hat ein separates Info-Symbol für Sensor-Details. Es zeigt Quelle, bei CPU und GPU zusätzlich den lokal erkannten Apple-Silicon-Chipnamen, bei SSDs die lokale Laufwerks-ID, den letzten gültigen Wert, dessen Zeitpunkt sowie den vorhandenen Messhinweis, ohne den Klick auf die Karte vom Temperaturverlauf wegzunehmen.
- Das Footer-Menü bietet lokale Temperaturwarnungen. CPU, GPU, interne SSD und externe SSDs haben getrennt wählbare Warnschwellen (CPU/GPU: 85–100 °C, SSD: 60–75 °C). Eine macOS-Mitteilung wird erst nach mindestens 60 Sekunden oberhalb der gewählten Schwelle ausgelöst und erst nach einer Abkühlung erneut für dieselbe Episode gesendet.
- Das Footer-Menü bietet einen nutzerinitiierten Export: kopierbarer Klartext des aktuellen Snapshots für Support sowie CSV über einen lokalen macOS-Speichern-Dialog. CSV enthält Minutenmittelwerte des bis zu 24-stündigen Verlaufs für aktuell erkannte Sensoren und zusätzlich den aktuellen Snapshot; `record_type` unterscheidet `history_average` und `current_snapshot`. Es verwendet ISO-8601-Zeitstempel und einen locales-unabhängigen Dezimalpunkt; ohne Nutzeraktion wird keine Datei erzeugt.
- Temperaturkarten für CPU, GPU, interne SSD sowie jede erkannte, aktuell eingebundene physische externe SSD mit ihrem tatsächlichen Laufwerks- beziehungsweise eingebundenen Volume-Namen als Kartenüberschrift; mehrere externe SSDs werden getrennt dargestellt. Ein ausgeworfenes, aber weiter verkabeltes externes Laufwerk erscheint nicht als Karte. Der lokale Dev-Test bestätigte Ausblenden beim Auswerfen und automatisches Wiedererscheinen nach dem erneuten Einbinden.
- Unter den Temperaturkarten zeigt ein separater Bereich „System Context“ beziehungsweise „Systemkontext“ CPU- und GPU-Gesamtauslastung, belegten Arbeitsspeicher im Verhältnis zum gesamten RAM, Stromquelle/Akku und den Energiesparmodus. Er ist ausdrücklich als Kontext und nicht als Temperatursignal gekennzeichnet und aktualisiert sich unabhängig von den Temperaturkarten alle 0,5 Sekunden; die CPU-Last erscheint erst nach dem zweiten Kontext-Scan, weil sie aus der Zeitdifferenz zweier Messungen berechnet wird.
- SSD-Karten zeigen zusätzlich den von macOS gemeldeten SMART-Status sowie – falls verfügbar – die aus `PERCENTAGE_USED` abgeleitete verbleibende Gesundheit als eigene Zeile; fehlende Statusangaben werden als `SMART: Nicht verfügbar` ausgewiesen.
- Menü `Scan Refresh` mit Aktualisierungsintervall von 1 bis 4 Sekunden in ganzen Sekunden; standardmäßig zwei Sekunden.
- Der 1-Sekunden-Refresh für CPU und GPU wurde im lokalen Dev-Lauf sichtbar bestätigt; die getrennten Laufwerkszyklen bremsen diese Anzeige nicht.
- Robuste Anzeige `Nicht verfügbar`, ohne Schätzwerte, wenn ein Sensor oder SMART-Daten nicht verfügbar sind.
- CPU- und GPU-Aggregation mit erklärender Herkunft in der Detailzeile.
- Farbliche Trennung der Sensor-Karten sowie temperaturabhängige Statusfarben.
- Vier Themes: Adaptiv, Liquid Glass, Aurora und Ember. Adaptiv folgt dem macOS-Hell- oder Dunkelmodus über Systemmaterial. Liquid Glass nutzt einen gemeinsamen systemeigenen Material-Hintergrund, adaptive Reflexe für Hell- und Dunkelmodus sowie einen opaken Fallback bei aktivierter macOS-Einstellung „Transparenz reduzieren“.
- Ein gemeinsames Footer-Menü bündelt `Themes`, `Scan Refresh`, `Window Size`, `Visible Temperatures`, `Menu Bar Display`, `Temperature Alerts`, den optionalen Start bei Anmeldung, `Language` beziehungsweise `Sprache`, `Export`, öffentliche GitHub- und Homepage-Links, die englischen und deutschen Handbücher, das Öffnen der macOS-Aktivitätsanzeige und das Beenden der App. Der Export bietet zusätzlich einen kopierbaren Diagnosebericht mit Hardwaremodell, macOS-Version, Chipbezeichnung und dem aktuellen lesbaren beziehungsweise nicht lesbaren Sensorstatus. Aktive Auswahlwerte sind jeweils mit einem Häkchen markiert.
- Das Fenster-Popover wird bei seinem Öffnen um 32 Punkte näher an die Menüleiste gesetzt, damit es nicht mit dem großen Standardabstand der Fensterdarstellung erscheint.

## Wichtige Designentscheidungen

- Kompaktes natives Menüleisten-Popup ohne Diagramm- oder Diagnose-Überladung.
- Dunkle, hochwertige Material-Optik; Hell- und Dunkelmodus bleiben unterstützt.
- Sensorfarben dienen der schnellen Zuordnung, Statusfarben der Temperaturbewertung.
- Karten priorisieren lesbare, kurze Kontexttexte: CPU und GPU zeigen den Aggregationshinweis statt technischer Rohsensorlisten; SMART-Status und SSD-Gesundheit nutzen kontrastreiche, separate Zeilen.
- Beim Milchglas-Theme liegt die räumliche Hintergrundwirkung nur am Root-Material, damit Karten lesbar und ruhig bleiben.

## Datenformate und Kompatibilität

- Laufwerksinformationen werden aus der Property-List-Ausgabe von `diskutil info -plist` gelesen.
- SMART-Temperaturen werden nur dann dargestellt, wenn der Wert vorhanden und plausibel ist; die Quelle liefert Kelvin, die Darstellung Celsius.
- Lokale Temperaturverläufe werden als codierte Minutenmittelwerte unter `thermalatlas.temperatureHistory` in `UserDefaults` gespeichert und beim Start auf maximal 24 Stunden gekürzt. Sie enthalten ausschließlich Zeit, Temperaturmittelwert, Anzahl der in die Minute eingeflossenen Werte und die lokale Sensor-ID; zwischengespeicherte SSD- oder GPU-Werte werden nicht erneut als Messung aufgezeichnet. Es gibt keine Cloud-Synchronisierung oder Telemetrie. Ein Klartext-Export des aktuellen Snapshots oder CSV-Export von Verlauf plus aktuellem Snapshot entsteht ausschließlich nach einer Nutzeraktion an einen von der Person gewählten lokalen Speicherort.
- Theme-Auswahl, Aktualisierungsintervall, Sprachwahl, sichtbare Sensorgruppen, Menüleistenmodus, Popover-Größe und Warnschwellen werden lokal in `UserDefaults` gespeichert. Die Schlüssel sind `thermalatlas.theme`, `thermalatlas.refreshInterval`, `thermalatlas.language`, `thermalatlas.visibleSensors`, `thermalatlas.menuBarDisplayMode`, `thermalatlas.compactPopover`, `thermalatlas.temperatureAlertsEnabled` sowie je ein Schwellenwert für CPU, GPU, interne und externe SSD. Der Energie-/Last-Kontext wird nur angezeigt, nicht gespeichert. Englisch ist der Standard; Deutsch kann im Footer-Menü unter `Language` beziehungsweise `Sprache` gewählt werden. Da `UserDefaults` pro Bundle-Identifier getrennt ist, teilen Dev, Beta und Final keine App-Einstellungen oder Caches.
- Zielplattform sind Apple-Silicon-Macs mit M1 bis M5; private SMC-Schlüssel sind nicht stabil garantiert und müssen zur Laufzeit geprüft werden. Für später veröffentlichte M-Generationen erscheint bis zu einer belegten Zuordnung korrekt `Nicht verfügbar`.

## Build und Release

- Die lokalen Builds werden mit `./build_dev_app.sh`, `./build_beta_app.sh` und `./build_final_app.sh` erstellt.
- Dev, Beta und Final haben getrennte Bundle-Identifier, App-Namen, Ausgabeverzeichnisse und Swift-Build-Caches unter `.build/dev`, `.build/beta` und `.build/final`.
- Die Bundle-Identifier sind `io.github.schrotty74.thermalatlas.dev`, `io.github.schrotty74.thermalatlas.beta` und `io.github.schrotty74.thermalatlas`.
- Das Dev-App-Icon liegt als `Resources/Assets.xcassets/AppIcon.appiconset` vor und wird mit Apples `actool` in den Bundle-Asset-Katalog kompiliert. Die originale Entwurfsvorlage liegt unter `Resources/IconSource/`. Der Dev-Build erzeugt zusätzlich `Contents/PkgInfo`, aktualisiert danach den Bundle-Zeitstempel und registriert genau dieses lokale Dev-Bundle bei LaunchServices, damit Finder Icon-Änderungen übernimmt.
- Dev, Beta und Final werden als getrennte lokale Artefakte erzeugt. Veröffentlichung, Tags und Releases bleiben separate, ausdrücklich beauftragte Schritte.
- Der Git-Branch `beta` ist ausschließlich der veröffentlichte Beta-Quellstand; `main` ist ausschließlich der finale Quellstand. Dev wird niemals nach Git gepusht. Ein Beta-Auftrag darf `main` nicht fortschreiben, ein Final-Auftrag darf `beta` nicht fortschreiben.
- `Scripts/build-release-package.sh` erzeugt auf ausdrücklichen Auftrag einen signierten Release-Ordner mit DMG, ZIP und SHA-256-Prüfsummen für Beta oder Final. Die ZIP-Erzeugung unterdrückt AppleDouble-Metadaten, damit kein `__MACOSX`-Ordner veröffentlicht wird. `Scripts/privacy-check.sh` prüft den zu veröffentlichenden Quellstand auf Zugangsdaten, private Kennungen und lokale Pfade. Ein Beta-Release wird mit seinem Commit auf `beta` getaggt und als GitHub-Pre-release veröffentlicht; ein Final-Release wird vom zugehörigen Commit auf `main` getaggt und als reguläres GitHub-Release veröffentlicht. Changelog und Release Notes sind Englisch.
- ThermalAtlas Beta 0.2.0 wurde als GitHub-Pre-Release vom Branch `beta` mit Tag `v0.2.0` veröffentlicht. Das Release enthält eine ad-hoc-signierte DMG mit Applications-Link, eine ZIP-Datei und SHA-256-Prüfsummen für beide Downloads. Die Prüfsummen sowie die Signatur der App im bereitgestellten DMG wurden vor der Veröffentlichung lokal geprüft.
- ThermalAtlas Beta 0.3.0 wurde als GitHub-Pre-Release vom Branch `beta` mit Tag `v0.3.0` veröffentlicht. Es enthält eine ad-hoc-signierte DMG mit Applications-Link, eine ZIP-Datei und SHA-256-Prüfsummen für beide Downloads. Prüfsummen, App-Signatur und der Inhalt der bereitgestellten DMG wurden vor dem Upload lokal geprüft.
- ThermalAtlas Beta 0.4.0 wurde als GitHub-Pre-Release vom Branch `beta` mit Tag `v0.4.0` veröffentlicht. Es enthält eine ad-hoc-signierte DMG mit Applications-Link, eine ZIP-Datei und SHA-256-Prüfsummen für beide Downloads. Die ZIP-Erzeugung unterdrückt AppleDouble-Metadaten, damit kein `__MACOSX`-Ordner veröffentlicht wird.
- ThermalAtlas Beta 0.5.0 wurde als GitHub-Pre-Release vom Branch `beta` mit Tag `v0.5.0` veröffentlicht. Es enthält eine ad-hoc-signierte DMG mit Applications-Link, eine ZIP-Datei und SHA-256-Prüfsummen für beide Downloads. Prüfsummen, ZIP-Inhalt, App-Signatur im bereitgestellten DMG und der Applications-Link wurden vor dem Upload lokal geprüft.
- Dev-Aufträge beschränken sich normalerweise auf lokale Entwicklung, Tests und Dev-Builds. Datenschutz-/Sicherheitsprüfungen für öffentliche Artefakte sowie Änderungen oder Neu-Erzeugungen von README, Handbüchern und Handbuch-PDFs sind sonst Teil eines ausdrücklich beauftragten Beta- oder Final-Builds mit anschließendem Git-Push. Eine ausdrücklich separat beauftragte lokale Handbuchpflege bleibt davon unberührt.
- Öffentliche Vorabpakete sind ad-hoc signiert und ohne Apple-Developer-Program-Notarisierung. Die README erklärt deshalb die notwendige Gatekeeper-Bestätigung beim ersten Start aus dem offiziellen GitHub-Release.
- `README.md` und `README.de.md` sind gleichwertige öffentliche Dokumentationen: Sie zeigen beide eine kurze Liste der wichtigsten Funktionen, die vier Theme-Screenshots sowie gleichwertige Installations-, Gatekeeper-, Datenschutz-, Status-, Lizenz- und Linkinformationen. Sie verlinken auf die vollständigen, gleichwertigen Detailübersichten `FEATURES.md` und `FEATURES.de.md`. Ihre öffentliche Tabelle führt nur die veröffentlichten Beta- und Final-Build-Kanäle; der rein lokale Dev-Kanal wird dort nicht aufgeführt. Sie enthalten außerdem einen eigenen Hardware-Kompatibilitätsabschnitt mit den nur auf M4 Max, M5 und M5 Pro bestätigten CPU-/GPU-Erkennungen. Der Changelog bleibt ausschließlich Englisch.
- `MANUAL.md` und `MANUAL.de.md` sind gleichwertige öffentliche Handbücher. Die zugehörigen PDFs unter `Documentation/` verwenden ein dunkles, an die App angelehntes Farbdesign und füllen sieben gestaltete A4-Seiten pro Sprache mit der aktuellen Kartenoberfläche, Systemkontext mit CPU-/GPU-Last und RAM, Menüleistenanzeige, lokalem Temperaturverlauf, Temperaturwarnungen, Export, allen vier Themes sowie den Menüs `Themes`, `Scan Refresh`, `Window Size`, `Visible Temperatures`, `Menu Bar Display`, `Temperature Alerts`, `Start at Login`, `Language`, `Export` mit Diagnosebericht und `Manuals`. Das englische Handbuch dokumentiert Englisch als Standard; das deutsche Handbuch übersetzt die englischen Menübegriffe nachvollziehbar. Ihre reguläre Veröffentlichung erfolgt nur im beauftragten Beta-/Final-Releaseablauf mit Git-Push.
- Jede SEO- oder Discoverability-Änderung an `README.md` wird im selben Auftrag als inhaltlich gleichwertige, natürlich formulierte deutsche Entsprechung in `README.de.md` umgesetzt: H1, Überblick, Funktionen, Screenshots und Alt-Texte, Voraussetzungen, Download/Installation, Gatekeeper, Datenschutz/Datenverarbeitung, Status, Lizenz, Links und Entwicklung bleiben strukturell gleich.
- `PORTFOLIO_UPDATE.md` dokumentiert die Regeln für die öffentliche Darstellung von ThermalAtlas im Schrotty74-Profil und -Portfolio.

## Projektspezifischer Datenschutz

- Keine Hintergrundnetzwerkkommunikation, Telemetrie, Accounts oder Drittanbieter-SDKs. Die optionalen GitHub-, Homepage- und Handbuch-Menüeinträge übergeben eine öffentliche URL nur nach einer Nutzeraktion an den Standardbrowser.
- Es werden ausschließlich lokale, lesende Sensor- und Laufwerksabfragen ausgeführt.
- CPU-/GPU-Last, RAM-Auslastung, Stromquelle/Akku und Energiesparmodus werden ausschließlich lokal und lesend abgefragt; ThermalAtlas steuert weder Leistung noch Stromversorgung.
- Private SMC-Zugriffe sind auf lesende Operationen beschränkt.
- Für alle Repository-Inhalte und öffentlichen Materialien gelten zusätzlich die Datenschutz- und Namensregeln aus `AGENTS.md`.

## Bekannte Einschränkungen und bestätigte Probleme

- Apple-Silicon-SMC-Sensoren sind private Schnittstellen. macOS-Updates oder Gerätevarianten können Schlüssel verändern oder zeitweise nicht lesbar machen.
- Die M1- bis M5-Schlüsselgruppen sind im Quellcode hinterlegt und durch Abwesenheits- und Plausibilitätsprüfungen abgesichert; sie wurden nicht auf jeder Hardwarevariante manuell verifiziert. CPU- und GPU-Erkennung sind bislang nur auf M4 Max lokal sowie auf M5 und M5 Pro extern bestätigt.
- Alle weiteren M1- bis M5-Varianten, ihre Rohsensoren sowie spätere M-Generationen bleiben separat auf echter Hardware zu prüfen.
- Die GPU kann trotz Wiederverbindung des SMC-Clients sporadisch `Nicht verfügbar` melden, wenn alle abgefragten GPU-Zonen vorübergehend keine gültige Antwort liefern.
- Seit der letzten Änderung am GPU-Fix zeigte der lokale Dev-Lauf durchgehend GPU-Werte; ob der zuvor sporadische Ausfall damit dauerhaft behoben ist, bleibt ohne längeren Lauf noch offen.
- Die CPU-Messung hängt von den auf diesem Mac lesbaren SMC-Schlüsseln ab; nicht lesbare Schlüssel werden nicht ersetzt oder geschätzt.
- Externe SSDs und ihre Gehäuse stellen häufig keine SMART-Temperatur bereit. In diesem Fall ist `Nicht verfügbar` das erwartete Ergebnis.
- Der lokale Lauf von `swift test -c debug` am 25. August 2026 hatte vierundzwanzig erfolgreiche Tests, einschließlich erfolgreicher und zeitlich begrenzter lokaler Prozessaufrufe; ein aktueller Dev-Build und seine Code-Signatur wurden ebenfalls lokal erfolgreich geprüft. Der Beta-Build und seine Code-Signatur waren zuvor lokal erfolgreich geprüft. Die vier Themes Adaptiv, Liquid Glass, Aurora und Ember wurden am 26. August 2026 manuell in Hell- und Dunkelmodus sowie mit aktivierter Transparenzreduktion geprüft.
