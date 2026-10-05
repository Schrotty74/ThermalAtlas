# Privacy Report

**English** · [Deutsch](PRIVACY.de.md)

ThermalAtlas keeps temperature monitoring local and does not sell personal data. Optional GitHub update checks expose the connection IP address to GitHub.

## Data the app reads

- Local Apple-silicon SMC temperature values through read-only IOKit calls.
- Local drive metadata and SMART temperature data through `diskutil info -plist`.
- Public macOS CPU-tick data, read-only SMC fan-speed values, and local virtual-memory statistics for the displayed CPU-load, fan-speed and memory context, plus the current power source/battery level and Low Power Mode state.
- When you open System Information, the app reads the displayed Mac model, chip, CPU/GPU core counts, memory, internal-storage capacity, macOS version, and macOS Thermal State through targeted local system queries. It does not query, display, or retain serial numbers or UUIDs.

## Storage

Local `UserDefaults` stores the selected theme, Scan Refresh interval, display language, visible sensor groups, menu-bar display mode, window size, Mini Display mode, always-on-top choice, and temperature-alert settings. The optional Start at Login registration is managed by macOS through `SMAppService`, not stored in `UserDefaults`. ThermalAtlas also stores per-sensor, minute-averaged temperature history for no more than 24 hours so it can draw the in-app chart. Each stored history point contains only a local sensor identifier, timestamp, average temperature, and sample count. Fan history is stored separately under `thermalatlas.fanHistory`: each point contains the local SMC fan index, timestamp, average RPM and sample count. It is limited to 24 hours and written at most once per minute. CPU load, memory use, power source/battery, Low Power Mode, and System Information are displayed but not stored. Dev, Beta, and Final have separate bundle identifiers, settings, and caches.

Update intervals, last successful and attempted check timestamps, and already reported release tags are also stored locally in `UserDefaults`.

## Network and system changes

The app has no telemetry, analytics, accounts, cloud sync, advertising SDKs, or third-party dependencies. It has no fan-control, power-control, or sensor-write paths. A text or CSV export is created only after the user chooses it and selects a local destination. Activity Monitor and the optional GitHub, Homepage, and manual links open only after the user clicks the corresponding menu item.

## Limits

Some drives and external enclosures do not expose SMART temperatures. Private Apple-silicon SMC keys can change or be unavailable after macOS updates. ThermalAtlas shows unavailable values rather than estimating them.

## Optional update checks

Optional App Updates checks GitHub for newer Final and Beta releases. Check Now runs immediately; automatic checks are off by default and can be set to daily, weekly or monthly. Checks send no sensor, drive, device or installed-version data. GitHub receives the connection IP address. No stored cookies or credentials are used, and updates are never downloaded or installed automatically.
