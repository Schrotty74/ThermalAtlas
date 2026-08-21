# ThermalAtlas – Projektkontext

## Ziel und Zweck

ThermalAtlas ist eine native macOS-Menüleisten-App für Apple-Silicon-Macs. Sie zeigt ausschließlich Temperaturen für CPU, GPU, interne SSD und erkannte externe SSDs an. Die App liest Daten nur aus und nimmt keine Änderungen an Lüftern, Energieoptionen oder anderen Systemeinstellungen vor.

## Architektur und technische Entscheidungen

- Swift Package mit SwiftUI, Mindestplattform macOS 14; keine Drittanbieter-Abhängigkeiten.
- `SensorService` koordiniert die Aktualisierung im Zwei-Sekunden-Takt und liefert ein UI-unabhängiges Datenmodell.
- `AppleSiliconSMCTemperatureBackend` kapselt private, lesende Apple-Silicon-SMC-Zugriffe defensiv. Fehlerhafte oder geänderte Schlüssel führen zu einem sicheren Fallback statt zu einem Absturz.
- CPU- und GPU-Gesamtwerte werden aus passenden verfügbaren Rohsensoren als arithmetischer Mittelwert gebildet. Die ausgewählten Sensorfamilien und die Zuordnung sind im Backend dokumentiert.
- Interne und externe Laufwerke werden über `diskutil info -plist` erkannt. SMART-Temperaturen werden nur bei tatsächlich gelieferten Daten von Kelvin in Celsius umgerechnet.
- Kurzzeitige GPU-SMC-Ausfälle werden begrenzt mit einem zuletzt echten Messwert überbrückt; anschließend erscheint korrekt `Nicht verfügbar`.

## Relevante Dateistruktur und Einstiegspunkte

- `Package.swift` – Swift-Package-Konfiguration und Zielnamen.
- `Sources/ThermalView/ThermalViewApp.swift` – SwiftUI-App-Einstieg und Menüleisten-Szene.
- `Sources/ThermalView/SensorService.swift` – Aktualisierung, Datenbeschaffung und Fehlerbehandlung.
- `Sources/ThermalView/AppleSiliconSMCTemperatureBackend.swift` – isolierter Apple-Silicon-SMC-Adapter.
- `Sources/ThermalView/TemperatureAggregation.swift` – nachvollziehbare Temperaturaggregation.
- `Sources/ThermalView/Models.swift` – Temperatur- und Sensordatenmodelle.
- `Sources/ThermalView/ThermalPopover.swift` – Popup und Sensor-Karten.
- `Sources/ThermalView/ThermalTheme.swift` – Themes und visueller Stil.
- `Tests/ThermalViewTests/TemperatureAggregationTests.swift` – Tests der Aggregationslogik.
- `build_dev_app.sh` – lokaler Dev-Build als App-Bundle.
- `Resources/Dev-Info.plist` – Dev-Bundle-Metadaten.

## Umgesetzte Funktionen

- Menüleistensymbol mit Thermometer und optional höchster verfügbarer Temperatur.
- Vier Temperaturkarten: CPU, GPU, interne SSD sowie externe SSD mit tatsächlichem Laufwerksnamen, wenn erkannt.
- Aktualisierung alle zwei Sekunden.
- Robuste Anzeige `Nicht verfügbar`, ohne Schätzwerte, wenn ein Sensor oder SMART-Daten nicht verfügbar sind.
- CPU- und GPU-Aggregation mit erklärender Herkunft in der Detailzeile.
- Farbliche Trennung der Sensor-Karten sowie temperaturabhängige Statusfarben.
- Vier Themes: Klassisch, Liquid Glass, Aurora und Ember. Liquid Glass nutzt einen gemeinsamen systemeigenen Material-Hintergrund, adaptive Reflexe für Hell- und Dunkelmodus sowie einen opaken Fallback bei aktivierter macOS-Einstellung „Transparenz reduzieren“.
- Der Theme-Menüpunkt öffnet die vier Themes direkt; das aktuelle Theme ist darin mit einem Häkchen markiert.
- Schaltflächen zum Öffnen der macOS-Aktivitätsanzeige und zum Beenden der App.

## Wichtige Designentscheidungen

- Kompaktes natives Menüleisten-Popup ohne Diagramm- oder Diagnose-Überladung.
- Dunkle, hochwertige Material-Optik; Hell- und Dunkelmodus bleiben unterstützt.
- Sensorfarben dienen der schnellen Zuordnung, Statusfarben der Temperaturbewertung.
- Beim Milchglas-Theme liegt die räumliche Hintergrundwirkung nur am Root-Material, damit Karten lesbar und ruhig bleiben.

## Datenformate und Kompatibilität

- Laufwerksinformationen werden aus der Property-List-Ausgabe von `diskutil info -plist` gelesen.
- SMART-Temperaturen werden nur dann dargestellt, wenn der Wert vorhanden und plausibel ist; die Quelle liefert Kelvin, die Darstellung Celsius.
- Es werden keine Temperaturverläufe oder Messdaten persistent gespeichert.
- Die Theme-Auswahl wird lokal in `UserDefaults` unter `thermalatlas.theme` gespeichert. Da `UserDefaults` pro Bundle-Identifier getrennt ist, teilen Dev, Beta und Final keine App-Einstellungen oder Caches.
- Zielplattform sind aktuelle Apple-Silicon-Macs, besonders Mac Studio mit M4 Max. Private SMC-Schlüssel sind nicht stabil garantiert und müssen zur Laufzeit geprüft werden.

## Build und Release

- Die lokalen Builds werden mit `./build_dev_app.sh`, `./build_beta_app.sh` und `./build_final_app.sh` erstellt.
- Dev, Beta und Final haben getrennte Bundle-Identifier, App-Namen, Ausgabeverzeichnisse und Swift-Build-Caches unter `.build/dev`, `.build/beta` und `.build/final`.
- Die Bundle-Identifier sind `io.github.schrotty74.thermalatlas.dev`, `io.github.schrotty74.thermalatlas.beta` und `io.github.schrotty74.thermalatlas`.
- Das Dev-App-Icon liegt als `Resources/Assets.xcassets/AppIcon.appiconset` vor und wird mit Apples `actool` in den Bundle-Asset-Katalog kompiliert. Die originale Entwurfsvorlage liegt unter `Resources/IconSource/`. Der Dev-Build erzeugt zusätzlich `Contents/PkgInfo`, aktualisiert danach den Bundle-Zeitstempel und registriert genau dieses lokale Dev-Bundle bei LaunchServices, damit Finder Icon-Änderungen übernimmt.
- Dev, Beta und Final werden als getrennte lokale Artefakte erzeugt. Veröffentlichung, Tags und Releases bleiben separate, ausdrücklich beauftragte Schritte.
- Das öffentliche Repository ist `Schrotty74/ThermalAtlas`; veröffentlichte Inhalte dürfen keine lokalen Pfade, privaten Daten oder Build-Artefakte enthalten.

## Datenschutz

- Keine Netzwerkkommunikation, Telemetrie, Accounts oder Drittanbieter-SDKs.
- Es werden ausschließlich lokale, lesende Sensor- und Laufwerksabfragen ausgeführt.
- Private SMC-Zugriffe sind auf lesende Operationen beschränkt.

## Bekannte Einschränkungen und bestätigte Probleme

- Apple-Silicon-SMC-Sensoren sind private Schnittstellen. macOS-Updates oder Gerätevarianten können Schlüssel verändern oder zeitweise nicht lesbar machen.
- Die GPU kann trotz Wiederverbindung des SMC-Clients sporadisch `Nicht verfügbar` melden, wenn alle abgefragten GPU-Zonen vorübergehend keine gültige Antwort liefern.
- Die CPU-Messung hängt von den auf diesem Mac lesbaren SMC-Schlüsseln ab; nicht lesbare Schlüssel werden nicht ersetzt oder geschätzt.
- Externe SSDs und ihre Gehäuse stellen häufig keine SMART-Temperatur bereit. In diesem Fall ist `Nicht verfügbar` das erwartete Ergebnis.
- Der letzte lokale Lauf von `swift test -c debug` hatte vier erfolgreiche Tests; der Dev-Build und seine Code-Signatur wurden lokal erfolgreich geprüft. Eine vollständige visuelle Prüfung aller Themes wurde noch nicht dokumentiert.
