# ThermalAtlas - Benutzerhandbuch

<p align="center">
  <img src="Resources/IconSource/ThermalAtlas-LiquidGlass.png" width="150" alt="ThermalAtlas App-Icon">
</p>

<p align="center">
  <strong>Schlanke, datenschutzfreundliche Temperaturanzeige für Apple Silicon</strong><br>
  CPU - GPU - interne SSD - externe SSDs
</p>

<p align="center">
  <a href="MANUAL.md">English manual</a> - <a href="README.de.md">Zurück zur deutschen Startseite</a>
</p>

---

## 1. Was ist ThermalAtlas?

ThermalAtlas ist eine kompakte macOS-Menüleisten-App für Apple-Silicon-Macs. Sie zeigt echte Temperaturwerte für CPU, GPU, die interne SSD und jede erkannte physische externe SSD, sofern macOS oder der Laufwerkscontroller sie bereitstellt.

Die App ist bewusst auf die Anzeige konzentriert. Sie verändert **keine Lüftersteuerung, keine Leistungsparameter, keine Energieeinstellungen und keine Systemeinstellungen**. Werte werden nie geschätzt: Ist kein echter Sensor- oder SMART-Wert verfügbar, zeigt ThermalAtlas **Nicht verfügbar**.

### Die wichtigsten Eigenschaften

| Bereich | Verhalten |
| --- | --- |
| CPU | Rein lesende Apple-Silicon-SMC-Sensoren; lesbare Sensoren werden gemittelt |
| GPU | Rein lesende Apple-Silicon-SMC-Sensoren; lesbare Zonen werden gemittelt |
| Interne SSD | SMART-Temperatur, Status und Gesundheit nur bei echten macOS-Daten |
| Externe SSDs | Jede physische externe SSD wird getrennt angezeigt, wenn macOS sie erkennt |
| Aktualisierung | Wählbar alle 1, 2, 3 oder 4 Sekunden; Standard: 2 Sekunden |
| Speicherung | Lokale Einstellungen, Warnschwellen und höchstens 24 Stunden minutenweise gemittelter Temperaturverlauf werden lokal gespeichert |
| Netzwerk | Für die Temperaturanzeige ist keine Netzwerkfunktion nötig |
| Telemetrie | Keine Telemetrie und keine Analyse-Dienste |

---

## 2. Die App-Oberfläche

Die Screenshots in diesem Handbuch zeigen die aktuelle ThermalAtlas-Oberfläche. Die angezeigten SSD-Namen, Temperaturen und Gesundheitswerte sind Beispiele vom aufgenommenen Mac; Anzahl und Namen externer SSD-Karten unterscheiden sich je nach angeschlossener Hardware.

<p align="center">
  <img src="Resources/Screenshots/classic.png" width="430" alt="ThermalAtlas Adaptiv mit CPU, GPU, interner SSD und zwei externen SSD-Karten">
</p>

### Was du im Fenster siehst

**Temperaturkarten**  
CPU- und GPU-Karten zeigen den Mittelwert der lesbaren passenden Sensoren. Jede SSD-Karte zeigt den echten Laufwerks- oder eingebundenen Volume-Namen. Rechts steht die aktuelle Temperatur.

**SSD-Status und Gesundheit**
Wenn macOS die Daten liefert, zeigt eine SSD-Karte `SMART: Verifiziert` und eine eigene Zeile mit der verbleibenden Gesundheit in Prozent. Der Prozentwert wird ausschließlich aus dem NVMe-Feld `PERCENTAGE_USED` abgeleitet. Fehlen SMART-Daten oder dieses Feld, erfindet ThermalAtlas keinen Status und keinen Prozentwert.

**Letzter echter GPU-Wert**
Schlägt eine kurze GPU-SMC-Abfrage fehl, kann ThermalAtlas den letzten zuvor verifizierten echten GPU-Wert kurz weiter anzeigen. Die orange Beschriftung im Aurora-Screenshot macht das ausdrücklich sichtbar; es ist keine Schätzung und der Wert läuft nach kurzer Zeit aus.

<p align="center">
  <img src="Resources/Screenshots/liquid-glass.png" width="430" alt="ThermalAtlas Liquid Glass mit Hinweis auf den letzten verifizierten echten GPU-Wert">
</p>

**Farbliche Statusanzeige**

| Farbe | Temperaturbereich | Bedeutung |
| --- | ---: | --- |
| Grün | unter 55 C | kühler bzw. normaler Bereich |
| Orange | 55 bis unter 75 C | erhöhte Temperatur |
| Rot | ab 75 C | hoher Temperaturbereich |
| Grau | kein Messwert | echter Temperaturwert nicht verfügbar |

Die Farben dienen nur als schnelle Orientierung. ThermalAtlas verändert aufgrund dieser Anzeige nichts am Mac.

**Zeitpunkt „Aktualisiert“**  
Unten im Fenster steht die Uhrzeit des zuletzt übernommenen Sensor-Snapshots.

**Systemkontext**
Unter den Temperaturkarten zeigt ThermalAtlas CPU- und GPU-Last, den belegten Arbeitsspeicher im Verhältnis zum eingebauten RAM, Stromquelle oder Akku und Energiesparmodus. Der Bereich ist ausdrücklich als Kontext und nicht als Temperatursensor gekennzeichnet. Diese Werte aktualisieren sich unabhängig alle 0,5 Sekunden; die CPU-Last wird aus zwei aufeinanderfolgenden System-Snapshots berechnet und erscheint deshalb nach der zweiten Kontext-Aktualisierung. Diese rein lesenden Werte verändern niemals macOS-Energieeinstellungen und werden nicht gespeichert.

<p align="center">
  <img src="Resources/ManualScreenshots/system-context-load.png" width="620" alt="ThermalAtlas-Systemkontext mit CPU-Last, GPU-Last, Arbeitsspeicher, Stromquelle und Energiesparmodus">
</p>

---

## 3. Menüleisten-Anzeige

Nach dem Start kann ThermalAtlas in der macOS-Menüleiste kompakte, farblich getrennte Sensorsymbole und alle aktuell verfügbaren Temperaturen der ausgewählten Gruppen zeigen. CPU ist goldgelb, GPU blau, die interne SSD türkis und externe SSDs sind grün; nicht verfügbare Sensoren erhalten keine erfundenen Ersatzwerte.

Die angezeigten Gruppen werden im gemeinsamen Menü unter **Sichtbare Temperaturen** gewählt und gelten gleichermaßen für Menüleiste und ThermalAtlas-Fenster. Unter **Menüleistenanzeige** gibt es zwei Modi: **Alle Werte** ist der Standard und zeigt die gewählten Gruppen; **Nur Symbol** blendet Temperaturtexte aus und zeigt nur das ThermalAtlas-Symbol. Ein Klick auf den Menüleisteneintrag öffnet das ThermalAtlas-Fenster.

<p align="center">
  <img src="Resources/ManualScreenshots/menu-bar-temperatures.png" width="430" alt="ThermalAtlas-Menüleiste mit farblich getrennten CPU-, GPU- und SSD-Temperaturen in einer kontrastreichen Statusfläche">
</p>

---

## 4. Bedienelemente und gemeinsames Menü

Der runde **Dreipunkt-Button** im Footer öffnet ein gemeinsames Menü. So bleiben alle sekundären Aktionen zusammengefasst, ohne zusätzliche Buttons in der Temperaturansicht.

<p align="center">
  <img src="Resources/ManualScreenshots/shared-menu.png" width="330" alt="Englisches ThermalAtlas-Hauptmenü mit Themes, Scan Refresh, Window Size, Visible Temperatures, Menu Bar Display, Temperature Alerts, Start at Login, Language, Export, Links, Handbüchern, Aktivitätsanzeige und Beenden">
</p>

### Themes (Themen)

Wähle im gemeinsamen Menü **Themes**, um eine Darstellung zu wählen. Die aktive Auswahl ist mit einem Häkchen markiert.

<p align="center">
  <img src="Resources/ManualScreenshots/themes-menu.png" width="232" alt="ThermalAtlas-Menü Themes mit Adaptiv, Liquid Glass, Aurora und Ember">
</p>

- **Adaptiv** - folgt dem macOS-Hell- oder Dunkelmodus mit einer zurückhaltenden Oberfläche aus Systemmaterial
- **Liquid Glass** - kühl eingefärbte, durchscheinende Glasflächen mit opaker Darstellung bei aktivierter Transparenzreduktion
- **Aurora** - dunkle Blau- und Violett-Töne
- **Ember** - warme Rot- und Orange-Töne

Die Auswahl verändert nur die Darstellung, nicht die Messlogik. Sie wird lokal gespeichert. Alle vier Varianten zeigen dieselben Sensordaten.

| Adaptiv | Liquid Glass |
| --- | --- |
| <img src="Resources/Screenshots/classic.png" width="300" alt="ThermalAtlas Theme Adaptiv"> | <img src="Resources/Screenshots/liquid-glass.png" width="300" alt="ThermalAtlas Theme Liquid Glass"> |
| **Aurora** | **Ember** |
| <img src="Resources/Screenshots/aurora.png" width="300" alt="ThermalAtlas Theme Aurora"> | <img src="Resources/Screenshots/ember.png" width="300" alt="ThermalAtlas Theme Ember"> |

### Scan Refresh (Aktualisierungsintervall)

Wähle **Scan Refresh**, um 1, 2, 3 oder 4 Sekunden einzustellen. Der Standard ist 2 Sekunden, die aktive Auswahl trägt ein Häkchen.

<p align="center">
  <img src="Resources/ManualScreenshots/scan-refresh-menu.png" width="238" alt="ThermalAtlas-Menü Scan Refresh mit Optionen von einer bis vier Sekunden">
</p>

Ein kürzeres Intervall reagiert schneller auf echte Änderungen, fragt die rein lesenden Sensorquellen aber häufiger ab. Ein längeres Intervall reduziert diese Abfragen. Das Intervall verändert nur, wie oft ThermalAtlas neue Werte anfordert; Kühlung, Energieeinstellungen und Hardwareverhalten des Macs bleiben unverändert.

### Window Size (Fenstergröße)

Wähle **Window Size** und danach **Standard** oder **Compact (about 40% smaller)**. Die kompakte Ansicht reduziert die Fensterbreite um rund 40 % und verwendet zugleich dichtere Karten, kleinere Abstände und kleinere Schrift. Dadurch bleibt die Anzeige praktisch nutzbar, statt nur zusammengedrückt zu werden. Die Größenwahl wird lokal gespeichert.

<p align="center">
  <img src="Resources/ManualScreenshots/compact-view.png" width="300" alt="Kompaktansicht von ThermalAtlas mit Temperaturkarten und Systemkontext">
</p>

<p align="center">
  <img src="Resources/ManualScreenshots/window-size-menu.png" width="360" alt="ThermalAtlas-Untermenü Window Size mit ausgewählter Option Compact about 40 percent smaller">
</p>

### Visible Temperatures (Sichtbare Temperaturen)

Unter **Visible Temperatures** lassen sich CPU, GPU, interne SSD und alle externen SSDs ein- oder ausblenden. Die Auswahl wirkt sofort sowohl in der Menüleiste als auch im Fenster mit den Temperaturkarten. Externe SSDs werden gemeinsam geschaltet; bei sichtbarer Gruppe behält jedes erkannte Laufwerk seine eigene Karte. Mindestens eine Gruppe bleibt ausgewählt, damit ThermalAtlas immer eine sichtbare Temperaturanzeige besitzt.

<p align="center">
  <img src="Resources/ManualScreenshots/visible-temperatures-menu.png" width="230" alt="ThermalAtlas-Untermenü Visible Temperatures mit ausgewählten Gruppen CPU, GPU, Internal SSD und External SSD">
</p>

### Menu Bar Display (Menüleistenanzeige)

Unter **Menu Bar Display** legst du fest, wie viel Platz ThermalAtlas in der macOS-Menüleiste verwendet. **All Values** zeigt die Temperaturen der unter **Visible Temperatures** gewählten Gruppen. **Symbol Only** lässt nur das ThermalAtlas-Thermometer stehen; die gewählten Gruppen bleiben unverändert und sind weiterhin im App-Fenster sichtbar. Die Auswahl wird lokal gespeichert.

<p align="center">
  <img src="Resources/ManualScreenshots/menu-bar-display-menu.png" width="260" alt="ThermalAtlas-Untermenü Menu Bar Display mit ausgewähltem All Values und verfügbarem Symbol Only">
</p>

### Temperature History (Temperaturverlauf)

Klicke eine Temperaturkarte an, um ihren lokalen **Temperaturverlauf** zu öffnen. Wähle **1 Hour**, **6 Hours** oder **24 Hours**; die orange gestrichelte Linie markiert die für diese Sensorgruppe gewählte Warnschwelle. ThermalAtlas speichert nur Minutenmittelwerte echter, lesbarer Werte und bewahrt höchstens 24 Stunden auf. Direkt nach dem Start braucht das Diagramm zwei unterschiedliche Minuten, bevor es eine Linie zeichnen kann. Ein nur kurz überbrückter GPU-Wert ist klar markiert und wird nicht als neue Messung aufgezeichnet.

<p align="center">
  <img src="Resources/ManualScreenshots/temperature-history-card.png" width="430" alt="ThermalAtlas-SSD-Karte mit lokalem Einstunden-Temperaturverlauf und Warnschwellenlinie">
</p>

### Temperature Alerts (Temperaturwarnungen)

Unter **Temperature Alerts** lassen sich lokale macOS-Mitteilungen ein- oder ausschalten. CPU, GPU, interne SSD und externe SSDs besitzen jeweils ein eigenes Schwellen-Untermenü. Für CPU und GPU stehen 85, 90, 95 oder 100 °C zur Wahl, für SSDs 60, 65, 70 oder 75 °C. Eine Mitteilung erscheint erst, wenn ein echter Wert mindestens eine Minute lang an oder über der Schwelle liegt. Dieselbe Temperaturphase meldet sich erst wieder, nachdem der Sensor unter die Schwelle abgekühlt ist. Beim ersten Aktivieren kann macOS die Benachrichtigungsberechtigung abfragen.

<p align="center">
  <img src="Resources/ManualScreenshots/temperature-alerts-menu.png" width="230" alt="ThermalAtlas-Menü Temperature Alerts mit getrennten CPU-, GPU- und SSD-Schwellen-Untermenüs">
  <img src="Resources/ManualScreenshots/temperature-alert-thresholds.png" width="130" alt="ThermalAtlas-Untermenü der CPU-Warnschwelle mit ausgewählten 95 Grad Celsius">
</p>

### Start at Login (Bei Anmeldung starten)

Mit **Start at Login** registrierst du ThermalAtlas bei macOS für den automatischen Start nach der Anmeldung. Die erneute Auswahl deaktiviert diese Registrierung wieder. Es ändert nur den Login-Start der App, niemals Energie-, Leistungs- oder Sensoreinstellungen.

### Export

Unter **Export** bereitest du bei Bedarf lokale Diagnosedaten vor. **Copy Current Readings** kopiert den aktuellen Snapshot als Text in die Zwischenablage. **Copy Diagnostic Report** kopiert Mac-Modell, macOS-Version, Chipbezeichnung und den aktuellen lesbaren beziehungsweise nicht verfügbaren Sensorstatus. **Export CSV** öffnet den normalen macOS-Speicherdialog und schreibt eine CSV mit den verfügbaren Minutenmittelwerten des lokalen Verlaufs sowie dem aktuellen Snapshot. Ohne deine Auswahl eines Speicherorts entsteht keine Exportdatei.

<p align="center">
  <img src="Resources/ManualScreenshots/export-menu.png" width="394" alt="ThermalAtlas-Untermenü Export">
</p>

### Language (Sprache)

ThermalAtlas startet standardmäßig auf **Englisch**. Wähle im gemeinsamen Menü **Language** (Sprache) und danach **English** oder **Deutsch**. Die Auswahl ändert die sichtbaren App-Texte und wird lokal gespeichert; Laufwerksnamen und Sensordaten bleiben unverändert.

<p align="center">
  <img src="Resources/ManualScreenshots/language-menu.png" width="198" alt="Englisches ThermalAtlas-Untermenü Language mit ausgewähltem English und verfügbarem Deutsch">
</p>

Die Begriffe des englischen Standardmenüs entsprechen in der deutschen Oberfläche diesen Bezeichnungen:

| English | Deutsch |
| --- | --- |
| Themes | Themen |
| Scan Refresh | Aktualisierungsintervall |
| Window Size | Fenstergröße |
| Visible Temperatures | Sichtbare Temperaturen |
| Menu Bar Display | Menüleistenanzeige |
| Temperature Alerts | Temperaturwarnungen |
| Start at Login | Bei Anmeldung starten |
| Export | Export |
| Language | Sprache |
| Manuals | Handbücher |
| Open Activity Monitor | Aktivitätsanzeige öffnen |
| Quit ThermalAtlas | ThermalAtlas beenden |

### Links, Manuals (Handbücher), Aktivitätsanzeige und Beenden

Dasselbe Menü bietet direkte Links zum öffentlichen **GitHub-Repository**, zur **ThermalAtlas-Homepage** und zu beiden Handbüchern. **Aktivitätsanzeige öffnen** startet die gleichnamige macOS-App. **ThermalAtlas beenden** beendet die App und die regelmäßige Sensorabfrage.

<p align="center">
  <img src="Resources/ManualScreenshots/manuals-menu.png" width="324" alt="Englisches ThermalAtlas-Untermenü Manuals mit English Manual und Deutsches Handbuch">
</p>

Das Öffnen eines öffentlichen Links geschieht nur nach deiner Auswahl und übergibt dessen öffentliche URL an deinen Standardbrowser. Die Temperaturanzeige selbst besitzt keine Netzwerkfunktion.

---

## 5. CPU- und GPU-Temperaturen

ThermalAtlas verwendet für CPU und GPU einen rein lesenden Apple-Silicon-SMC-Zugriff über IOKit.

### CPU

Für die CPU wird aus den lesbaren CPU-Sensoren ein arithmetischer Mittelwert gebildet. Die App zeigt damit einen kompakten Durchschnittswert statt einer langen Liste einzelner Kerne.

### GPU

Auch für die GPU wird aus den verfügbaren GPU-Zonen ein Mittelwert gebildet. Sind alle passenden GPU-Zonen vorübergehend nicht verfügbar, folgt die App dem oben beschriebenen klar markierten letzten echten Wert und zeigt danach korrekt wieder **Nicht verfügbar**, sobald dieser abläuft.

---

## 6. SSD-Temperaturen, SMART und „Nicht verfügbar“

ThermalAtlas verwendet für Laufwerksinformationen die von macOS bereitgestellten `diskutil`-Daten. Die App zeigt den echten Namen des internen Laufwerks und jede erkannte physische externe SSD mit eingebundenem Volume- oder Laufwerksnamen als eigene Karte. Virtuelle Disk-Images werden ignoriert.

Eine SSD-Temperatur wird nur angezeigt, wenn ein echter SMART-Wert vorhanden ist. Besonders bei externen SSDs hängt das davon ab, ob das Laufwerk, der USB-/Thunderbolt-Controller und das Gehäuse die Temperaturinformation bis macOS weiterreichen.

### Wenn „Nicht verfügbar“ erscheint

Das bedeutet nicht automatisch, dass mit dem Laufwerk etwas nicht stimmt. Mögliche Gründe sind:

- macOS stellt für dieses Gerät keinen Temperaturwert bereit.
- Das externe Gehäuse reicht SMART-Daten nicht weiter.
- Ein Sensor ist auf diesem Mac-Modell nicht über den verwendeten rein lesenden Zugriff verfügbar.
- Es wurde kein passendes externes Solid-State-Laufwerk erkannt.

ThermalAtlas zeigt in diesen Fällen bewusst **keinen erfundenen oder geschätzten Wert**.

---

## 7. Installation

### Download

Lade ein verfügbares macOS-Paket ausschließlich über die offiziellen [ThermalAtlas Releases](https://github.com/Schrotty74/ThermalAtlas/releases) herunter.

1. DMG öffnen.
2. `ThermalAtlas.app` in den Programme-Ordner ziehen.
3. ThermalAtlas starten.

### Gatekeeper beim ersten Start

Öffentliche Vorab-Builds sind derzeit ad-hoc signiert und nicht mit einer Apple-Developer-Program-Identität notarisiert. Deshalb kann macOS beim ersten Start eine Warnung anzeigen.

1. Im Finder per Rechtsklick bzw. Control-Klick auf `ThermalAtlas.app` klicken.
2. **Öffnen** wählen.
3. **Öffnen** im macOS-Dialog bestätigen.
4. Falls macOS die App weiterhin blockiert: **Systemeinstellungen -> Datenschutz & Sicherheit -> Dennoch öffnen**.

Bestätige eine solche Ausnahme nur für eine App, die du aus dem offiziellen ThermalAtlas-Repository geladen hast.

---

## 8. Datenschutz

ThermalAtlas ist datenschutzfreundlich und lokal ausgerichtet:

- keine Benutzerkonten
- keine Telemetrie
- keine Analyse-Dienste
- keine Cloud-Synchronisation
- keine Werbe-SDKs
- keine dauerhafte Speicherung der Temperaturmesswerte
- keine Netzwerkfunktion für die Temperaturanzeige
- keine Drittanbieter-Abhängigkeiten

Lokal gespeichert werden das gewählte Theme, das Scan-Refresh-Intervall, die sichtbaren Temperaturgruppen, der Menüleistenmodus, die Fenstergröße, die Sprachwahl und die Warnschwellen. Zusätzlich bewahrt ThermalAtlas höchstens 24 Stunden lokale, minutenweise gemittelte Temperaturverläufe auf. CPU-Last, Stromquelle oder Akku und Energiesparmodus werden nur angezeigt und nicht gespeichert. Es gibt keine Konten, Telemetrie, Analyse-Dienste oder Cloud-Synchronisierung. Weitere Details stehen im [Datenschutzbericht](PRIVACY.de.md) und in der [Sicherheitsprüfung](SECURITY.md).

---

## 9. Ressourcenverbrauch

ThermalAtlas ist architektonisch kompakt aufgebaut: eine Menüleisten-App, ein Sensor-Snapshot im gewählten Intervall und rein lesende Sensorzugriffe. Eine öffentliche Aussage wie **„extrem niedrige CPU-/GPU-Nutzung“** wird in diesem Handbuch bewusst nicht behauptet, solange dafür kein reproduzierbarer Laufzeittest mit gemessenen Werten vorliegt.

---

## 10. Voraussetzungen und Projektstatus

- macOS 14 oder neuer
- Apple Silicon
- Für eigene Builds: Xcode Command Line Tools mit Swift und `actool`

ThermalAtlas befindet sich in aktiver Entwicklung. Öffentliche Vorab-Builds werden über [GitHub Releases](https://github.com/Schrotty74/ThermalAtlas/releases) veröffentlicht.

---

## 11. Weitere Informationen

- [ThermalAtlas Startseite](README.de.md)
- [Releases und Downloads](https://github.com/Schrotty74/ThermalAtlas/releases)
- [Datenschutzbericht](PRIVACY.de.md)
- [Sicherheitsprüfung](SECURITY.md)
- [Quellcode](https://github.com/Schrotty74/ThermalAtlas)
- [English User Manual](MANUAL.md)
