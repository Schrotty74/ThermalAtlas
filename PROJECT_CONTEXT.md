# ThermalAtlas – Projektkontext

## Ziel und Zweck

ThermalAtlas ist eine native macOS-Menüleisten-App für Apple-Silicon-Macs. Sie zeigt ausschließlich Temperaturen für CPU, GPU, interne SSD und jede erkannte physische externe SSD an. Die App liest Daten nur aus und nimmt keine Änderungen an Lüftern, Energieoptionen oder anderen Systemeinstellungen vor.

## Architektur und technische Entscheidungen

- Swift Package mit SwiftUI, Mindestplattform macOS 14; keine Drittanbieter-Abhängigkeiten.
- `SensorService` koordiniert die Aktualisierung mit einem lokal wählbaren Scan-Refresh-Intervall von 1 bis 4 Sekunden in ganzen Sekunden und liefert ein UI-unabhängiges Datenmodell.
- `AppleSiliconSMCTemperatureBackend` kapselt private, lesende Apple-Silicon-SMC-Zugriffe defensiv. Fehlerhafte oder geänderte Schlüssel führen zu einem sicheren Fallback statt zu einem Absturz.
- `AppLanguage` kapselt sichtbare EN/DE-Texte und typisierte Verfügbarkeits- beziehungsweise SMART-Statuswerte. Die App startet auf Englisch; Deutsch ist eine lokale, persistierte Wahl.
- CPU- und GPU-Gesamtwerte werden aus passenden verfügbaren Rohsensoren als arithmetischer Mittelwert gebildet. Die ausgewählten Sensorfamilien und die Zuordnung sind im Backend dokumentiert.
- Interne und externe Laufwerke werden über `diskutil info -plist` erkannt. Jede externe physische SSD erhält eine eigene Karte; virtuelle Disk-Images werden ignoriert. Bei APFS-Laufwerken wird der physische Store über den Container zum eingebundenen Volume-Namen aufgelöst. SMART-Temperaturen werden nur bei tatsächlich gelieferten Daten von Kelvin in Celsius umgerechnet; der von macOS gelieferte SMART-Status und die verbleibende Gesundheit aus NVMe-`PERCENTAGE_USED` werden als eigene Zeile auf SSD-Karten dargestellt. Ohne dieses Feld gibt es keinen geschätzten Prozentwert.
- Kurzzeitige GPU-SMC-Ausfälle werden begrenzt mit einem zuletzt echten Messwert überbrückt; anschließend erscheint korrekt `Nicht verfügbar`.

## Relevante Dateistruktur und Einstiegspunkte

- `Package.swift` – Swift-Package-Konfiguration und Zielnamen.
- `Sources/ThermalView/ThermalViewApp.swift` – SwiftUI-App-Einstieg und Menüleisten-Szene.
- `Sources/ThermalView/SensorService.swift` – Aktualisierung, Datenbeschaffung und Fehlerbehandlung.
- `Sources/ThermalView/AppleSiliconSMCTemperatureBackend.swift` – isolierter Apple-Silicon-SMC-Adapter.
- `Sources/ThermalView/TemperatureAggregation.swift` – nachvollziehbare Temperaturaggregation.
- `Sources/ThermalView/Models.swift` – Temperatur- und Sensordatenmodelle.
- `Sources/ThermalView/AppLanguage.swift` – Sprachwahl sowie lokalisierte Status- und Oberflächentexte.
- `Sources/ThermalView/ThermalPopover.swift` – Popup und Sensor-Karten.
- `Sources/ThermalView/ThermalTheme.swift` – Themes und visueller Stil.
- `Tests/ThermalViewTests/TemperatureAggregationTests.swift` – Tests der Aggregationslogik.
- `build_dev_app.sh` – lokaler Dev-Build als App-Bundle.
- `Resources/Dev-Info.plist` – Dev-Bundle-Metadaten.

## Umgesetzte Funktionen

- Menüleistensymbol mit Thermometer und optional höchster verfügbarer Temperatur.
- Temperaturkarten für CPU, GPU, interne SSD sowie jede erkannte physische externe SSD mit ihrem tatsächlichen Laufwerks- beziehungsweise eingebundenen Volume-Namen als Kartenüberschrift; mehrere externe SSDs werden getrennt dargestellt.
- SSD-Karten zeigen zusätzlich den von macOS gemeldeten SMART-Status sowie – falls verfügbar – die aus `PERCENTAGE_USED` abgeleitete verbleibende Gesundheit als eigene Zeile; fehlende Statusangaben werden als `SMART: Nicht verfügbar` ausgewiesen.
- Menü `Scan Refresh` mit Aktualisierungsintervall von 1 bis 4 Sekunden in ganzen Sekunden; standardmäßig zwei Sekunden.
- Robuste Anzeige `Nicht verfügbar`, ohne Schätzwerte, wenn ein Sensor oder SMART-Daten nicht verfügbar sind.
- CPU- und GPU-Aggregation mit erklärender Herkunft in der Detailzeile.
- Farbliche Trennung der Sensor-Karten sowie temperaturabhängige Statusfarben.
- Vier Themes: Klassisch, Liquid Glass, Aurora und Ember. Liquid Glass nutzt einen gemeinsamen systemeigenen Material-Hintergrund, adaptive Reflexe für Hell- und Dunkelmodus sowie einen opaken Fallback bei aktivierter macOS-Einstellung „Transparenz reduzieren“.
- Ein gemeinsames Footer-Menü bündelt `Themes`, `Scan Refresh`, `Language` beziehungsweise `Sprache`, öffentliche GitHub- und Homepage-Links, die englischen und deutschen Handbücher, das Öffnen der macOS-Aktivitätsanzeige und das Beenden der App. Aktuelles Theme, Intervall und Sprache sind jeweils mit einem Häkchen markiert.

## Wichtige Designentscheidungen

- Kompaktes natives Menüleisten-Popup ohne Diagramm- oder Diagnose-Überladung.
- Dunkle, hochwertige Material-Optik; Hell- und Dunkelmodus bleiben unterstützt.
- Sensorfarben dienen der schnellen Zuordnung, Statusfarben der Temperaturbewertung.
- Karten priorisieren lesbare, kurze Kontexttexte: CPU und GPU zeigen den Aggregationshinweis statt technischer Rohsensorlisten; SMART-Status und SSD-Gesundheit nutzen kontrastreiche, separate Zeilen.
- Beim Milchglas-Theme liegt die räumliche Hintergrundwirkung nur am Root-Material, damit Karten lesbar und ruhig bleiben.

## Datenformate und Kompatibilität

- Laufwerksinformationen werden aus der Property-List-Ausgabe von `diskutil info -plist` gelesen.
- SMART-Temperaturen werden nur dann dargestellt, wenn der Wert vorhanden und plausibel ist; die Quelle liefert Kelvin, die Darstellung Celsius.
- Es werden keine Temperaturverläufe oder Messdaten persistent gespeichert.
- Theme-Auswahl, Aktualisierungsintervall und die Sprachwahl werden lokal in `UserDefaults` unter `thermalatlas.theme`, `thermalatlas.refreshInterval` beziehungsweise `thermalatlas.language` gespeichert. Englisch ist der Standard; Deutsch kann im Footer-Menü unter `Language` beziehungsweise `Sprache` gewählt werden. Da `UserDefaults` pro Bundle-Identifier getrennt ist, teilen Dev, Beta und Final keine App-Einstellungen oder Caches.
- Zielplattform sind aktuelle Apple-Silicon-Macs, besonders Mac Studio mit M4 Max. Private SMC-Schlüssel sind nicht stabil garantiert und müssen zur Laufzeit geprüft werden.

## Build und Release

- Die lokalen Builds werden mit `./build_dev_app.sh`, `./build_beta_app.sh` und `./build_final_app.sh` erstellt.
- Dev, Beta und Final haben getrennte Bundle-Identifier, App-Namen, Ausgabeverzeichnisse und Swift-Build-Caches unter `.build/dev`, `.build/beta` und `.build/final`.
- Die Bundle-Identifier sind `io.github.schrotty74.thermalatlas.dev`, `io.github.schrotty74.thermalatlas.beta` und `io.github.schrotty74.thermalatlas`.
- Das Dev-App-Icon liegt als `Resources/Assets.xcassets/AppIcon.appiconset` vor und wird mit Apples `actool` in den Bundle-Asset-Katalog kompiliert. Die originale Entwurfsvorlage liegt unter `Resources/IconSource/`. Der Dev-Build erzeugt zusätzlich `Contents/PkgInfo`, aktualisiert danach den Bundle-Zeitstempel und registriert genau dieses lokale Dev-Bundle bei LaunchServices, damit Finder Icon-Änderungen übernimmt.
- Dev, Beta und Final werden als getrennte lokale Artefakte erzeugt. Veröffentlichung, Tags und Releases bleiben separate, ausdrücklich beauftragte Schritte.
- Der aktuelle Beta-Build wurde lokal mit `./build_beta_app.sh` erzeugt und seine Ad-hoc-Signatur erfolgreich geprüft; ein GitHub-Release ist davon getrennt.
- Dev-Aufträge beschränken sich normalerweise auf lokale Entwicklung, Tests und Dev-Builds. Datenschutz-/Sicherheitsprüfungen für öffentliche Artefakte sowie Änderungen oder Neu-Erzeugungen von README, Handbüchern und Handbuch-PDFs sind sonst Teil eines ausdrücklich beauftragten Beta- oder Final-Builds mit anschließendem Git-Push. Eine ausdrücklich separat beauftragte lokale Handbuchpflege bleibt davon unberührt.
- Öffentliche Vorabpakete sind ad-hoc signiert und ohne Apple-Developer-Program-Notarisierung. Die README erklärt deshalb die notwendige Gatekeeper-Bestätigung beim ersten Start aus dem offiziellen GitHub-Release.
- `README.md` und `README.de.md` sind gleichwertige öffentliche Dokumentationen: Sie zeigen beide die vier Theme-Screenshots sowie gleichwertige Installations-, Gatekeeper-, Datenschutz-, Status-, Lizenz- und Linkinformationen. Der Changelog bleibt ausschließlich Englisch.
- `MANUAL.md` und `MANUAL.de.md` sind gleichwertige öffentliche Handbücher. Die zugehörigen PDFs unter `Documentation/` verwenden ein dunkles, an die App angelehntes Farbdesign und füllen sechs gestaltete A4-Seiten pro Sprache mit der aktuellen Kartenoberfläche, allen vier Themes sowie den Menüs `Themes`, `Scan Refresh`, `Language` und `Manuals`. Das englische Handbuch dokumentiert Englisch als Standard; das deutsche Handbuch übersetzt die englischen Menübegriffe nachvollziehbar. Ihre reguläre Veröffentlichung erfolgt nur im beauftragten Beta-/Final-Releaseablauf mit Git-Push.
- Jede SEO- oder Discoverability-Änderung an `README.md` wird im selben Auftrag als inhaltlich gleichwertige, natürlich formulierte deutsche Entsprechung in `README.de.md` umgesetzt: H1, Überblick, Funktionen, Screenshots und Alt-Texte, Voraussetzungen, Download/Installation, Gatekeeper, Datenschutz/Datenverarbeitung, Status, Lizenz, Links und Entwicklung bleiben strukturell gleich.
- `PORTFOLIO_UPDATE.md` dokumentiert die Regeln für die öffentliche Darstellung von ThermalAtlas im Schrotty74-Profil und -Portfolio.
- Das öffentliche Repository ist `Schrotty74/ThermalAtlas`; veröffentlichte Inhalte dürfen keine lokalen Pfade, privaten Daten oder Build-Artefakte enthalten.

## Datenschutz

- Keine Hintergrundnetzwerkkommunikation, Telemetrie, Accounts oder Drittanbieter-SDKs. Die optionalen GitHub-, Homepage- und Handbuch-Menüeinträge übergeben eine öffentliche URL nur nach einer Nutzeraktion an den Standardbrowser.
- Es werden ausschließlich lokale, lesende Sensor- und Laufwerksabfragen ausgeführt.
- Private SMC-Zugriffe sind auf lesende Operationen beschränkt.

## Bekannte Einschränkungen und bestätigte Probleme

- Apple-Silicon-SMC-Sensoren sind private Schnittstellen. macOS-Updates oder Gerätevarianten können Schlüssel verändern oder zeitweise nicht lesbar machen.
- Die GPU kann trotz Wiederverbindung des SMC-Clients sporadisch `Nicht verfügbar` melden, wenn alle abgefragten GPU-Zonen vorübergehend keine gültige Antwort liefern.
- Die CPU-Messung hängt von den auf diesem Mac lesbaren SMC-Schlüsseln ab; nicht lesbare Schlüssel werden nicht ersetzt oder geschätzt.
- Externe SSDs und ihre Gehäuse stellen häufig keine SMART-Temperatur bereit. In diesem Fall ist `Nicht verfügbar` das erwartete Ergebnis.
- Der letzte lokale Lauf von `swift test -c debug` hatte zehn erfolgreiche Tests; der Beta-Build und seine Code-Signatur wurden lokal erfolgreich geprüft. Eine vollständige visuelle Prüfung aller Themes wurde noch nicht dokumentiert.
