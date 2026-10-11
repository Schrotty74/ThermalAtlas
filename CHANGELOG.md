# Changelog

All notable user-visible changes are documented here in English. Development builds remain local; public releases and prereleases are announced through GitHub Releases.

## 1.2.0

### Added

- Movable Mini Display with a right-click choice of Standard or Compact, plus Always on Top for the main window and Mini Display in other apps' full-screen spaces.
- Read-only fan speeds and local fan histories. Temperature and fan charts offer 1, 3, 6, 12 and 24 hours, Min/Max/average summaries, and point selection by mouse or keyboard.
- Optional GitHub checks for newer Final and Beta releases, manually or daily, weekly or monthly. Automatic checks are off by default; downloads and installation remain manual.
- CPU/GPU Hotspot and valid sensor counts in Sensor Details, plus the macOS Thermal State in System Information. CPU/GPU alerts use the Hotspot; the main readings and history keep showing the average.

### Improved

- Adaptive uses neutral macOS surfaces in light and dark mode. The app icon includes appearance variants and a conventional fallback for older macOS versions.
- Retained GPU readings show their age. Missing history minutes interrupt chart lines, and single recorded points remain visible and selectable, including 0 RPM.
- Temperature cards and chart navigation support the keyboard. Menu bar and Mini Display readings have localized accessibility labels and values; charts follow the selected English or German language.
- Windows have standard controls, retain their position, fit expanded history content and respect Reduce Motion. System Context gives values more room and offers a compact explanation.
- History cleanup and point lookup avoid repeated work; hidden or unchanged Mini Display panels skip unnecessary updates.

### Fixed

- Reconnected drives and changed alert thresholds start a new warning period.
- CSV save failures show a localized error with Try Again and Close actions. Try Again reopens the save dialog.
- The System Context explanation no longer opens in an excessively tall popover. The macOS Settings window provides a button to open ThermalAtlas.

### Changed

- Removed unreliable GPU-load percentages; GPU temperatures remain available.
- System Information reads only the displayed values through targeted local queries, without collecting serial numbers or UUIDs.

### Documentation

- Updated the bilingual README, feature overview, privacy and security descriptions, and manuals for Final 1.2.0. Both PDFs have fifteen pages and explain the new controls and recovery steps.

## 1.2.0-beta.7

### Improved

- CSV save failures show a localized error with Try Again and Close actions. Try Again opens the save dialog again so you can choose another destination.
- Temperature cards can be opened from the keyboard. Temperature and fan charts support previous/next point buttons, Left/Right arrow keys and Escape to clear the selection.
- Charts show and allow selection of a single recorded point, including a fan reading of 0 RPM. Chart labels, times and numbers follow the selected English or German app language.
- Menu bar and Mini Display readings have localized accessibility labels and values. Mini Display size selection also supports the accessibility press action, Return and Space.
- Window resizing respects Reduce Motion and fits expanded history content while preserving the window width and top edge.
- The macOS Settings window provides an explanation and a button to open the main ThermalAtlas window.
- System Context gives its values more room within the existing window width. Its info button opens a compact explanation of CPU load, fans, memory and power status.
- History cleanup and point lookup do less repeated work. Hidden or unchanged Mini Display panels skip unnecessary image and size updates.

### Fixed

- Removed drives no longer retain old temperature-warning episodes. A reconnected drive starts a new warning period; changing a threshold also resets its period.
- The System Context explanation no longer opens in an excessively tall popover.

### Documentation

- Updated both manuals and fifteen-page PDFs with keyboard navigation, accessibility, CSV error recovery and the System Context explanation.
- Updated the bilingual feature overview and release information. Local history formats, read-only monitoring and optional GitHub update behavior remain unchanged.

## 1.2.0-beta.6

### Added

- Click a readable fan RPM value in System Context to open its local history in a separate chart.
- Temperature and fan histories offer 1, 3, 6, 12 and 24 hours. Both show Min, Max and average of the recorded minute averages, plus the time and value of a selected point.

### Improved

- Adaptive uses neutral macOS window and control surfaces in light and dark mode, with subtle grey outlines and shadows.
- Retained GPU readings show their age on the card. Sensor Details uses the actual reading timestamp, including separately refreshed SSD values; the last valid GPU timestamp remains visible after its 15-second retention limit expires.
- Missing minutes interrupt chart lines instead of connecting across gaps.

### Privacy

- Fan history stays in local UserDefaults for at most 24 hours, separate from temperature history. Missing readings are not stored as zero. Fan control, temperature CSV format and network behavior remain unchanged.

### Documentation

- Updated both manuals and their fourteen-page PDFs with the fan-history screenshot, opening instructions, five time ranges and explanations of RPM axes, minute averages and reading age.
- Updated the bilingual README, feature overview and privacy report for the new histories and Adaptive appearance.

## 1.2.0-beta.5

### Added

- App Updates in the footer menu: check GitHub for newer Final and Beta releases manually, or enable daily, weekly or monthly checks. Automatic checks are off by default.
- Update results show the installed version, the last successful check and links to newer releases. Each new release is reported automatically once; download and installation remain manual.

### Privacy

- Update checks use HTTPS without stored cookies or credentials. No sensor, drive, device or installed-version data is sent; GitHub receives the connection IP address. Monitoring continues to work offline.

### Documentation

- Updated English and German manuals with the App Updates screenshot, interval settings, version comparisons and privacy details. Both PDFs now have thirteen pages.
- Completed the bilingual README and feature overview with update checks, icon appearance variants and Reduce Transparency support.

## 1.2.0-beta.4

### Added

- Mini Display under Window Size shows the selected temperatures in a movable floating strip. Right-click the strip to return to Standard or Compact; the selected mode is saved locally.
- Click or drag in a temperature chart to see the nearest recorded point, its time and minute-average temperature.

### Improved

- Always on Top lets Mini Display join other apps' full-screen spaces. Visibility over individual full-screen games still needs to be checked.
- The app icon now uses an appearance-aware Icon Composer asset, with a conventional icon fallback for older macOS versions.

### Documentation

- Updated both manuals and their twelve-page PDFs with Mini Display, chart selection, sensor details, warnings, refresh intervals, exports and window controls.
- Updated the public example images without changing their existing links.

## 1.2.0-beta.3

### Changed

- System Context now shows the RPM of each readable fan. ThermalAtlas reads the speeds without controlling the fans.
- Removed the GPU-load percentage after comparisons showed that it did not reliably reflect GPU activity. GPU temperature remains available.

### Documentation

- Updated the English and German manuals and PDFs for fan speeds, and replaced the four theme screenshots with examples using sample data.

## 1.2.0-beta.2

### Improved

- Temperature cards tell VoiceOver whether their history is open and how to toggle it, in English and German.
- Card entrance, number changes, and history expansion respect the macOS Reduce Motion setting.
- On macOS 27, the System Information button uses the interactive system glass style in the Liquid Glass theme. Earlier macOS versions retain the plain button.

## 1.2.0-beta.1

### Added

- Sensor Details now shows the measured Hotspot and valid sensor count for CPU and GPU. The cards, menu bar, and history continue to show the average. CPU/GPU warning thresholds use the Hotspot; SSD warnings still use the displayed SSD temperature.
- System Information now shows the macOS Thermal State beside the Mac model. It is an overall system assessment, not another temperature sensor.
- An optional Always on Top setting keeps the main window visible above other apps and when using the macOS menu bar.

### Changed

- The main window can be moved freely, retains its position after minimize and reopen, and has standard macOS window controls. Its width adjusts when switching between Standard and Compact.
- System Information reads only the displayed local values through targeted system queries instead of processing a complete hardware profile. Its Mac and Thermal State tiles now share the top row.

### Documentation

- Updated the English and German manuals and PDFs with the current System Information screenshot, Thermal State, Hotspot details, and window controls.

## 1.1.0

### Added

- A local **System Information** window opened from the header thermometer. It shows the Mac model, Apple chip, CPU/GPU core counts, memory, internal storage, and macOS version without collecting serial numbers, UUIDs, or other hardware identifiers.
- Current public manuals now include a System Information example and explain the locally read fields.

### Fixed

- The ThermalAtlas window keeps its intended menu-bar position when it opens, when a temperature-history card opens or closes, and when the window is opened again.

### Documentation

- Updated English and German home pages, feature overviews, privacy reports, manuals, and PDFs for System Information and the current local-only data handling.

## 1.0.0

### Stable release

- First stable ThermalAtlas release, based on the tested 0.5.0 Beta feature set.
- Includes local CPU, GPU, internal-SSD and physical external-SSD monitoring; read-only System Context; local history, alerts and user-initiated export; four themes; and English/German documentation.

## 0.5.0

### Added

- Optional macOS **Start at Login** registration, controlled locally from the shared footer menu.
- A copyable diagnostic report with the Mac model, macOS version, detected Apple-silicon chip name, and current sensor states.
- A transparent memory status of Normal, Elevated, or High based on the displayed locally used-memory share.
- The detected connection type for an external SSD in its Sensor Details when macOS provides it.

### Improved

- All-values menu-bar readings now use distinct CPU, GPU, internal-SSD, and external-SSD colours with a high-contrast status frame: green normally, yellow near the configured warning threshold, and red at the threshold.
- Renamed the system-following appearance to **Adaptive** and refined the Liquid Glass presentation.

### Documentation

- Updated the English and German public documentation for the current monitoring interface, local diagnostics, Start at Login, memory status, and menu-bar presentation.

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
