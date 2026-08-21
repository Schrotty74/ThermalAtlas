# Änderungsprotokoll

[English](CHANGELOG.md) · **Deutsch**

## 0.1.0 Beta 1

### Neu

- Native Apple-Silicon-Temperaturanzeige für CPU, GPU, interne SSD und externe SSDs, wenn echte SMART-Daten verfügbar sind.
- Kompakte Menüleistenoberfläche mit Aktualisierung alle zwei Sekunden.
- Defensive Behandlung nicht verfügbarer Sensoren ohne geschätzte Werte.
- Vier visuelle Themes, darunter adaptives Liquid Glass.
- Getrennte Dev-, Beta- und Final-Build-Kanäle mit isolierten Einstellungen und Build-Caches.
- Lokale Beta-/Final-Paketierung als ZIP und DMG. Das DMG enthält einen `Applications`-Alias für Drag-and-drop-Installation.
- Strikte Validierung der Release-Version und Paketprüfungen, die maschinenlokale Build-Pfade vor der Veröffentlichung entfernen.

### Datenschutz und Sicherheit

- Keine Netzwerkkommunikation, Analyse-Dienste, Konten oder Drittanbieter-Abhängigkeiten.
- Ausschließlich lesender Zugriff auf Systemsensoren.
