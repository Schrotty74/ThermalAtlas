import Foundation
import Observation

struct FanHistoryPoint: Codable, Sendable {
    let date: Date
    var averageRPM: Double
    var sampleCount: Int
}

/// Separate, local RPM history. Missing fans never contribute zero samples.
@MainActor
@Observable
final class FanHistoryStore {
    static let storageKey = "thermalatlas.fanHistory"
    private let defaults: UserDefaults
    private let storageKey: String
    private(set) var pointsByFanIndex: [Int: [FanHistoryPoint]]
    private var lastPersistedMinute: Date?

    init(defaults: UserDefaults = .standard, storageKey: String = FanHistoryStore.storageKey, now: Date = .now) {
        self.defaults = defaults
        self.storageKey = storageKey
        let decoded = defaults.data(forKey: storageKey).flatMap {
            try? JSONDecoder().decode([Int: [FanHistoryPoint]].self, from: $0)
        } ?? [:]
        pointsByFanIndex = decoded.mapValues { points in
            points.filter { $0.date >= now.addingTimeInterval(-TemperatureHistoryStore.maximumAge) && $0.date <= now && $0.averageRPM.isFinite && $0.averageRPM >= 0 && $0.sampleCount > 0 }
        }.filter { !$0.value.isEmpty }
    }

    func record(_ fans: [SMCFanSpeedReader.Fan], at now: Date = .now) {
        let minute = Date(timeIntervalSinceReferenceDate: floor(now.timeIntervalSinceReferenceDate / 60) * 60)
        let cutoff = now.addingTimeInterval(-TemperatureHistoryStore.maximumAge)
        for fan in fans where fan.rpm >= 0 {
            var points = pointsByFanIndex[fan.index] ?? []
            if let last = points.indices.last, points[last].date == minute {
                let count = points[last].sampleCount
                points[last].averageRPM += (Double(fan.rpm) - points[last].averageRPM) / Double(count + 1)
                points[last].sampleCount += 1
            } else {
                points.append(FanHistoryPoint(date: minute, averageRPM: Double(fan.rpm), sampleCount: 1))
            }
            pointsByFanIndex[fan.index] = points.filter { $0.date >= cutoff }
        }
        // Prune even while all fans are unavailable; persist once per minute.
        if lastPersistedMinute != minute {
            pointsByFanIndex = pointsByFanIndex.mapValues { $0.filter { $0.date >= cutoff } }.filter { !$0.value.isEmpty }
            if let data = try? JSONEncoder().encode(pointsByFanIndex) { defaults.set(data, forKey: storageKey) }
            lastPersistedMinute = minute
        }
    }

    func points(for index: Int, range: TemperatureHistoryRange, now: Date = .now) -> [FanHistoryPoint] {
        let cutoff = now.addingTimeInterval(-TimeInterval(range.rawValue) * 3600)
        return (pointsByFanIndex[index] ?? []).filter { $0.date >= cutoff && $0.date <= now }
    }
}

struct HistoryChartPoint: Identifiable {
    let date: Date
    let value: Double
    var segment: Int = 0
    var isIsolated: Bool = false
    var id: Date { date }

    static func segmented(_ points: [HistoryChartPoint]) -> [HistoryChartPoint] {
        var segment = 0
        var result = points.enumerated().map { index, point in
            if index > 0 && point.date.timeIntervalSince(points[index - 1].date) > 90 { segment += 1 }
            return HistoryChartPoint(date: point.date, value: point.value, segment: segment)
        }
        for index in result.indices {
            let hasPrevious = index > 0 && result[index - 1].segment == result[index].segment
            let hasNext = index + 1 < result.count && result[index + 1].segment == result[index].segment
            result[index].isIsolated = !hasPrevious && !hasNext
        }
        return result
    }
}

/// Equal weight per displayed minute, independent of the sensor refresh rate.
struct HistorySummary {
    let minimum: Double
    let maximum: Double
    let average: Double

    init?(values: [Double]) {
        let valid = values.filter(\.isFinite)
        guard let minimum = valid.min(), let maximum = valid.max() else { return nil }
        self.minimum = minimum
        self.maximum = maximum
        self.average = valid.reduce(0, +) / Double(valid.count)
    }
}

/// Searches chronologically ordered minute points without scanning every point
/// on each pointer movement. Ties select the earlier minute.
enum HistoryPointSelection {
    static func nearestIndex(to date: Date, in points: [HistoryChartPoint]) -> Int? {
        guard !points.isEmpty else { return nil }
        var lower = 0
        var upper = points.count
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if points[middle].date < date { lower = middle + 1 } else { upper = middle }
        }
        if lower == 0 { return 0 }
        if lower == points.count { return points.count - 1 }
        return date.timeIntervalSince(points[lower - 1].date) <= points[lower].date.timeIntervalSince(date)
            ? lower - 1 : lower
    }

    static func movedIndex(from date: Date?, offset: Int, in points: [HistoryChartPoint]) -> Int? {
        guard !points.isEmpty else { return nil }
        guard let date, let current = nearestIndex(to: date, in: points) else {
            return offset < 0 ? points.count - 1 : 0
        }
        return min(points.count - 1, max(0, current + offset))
    }
}
