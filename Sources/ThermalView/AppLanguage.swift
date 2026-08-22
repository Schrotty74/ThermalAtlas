import Foundation

/// The app language is deliberately independent from the macOS system locale.
/// English is the stable default; users can opt into German in the footer menu.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case german

    static let defaultLanguage: AppLanguage = .english

    var id: String { rawValue }

    var displayName: String {
        return switch self {
        case .english: "English"
        case .german: "Deutsch"
        }
    }

    var locale: Locale {
        Locale(identifier: self == .english ? "en_US" : "de_DE")
    }

    var appSubtitle: String {
        switch self {
        case .english: "Temperatures on this Mac"
        case .german: "Temperaturen dieses Macs"
        }
    }

    var themesMenuTitle: String { self == .english ? "Themes" : "Themes" }
    var refreshMenuTitle: String { "Scan Refresh" }
    var languageMenuTitle: String { self == .english ? "Language" : "Sprache" }
    var manualsMenuTitle: String { self == .english ? "Manuals" : "Handbücher" }
    var englishManualTitle: String { "English Manual" }
    var germanManualTitle: String { "Deutsches Handbuch" }
    var updatedPrefix: String { self == .english ? "Updated" : "Akt." }
    var activityMonitorTitle: String { self == .english ? "Open Activity Monitor" : "Aktivitätsanzeige öffnen" }
    var quitTitle: String { self == .english ? "Quit ThermalAtlas" : "ThermalAtlas beenden" }
    var footerMenuAccessibilityLabel: String { self == .english ? "ThermalAtlas menu" : "ThermalAtlas-Menü" }
    var footerMenuHelp: String { self == .english ? "Themes, Scan Refresh, language and app actions" : "Themes, Scan Refresh, Sprache und App-Aktionen" }
    var healthPrefix: String { self == .english ? "Health" : "Gesundheit" }
    var lastRealGPUValue: String { self == .english ? "Last real GPU reading" : "Letzter echter GPU-Wert" }
    var averageCPUSensors: String { self == .english ? "Average CPU sensors" : "Mittelwert CPU-Sensoren" }
    var averageGPUSensors: String { self == .english ? "Average GPU sensors" : "Mittelwert GPU-Sensoren" }
    var notAvailable: String { self == .english ? "Not available" : "Nicht verfügbar" }

    func highestTemperatureAccessibilityLabel(_ temperature: Int?) -> String {
        guard let temperature else { return "ThermalAtlas" }
        return switch self {
        case .english: "Highest temperature \(temperature) degrees Celsius"
        case .german: "Höchste Temperatur \(temperature) Grad Celsius"
        }
    }
}

enum SensorAvailabilityReason: Sendable {
    case checking
    case cpuSensorUnavailable
    case gpuSensorUnavailable
    case noMatchingDrive
    case smartTemperatureUnavailable

    func localized(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.checking, .english): "Checking"
        case (.checking, .german): "Wird geprüft"
        case (.cpuSensorUnavailable, .english): "No readable CPU temperature sensor"
        case (.cpuSensorUnavailable, .german): "Kein lesbarer CPU-Temperatursensor"
        case (.gpuSensorUnavailable, .english): "No readable GPU temperature sensor"
        case (.gpuSensorUnavailable, .german): "Kein lesbarer GPU-Temperatursensor"
        case (.noMatchingDrive, .english): "No matching drive detected"
        case (.noMatchingDrive, .german): "Kein passendes Laufwerk erkannt"
        case (.smartTemperatureUnavailable, .english): "SMART temperature is not available"
        case (.smartTemperatureUnavailable, .german): "SMART-Temperatur wird nicht bereitgestellt"
        }
    }
}

enum SMARTStatus: Sendable, Equatable {
    case verified
    case failing
    case unsupported
    case unavailable
    case reported(String)

    func localized(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.verified, .english): "SMART: Verified"
        case (.verified, .german): "SMART: Verifiziert"
        case (.failing, .english): "SMART: Failing"
        case (.failing, .german): "SMART: Fehler"
        case (.unsupported, .english): "SMART: Not supported"
        case (.unsupported, .german): "SMART: Nicht unterstützt"
        case (.unavailable, .english): "SMART: Not available"
        case (.unavailable, .german): "SMART: Nicht verfügbar"
        case let (.reported(value), _): "SMART: \(value)"
        }
    }
}
