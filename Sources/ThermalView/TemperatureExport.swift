import Foundation
import Darwin

@MainActor
enum TemperatureExport {
    static func plainText(snapshot: ThermalSnapshot, language: AppLanguage) -> String {
        let timestamp = snapshot.updatedAt.formatted(.dateTime.year().month().day().hour().minute().second().locale(language.locale))
        let heading = language == .german ? "ThermalAtlas-Messwerte" : "ThermalAtlas readings"
        let updated = language == .german ? "Aktualisiert" : "Updated"
        let lines = snapshot.readings.map { reading in
            let name = reading.title ?? reading.kind.title(for: language)
            let value = reading.temperatureCelsius.map {
                "\($0.formatted(.number.precision(.fractionLength(1)).locale(language.locale))) °C"
            } ?? language.notAvailable
            return "\(name): \(value) · \(reading.kind.sourceDescription(for: language))"
        }
        return ([heading, "\(updated): \(timestamp)"] + lines).joined(separator: "\n")
    }

    static func csv(
        snapshot: ThermalSnapshot,
        history: TemperatureHistoryStore,
        language: AppLanguage
    ) -> String {
        let formatter = ISO8601DateFormatter()
        let historyRows = snapshot.readings.flatMap { reading -> [[String]] in
            history.points(for: reading.id, range: .twentyFourHours, now: snapshot.updatedAt).map { point in
                [
                    formatter.string(from: point.date),
                    "history_average",
                    reading.kind.rawValue,
                    reading.title ?? reading.kind.title(for: language),
                    reading.sourceIdentifier ?? reading.kind.sourceDescription(for: language),
                    point.averageTemperature.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "en_US_POSIX"))),
                    "minute_average",
                    "",
                    ""
                ]
            }
        }
        let currentRows = snapshot.readings.map { reading -> [String] in
            [
                formatter.string(from: snapshot.updatedAt),
                "current_snapshot",
                reading.kind.rawValue,
                reading.title ?? reading.kind.title(for: language),
                reading.sourceIdentifier ?? reading.kind.sourceDescription(for: language),
                reading.temperatureCelsius.map {
                    $0.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "en_US_POSIX")))
                } ?? "",
                reading.isLastVerifiedValue ? "last_verified" : "current",
                reading.smartStatus?.localized(for: language) ?? "",
                reading.smartHealthPercentage.map(String.init) ?? ""
            ]
        }
        let header = ["timestamp", "record_type", "sensor_kind", "name", "source", "temperature_celsius", "value_status", "smart_status", "health_percent"]
        return ([header] + historyRows + currentRows).map { $0.map(csvField).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    static func diagnosticReport(snapshot: ThermalSnapshot, language: AppLanguage) -> String {
        let heading = language == .english ? "ThermalAtlas diagnostic report" : "ThermalAtlas-Diagnosebericht"
        let generated = language == .english ? "Generated" : "Erstellt"
        let hardware = language == .english ? "Hardware" : "Hardware"
        let system = language == .english ? "macOS" : "macOS"
        let chip = language == .english ? "Chip" : "Chip"
        let sensorStatus = language == .english ? "Sensor status" : "Sensorstatus"
        let timestamp = snapshot.updatedAt.formatted(.dateTime.year().month().day().hour().minute().second().locale(language.locale))
        let chipName = AppleSiliconSMCTemperatureBackend.detectedChipNameForDiagnostics() ?? language.notAvailable
        let lines = snapshot.readings.map { reading in
            let name = reading.title ?? reading.kind.title(for: language)
            let result = reading.temperatureCelsius.map {
                "\($0.formatted(.number.precision(.fractionLength(1)).locale(language.locale))) °C"
            } ?? reading.unavailableReason?.localized(for: language) ?? language.notAvailable
            let detail = reading.detail.map { " · \($0)" } ?? ""
            return "- \(name): \(result)\(detail)"
        }
        return ([
            heading,
            "\(generated): \(timestamp)",
            "\(hardware): \(hardwareModel())",
            "\(system): \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "\(chip): \(chipName)",
            "",
            sensorStatus
        ] + lines).joined(separator: "\n")
    }

    private static func csvField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static func hardwareModel() -> String {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 1 else { return "Unknown" }
        var value = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &value, &size, nil, 0) == 0 else { return "Unknown" }
        return String(decoding: value.map { UInt8(bitPattern: $0) }.prefix(while: { $0 != 0 }), as: UTF8.self)
    }
}
