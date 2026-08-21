# Changelog

**English** · [Deutsch](CHANGELOG.de.md)

## 0.1.0 Beta 1

### Added

- Native Apple-silicon temperature monitoring for CPU, GPU, internal SSD, and external SSDs when real SMART data is available.
- A compact menu-bar interface with a two-second refresh interval.
- Defensive handling of unavailable sensors without estimated values.
- Four visual themes, including adaptive Liquid Glass.
- Separate Dev, Beta, and Final build channels with isolated settings and build caches.
- Local Beta/Final ZIP and DMG packaging. The DMG includes an `Applications` alias for drag-and-drop installation.
- Strict release-version validation and package checks that remove machine-local build paths before publication.

### Privacy and security

- No network communication, analytics, accounts, or third-party dependencies.
- Read-only system sensor access only.
