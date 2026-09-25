# Security Policy

[Deutsch](SECURITY.de.md)

## Supported Versions

| Version | Supported |
| --- | --- |
| 1.1.x | Yes |
| 1.0.x and earlier | No |

The current stable release is 1.1.0.

## Security Model

ThermalAtlas is a read-only Apple-silicon monitoring app. It reads available SMC temperature values, drive/SMART information and local system context without providing fan, SMC, power or hardware-control write operations. It requires no administrator or root access and has no telemetry, analytics, accounts or background network communication.

Apple-silicon SMC access uses private macOS interfaces. Missing keys and IOKit failures are treated as unavailable measurements. Compatibility may change with macOS updates.

## Reporting a Vulnerability

Please do not publish sensitive vulnerability details in a public GitHub issue. Contact the repository owner privately. Include the ThermalAtlas and macOS versions, Mac model/chip where relevant, reproduction steps and sanitized logs or screenshots. Do not include serial numbers, UUIDs or other unnecessary device identifiers.

## Scope

Relevant reports include read-only SMC/IOKit sensor access, drive and SMART queries, system-information collection, local temperature history, alerts, CSV/diagnostic exports, Start at Login behavior, local preferences and any unintended ability to modify hardware or system state.

Thank you for helping keep ThermalAtlas and its users secure.
