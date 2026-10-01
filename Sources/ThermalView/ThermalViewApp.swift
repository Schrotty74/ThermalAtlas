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
    private let appUpdateService = AppUpdateService()
    private var statusItem: NSStatusItem?
    private var statusRefreshTimer: Timer?
    private var mainPanel: NSPanel?
    private var miniPanel: NSPanel?
    private var miniImageView: NSImageView?
    private var miniControlsView: NSView?

    override init() {
        let savedInterval = UserDefaults.standard.object(forKey: "thermalatlas.refreshInterval") as? Double
        sensorService = SensorService(refreshInterval: savedInterval ?? RefreshIntervalOption.defaultOption.rawValue)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        appUpdateService.report = { service, manual in AppUpdateWindow.show(service: service, manual: manual) }
        appUpdateService.start()
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(showMainWindow)
        statusItem.button?.sendAction(on: [.leftMouseUp])
        statusItem.button?.toolTip = "ThermalAtlas"
        self.statusItem = statusItem
        refreshStatusItem()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMiniDisplayVisibility),
            name: .thermalAtlasMiniDisplayVisibilityChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMiniDisplayAlwaysOnTop),
            name: .thermalAtlasMiniAlwaysOnTopChanged,
            object: nil
        )
        updateMiniDisplayVisibility()

        statusRefreshTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(refreshStatusItem),
            userInfo: nil,
            repeats: true
        )
        hideSettingsWindow()
        if !UserDefaults.standard.bool(forKey: MiniDisplay.storageKey) {
            showMainWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        appUpdateService.stop()
        statusRefreshTimer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: .thermalAtlasMiniDisplayVisibilityChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .thermalAtlasMiniAlwaysOnTopChanged, object: nil)
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
        let status = MenuBarTemperatureStatus.from(readings: readings, configuration: configuration)
        button.image = displayMode == .symbolOnly
            ? MenuBarStatusImage.symbolOnly()
            : MenuBarStatusImage.make(
                readings: readings,
                status: status
            )
        updateMiniDisplay(readings: readings, status: status)
    }

    private func hideSettingsWindow() {
        DispatchQueue.main.async {
            NSApp.windows
                .filter { $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" }
                .forEach { $0.orderOut(nil) }
        }
    }

    private func makeMainPanel() -> NSPanel {
        let hostingView = NSHostingView(rootView: ThermalAtlasWindowContent(service: sensorService, appUpdateService: appUpdateService))
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

    @objc private func updateMiniDisplayVisibility() {
        if UserDefaults.standard.bool(forKey: MiniDisplay.storageKey) {
            let panel = miniPanel ?? makeMiniPanel()
            updateMiniDisplayAlwaysOnTop()
            mainPanel?.orderOut(nil)
            panel.orderFrontRegardless()
            refreshStatusItem()
        } else {
            miniPanel?.orderOut(nil)
            hideMiniControls()
            showMainWindow()
        }
    }

    private func makeMiniPanel() -> NSPanel {
        let imageView = DraggableMiniImageView(frame: .zero)
        imageView.imageScaling = .scaleNone
        imageView.imageAlignment = .alignCenter
        imageView.onRightClick = { [weak self] in self?.toggleMiniModePanel() }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 32),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.contentView = DraggableMiniContentView()
        panel.contentView?.addSubview(imageView)
        panel.center()
        miniPanel = panel
        miniImageView = imageView
        return panel
    }

    @objc private func updateMiniDisplayAlwaysOnTop() {
        guard let panel = miniPanel else { return }
        if UserDefaults.standard.bool(forKey: "thermalatlas.alwaysOnTop") {
            panel.collectionBehavior = [
                .canJoinAllSpaces,
                .canJoinAllApplications,
                .fullScreenAuxiliary,
                .stationary
            ]
            panel.level = .screenSaver
            if panel.isVisible { panel.orderFrontRegardless() }
        } else {
            panel.collectionBehavior = []
            panel.level = .floating
        }
    }

    private func toggleMiniModePanel() {
        guard let panel = miniPanel, let imageView = miniImageView else { return }
        if miniControlsView != nil {
            hideMiniControls()
            layoutMiniPanel(panel: panel, imageView: imageView)
            return
        }

        let language = AppLanguage(
            rawValue: UserDefaults.standard.string(forKey: "thermalatlas.language") ?? ""
        ) ?? .defaultLanguage
        let contentView = NSVisualEffectView()
        contentView.material = .popover
        contentView.blendingMode = .withinWindow
        contentView.state = .active
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 9
        contentView.layer?.masksToBounds = true

        let title = NSTextField(labelWithString: language.windowSizeMenuTitle)
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        title.frame = NSRect(x: 10, y: 64, width: 200, height: 18)
        contentView.addSubview(title)

        let standardButton = NSButton(title: language.standardWindowSizeTitle, target: self, action: #selector(selectStandardWindowSize))
        standardButton.bezelStyle = .rounded
        standardButton.frame = NSRect(x: 10, y: 34, width: 200, height: 24)
        contentView.addSubview(standardButton)

        let compactButton = NSButton(title: language.compactWindowSizeTitle, target: self, action: #selector(selectCompactWindowSize))
        compactButton.bezelStyle = .rounded
        compactButton.frame = NSRect(x: 10, y: 6, width: 200, height: 24)
        contentView.addSubview(compactButton)
        panel.contentView?.addSubview(contentView)
        miniControlsView = contentView
        layoutMiniPanel(panel: panel, imageView: imageView)
    }

    @objc private func selectStandardWindowSize() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "thermalatlas.compactPopover")
        defaults.set(false, forKey: MiniDisplay.storageKey)
        hideMiniControls()
        updateMiniDisplayVisibility()
    }

    @objc private func selectCompactWindowSize() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "thermalatlas.compactPopover")
        defaults.set(false, forKey: MiniDisplay.storageKey)
        hideMiniControls()
        updateMiniDisplayVisibility()
    }

    private func updateMiniDisplay(readings: [TemperatureReading], status: MenuBarTemperatureStatus) {
        guard let panel = miniPanel, let imageView = miniImageView else { return }
        let image = MenuBarStatusImage.make(readings: readings, status: status)
        imageView.image = image
        layoutMiniPanel(panel: panel, imageView: imageView)
    }

    private func layoutMiniPanel(panel: NSPanel, imageView: NSImageView) {
        let imageSize = imageView.image?.size ?? .zero
        let controlsHeight: CGFloat = miniControlsView == nil ? 0 : 92
        let contentSize = NSSize(
            width: max(ceil(imageSize.width) + 12, miniControlsView == nil ? 0 : 220),
            height: ceil(imageSize.height) + 12 + controlsHeight
        )
        imageView.frame = NSRect(
            x: 6,
            y: controlsHeight + 6,
            width: imageSize.width,
            height: imageSize.height
        )
        miniControlsView?.frame = NSRect(x: 6, y: 6, width: contentSize.width - 12, height: controlsHeight - 6)
        panel.setContentSize(contentSize)
    }

    private func hideMiniControls() {
        miniControlsView?.removeFromSuperview()
        miniControlsView = nil
    }
}

extension Notification.Name {
    static let thermalAtlasMiniDisplayVisibilityChanged = Notification.Name("thermalAtlasMiniDisplayVisibilityChanged")
    static let thermalAtlasMiniAlwaysOnTopChanged = Notification.Name("thermalAtlasMiniAlwaysOnTopChanged")
}

private final class DraggableMiniContentView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }
}

private final class DraggableMiniImageView: NSImageView {
    var onRightClick: (() -> Void)?

    override var mouseDownCanMoveWindow: Bool { true }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }
}

private struct ThermalAtlasWindowContent: View {
    let service: SensorService
    let appUpdateService: AppUpdateService
    @AppStorage("thermalatlas.theme") private var themeRawValue = ThermalTheme.classic.rawValue
    @AppStorage("thermalatlas.refreshInterval") private var refreshInterval = RefreshIntervalOption.defaultOption.rawValue
    @AppStorage("thermalatlas.language") private var languageRawValue = AppLanguage.defaultLanguage.rawValue
    @AppStorage(SensorVisibility.storageKey) private var visibleSensorsRawValue = SensorVisibility.defaultStorageValue
    @AppStorage(MenuBarDisplayMode.storageKey) private var menuBarDisplayModeRawValue = MenuBarDisplayMode.defaultMode.rawValue
    @AppStorage("thermalatlas.compactPopover") private var compactPopover = false
    @AppStorage(MiniDisplay.storageKey) private var miniDisplayVisible = false
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
            appUpdateService: appUpdateService,
            selectedTheme: selectedTheme,
            refreshInterval: $refreshInterval,
            selectedLanguage: selectedLanguage,
            visibleSensorKinds: selectedVisibleSensorKinds,
            menuBarDisplayMode: selectedMenuBarDisplayMode,
            compactPopover: $compactPopover,
            miniDisplayVisible: $miniDisplayVisible,
            alwaysOnTop: $alwaysOnTop,
            alertsEnabled: $alertsEnabled,
            cpuAlertThreshold: $cpuAlertThreshold,
            gpuAlertThreshold: $gpuAlertThreshold,
            internalSSDAlertThreshold: $internalSSDAlertThreshold,
            externalSSDAlertThreshold: $externalSSDAlertThreshold
        )
    }
}
