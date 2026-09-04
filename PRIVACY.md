# Privacy Report

**English** · [Deutsch](PRIVACY.de.md)

ThermalAtlas is a local-only temperature display. It does not collect, transmit, or sell personal data.

## Data the app reads

- Local Apple-silicon SMC temperature values through read-only IOKit calls.
- Local drive metadata and SMART temperature data through `diskutil info -plist`.
- Public macOS CPU-tick data, the Apple graphics driver's currently published aggregate GPU utilization, and local virtual-memory statistics for the displayed CPU/GPU-load and memory context, plus the current power source/battery level and Low Power Mode state.
- When you open System Information, the current build processes the local `system_profiler` hardware and display profiles to obtain the displayed Mac model, chip, CPU/GPU core counts, memory, internal-storage capacity, and macOS version. The visible snapshot does not show or retain serial numbers or UUIDs; the hardware profile can nevertheless contain them. Replacing this broad profile query with targeted system values is tracked in `NEXT_STEPS.md`.

## Storage

Local `UserDefaults` stores the selected theme, Scan Refresh interval, display language, visible sensor groups, menu-bar display mode, window size, and temperature-alert settings. The optional Start at Login registration is managed by macOS through `SMAppService`, not stored in `UserDefaults`. ThermalAtlas also stores per-sensor, minute-averaged temperature history for no more than 24 hours so it can draw the in-app chart. Each stored history point contains only a local sensor identifier, timestamp, average temperature, and sample count. CPU/GPU load, memory use, power source/battery, Low Power Mode, and System Information are displayed but not stored. Dev, Beta, and Final have separate bundle identifiers, settings, and caches.

## Network and system changes

The app has no background network features, telemetry, analytics, accounts, cloud sync, advertising SDKs, or third-party dependencies. It has no fan-control, power-control, or sensor-write paths. A text or CSV export is created only after the user chooses it and selects a local destination. Activity Monitor and the optional GitHub, Homepage, and manual links open only after the user clicks the corresponding menu item.

## Limits

Some drives and external enclosures do not expose SMART temperatures. Private Apple-silicon SMC keys can change or be unavailable after macOS updates. ThermalAtlas shows unavailable values rather than estimating them.
