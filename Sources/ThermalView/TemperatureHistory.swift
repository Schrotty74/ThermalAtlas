import Foundation
import Observation

enum TemperatureHistoryRange: Int, CaseIterable, Identifiable {
    case oneHour = 1
    case sixHours = 6
    case twentyFourHours = 24

    var id: Int { rawValue }

    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.oneHour, .english): "1 Hour"
        case (.sixHours, .english): "6 Hours"
        case (.twentyFourHours, .english): "24 Hours"
        case (.oneHour, .german): "1 Stunde"
        case (.sixHours, .german): "6 Stunden"
        case (.twentyFourHours, .german): "24 Stunden"
        }
    }
}

struct TemperatureHistoryPoint: Codable, Identifiable, Sendable {
    let date: Date
    var averageTemperature: Double
    var sampleCount: Int

    var id: Date { date }
}

/// Stores one local average per sensor and minute. The bounded history is used
/// only for the in-app chart and never leaves this Mac.
@MainActor
@Observable
final class TemperatureHistoryStore {
    static let storageKey = "thermalatlas.temperatureHistory"
    static let maximumAge: TimeInterval = 24 * 60 * 60

    private let defaults: UserDefaults
    private let storageKey: String
    private(set) var pointsByReadingID: [String: [TemperatureHistoryPoint]]

    init(defaults: UserDefaults = .standard, storageKey: String = TemperatureHistoryStore.storageKey) {
        self.defaults = defaults
        self.storageKey = storageKey
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: [TemperatureHistoryPoint]].self, from: data) {
            self.pointsByReadingID = Self.pruned(decoded, before: .now.addingTimeInterval(-Self.maximumAge))
        } else {
            self.pointsByReadingID = [:]
        }
    }

    func record(_ snapshot: ThermalSnapshot) {
        let minute = Date(timeIntervalSinceReferenceDate:
            floor(snapshot.updatedAt.timeIntervalSinceReferenceDate / 60) * 60
        )
        let cutoff = snapshot.updatedAt.addingTimeInterval(-Self.maximumAge)

        var startedNewMinute = false
        for reading in snapshot.readings where reading.isFreshMeasurement && !reading.isLastVerifiedValue {
            guard let temperature = reading.temperatureCelsius else { continue }
            let identifier = reading.id
            var points = pointsByReadingID[identifier] ?? []
            if let last = points.indices.last, points[last].date == minute {
                let count = points[last].sampleCount
                points[last].averageTemperature = (points[last].averageTemperature * Double(count) + temperature) / Double(count + 1)
                points[last].sampleCount = count + 1
            } else {
                points.append(TemperatureHistoryPoint(date: minute, averageTemperature: temperature, sampleCount: 1))
                startedNewMinute = true
            }
            pointsByReadingID[identifier] = points.filter { $0.date >= cutoff }
        }
        pointsByReadingID = Self.pruned(pointsByReadingID, before: cutoff)
        // Keep refining the in-memory average during a minute, but write only
        // when a new minute begins. This avoids disk activity on every scan.
        if startedNewMinute { persist() }
    }

    func points(for readingID: String, range: TemperatureHistoryRange, now: Date = .now) -> [TemperatureHistoryPoint] {
        let cutoff = now.addingTimeInterval(-TimeInterval(range.rawValue) * 60 * 60)
        return (pointsByReadingID[readingID] ?? []).filter { $0.date >= cutoff }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(pointsByReadingID) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func pruned(
        _ values: [String: [TemperatureHistoryPoint]],
        before cutoff: Date
    ) -> [String: [TemperatureHistoryPoint]] {
        values.reduce(into: [:]) { result, entry in
            let points = entry.value.filter { $0.date >= cutoff }
            if !points.isEmpty { result[entry.key] = points }
        }
    }
}
