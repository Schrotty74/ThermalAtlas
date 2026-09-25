import AppKit
import SwiftUI

@main
struct ThermalAtlasApp: App {
    @NSApplicationDelegateAdaptor(ThermalAtlasApplicationDelegate.self) private var applicationDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

/// Owns the menu-bar item and the independent main window.  A window-style
/// `MenuBarExtra` is always re-anchored under the status item by macOS after it
/// is reopened, so it cannot reliably preserve a user-selected position.
@MainActor
private final class ThermalAtlasApplicationDelegate: NSObject, NSApplicationDelegate {
    private let sensorService: SensorService
    private var statusItem: NSStatusItem?
    private var statusRefreshTimer: Timer?
    private var mainPanel: NSPanel?

    override init() {
        let savedInterval = UserDefaults.standard.object(forKey: "thermalatlas.refreshInterval") as? Double
        sensorService = SensorService(refreshInterval: savedInterval ?? RefreshIntervalOption.defaultOption.rawValue)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(showMainWindow)
        statusItem.button?.sendAction(on: [.leftMouseUp])
        statusItem.button?.toolTip = "ThermalAtlas"
        self.statusItem = statusItem
        refreshStatusItem()

        statusRefreshTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(refreshStatusItem),
            userInfo: nil,
            repeats: true
        )
        hideSettingsWindow()
        showMainWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusRefreshTimer?.invalidate()
    }

    @objc private func showMainWindow() {
        let panel = mainPanel ?? makeMainPanel()
        if panel.isMiniaturized {
            panel.deminiaturize(nil)
        }
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func refreshStatusItem() {
        guard let button = statusItem?.button else { return }
        let defaults = UserDefaults.standard
        let displayMode = MenuBarDisplayMode(rawValue: defaults.string(forKey: MenuBarDisplayMode.storageKey) ?? "") ?? .defaultMode
        let visibleKinds = SensorVisibility.selectedKinds(
            from: defaults.string(forKey: SensorVisibility.storageKey) ?? SensorVisibility.defaultStorageValue
        )
        let readings = sensorService.snapshot.readings.filter { visibleKinds.contains($0.kind) }
        let configuration = TemperatureAlertConfiguration(
            isEnabled: defaults.object(forKey: TemperatureAlertSettings.enabledKey) as? Bool ?? false,
            cpuThreshold: defaults.object(forKey: TemperatureAlertSettings.cpuThresholdKey) as? Double ?? TemperatureAlertSettings.defaultThreshold(for: .cpu),
            gpuThreshold: defaults.object(forKey: TemperatureAlertSettings.gpuThresholdKey) as? Double ?? TemperatureAlertSettings.defaultThreshold(for: .gpu),
            internalSSDThreshold: defaults.object(forKey: TemperatureAlertSettings.internalSSDThresholdKey) as? Double ?? TemperatureAlertSettings.defaultThreshold(for: .internalSSD),
            externalSSDThreshold: defaults.object(forKey: TemperatureAlertSettings.externalSSDThresholdKey) as? Double ?? TemperatureAlertSettings.defaultThreshold(for: .externalSSD),
            language: AppLanguage(rawValue: defaults.string(forKey: "thermalatlas.language") ?? "") ?? .defaultLanguage
        )
        button.image = displayMode == .symbolOnly
            ? MenuBarStatusImage.symbolOnly()
            : MenuBarStatusImage.make(
                readings: readings,
                status: MenuBarTemperatureStatus.from(readings: readings, configuration: configuration)
            )
    }

    private func hideSettingsWindow() {
        DispatchQueue.main.async {
            NSApp.windows
                .filter { $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" }
                .forEach { $0.orderOut(nil) }
        }
    }

    private func makeMainPanel() -> NSPanel {
        let hostingView = NSHostingView(rootView: ThermalAtlasWindowContent(service: sensorService))
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 370, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "ThermalAtlas"
        panel.titleVisibility = .visible
        panel.titlebarAppearsTransparent = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        panel.contentView = hostingView
        hostingView.layoutSubtreeIfNeeded()
        let fittingSize = hostingView.fittingSize
        if fittingSize.width > 0, fittingSize.height > 0 {
            panel.setContentSize(fittingSize)
        }
        panel.center()
        PopoverWindowCoordinator.window = panel
        mainPanel = panel
        return panel
    }
}

private struct ThermalAtlasWindowContent: View {
    let service: SensorService
    @AppStorage("thermalatlas.theme") private var themeRawValue = ThermalTheme.classic.rawValue
    @AppStorage("thermalatlas.refreshInterval") private var refreshInterval = RefreshIntervalOption.defaultOption.rawValue
    @AppStorage("thermalatlas.language") private var languageRawValue = AppLanguage.defaultLanguage.rawValue
    @AppStorage(SensorVisibility.storageKey) private var visibleSensorsRawValue = SensorVisibility.defaultStorageValue
    @AppStorage(MenuBarDisplayMode.storageKey) private var menuBarDisplayModeRawValue = MenuBarDisplayMode.defaultMode.rawValue
    @AppStorage("thermalatlas.compactPopover") private var compactPopover = false
    @AppStorage("thermalatlas.alwaysOnTop") private var alwaysOnTop = false
    @AppStorage(TemperatureAlertSettings.enabledKey) private var alertsEnabled = false
    @AppStorage(TemperatureAlertSettings.cpuThresholdKey) private var cpuAlertThreshold = TemperatureAlertSettings.defaultThreshold(for: .cpu)
    @AppStorage(TemperatureAlertSettings.gpuThresholdKey) private var gpuAlertThreshold = TemperatureAlertSettings.defaultThreshold(for: .gpu)
    @AppStorage(TemperatureAlertSettings.internalSSDThresholdKey) private var internalSSDAlertThreshold = TemperatureAlertSettings.defaultThreshold(for: .internalSSD)
    @AppStorage(TemperatureAlertSettings.externalSSDThresholdKey) private var externalSSDAlertThreshold = TemperatureAlertSettings.defaultThreshold(for: .externalSSD)

    private var selectedTheme: Binding<ThermalTheme> {
        Binding(
            get: { ThermalTheme(rawValue: themeRawValue) ?? .classic },
            set: { themeRawValue = $0.rawValue }
        )
    }

    private var selectedLanguage: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: languageRawValue) ?? .defaultLanguage },
            set: { languageRawValue = $0.rawValue }
        )
    }

    private var visibleSensorKinds: Set<SensorKind> {
        SensorVisibility.selectedKinds(from: visibleSensorsRawValue)
    }

    private var selectedVisibleSensorKinds: Binding<Set<SensorKind>> {
        Binding(
            get: { visibleSensorKinds },
            set: { visibleSensorsRawValue = SensorVisibility.storageValue(for: $0) }
        )
    }

    private var selectedMenuBarDisplayMode: Binding<MenuBarDisplayMode> {
        Binding(
            get: { MenuBarDisplayMode(rawValue: menuBarDisplayModeRawValue) ?? .defaultMode },
            set: { menuBarDisplayModeRawValue = $0.rawValue }
        )
    }

    var body: some View {
        ThermalPopover(
            service: service,
            selectedTheme: selectedTheme,
            refreshInterval: $refreshInterval,
            selectedLanguage: selectedLanguage,
            visibleSensorKinds: selectedVisibleSensorKinds,
            menuBarDisplayMode: selectedMenuBarDisplayMode,
            compactPopover: $compactPopover,
            alwaysOnTop: $alwaysOnTop,
            alertsEnabled: $alertsEnabled,
            cpuAlertThreshold: $cpuAlertThreshold,
            gpuAlertThreshold: $gpuAlertThreshold,
            internalSSDAlertThreshold: $internalSSDAlertThreshold,
            externalSSDAlertThreshold: $externalSSDAlertThreshold
        )
    }
}
