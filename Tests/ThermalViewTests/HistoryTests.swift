import XCTest
@testable import ThermalAtlas

final class HistoryTests: XCTestCase {
    @MainActor
    func testFanMinutesIncludeUnchangedSamplesAndKeepFansSeparate() throws {
        let name = "ThermalAtlasTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let now = Date(timeIntervalSinceReferenceDate: 120_000)
        let store = FanHistoryStore(defaults: defaults, now: now)
        store.record([.init(index: 0, rpm: 1000), .init(index: 1, rpm: 2000)], at: now)
        store.record([.init(index: 0, rpm: 1000)], at: now.addingTimeInterval(10))
        store.record([.init(index: 0, rpm: 1600)], at: now.addingTimeInterval(20))
        let first = try XCTUnwrap(store.points(for: 0, range: .oneHour, now: now.addingTimeInterval(20)).first)
        XCTAssertEqual(first.averageRPM, 1200, accuracy: 0.00001)
        XCTAssertEqual(first.sampleCount, 3)
        XCTAssertEqual(store.points(for: 1, range: .oneHour, now: now.addingTimeInterval(20)).first?.averageRPM, 2000)
    }

    @MainActor
    func testMissingFanDoesNotBecomeZeroButStoppedFanIsRecorded() throws {
        let name = "ThermalAtlasTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let now = Date(timeIntervalSinceReferenceDate: 120_000)
        let store = FanHistoryStore(defaults: defaults, now: now)
        store.record([.init(index: 0, rpm: 1000)], at: now)
        store.record([], at: now.addingTimeInterval(60))
        store.record([.init(index: 0, rpm: 0)], at: now.addingTimeInterval(120))
        let points = store.points(for: 0, range: .oneHour, now: now.addingTimeInterval(120))
        XCTAssertEqual(points.map(\.averageRPM), [1000, 0])
        XCTAssertEqual(points.map(\.date), [now, now.addingTimeInterval(120)])
    }

    @MainActor
    func testFanHistorySurvivesRestartAndPrunesWithoutReadableFans() throws {
        let name = "ThermalAtlasTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let now = Date(timeIntervalSinceReferenceDate: 120_000)
        let store = FanHistoryStore(defaults: defaults, now: now)
        store.record([.init(index: 0, rpm: 1000)], at: now)
        store.record([.init(index: 0, rpm: 2000)], at: now.addingTimeInterval(60))
        let loaded = FanHistoryStore(defaults: defaults, now: now.addingTimeInterval(60))
        XCTAssertEqual(loaded.points(for: 0, range: .oneHour, now: now.addingTimeInterval(60)).map(\.averageRPM), [1000, 2000])
        loaded.record([], at: now.addingTimeInterval(24 * 3600 + 120))
        XCTAssertTrue(loaded.pointsByFanIndex.isEmpty)
        XCTAssertTrue(FanHistoryStore(defaults: defaults, now: now.addingTimeInterval(24 * 3600 + 120)).pointsByFanIndex.isEmpty)
    }

    @MainActor
    func testFanRangeFiltersOlderMinutes() throws {
        let name = "ThermalAtlasTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let now = Date(timeIntervalSinceReferenceDate: 120_000)
        let store = FanHistoryStore(defaults: defaults, now: now)
        store.record([.init(index: 0, rpm: 1000)], at: now)
        store.record([.init(index: 0, rpm: 2000)], at: now.addingTimeInterval(7200))
        XCTAssertEqual(store.points(for: 0, range: .oneHour, now: now.addingTimeInterval(7200)).count, 1)
        XCTAssertEqual(store.points(for: 0, range: .sixHours, now: now.addingTimeInterval(7200)).count, 2)
    }

    @MainActor
    func testAllFiveRangesFilterTemperatureAndFanHistory() throws {
        XCTAssertEqual(TemperatureHistoryRange.allCases.map(\.rawValue), [1, 3, 6, 12, 24])
        XCTAssertEqual(TemperatureHistoryRange.threeHours.title(for: .german), "3 Stunden")
        XCTAssertEqual(TemperatureHistoryRange.twelveHours.title(for: .english), "12 Hours")
        let name = "ThermalAtlasTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let base = Date(timeIntervalSinceReferenceDate: 120_000)
        let temperatures = TemperatureHistoryStore(defaults: defaults, storageKey: "temperature")
        let fans = FanHistoryStore(defaults: defaults, storageKey: "fan", now: base)
        for hour in [0, 10, 16, 20, 22] {
            let date = base.addingTimeInterval(Double(hour) * 3600)
            temperatures.record(ThermalSnapshot(readings: [TemperatureReading(kind: .cpu, temperatureCelsius: 40, detail: nil, unavailableReason: nil)], updatedAt: date))
            fans.record([.init(index: 0, rpm: 1000)], at: date)
        }
        let now = base.addingTimeInterval(22 * 3600)
        for (range, count) in zip(TemperatureHistoryRange.allCases, [1, 2, 3, 4, 5]) {
            XCTAssertEqual(temperatures.points(for: "cpu", range: range, now: now).count, count)
            XCTAssertEqual(fans.points(for: 0, range: range, now: now).count, count)
        }
    }

    func testSummaryDescribesDisplayedMinutesAndHandlesEmptyOrInvalidValues() throws {
        let summary = try XCTUnwrap(HistorySummary(values: [30, 60, 90, .nan, .infinity]))
        XCTAssertEqual(summary.minimum, 30)
        XCTAssertEqual(summary.maximum, 90)
        XCTAssertEqual(summary.average, 60)
        XCTAssertNil(HistorySummary(values: []))
        XCTAssertNil(HistorySummary(values: [.nan]))
    }

    func testChartLeavesMissingMinutesAsSeparateSegments() {
        let date = Date(timeIntervalSinceReferenceDate: 120_000)
        let points = [0.0, 60, 180, 240].map { HistoryChartPoint(date: date.addingTimeInterval($0), value: 1000) }
        XCTAssertEqual(HistoryChartPoint.segmented(points).map(\.segment), [0, 0, 1, 1])
        XCTAssertEqual(HistoryChartPoint.segmented([points[0], points[2]]).map(\.isIsolated), [true, true])
    }

    func testMeasurementAgeUsesSecondsMinutesHoursAndNeverNegativeAge() {
        let date = Date(timeIntervalSinceReferenceDate: 120_000)
        XCTAssertEqual(AppLanguage.german.measurementAge(since: date, now: date.addingTimeInterval(8)), "8 s alt")
        XCTAssertEqual(AppLanguage.english.measurementAge(since: date, now: date.addingTimeInterval(90)), "1 min old")
        XCTAssertEqual(AppLanguage.german.measurementAge(since: date, now: date.addingTimeInterval(7200)), "2 h alt")
        XCTAssertEqual(AppLanguage.english.measurementAge(since: date, now: date.addingTimeInterval(-1)), "0 s old")
    }
}
