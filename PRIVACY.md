# Privacy Report

**English** · [Deutsch](PRIVACY.de.md)

ThermalAtlas is a local-only temperature display. It does not collect, transmit, or sell personal data.

## Data the app reads

- Local Apple-silicon SMC temperature values through read-only IOKit calls.
- Local drive metadata and SMART temperature data through `diskutil info -plist`.
- The locally selected visual theme and Scan Refresh interval.

## Storage

Only the chosen theme and Scan Refresh interval are stored in local `UserDefaults`. Dev, Beta, and Final have separate bundle identifiers, settings, and caches. Temperature readings are not persisted.

## Network and system changes

The app has no network features, telemetry, analytics, accounts, cloud sync, advertising SDKs, or third-party dependencies. It has no fan-control, power-control, or sensor-write paths. Activity Monitor opens only after the user clicks its button.

## Limits

Some drives and external enclosures do not expose SMART temperatures. Private Apple-silicon SMC keys can change or be unavailable after macOS updates. ThermalAtlas shows unavailable values rather than estimating them.
