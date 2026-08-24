# Changelog

All notable user-visible changes are documented here in English. Development builds remain local; public prereleases are announced through GitHub Releases.

## 0.4.0

### Added

- CPU and GPU temperature-key families for Apple-silicon M1 through M5, including known Pro, Max, and Ultra variants. CPU/GPU recognition is currently hardware-confirmed only on M4 Max, M5, and M5 Pro; all other variants remain to be tested.
- GPU load and used memory alongside CPU load, power source/battery, and Low Power Mode in the separate read-only System Context.
- New compact-view and System Context screenshots in the English and German manuals and their PDFs.

### Improved

- System Context refreshes independently every 0.5 seconds, while CPU/GPU temperature refresh stays selectable from one to four seconds.
- External-drive topology now refreshes at launch, on macOS mount/unmount events, and hourly. An ejected but still connected external SSD no longer remains visible.
- Known physical SSD temperatures refresh every minute for local history and alerts. SMART status and remaining health refresh at launch, after a real topology change, and at most once per day.

### Fixed

- Retried a complete unavailable GPU sensor batch with a newly opened read-only SMC client, avoiding a transient all-GPU-sensor failure on supported Macs.

### Documentation

- Updated English and German documentation for M1-M5 support, separate refresh cycles, System Context load and memory values, and the current manual screenshots.

## 0.3.0

### Added

- A choice of visible CPU, GPU, internal SSD, and external SSD groups for both the popover and menu bar.
- Menu Bar Display modes: **All Values** shows selected readings with compact symbols; **Symbol Only** keeps just the ThermalAtlas icon.
- Standard and Compact popover sizes, with a compact history control layout that remains readable.
- Local per-minute temperature history for 1, 6, or 24 hours, plus Sensor Details for source, last valid reading, and update time.
- Per-group temperature alerts that require a sustained threshold crossing before notifying again after recovery.
- User-initiated copyable current readings and CSV export of local history plus the current snapshot.
- A separate, read-only System Context for CPU load, power source/battery, and Low Power Mode.

### Improved

- The popover now grows and shrinks with an expanded history card instead of leaving unused space or requiring scrolling.
- GPU read recovery retries a complete unavailable GPU batch once with a newly opened read-only SMC client; a briefly retained value is always labelled as the last real GPU reading.
- English and German project home pages, manuals, and screenshots now document the current controls and monitoring view.

### Fixed

- Corrected the public privacy reports to describe the locally stored display and alert settings, the bounded 24-hour temperature history, the read-only System Context, and user-initiated export accurately.
- Dev and Beta builds now open the current manuals from the `beta` branch; Final builds continue to open the Final manuals from `main`.

### Documentation

- Synced the documented footer controls, manual menu list, security review, and Beta/Final release-documentation workflow with the current app.

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
