import SwiftUI

@main
struct ThermalAtlasApp: App {
    @State private var sensorService: SensorService
    @AppStorage("thermalatlas.theme") private var themeRawValue = ThermalTheme.classic.rawValue
    @AppStorage("thermalatlas.refreshInterval") private var refreshInterval = RefreshIntervalOption.defaultOption.rawValue
    @AppStorage("thermalatlas.language") private var languageRawValue = AppLanguage.defaultLanguage.rawValue
    @AppStorage(SensorVisibility.storageKey) private var visibleSensorsRawValue = SensorVisibility.defaultStorageValue
    @AppStorage(MenuBarDisplayMode.storageKey) private var menuBarDisplayModeRawValue = MenuBarDisplayMode.defaultMode.rawValue
    @AppStorage("thermalatlas.compactPopover") private var compactPopover = false
    @AppStorage(TemperatureAlertSettings.enabledKey) private var alertsEnabled = false
    @AppStorage(TemperatureAlertSettings.cpuThresholdKey) private var cpuAlertThreshold = TemperatureAlertSettings.defaultThreshold(for: .cpu)
    @AppStorage(TemperatureAlertSettings.gpuThresholdKey) private var gpuAlertThreshold = TemperatureAlertSettings.defaultThreshold(for: .gpu)
    @AppStorage(TemperatureAlertSettings.internalSSDThresholdKey) private var internalSSDAlertThreshold = TemperatureAlertSettings.defaultThreshold(for: .internalSSD)
    @AppStorage(TemperatureAlertSettings.externalSSDThresholdKey) private var externalSSDAlertThreshold = TemperatureAlertSettings.defaultThreshold(for: .externalSSD)

    init() {
        let savedInterval = UserDefaults.standard.object(forKey: "thermalatlas.refreshInterval") as? Double
        _sensorService = State(initialValue: SensorService(refreshInterval: savedInterval ?? RefreshIntervalOption.defaultOption.rawValue))
    }

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

    var body: some Scene {
        MenuBarExtra {
            ThermalPopover(
                service: sensorService,
                selectedTheme: selectedTheme,
                refreshInterval: $refreshInterval,
                selectedLanguage: selectedLanguage,
                visibleSensorKinds: selectedVisibleSensorKinds,
                menuBarDisplayMode: selectedMenuBarDisplayMode,
                compactPopover: $compactPopover,
                alertsEnabled: $alertsEnabled,
                cpuAlertThreshold: $cpuAlertThreshold,
                gpuAlertThreshold: $gpuAlertThreshold,
                internalSSDAlertThreshold: $internalSSDAlertThreshold,
                externalSSDAlertThreshold: $externalSSDAlertThreshold
            )
        } label: {
            MenuBarLabel(
                service: sensorService,
                visibleSensorKinds: visibleSensorKinds,
                displayMode: selectedMenuBarDisplayMode.wrappedValue,
                language: selectedLanguage.wrappedValue,
                alertConfiguration: TemperatureAlertConfiguration(
                    isEnabled: alertsEnabled,
                    cpuThreshold: cpuAlertThreshold,
                    gpuThreshold: gpuAlertThreshold,
                    internalSSDThreshold: internalSSDAlertThreshold,
                    externalSSDThreshold: externalSSDAlertThreshold,
                    language: selectedLanguage.wrappedValue
                )
            )
        }
        .menuBarExtraStyle(.window)
    }
}
