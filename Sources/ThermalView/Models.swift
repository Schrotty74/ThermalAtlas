import Foundation

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
    let temperatureCelsius: Double?
    let detail: String?
    let unavailableReason: String?
    let isLastVerifiedValue: Bool

    init(
        kind: SensorKind,
        temperatureCelsius: Double?,
        detail: String?,
        unavailableReason: String?,
        isLastVerifiedValue: Bool = false
    ) {
        self.kind = kind
        self.temperatureCelsius = temperatureCelsius
        self.detail = detail
        self.unavailableReason = unavailableReason
        self.isLastVerifiedValue = isLastVerifiedValue
    }

    var id: SensorKind { kind }
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
