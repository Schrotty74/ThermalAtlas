#!/usr/bin/env python3
from pathlib import Path

from reportlab.lib.colors import Color, HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader


ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Documentation"
ASSETS = ROOT / "Resources"
W, H = A4
BG = HexColor("#0C1725")
PANEL = HexColor("#19293B")
MUTED = HexColor("#B8C7D9")
CYAN = HexColor("#32C9FF")
VIOLET = HexColor("#9B72FF")
GREEN = HexColor("#29E87A")
ORANGE = HexColor("#FF9C22")


def image_size(path):
    image = ImageReader(str(path))
    return image, image.getSize()


def image(c, path, x, y, width, height):
    reader, (iw, ih) = image_size(path)
    scale = min(width / iw, height / ih)
    draw_w, draw_h = iw * scale, ih * scale
    c.drawImage(reader, x + (width - draw_w) / 2, y + (height - draw_h) / 2,
                draw_w, draw_h, mask="auto")


def lines(c, text, x, y, width, size=12, leading=17, color=white, font="Helvetica"):
    c.setFont(font, size)
    c.setFillColor(color)
    words, current = text.split(), ""
    for word in words:
        proposed = f"{current} {word}".strip()
        if stringWidth(proposed, font, size) > width and current:
            c.drawString(x, y, current)
            y -= leading
            current = word
        else:
            current = proposed
    if current:
        c.drawString(x, y, current)
        y -= leading
    return y


def base(c, number, section, title, subtitle, page):
    c.setFillColor(BG)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(HexColor("#132942"))
    c.circle(W + 35, H - 25, 180, fill=1, stroke=0)
    c.setStrokeColor(CYAN)
    c.setLineWidth(1)
    c.line(42, H - 42, W - 42, H - 42)
    c.setFillColor(CYAN)
    c.setFont("Helvetica", 9)
    c.drawString(42, H - 68, f"{number:02d} · {section.upper()}")
    c.setFillColor(white)
    title_size = 27
    while title_size > 18 and stringWidth(title, "Helvetica", title_size) > W - 84:
        title_size -= 1
    c.setFont("Helvetica", title_size)
    c.drawString(42, H - 98, title)
    c.setFillColor(MUTED)
    c.setFont("Helvetica", 12)
    c.drawString(42, H - 120, subtitle)
    c.setFillColor(MUTED)
    c.setFont("Helvetica", 8)
    c.drawString(42, 25, "ThermalAtlas · local, read-only temperature monitoring")
    c.drawRightString(W - 42, 25, str(page))


def panel(c, x, y, width, height, stroke=CYAN, title=None, text=None):
    c.setFillColor(PANEL)
    c.setStrokeColor(stroke)
    c.roundRect(x, y, width, height, 14, fill=1, stroke=1)
    cursor = y + height - 24
    if title:
        c.setFillColor(stroke)
        c.setFont("Helvetica", 13)
        c.drawString(x + 14, cursor, title)
        cursor -= 21
    if text:
        lines(c, text, x + 14, cursor, width - 28, 11, 15, white)


def build(language, output):
    de = language == "de"
    t = {
        "cover": "ThermalAtlas", "cover_sub": "Temperaturen direkt in der macOS-Menüleiste" if de else "Temperatures directly in the macOS menu bar",
        "readings": "Werte auf einen Blick" if de else "Readings at a glance",
        "interface": "Echte Werte, klare Einordnung." if de else "Real values, clear context.",
        "menu": "Menüleiste & Steuerung" if de else "Menu bar & controls",
        "menu_sub": "Alle wichtigen Einstellungen in einem gemeinsamen Footer-Menü." if de else "Every important setting in one shared footer menu.",
        "size": "Fenstergröße" if de else "Window Size",
        "visible": "Sichtbare Temperaturen" if de else "Visible Temperatures",
        "history": "Temperaturverlauf" if de else "Temperature History",
        "alerts": "Temperaturwarnungen" if de else "Temperature Alerts",
        "themes": "Themes", "theme_sub": "Vier Darstellungen, dieselben Sensordaten." if de else "Four appearances, the same sensor data.",
        "privacy": "Lokal & datenschutzfreundlich" if de else "Local & privacy-friendly",
        "privacy_sub": "Lesende Sensorabfragen ohne Konten, Telemetrie oder Cloud." if de else "Read-only sensor checks without accounts, telemetry or cloud.",
    }
    c = canvas.Canvas(str(output), pagesize=A4)

    # 1 Cover
    base(c, 0, "ThermalAtlas", t["cover"], t["cover_sub"], 1)
    image(c, ASSETS / "ManualScreenshots" / "full-liquid-glass-fans.png", 110, 210, 375, 410)
    panel(c, 70, 82, W - 140, 82, VIOLET,
          "CPU · GPU · SSD",
          "Echte, lokal gelesene Temperaturen für Apple-Silicon-Macs." if de else "Real, locally read temperatures for Apple-silicon Macs.")
    c.showPage()

    # 2 Readings
    base(c, 1, "Messwerte" if de else "Readings", t["readings"], t["interface"], 2)
    image(c, ASSETS / "ManualScreenshots" / "full-adaptive-fans.png", 48, 180, 220, 490)
    image(c, ASSETS / "ManualScreenshots" / "system-context-fans.png", 290, 555, 260, 105)
    panel(c, 290, 415, 260, 110, VIOLET, "CPU / GPU",
          "Mittelwert der aktuell lesbaren passenden Sensoren." if de else "Average of matching sensors that are readable right now.")
    panel(c, 290, 275, 260, 110, GREEN, "SSD / SMART",
          "Temperatur, SMART-Status und Gesundheit erscheinen nur bei echten macOS-Daten. Externe Gehäuse müssen SMART weiterreichen; fehlt die Temperatur, erscheint Nicht verfügbar." if de else "Temperature, SMART status and health appear only when macOS supplies real data. External enclosures must pass SMART through; missing temperatures show Not available.")
    panel(c, 290, 85, 260, 160, CYAN, "Systemkontext" if de else "System Context",
          "CPU-Last, Lüfter 1 und 2 in RPM, Arbeitsspeicher, Stromquelle und Energiesparmodus. GPU-Last wird nicht angezeigt. Die Kontextwerte aktualisieren sich etwa alle 0,5 Sekunden." if de else "CPU load, Fan 1 and 2 in RPM, memory, power source and Low Power Mode. GPU load is not shown. Context values refresh about every 0.5 seconds.")
    c.showPage()

    # 3 Menu bar and shared menu
    base(c, 2, "Steuerung" if de else "Controls", t["menu"], t["menu_sub"], 3)
    panel(c, 48, 555, W - 96, 115, CYAN,
          "Menüleisten-Anzeige" if de else "Menu bar display",
          "Farbig getrennte Sensorsymbole zeigen alle verfügbaren Werte der ausgewählten Gruppen in einer kontrastreichen Statusfläche." if de else "Colour-coded sensor symbols show every available value from the selected groups in a high-contrast status frame.")
    image(c, ASSETS / "ManualScreenshots" / "menu-bar-temperatures.png", 76, 490, W - 152, 45)
    image(c, ASSETS / "ManualScreenshots" / "shared-menu.png", 70, 105, 250, 345)
    panel(c, 345, 310, 200, 140, VIOLET, "Themes / Scan Refresh",
          "Darstellung und Aktualisierungsintervall ändern nur die Oberfläche beziehungsweise die Häufigkeit der lesenden Abfragen." if de else "Appearance and refresh interval change only the interface or the frequency of read-only checks.")
    panel(c, 345, 145, 200, 135, GREEN, "Export / Fenster",
          "Unter Export folgen Immer im Vordergrund und Start bei Anmeldung. Immer im Vordergrund hält das Fenster über anderen Apps sichtbar." if de else "Below Export are Always on Top and Start at Login. Always on Top keeps the window visible above other apps.")
    c.showPage()

    # 4 New options
    base(c, 3, "Neue Optionen" if de else "New options", "Fenstergröße & sichtbare Werte" if de else "Window size & visible values",
         "Beide Einstellungen gelten sofort und werden lokal gespeichert." if de else "Both settings take effect immediately and are stored locally.", 4)
    image(c, ASSETS / "ManualScreenshots" / "window-size-menu.png", 70, 560, 455, 110)
    panel(c, 70, 410, 455, 115, VIOLET, t["size"],
          "Standard zeigt die großzügige Kartenansicht. Kompakt ist rund 40 % schmaler und nutzt dichtere Karten, kleinere Abstände und kleinere Schrift. Mini Display ersetzt das Fenster durch eine verschiebbare Leiste mit den ausgewählten Temperaturwerten. Mehr dazu auf Seite 5." if de else "Standard keeps the generous card layout. Compact is about 40% narrower and uses denser cards, smaller spacing and smaller type. Mini Display replaces the window with a movable strip showing the selected temperatures. See page 5 for details.")
    image(c, ASSETS / "ManualScreenshots" / "compact-view.png", 70, 110, 180, 280)
    panel(c, 280, 255, 245, 135, GREEN, "Kompakt & Verlauf" if de else "Compact & history",
          "Die kompakte Ansicht behält den Temperaturverlauf mit 1, 6 und 24 Stunden bei." if de else "The compact view retains the 1-, 6- and 24-hour temperature history.")
    image(c, ASSETS / "ManualScreenshots" / "menu-bar-display-menu.png", 310, 150, 215, 68)
    panel(c, 280, 75, 245, 60, CYAN, None,
          "Menüleistenmodus und sichtbare Temperaturgruppen werden ebenfalls lokal gespeichert." if de else "Menu bar mode and visible temperature groups are also stored locally.")
    c.showPage()

    # 5 Mini display
    base(c, 4, "Mini-Anzeige" if de else "Mini Display", "Kompakte schwebende Anzeige" if de else "Compact floating display",
         "Ausgewählte Werte bleiben sichtbar, ohne das große Fenster zu öffnen." if de else "Selected values stay visible without opening the large window.", 5)
    panel(c, 55, 555, W - 110, 115, GREEN, "Mini Display",
          "Die Auswahl ersetzt das große Fenster durch eine schmale, verschiebbare Leiste mit den ausgewählten lesbaren Temperaturen. Aktiviere Immer im Vordergrund, damit die Leiste auch Vollbildbereiche anderer Apps betreten kann. Das Verhalten über einem bestimmten Vollbildspiel muss noch dort geprüft werden." if de else "This choice replaces the large window with a narrow, movable strip showing the selected readable temperatures. Enable Always on Top to let it join other apps' full-screen spaces. Its behavior over a particular full-screen game still needs to be checked in that game.")
    image(c, ASSETS / "ManualScreenshots" / "mini-display.png", 55, 430, W - 110, 58)
    panel(c, 55, 325, W - 110, 75, CYAN, "Rechtsklick" if de else "Right-click",
          "Die Leiste klappt Window Size mit Standard und Compact direkt darunter auf." if de else "The strip expands Window Size with Standard and Compact directly below it.")
    image(c, ASSETS / "ManualScreenshots" / "mini-display-controls.png", 55, 62, W - 110, 235)
    c.showPage()

    # 6 History and alerts
    base(c, 5, "Verlauf" if de else "History", "Temperaturverlauf & Warnungen" if de else "Temperature history & alerts",
         "Lokale Minutenmittelwerte und zurückhaltende macOS-Mitteilungen." if de else "Local minute averages and restrained macOS notifications.", 6)
    image(c, ASSETS / "ManualScreenshots" / "temperature-history-card.png", 70, 385, 455, 285)
    panel(c, 70, 270, 455, 110, CYAN, t["history"],
          "Wähle 1, 6 oder 24 Stunden. Klicke oder ziehe im Graphen: Die Markierung zeigt den nächsten gespeicherten Messpunkt mit Uhrzeit und Minutenmittelwert. Ein Bereichswechsel löscht die Auswahl. Ein Klick auf die Karte außerhalb des Graphen schließt den Verlauf. Die gestrichelte Linie zeigt die Warnschwelle." if de else "Choose 1, 6 or 24 hours. Click or drag in the chart to mark the nearest recorded point and show its time and minute average. Changing the range clears the selection. Click the card outside the chart to close history. The dashed line shows the warning threshold.")
    image(c, ASSETS / "ManualScreenshots" / "temperature-alerts-menu.png", 70, 78, 185, 190)
    image(c, ASSETS / "ManualScreenshots" / "temperature-alert-thresholds.png", 275, 78, 110, 155)
    image(c, ASSETS / "ManualScreenshots" / "export-menu.png", 400, 210, 125, 40)
    panel(c, 400, 78, 125, 110, ORANGE, "Export",
          "Text kopieren oder CSV mit Verlauf und aktuellem Snapshot lokal speichern." if de else "Copy text or save a local CSV with history and the current snapshot.")
    c.showPage()

    # 7 Themes
    base(c, 6, "Darstellung" if de else "Appearance", t["themes"], t["theme_sub"], 7)
    positions = [(55, 390), (312, 390), (55, 85), (312, 85)]
    names = ["Adaptiv" if de else "Adaptive", "Liquid Glass", "Aurora", "Ember"]
    files = ["full-adaptive-fans.png", "full-liquid-glass-fans.png", "full-aurora-fans.png", "full-ember-fans.png"]
    colors = [CYAN, VIOLET, CYAN, ORANGE]
    for (x, y), name, filename, color in zip(positions, names, files, colors):
        panel(c, x, y, 225, 285, color, name)
        image(c, ASSETS / "ManualScreenshots" / filename, x + 15, y + 12, 195, 245)
    c.showPage()

    # 8 Privacy and use
    base(c, 7, "Datenschutz" if de else "Privacy", t["privacy"], t["privacy_sub"], 8)
    panel(c, 55, 560, W - 110, 105, GREEN,
          "Lokale Sensordaten" if de else "Local sensor data",
          "Keine Konten, keine Telemetrie, keine Analyse-Dienste und keine Cloud-Synchronisierung. Der Verlauf bleibt lokal und ist auf 24 Stunden begrenzt." if de else "No accounts, telemetry, analytics services or cloud synchronization. History stays local and is limited to 24 hours.")
    panel(c, 55, 415, W - 110, 105, CYAN,
          "Gespeicherte Auswahl" if de else "Stored choices",
          "Theme, Scan Refresh, Sprache, sichtbare Sensorgruppen, Menüleistenmodus, Fenstergröße, Mini-Anzeige, Immer im Vordergrund, Warnschwellen und Minutenmittelwerte bleiben lokal. Das gilt auch für Updateintervalle, Prüfzeitpunkte und bereits gemeldete Release-Tags." if de else "Theme, Scan Refresh, language, visible sensor groups, menu bar mode, window size, Mini Display, Always on Top, warning thresholds and minute averages stay local. So do update intervals, check timestamps and already reported release tags.")
    panel(c, 55, 270, W - 110, 105, ORANGE,
          "Sicherer Umgang" if de else "Safe operation",
          "ThermalAtlas liest Temperaturen, Laufwerksinformationen und Systemkontext. Die App verändert keine Lüfter-, Energie- oder sonstigen Systemeinstellungen." if de else "ThermalAtlas reads temperatures, drive information and system context. It changes no fan, power or other system settings.")
    panel(c, 55, 125, W - 110, 105, VIOLET,
          "GitHub-Updateprüfung" if de else "GitHub update checks",
          "Optionale Updateprüfungen kontaktieren GitHub über HTTPS. GitHub sieht die IP-Adresse, erhält aber keine Sensor- oder Gerätedaten und keine installierte Version. Automatische Prüfungen sind zunächst aus (Seite 13). README, Datenschutzbericht und Sicherheitsprüfung stehen im offiziellen Repository." if de else "Optional update checks contact GitHub over HTTPS. GitHub sees the IP address but receives no sensor or device data or installed version. Automatic checks are off by default (page 13). The README, privacy report and security review are in the official repository.")
    c.showPage()

    # 9 System information
    base(c, 8, "Systeminformationen" if de else "System Information",
         "Dieser Mac auf einen Blick" if de else "This Mac at a glance",
         "Die Angaben bleiben lokal und werden nur beim Öffnen gelesen." if de else "The details stay local and are read only when opened.", 9)
    image(c, ASSETS / "ManualScreenshots" / "system-information.png", 82, 320, W - 164, 375)
    panel(c, 55, 205, W - 110, 90, VIOLET,
          "Thermischer Zustand" if de else "Thermal State",
          "macOS meldet Normal, Erhöht, Hoch oder Kritisch. Diese Systembewertung ist keine Temperatur in Grad. Die Angaben werden beim Öffnen gelesen; öffne das Fenster erneut für den aktuellen Zustand." if de else "macOS reports Normal, Elevated, High or Critical. This system assessment is not a temperature in degrees. Details are read when the window opens; reopen it for the current state.")
    panel(c, 55, 125, W - 110, 65, CYAN,
          "Thermometer im Kopf" if de else "Header thermometer",
          "Es öffnet Mac-Modell, Chip, CPU-/GPU-Kerne, Arbeitsspeicher, internen Speicher und macOS-Version." if de else "It opens the Mac model, chip, CPU/GPU cores, memory, internal storage and macOS version.")
    panel(c, 55, 48, W - 110, 55, GREEN,
          "Privat" if de else "Private",
          "Keine Seriennummern, UUIDs oder anderen Hardware-Kennungen." if de else "No serial numbers, UUIDs or other hardware identifiers.")
    c.showPage()

    # 10 Gatekeeper
    base(c, 9, "Installation" if de else "Installation",
         "Sicher öffnen" if de else "Open safely",
         "Freigabe nur für die offizielle App." if de else "Approve only the official app.", 10)
    panel(c, 55, 515, W - 110, 145, CYAN,
          "Gatekeeper" if de else "Gatekeeper",
          "Öffentliche Builds sind ad-hoc signiert und nicht notarisiert. macOS kann den ersten Start deshalb blockieren." if de else "Public builds are ad-hoc signed and not notarized. macOS can therefore block the first launch.")
    panel(c, 55, 280, W - 110, 195, VIOLET,
          "So öffnest du ThermalAtlas" if de else "How to open ThermalAtlas",
          "1. ThermalAtlas.app einmal normal öffnen. macOS blockiert den Start. 2. Systemeinstellungen > Datenschutz & Sicherheit öffnen. 3. Zum Bereich Sicherheit scrollen und bei ThermalAtlas Dennoch öffnen wählen. 4. Die Warnung mit Öffnen bestätigen und bei Bedarf authentifizieren." if de else "1. Open ThermalAtlas.app normally once. macOS blocks the launch. 2. Open System Settings > Privacy & Security. 3. Scroll to Security and choose Open Anyway for ThermalAtlas. 4. Confirm the warning with Open and authenticate if macOS asks you to.")
    panel(c, 55, 115, W - 110, 125, GREEN,
          "Nur diese App" if de else "Only this app",
          "Dennoch öffnen erscheint nur für begrenzte Zeit nach dem blockierten Startversuch. Dadurch wird nur für ThermalAtlas eine Ausnahme angelegt; Gatekeeper wird nicht systemweit deaktiviert. Die Freigabe nur für eine App aus dem offiziellen ThermalAtlas-GitHub-Release verwenden." if de else "Open Anyway is shown only for a limited time after the blocked launch attempt. This creates an exception only for ThermalAtlas and does not disable Gatekeeper system-wide. Use it only for an app obtained from the official ThermalAtlas GitHub release.")
    c.showPage()

    # 11 Menu settings and exports
    base(c, 10, "Menüfunktionen" if de else "Menu functions",
         "Einstellungen & Export" if de else "Settings & export",
         "Wähle die Optionen im Dreipunkt-Menü unten im Hauptfenster." if de else "Choose these options in the ellipsis menu at the bottom of the main window.", 11)
    panel(c, 55, 535, W - 110, 130, CYAN,
          "Scan Refresh / Visible Temperatures",
          "Scan Refresh wählt 1, 2, 3 oder 4 Sekunden für CPU und GPU; Standard sind 2 Sekunden. SSD-Temperaturen werden jede Minute gelesen, der Systemkontext etwa alle 0,5 Sekunden. Visible Temperatures schaltet CPU, GPU, interne SSD oder alle externen SSDs gemeinsam für Fenster, Menüleiste und Mini-Anzeige. Mindestens eine Gruppe bleibt ausgewählt." if de else "Scan Refresh selects 1, 2, 3 or 4 seconds for CPU and GPU; the default is 2 seconds. SSD temperatures are read every minute and System Context about every 0.5 seconds. Visible Temperatures switches CPU, GPU, Internal SSD or all External SSDs for the window, menu bar and mini strip. At least one group remains selected.")
    panel(c, 55, 375, W - 110, 135, GREEN,
          "Menu Bar Display / Always on Top",
          "All Values zeigt die ausgewählten verfügbaren Temperaturen. Symbol Only zeigt nur das Thermometer in der Menüleiste. Immer im Vordergrund hält das Hauptfenster über normalen App-Fenstern; die Mini-Leiste erhält zusätzlich Vollbild-Unterstützung (Seite 5). Erneut auswählen schaltet die Option aus. Die Auswahl wird lokal gespeichert." if de else "All Values shows the selected available temperatures. Symbol Only leaves just the thermometer in the menu bar. Always on Top keeps the main window above normal app windows and adds full-screen support to the mini strip (page 5). Choose it again to turn it off. These choices are stored locally.")
    panel(c, 55, 205, W - 110, 145, VIOLET,
          "Export",
          "Copy Current Readings kopiert die aktuellen Temperaturen als Text. Copy Diagnostic Report kopiert Mac-Modell, macOS-Version, Chip und Sensorstatus. Export CSV öffnet den Speicherdialog für bis zu 24 Stunden Minutenmittelwerte und den aktuellen Snapshot. Die CSV enthält Zeit, Sensor, Quelle, Temperatur und Wertstatus sowie vorhandene SMART-Daten. Hotspots werden nicht exportiert. Ohne deine Auswahl wird keine Datei erstellt." if de else "Copy Current Readings copies current temperatures as text. Copy Diagnostic Report copies the Mac model, macOS version, chip and sensor status. Export CSV opens a save dialog for up to 24 hours of minute averages and the current snapshot. CSV includes time, sensor, source, temperature and value status plus available SMART data. Hotspots are not exported. No file is created without your choice.")
    panel(c, 55, 55, W - 110, 125, ORANGE,
          "Language / Start at Login",
          "Language wechselt zwischen English und Deutsch. Die Wahl wird gespeichert; Laufwerksnamen bleiben unverändert. Start at Login aktiviert den App-Start nach der macOS-Anmeldung. Erneut auswählen deaktiviert ihn. Es werden keine Energie- oder Leistungseinstellungen geändert." if de else "Language switches between English and Deutsch. The choice is stored; drive names stay unchanged. Start at Login enables app launch after signing in to macOS. Choose it again to disable it. Power and performance settings are unaffected.")
    c.showPage()

    # 12 Sensor details, warnings and accessibility
    base(c, 11, "Bedienung" if de else "Operation",
         "Details & Warnungen" if de else "Details & alerts",
         "Temperatur, Verlauf und Systembewertung haben unterschiedliche Aufgaben." if de else "Temperature, history and system assessments serve different purposes.", 12)
    panel(c, 55, 510, W - 110, 155, CYAN,
          "Info-Symbol / Hotspot" if de else "Info symbol / Hotspot",
          "Das Info-Symbol öffnet Quelle, letzten gültigen Wert und Zeitpunkt. CPU und GPU zeigen zusätzlich Chip, Durchschnitt, höchsten lesbaren Sensorwert (Hotspot) und Anzahl gültiger Sensoren. SSDs zeigen die Laufwerks-ID und vorhandene Messhinweise. Karte, Menüleiste, Mini-Anzeige und Verlauf zeigen den Durchschnitt. Bei einem kurzen GPU-Ausfall bleibt ein markierter echter Wert höchstens 15 Sekunden stehen; danach erscheint Nicht verfügbar." if de else "The info symbol opens the source, last valid value and time. CPU and GPU also show the chip, average, highest readable sensor value (Hotspot) and valid sensor count. SSDs show the drive ID and available reading details. Cards, menu bar, mini strip and history show the average. A short GPU failure can retain a marked real value for at most 15 seconds, then shows Not available.")
    panel(c, 55, 345, W - 110, 140, ORANGE,
          "Temperature Alerts",
          "CPU/GPU: 85, 90, 95 oder 100 °C (Standard 95); SSDs: 60, 65, 70 oder 75 °C (Standard 70). CPU/GPU verwenden den Hotspot, falls vorhanden, sonst den Durchschnitt. Eine Mitteilung folgt erst nach mindestens einer Minute an oder über der Schwelle; eine neue Episode erfordert Abkühlung. Der Menüleistenrahmen wird zehn Grad unter der Schwelle gelb und ab der Schwelle rot, auch bei ausgeschalteten Mitteilungen. Der Verlauf bleibt ein Minutenmittelwert." if de else "CPU/GPU: 85, 90, 95 or 100 °C (default 95); SSDs: 60, 65, 70 or 75 °C (default 70). CPU/GPU use the Hotspot when available, otherwise the average. Notifications require at least one minute at or above the threshold; a new episode requires cooling. The menu bar frame turns yellow within ten degrees below the threshold and red at it, even with notifications disabled. History remains a minute average.")
    panel(c, 55, 180, W - 110, 140, GREEN,
          "VoiceOver / Darstellung" if de else "VoiceOver / appearance",
          "Temperaturkarten geben Verlaufstatus und Bedienung über VoiceOver aus. Bewegung reduzieren begrenzt Kartenanimationen und Verlaufsexpansion; Transparenz reduzieren macht Glasflächen opaker. Im Liquid-Glass-Theme nutzt der Thermometer-Button ab macOS 27 den interaktiven Systemglasstil. Der RAM-Status ist Normal unter 70 %, Erhöht unter 85 % und Hoch ab 85 % Belegung; er ist keine Speicherdruckanzeige." if de else "Temperature cards announce history state and controls through VoiceOver. Reduce Motion limits card and history-opening animations; Reduce Transparency makes glass surfaces opaque. In Liquid Glass on macOS 27 or later, the thermometer button uses interactive system glass. Memory status is Normal below 70%, Elevated below 85% and High from 85% usage; it is not a memory-pressure indicator.")
    panel(c, 55, 40, W - 110, 115, VIOLET,
          "Fenster, Links & Beenden" if de else "Windows, links & quit",
          "Ziehe Titelleiste oder Hintergrund zum Verschieben. Schließen verbirgt das Hauptfenster; die Erfassung läuft weiter. Der Menüleisteneintrag öffnet es erneut. GitHub, Homepage und Manuals öffnen Links im Browser. Open Activity Monitor öffnet die Aktivitätsanzeige. Quit ThermalAtlas beendet App und Erfassung." if de else "Drag the title bar or background to move the window. Closing hides the main window; collection continues. The menu bar item opens it again. GitHub, Homepage and Manuals open browser links. Open Activity Monitor opens Activity Monitor. Quit ThermalAtlas stops the app and collection.")
    c.showPage()

    # 13 App updates
    base(c, 12, "App-Updates" if de else "App Updates",
         "Final- und Beta-Versionen prüfen" if de else "Check Final and Beta versions",
         "Verfügbar ab Beta 1.2.0-beta.5." if de else "Available from Beta 1.2.0-beta.5.", 13)
    image(c, ASSETS / "ManualScreenshots" / "app-updates-menu.png", 55, 510, W - 110, 165)
    lines(c, "Englisches Menü; Version, Zeitpunkt und Beta-Tag stammen aus dieser Aufnahme." if de else "English menu; version, timestamp and Beta tag are values from this capture.",
          55, 491, W - 110, 9, 12, MUTED)
    panel(c, 55, 370, W - 110, 100, CYAN,
          "Check Now / Jetzt prüfen" if de else "Check Now",
          "Öffne App Updates unter Start at Login. Check Now prüft sofort, auch bei Off. Das Ergebnisfenster zeigt neuere Versionen oder meldet, dass keine verfügbar sind. Eine fehlgeschlagene Prüfung ist keine Bestätigung, dass die App aktuell ist." if de else "Open App Updates below Start at Login. Check Now checks immediately, even with Off selected. The result window lists newer versions or reports none available. A failed check does not confirm that the app is up to date.")
    panel(c, 55, 205, W - 110, 145, GREEN,
          "Automatic Checks / Automatisch prüfen" if de else "Automatic Checks",
          "Off ist der Standard. Daily prüft nach einem Kalendertag, Weekly nach sieben Tagen und Monthly nach einem Kalendermonat ab der letzten erfolgreichen Prüfung. Die App muss laufen; Hauptfenster und Mini-Anzeige dürfen geschlossen sein. Überfällige Prüfungen werden nachgeholt. Nach einem Fehler wartet ein automatischer Wiederholungsversuch mindestens eine Stunde. Die Auswahl bleibt lokal gespeichert." if de else "Off is the default. Daily checks after one calendar day, Weekly after seven days and Monthly after one calendar month from the last successful check. The app must be running; its main window and mini strip may be closed. Overdue checks are caught up. After a failure, an automatic retry waits at least one hour. The choice is stored locally.")
    panel(c, 55, 45, W - 110, 140, VIOLET,
          "Version, Zeitpunkt und Funde" if de else "Version, time and results",
          "Installed version nennt die laufende App-Version, Last successful check den letzten erfolgreichen Abruf. Final und Beta öffnen je Kanal die höchste neuere Release-Version. Final ist neuer als Beta derselben Nummer. Neue Funde öffnen ein Hinweisfenster; automatisch wird jedes Release einmal gemeldet. Check Now zeigt es erneut. Download und Installation wählst du selbst. Keine Sensor- oder Gerätedaten werden gesendet; keine gespeicherten Cookies oder Zugangsdaten verwendet." if de else "Installed version identifies the running app. Last successful check shows the last successful GitHub check. Final and Beta open the highest newer release in each channel. A Final is newer than a Beta with the same version number. New finds open a notice window; each release is reported automatically once. Check Now can show it again. You choose download and installation. Checks send no sensor or device data and use no stored cookies or credentials.")
    c.save()


if __name__ == "__main__":
    build("en", OUT / "ThermalAtlas-User-Manual-EN.pdf")
    build("de", OUT / "ThermalAtlas-Handbuch-DE.pdf")
