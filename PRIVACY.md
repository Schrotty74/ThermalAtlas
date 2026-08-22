# Privacy Report

**English** · [Deutsch](PRIVACY.de.md)

ThermalAtlas is a local-only temperature display. It does not collect, transmit, or sell personal data.

## Data the app reads

- Local Apple-silicon SMC temperature values through read-only IOKit calls.
- Local drive metadata and SMART temperature data through `diskutil info -plist`.
- The locally selected visual theme, Scan Refresh interval, and display language.

## Storage

Only the chosen theme, Scan Refresh interval, and display language are stored in local `UserDefaults`. Dev, Beta, and Final have separate bundle identifiers, settings, and caches. Temperature readings are not persisted.

## Network and system changes

The app has no background network features, telemetry, analytics, accounts, cloud sync, advertising SDKs, or third-party dependencies. It has no fan-control, power-control, or sensor-write paths. Activity Monitor and the optional GitHub, Homepage, and manual links open only after the user clicks the corresponding menu item.

## Limits

Some drives and external enclosures do not expose SMART temperatures. Private Apple-silicon SMC keys can change or be unavailable after macOS updates. ThermalAtlas shows unavailable values rather than estimating them.
