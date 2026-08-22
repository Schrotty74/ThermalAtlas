import Foundation

enum RefreshIntervalOption: Double, CaseIterable, Identifiable, Sendable {
    case oneSecond = 1.0
    case twoSeconds = 2.0
    case threeSeconds = 3.0
    case fourSeconds = 4.0

    static let defaultOption: RefreshIntervalOption = .twoSeconds

    var id: Double { rawValue }

    var displayName: String {
        rawValue == 1 ? "1 Sekunde" : "\(Int(rawValue)) Sekunden"
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

enum SensorKind: String, CaseIterable, Identifiable, Sendable {
    case cpu, gpu, internalSSD, externalSSD

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cpu: "CPU"
        case .gpu: "GPU"
        case .internalSSD: "Interne SSD"
        case .externalSSD: "Externe SSD"
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

struct TemperatureReading: Identifiable, Sendable {
    let kind: SensorKind
    let sourceIdentifier: String?
    let title: String?
    let temperatureCelsius: Double?
    let detail: String?
    let smartStatus: String?
    let smartHealthPercentage: Int?
    let unavailableReason: String?
    let isLastVerifiedValue: Bool

    init(
        kind: SensorKind,
        sourceIdentifier: String? = nil,
        title: String? = nil,
        temperatureCelsius: Double?,
        detail: String?,
        smartStatus: String? = nil,
        smartHealthPercentage: Int? = nil,
        unavailableReason: String?,
        isLastVerifiedValue: Bool = false
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
    }

    var id: String { sourceIdentifier ?? kind.rawValue }
}

struct ThermalSnapshot: Sendable {
    let readings: [TemperatureReading]
    let updatedAt: Date

    static let unavailable = ThermalSnapshot(
        readings: SensorKind.allCases.map { TemperatureReading(kind: $0, temperatureCelsius: nil, detail: nil, unavailableReason: "Wird geprüft") },
        updatedAt: .now
    )

    var highestTemperature: Double? { readings.compactMap(\.temperatureCelsius).max() }
}
