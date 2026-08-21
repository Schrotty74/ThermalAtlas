import SwiftUI

@main
struct ThermalAtlasApp: App {
    @State private var sensorService = SensorService()
    @AppStorage("thermalatlas.theme") private var themeRawValue = ThermalTheme.classic.rawValue

    private var selectedTheme: Binding<ThermalTheme> {
        Binding(
            get: { ThermalTheme(rawValue: themeRawValue) ?? .classic },
            set: { themeRawValue = $0.rawValue }
        )
    }

    var body: some Scene {
        MenuBarExtra {
            ThermalPopover(service: sensorService, selectedTheme: selectedTheme)
        } label: {
            MenuBarLabel(highestTemperature: sensorService.snapshot.highestTemperature)
        }
        .menuBarExtraStyle(.window)
    }
}
