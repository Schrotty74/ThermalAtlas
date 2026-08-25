# ThermalAtlas – Feature overview

**[Deutsch](FEATURES.de.md)**

This page lists the current Beta features in detail. For installation and everyday use, see the [user manual](MANUAL.md).

## Temperature monitoring

- Shows available CPU, GPU, internal-SSD, and every detected physical external-SSD temperature.
- Uses separate CPU and GPU Apple-silicon sensor-key families for M1 through M5, including known Pro, Max, and Ultra variants. Future unsupported generations remain unavailable instead of being guessed.
- Uses a defensive, read-only SMC adapter. Missing or implausible readings are displayed as `Not available`.
- Lets you select a temperature refresh interval of 1, 2, 3, or 4 seconds; the default is two seconds.
- Shows source, latest valid reading, and update time in Sensor Details.

## Drives and SMART

- Lists the internal SSD and each mounted physical external SSD separately, using the mounted volume name when available.
- Ignores virtual disk images and hides an ejected external drive even when it remains connected by cable.
- Refreshes drive topology at launch, after macOS mount/unmount events, and periodically in the background.
- Reads temperatures of known SSDs every minute for history and alerts.
- Shows the SMART status reported by macOS and remaining health derived from NVMe `PERCENTAGE_USED` when available; it does not estimate unavailable values.
- Refreshes SMART status and health at launch, after a topology change, and at most once per day.

## System Context

- Separately shows total CPU load, total GPU load, used memory relative to installed RAM with a Normal, Elevated, or High status, power source/battery, and Low Power Mode.
- Updates CPU/GPU load and used memory every 0.5 seconds, independently from the selected temperature interval.
- Treats these values as read-only context, never as temperature measurements or system controls.

## History, alerts, and export

- Opens a local 1-, 6-, or 24-hour temperature history from every temperature card.
- Stores only local per-minute averages for up to 24 hours; temporarily retained GPU readings are not recorded as new measurements.
- Provides separate CPU, GPU, internal-SSD, and external-SSD alert thresholds. A notification needs at least 60 seconds above the threshold and is sent again only after cooling down.
- Exports a copyable current snapshot, a copyable diagnostic report with the Mac model, macOS version, chip name and sensor states, or local history plus a current snapshot as CSV; CSV is created only after you choose an export location.

## Interface and display

- Offers Standard and Compact popover sizes; Compact is about 40% narrower while keeping controls readable.
- Lets you select the CPU, GPU, internal-SSD, and external-SSD groups visible in both the popover and menu bar.
- Offers menu-bar modes for **All Values** or **Symbol Only**.
- Colours CPU, GPU and SSD values distinctly in the all-values menu-bar mode and adds a high-contrast status frame: green normally, yellow near a threshold, red at a selected warning threshold.
- Includes four native themes: Adaptive, Liquid Glass, Aurora, and Ember.
- Starts in English and offers a local German interface choice.
- Offers an optional macOS **Start at Login** registration.
- Groups appearance, refresh, display, alerts, Start at Login, language, export, manuals, links, Activity Monitor, and Quit in one footer menu.

## Privacy and safety

- Reads local sensor and drive information only; it never changes fan, power, or other system settings.
- Has no accounts, telemetry, analytics, cloud sync, advertising SDKs, or third-party dependencies.
- Stores selected display preferences, alert thresholds, and local temperature history in `UserDefaults` only.
- Opens public links or creates exports only after an explicit user action.

## Hardware compatibility

CPU and GPU recognition is hardware-confirmed on M4 Max, M5, and M5 Pro. Other M1 through M5 variants and their raw sensors are implemented defensively but still need verification on real hardware.
