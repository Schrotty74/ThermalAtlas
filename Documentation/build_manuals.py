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
    c.setFont("Helvetica", 27)
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
    image(c, ASSETS / "Screenshots" / "liquid-glass.png", 110, 210, 375, 410)
    panel(c, 70, 82, W - 140, 82, VIOLET,
          "CPU · GPU · SSD",
          "Echte, lokal gelesene Temperaturen für Apple-Silicon-Macs." if de else "Real, locally read temperatures for Apple-silicon Macs.")
    c.showPage()

    # 2 Readings
    base(c, 1, "Messwerte" if de else "Readings", t["readings"], t["interface"], 2)
    image(c, ASSETS / "ManualScreenshots" / "compact-view.png", 48, 180, 220, 490)
    image(c, ASSETS / "ManualScreenshots" / "system-context-load.png", 290, 555, 260, 105)
    panel(c, 290, 415, 260, 110, VIOLET, "CPU / GPU",
          "Mittelwert der aktuell lesbaren passenden Sensoren." if de else "Average of matching sensors that are readable right now.")
    panel(c, 290, 275, 260, 110, GREEN, "SSD / SMART",
          "Temperatur, SMART-Status und Gesundheit erscheinen nur bei echten macOS-Daten." if de else "Temperature, SMART status and health appear only when macOS supplies real data.")
    panel(c, 290, 120, 260, 125, CYAN, "Systemkontext" if de else "System Context",
          "CPU- und GPU-Last, Arbeitsspeicher, Stromquelle und Energiesparmodus aktualisieren sich unabhängig alle 0,5 Sekunden." if de else "CPU and GPU load, memory, power source and Low Power Mode update independently every 0.5 seconds.")
    c.showPage()

    # 3 Menu bar and shared menu
    base(c, 2, "Steuerung" if de else "Controls", t["menu"], t["menu_sub"], 3)
    panel(c, 48, 555, W - 96, 115, CYAN,
          "Menüleisten-Anzeige" if de else "Menu bar display",
          "Kompakte Sensorsymbole zeigen alle verfügbaren Werte der ausgewählten Gruppen." if de else "Compact sensor symbols show every available value from the selected groups.")
    image(c, ASSETS / "ManualScreenshots" / "menu-bar-temperatures.png", 76, 490, W - 152, 45)
    image(c, ASSETS / "ManualScreenshots" / "shared-menu.png", 70, 105, 250, 345)
    panel(c, 345, 310, 200, 140, VIOLET, "Themes / Scan Refresh",
          "Darstellung und Aktualisierungsintervall ändern nur die Oberfläche beziehungsweise die Häufigkeit der lesenden Abfragen." if de else "Appearance and refresh interval change only the interface or the frequency of read-only checks.")
    panel(c, 345, 145, 200, 135, GREEN, "Alerts / Language",
          "Menüleistenmodus, Warnungen, Export, Sprache, Handbücher, öffentliche Links, Aktivitätsanzeige und Beenden bleiben zusammen im Footer-Menü." if de else "Menu bar mode, alerts, export, language, manuals, public links, Activity Monitor and quit remain together in the footer menu.")
    c.showPage()

    # 4 New options
    base(c, 3, "Neue Optionen" if de else "New options", "Fenstergröße & sichtbare Werte" if de else "Window size & visible values",
         "Beide Einstellungen gelten sofort und werden lokal gespeichert." if de else "Both settings take effect immediately and are stored locally.", 4)
    image(c, ASSETS / "ManualScreenshots" / "window-size-menu.png", 70, 560, 455, 110)
    panel(c, 70, 425, 455, 100, VIOLET, t["size"],
          "Standard zeigt die großzügige Kartenansicht. Kompakt ist rund 40 % schmaler und nutzt dichtere Karten, kleinere Abstände und kleinere Schrift." if de else "Standard keeps the generous card layout. Compact is about 40% narrower and uses denser cards, smaller spacing and smaller type.")
    image(c, ASSETS / "ManualScreenshots" / "visible-temperatures-menu.png", 70, 140, 210, 230)
    image(c, ASSETS / "ManualScreenshots" / "menu-bar-display-menu.png", 310, 300, 215, 68)
    panel(c, 310, 140, 215, 135, GREEN, "Menüleistenanzeige" if de else "Menu Bar Display",
          "Alle Werte zeigt die gewählten Gruppen. Nur Symbol spart Platz und lässt die Auswahl im Fenster unverändert." if de else "All Values shows the selected groups. Symbol Only saves space and leaves the window selection unchanged.")
    c.showPage()

    # 5 History and alerts
    base(c, 4, "Verlauf" if de else "History", "Temperaturverlauf & Warnungen" if de else "Temperature history & alerts",
         "Lokale Minutenmittelwerte und zurückhaltende macOS-Mitteilungen." if de else "Local minute averages and restrained macOS notifications.", 5)
    image(c, ASSETS / "ManualScreenshots" / "temperature-history-card.png", 70, 385, 455, 285)
    panel(c, 70, 295, 455, 65, CYAN, t["history"],
          "1, 6 oder 24 Stunden; die gestrichelte Linie markiert die lokale Warnschwelle. Erst zwei Minuten liefern eine sichtbare Kurve." if de else "1, 6 or 24 hours; the dashed line marks the local warning threshold. A visible curve starts after two minutes.")
    image(c, ASSETS / "ManualScreenshots" / "temperature-alerts-menu.png", 70, 78, 185, 190)
    image(c, ASSETS / "ManualScreenshots" / "temperature-alert-thresholds.png", 275, 78, 110, 155)
    image(c, ASSETS / "ManualScreenshots" / "export-menu.png", 400, 210, 125, 40)
    panel(c, 400, 78, 125, 110, ORANGE, "Export",
          "Text kopieren oder CSV mit Verlauf und aktuellem Snapshot lokal speichern." if de else "Copy text or save a local CSV with history and the current snapshot.")
    c.showPage()

    # 6 Themes
    base(c, 5, "Darstellung" if de else "Appearance", t["themes"], t["theme_sub"], 6)
    positions = [(55, 450), (312, 450), (55, 175), (312, 175)]
    names = ["Classic", "Liquid Glass", "Aurora", "Ember"]
    files = ["classic.png", "liquid-glass.png", "aurora.png", "ember.png"]
    colors = [CYAN, VIOLET, CYAN, ORANGE]
    for (x, y), name, filename, color in zip(positions, names, files, colors):
        panel(c, x, y, 225, 220, color, name)
        image(c, ASSETS / "Screenshots" / filename, x + 15, y + 15, 195, 165)
    c.showPage()

    # 7 Privacy and use
    base(c, 6, "Datenschutz" if de else "Privacy", t["privacy"], t["privacy_sub"], 7)
    panel(c, 55, 560, W - 110, 105, GREEN,
          "Nur lokal" if de else "Local only",
          "Keine Konten, keine Telemetrie, keine Analyse-Dienste und keine Cloud-Synchronisierung. Der Verlauf bleibt lokal und ist auf 24 Stunden begrenzt." if de else "No accounts, telemetry, analytics services or cloud synchronization. History stays local and is limited to 24 hours.")
    panel(c, 55, 415, W - 110, 105, CYAN,
          "Gespeicherte Auswahl" if de else "Stored choices",
          "Theme, Aktualisierungsintervall, Sprache, sichtbare Temperaturgruppen, Menüleistenmodus, Fenstergröße, Warnschwellen und Minutenmittelwerte bleiben ausschließlich lokal." if de else "Theme, refresh interval, language, visible temperature groups, menu bar mode, window size, warning thresholds and minute averages remain only locally.")
    panel(c, 55, 270, W - 110, 105, ORANGE,
          "Sicherer Umgang" if de else "Safe operation",
          "ThermalAtlas liest Temperaturen, Laufwerksinformationen und Systemkontext. Die App verändert keine Lüfter-, Energie- oder sonstigen Systemeinstellungen." if de else "ThermalAtlas reads temperatures, drive information and system context. It changes no fan, power or other system settings.")
    panel(c, 55, 125, W - 110, 105, VIOLET,
          "Mehr Informationen" if de else "More information",
          "README, Datenschutzbericht und Sicherheitsprüfung im offiziellen ThermalAtlas-Repository ergänzen dieses Handbuch." if de else "The README, privacy report and security review in the official ThermalAtlas repository complement this manual.")
    c.save()


if __name__ == "__main__":
    build("en", OUT / "ThermalAtlas-User-Manual-EN.pdf")
    build("de", OUT / "ThermalAtlas-Handbuch-DE.pdf")
