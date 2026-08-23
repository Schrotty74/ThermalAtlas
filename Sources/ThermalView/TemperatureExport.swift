import Foundation

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

    private static func csvField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
