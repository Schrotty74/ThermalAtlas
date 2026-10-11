# ThermalAtlas – Feature overview

**[Deutsch](FEATURES.de.md)**

This page lists the features in Beta 1.2.0-beta.7. For installation and everyday use, see the [user manual](MANUAL.md).

## Temperature monitoring

- Shows available CPU, GPU, internal-SSD, and every detected physical external-SSD temperature.
- Uses separate CPU and GPU Apple-silicon sensor-key families for M1 through M5, including known Pro, Max, and Ultra variants. Future unsupported generations remain unavailable instead of being guessed.
- Uses a defensive, read-only SMC adapter. Missing or implausible readings are displayed as `Not available`.
- Lets you select a temperature refresh interval of 1, 2, 3, or 4 seconds; the default is two seconds.
- Shows source, latest valid reading, and update time in Sensor Details.
- Shows the measured CPU/GPU Hotspot and valid sensor count in Sensor Details. Cards, menu bar, and history keep showing the average.

## Drives and SMART

- Lists the internal SSD and each mounted physical external SSD separately, using the mounted volume name when available.
- Ignores virtual disk images and hides an ejected external drive even when it remains connected by cable.
- Refreshes drive topology at launch, after macOS mount/unmount events, and periodically in the background.
- Reads temperatures of known SSDs every minute for history and alerts.
- Refreshes CPU/GPU temperatures separately from drive queries, so slow drive queries do not delay CPU/GPU readings.
- Shows the SMART status reported by macOS and remaining health derived from NVMe `PERCENTAGE_USED` when available; it does not estimate unavailable values.
- Refreshes SMART status and health at launch, after a topology change, and at most once per day.

## System Context

- Separately shows total CPU load, the RPM of each readable fan, used memory relative to installed RAM with a Normal, Elevated, or High status, power source/battery, and Low Power Mode.
- Updates CPU load, fan speeds and used memory every 0.5 seconds, independently from the selected temperature interval.
- Treats these values as read-only context, never as temperature measurements or system controls.

## System Information

- Opens from the header thermometer in a separate local window.
- Shows the Mac model and Apple chip beside the macOS Thermal State, followed by CPU and GPU core counts, memory, internal storage, and the macOS version with build number.
- Labels the Thermal State as macOS's overall assessment, not an additional temperature sensor.
- Reads only the displayed local values and does not query, display, or retain serial numbers or UUIDs.

## History, alerts, and export

- Opens a local 1-, 3-, 6-, 12-, or 24-hour temperature history from every temperature card.
- Shows the nearest recorded point’s time and minute-average temperature when you click or drag in the chart.
- Moves through chart points with the left and right arrow keys or Previous minute / Next minute buttons; Escape clears the selection. Chart labels, times and numbers follow the selected app language. Isolated points remain visible and selectable, including 0 RPM.
- Stores only local per-minute averages for up to 24 hours; temporarily retained GPU readings are not recorded as new measurements.
- Provides separate CPU, GPU, internal-SSD, and external-SSD alert thresholds. CPU/GPU alerts use the measured Hotspot; SSD alerts use the displayed temperature. A notification needs at least 60 seconds at or above the threshold and is sent again only after cooling down. The timer restarts when a sensor disappears and returns or when its threshold changes.
- Exports a copyable current snapshot, a copyable diagnostic report with the Mac model, macOS version, chip name and sensor states, or local history plus a current snapshot as CSV; CSV is created only after you choose an export location.
- Shows the macOS error description if a CSV write fails. Try Again reopens the save dialog so you can choose a destination again; Close ends the export attempt.

- Opens a separate RPM history from each readable fan value, with the same five ranges and point selection.
- Shows Min/Max/average of the available minute averages in both chart types. Each recorded minute has equal weight; missing minutes leave gaps.
- Shows reading age in Sensor Details and on cards with temporarily retained GPU values. The existing 15-second GPU retention limit remains unchanged.

## App Updates

- Checks the official GitHub releases for the highest newer Final and Beta versions; a Final is newer than a Beta with the same version number.
- Provides Check Now and optional Daily, Weekly or Monthly checks. Automatic checks are off by default and run while the app is running, even with its windows closed.
- Shows the installed version and last successful check, reports newly found releases once automatically, and opens their GitHub release pages on request.
- Keeps settings and check state locally. Failed automatic checks retry at most hourly; a failed check does not claim that the app is current.
- Leaves download and installation to you. Checks send no sensor or device data; GitHub receives the connection IP address.

## Interface and display

- Offers Standard and Compact window sizes; Compact is about 40% narrower while keeping controls readable.
- Adds a movable Mini Display for the selected temperatures. Right-click offers Standard and Compact; the mode is saved locally.
- With Always on Top, Mini Display can join other apps’ full-screen spaces.
- Lets you select the CPU, GPU, internal-SSD, and external-SSD groups visible in both the popover and menu bar.
- Offers menu-bar modes for **All Values** or **Symbol Only**.
- Colours CPU, GPU and SSD values distinctly in the all-values menu-bar mode and adds a high-contrast status frame: green normally, yellow near a threshold, red at a selected warning threshold.
- Includes four native themes: Adaptive, Liquid Glass, Aurora, and Ember. Adaptive uses neutral macOS window and control surfaces in both light and dark mode.
- Temperature cards support keyboard activation and announce their reading and history state to VoiceOver. Menu bar and Mini Display expose localized readings, unavailable values and temperature-warning status to VoiceOver. Mini Display responds to Return, Space and VoiceOver's press action. Reduce Motion applies to card appearance, history expansion and window resizing; Reduce Transparency adjusts glass surfaces.
- System Context tiles reflow in Standard and Compact sizes; its info button explains CPU load, fan speed, memory and power readings and notes that temperatures appear in the cards above. The macOS Settings scene points to the main window and provides an Open ThermalAtlas button.
- Fits the window height to expanded temperature histories while preserving its width and top edge.
- The layered Icon Composer app icon offers Default, Dark and Mono appearances on supported macOS versions, with an older macOS fallback.
- Starts in English and offers a local German interface choice.
- Offers an optional macOS **Start at Login** registration.
- Can keep its window above other apps with the optional **Always on Top** setting.
- Groups appearance, refresh, display, alerts, language, export, Always on Top, Start at Login, App Updates, manuals, links, Activity Monitor, and Quit in one footer menu.

## Privacy and safety

- Reads local sensor and drive information only; it never changes fan, power, or other system settings.
- Has no accounts, telemetry, analytics, cloud sync, advertising SDKs, or third-party dependencies.
- Stores selected display preferences, alert thresholds, update intervals, check timestamps, reported release tags, and local temperature and fan history in `UserDefaults` only.
- Opens public links or creates exports only after an explicit user action.

## Hardware compatibility

CPU and GPU recognition is hardware-confirmed on M4 Max, M5, and M5 Pro. Other M1 through M5 variants and their raw sensors are implemented defensively but still need verification on real hardware.
