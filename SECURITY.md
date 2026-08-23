# Security Review

## Scope

This review covers the Swift source, build scripts, public documentation, and
tracked icon assets in this repository. Generated bundles and Swift build
caches are excluded through `.gitignore` and are not published.

## Review result

No credentials, tokens, local file-system paths, telemetry endpoints, network
clients, or bundled private data are intentionally present in the public source.

The app's hardware access is restricted to:

- Read-only IOKit calls for Apple-silicon SMC temperature keys.
- `diskutil info -plist` with internally discovered disk identifiers.
- Public Mach CPU-tick snapshots plus read-only IOKit power-source data for the separately labelled System Context.

There are no SMC write commands, fan-control APIs, power-control APIs, shell
commands constructed from user input, network requests, or third-party packages.

## Known security boundary

Apple-silicon SMC access uses private macOS interfaces. The adapter treats
missing keys and IOKit failures as unavailable measurements and contains no
write path. Private interface compatibility can change with macOS updates.

## Reporting

Please report a potential vulnerability privately through the repository owner
before opening a public issue.
