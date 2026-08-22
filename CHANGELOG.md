# Changelog

All notable user-visible changes are documented here in English. Development builds remain local; public prereleases are announced through GitHub Releases.

## 0.2.0

### Added

- English as the default interface language, with German available from the shared footer menu.
- A shared footer menu for themes, Scan Refresh, language, GitHub, homepage, manuals, Activity Monitor, and Quit.
- SSD SMART status and, when macOS exposes NVMe `PERCENTAGE_USED`, a separately displayed remaining-health percentage.
- Separate temperature cards for every detected physical external SSD, using the mounted volume or drive name where available.

### Improved

- CPU and GPU cards now describe their values as averages of readable matching sensors.
- SSD status and health text has improved contrast and spacing.
- The public English and German project home pages now document the shared menu and display options.

### Fixed

- Temporary GPU sensor read failures can retain a clearly labelled last verified real value for a short time before correctly returning to `Not available`.
