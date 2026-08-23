import Foundation

enum RefreshIntervalOption: Double, CaseIterable, Identifiable, Sendable {
    case oneSecond = 1.0
    case twoSeconds = 2.0
    case threeSeconds = 3.0
    case fourSeconds = 4.0

    static let defaultOption: RefreshIntervalOption = .twoSeconds

    var id: Double { rawValue }

    func displayName(for language: AppLanguage) -> String {
        switch language {
        case .english:
            rawValue == 1 ? "1 Second" : "\(Int(rawValue)) Seconds"
        case .german:
            rawValue == 1 ? "1 Sekunde" : "\(Int(rawValue)) Sekunden"
        }
    }

    static func normalized(_ rawValue: Double) -> RefreshIntervalOption {
        allCases.min(by: { abs($0.rawValue - rawValue) < abs($1.rawValue - rawValue) }) ?? defaultOption
    }
}

enum SSDHealth {
    /// NVMe `PERCENTAGE_USED` reports consumed endurance. The remaining health
    /// percentage is derived only when the controller exposes that raw value.
    static func remainingPercentage(fromPercentageUsed percentageUsed: Double?) -> Int? {
        guard let percentageUsed, percentageUsed.isFinite, percentageUsed >= 0 else { return nil }
        let used = min(100, Int(percentageUsed.rounded(.towardZero)))
        return 100 - used
    }
}

enum SensorKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case cpu, gpu, internalSSD, externalSSD

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.cpu, _): "CPU"
        case (.gpu, _): "GPU"
        case (.internalSSD, .english): "Internal SSD"
        case (.internalSSD, .german): "Interne SSD"
        case (.externalSSD, .english): "External SSD"
        case (.externalSSD, .german): "Externe SSD"
        }
    }

    var symbol: String {
        switch self {
        case .cpu: "cpu"
        case .gpu: "display"
        case .internalSSD: "internaldrive"
        case .externalSSD: "externaldrive"
        }
    }

}

enum SensorVisibility {
    static let storageKey = "thermalatlas.visibleSensors"
    static let defaultStorageValue = SensorKind.allCases.map(\.rawValue).joined(separator: ",")

    static func selectedKinds(from storageValue: String) -> Set<SensorKind> {
        let kinds = Set(storageValue.split(separator: ",").compactMap { SensorKind(rawValue: String($0)) })
        return kinds.isEmpty ? Set(SensorKind.allCases) : kinds
    }

    static func storageValue(for selectedKinds: Set<SensorKind>) -> String {
        SensorKind.allCases
            .filter(selectedKinds.contains)
            .map(\.rawValue)
            .joined(separator: ",")
    }
}

enum MenuBarDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case allValues
    case symbolOnly

    static let storageKey = "thermalatlas.menuBarDisplayMode"
    static let defaultMode: MenuBarDisplayMode = .allValues

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.allValues, .english): "All Values"
        case (.allValues, .german): "Alle Werte"
        case (.symbolOnly, .english): "Symbol Only"
        case (.symbolOnly, .german): "Nur Symbol"
        }
    }

    var symbol: String {
        switch self {
        case .allValues: "list.number"
        case .symbolOnly: "thermometer.medium"
        }
    }
}

struct TemperatureReading: Identifiable, Sendable {
    let kind: SensorKind
    let sourceIdentifier: String?
    let title: String?
    let temperatureCelsius: Double?
    let detail: String?
    let smartStatus: SMARTStatus?
    let smartHealthPercentage: Int?
    let unavailableReason: SensorAvailabilityReason?
    let isLastVerifiedValue: Bool
    let lastVerifiedAt: Date?

    init(
        kind: SensorKind,
        sourceIdentifier: String? = nil,
        title: String? = nil,
        temperatureCelsius: Double?,
        detail: String?,
        smartStatus: SMARTStatus? = nil,
        smartHealthPercentage: Int? = nil,
        unavailableReason: SensorAvailabilityReason?,
        isLastVerifiedValue: Bool = false,
        lastVerifiedAt: Date? = nil
    ) {
        self.kind = kind
        self.sourceIdentifier = sourceIdentifier
        self.title = title
        self.temperatureCelsius = temperatureCelsius
        self.detail = detail
        self.smartStatus = smartStatus
        self.smartHealthPercentage = smartHealthPercentage
        self.unavailableReason = unavailableReason
        self.isLastVerifiedValue = isLastVerifiedValue
        self.lastVerifiedAt = lastVerifiedAt
    }

    var id: String { sourceIdentifier ?? kind.rawValue }
}

extension SensorKind {
    func sourceDescription(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.cpu, .english), (.gpu, .english): "Apple silicon SMC"
        case (.cpu, .german), (.gpu, .german): "Apple-Silicon-SMC"
        case (.internalSSD, .english), (.externalSSD, .english): "diskutil / SMART"
        case (.internalSSD, .german), (.externalSSD, .german): "diskutil / SMART"
        }
    }
}

struct ThermalSnapshot: Sendable {
    let readings: [TemperatureReading]
    let updatedAt: Date

    static let unavailable = ThermalSnapshot(
        readings: SensorKind.allCases.map { TemperatureReading(kind: $0, temperatureCelsius: nil, detail: nil, unavailableReason: .checking) },
        updatedAt: .now
    )

    var highestTemperature: Double? { readings.compactMap(\.temperatureCelsius).max() }
}
