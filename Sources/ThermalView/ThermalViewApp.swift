import SwiftUI

@main
struct ThermalAtlasApp: App {
    @State private var sensorService: SensorService
    @AppStorage("thermalatlas.theme") private var themeRawValue = ThermalTheme.classic.rawValue
    @AppStorage("thermalatlas.refreshInterval") private var refreshInterval = RefreshIntervalOption.defaultOption.rawValue
    @AppStorage("thermalatlas.language") private var languageRawValue = AppLanguage.defaultLanguage.rawValue

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

    var body: some Scene {
        MenuBarExtra {
            ThermalPopover(
                service: sensorService,
                selectedTheme: selectedTheme,
                refreshInterval: $refreshInterval,
                selectedLanguage: selectedLanguage
            )
        } label: {
            MenuBarLabel(
                highestTemperature: sensorService.snapshot.highestTemperature,
                language: selectedLanguage.wrappedValue
            )
        }
        .menuBarExtraStyle(.window)
    }
}
