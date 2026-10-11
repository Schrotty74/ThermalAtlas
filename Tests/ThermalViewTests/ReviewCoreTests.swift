import XCTest
@testable import ThermalAtlas

final class ReviewCoreTests: XCTestCase {
    func testRemovedUnreportedDriveStartsANewAlertEpisodeWhenItReturns() {
        var engine = TemperatureAlertEngine()
        let start = Date(timeIntervalSinceReferenceDate: 500_000)
        let hotDrive = reading(.externalSSD, id: "disk4", temperature: 75)

        XCTAssertTrue(engine.evaluate(readings: [hotDrive], configuration: configuration(), now: start).isEmpty)
        XCTAssertTrue(engine.evaluate(readings: [], configuration: configuration(), now: start.addingTimeInterval(30)).isEmpty)
        XCTAssertTrue(engine.evaluate(readings: [hotDrive], configuration: configuration(), now: start.addingTimeInterval(120)).isEmpty)
        XCTAssertEqual(
            engine.evaluate(readings: [hotDrive], configuration: configuration(), now: start.addingTimeInterval(180)).map(\.reading.id),
            ["disk4"]
        )
    }

    func testRemovedReportedDriveCanAlertAgainAfterItReturns() {
        var engine = TemperatureAlertEngine()
        let start = Date(timeIntervalSinceReferenceDate: 600_000)
        let hotDrive = reading(.externalSSD, id: "disk6", temperature: 75)

        XCTAssertTrue(engine.evaluate(readings: [hotDrive], configuration: configuration(), now: start).isEmpty)
        XCTAssertEqual(engine.evaluate(readings: [hotDrive], configuration: configuration(), now: start.addingTimeInterval(60)).count, 1)
        XCTAssertTrue(engine.evaluate(readings: [], configuration: configuration(), now: start.addingTimeInterval(61)).isEmpty)
        XCTAssertTrue(engine.evaluate(readings: [hotDrive], configuration: configuration(), now: start.addingTimeInterval(120)).isEmpty)
        XCTAssertEqual(engine.evaluate(readings: [hotDrive], configuration: configuration(), now: start.addingTimeInterval(180)).count, 1)
    }

    func testCachedNormalDriveDoesNotResetAFreshHotEpisode() {
        var engine = TemperatureAlertEngine()
        let start = Date(timeIntervalSinceReferenceDate: 700_000)
        let hotDrive = reading(.externalSSD, id: "disk8", temperature: 75)
        let cachedNormalDrive = reading(.externalSSD, id: "disk8", temperature: 35, fresh: false)

        XCTAssertTrue(engine.evaluate(readings: [hotDrive], configuration: configuration(), now: start).isEmpty)
        XCTAssertTrue(engine.evaluate(readings: [cachedNormalDrive], configuration: configuration(), now: start.addingTimeInterval(30)).isEmpty)
        XCTAssertEqual(engine.evaluate(readings: [hotDrive], configuration: configuration(), now: start.addingTimeInterval(60)).count, 1)
    }

    func testThresholdChangeStartsAHotReadingEpisodeAgain() {
        var engine = TemperatureAlertEngine()
        let start = Date(timeIntervalSinceReferenceDate: 800_000)
        let hotDrive = reading(.externalSSD, id: "disk10", temperature: 75)
        let original = configuration()
        let changed = configuration(externalSSDThreshold: 74)

        XCTAssertTrue(engine.evaluate(readings: [hotDrive], configuration: original, now: start).isEmpty)
        XCTAssertTrue(engine.evaluate(readings: [hotDrive], configuration: changed, now: start.addingTimeInterval(120)).isEmpty)
        XCTAssertEqual(engine.evaluate(readings: [hotDrive], configuration: changed, now: start.addingTimeInterval(180)).count, 1)
    }

    @MainActor
    func testHistoryPrunesOnMinuteCadenceAndPersistsRecent24HourData() throws {
        let suite = "ThermalAtlasTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let currentMinute = floor(Date.now.timeIntervalSinceReferenceDate / 60) * 60
        let now = Date(timeIntervalSinceReferenceDate: currentMinute)
        let expired = TemperatureHistoryPoint(date: now.addingTimeInterval(-25 * 60 * 60), averageTemperature: 40, sampleCount: 1)
        let retained = TemperatureHistoryPoint(date: now.addingTimeInterval(-60 * 60), averageTemperature: 42, sampleCount: 1)
        let encoded = try JSONEncoder().encode(["disk12": [expired, retained]])
        defaults.set(encoded, forKey: "history")
        let store = TemperatureHistoryStore(defaults: defaults, storageKey: "history")

        // Pruning also runs when a device has disappeared and supplies no sample.
        store.record(snapshot(temperature: nil, at: now))

        XCTAssertEqual(store.points(for: "disk12", range: .twentyFourHours, now: now).map(\.averageTemperature), [42])
        let restored = TemperatureHistoryStore(defaults: defaults, storageKey: "history")
        XCTAssertEqual(restored.points(for: "disk12", range: .twentyFourHours, now: now).map(\.averageTemperature), [42])
    }

    private func configuration(externalSSDThreshold: Double = 70) -> TemperatureAlertConfiguration {
        TemperatureAlertConfiguration(
            isEnabled: true,
            cpuThreshold: 95,
            gpuThreshold: 95,
            internalSSDThreshold: 70,
            externalSSDThreshold: externalSSDThreshold,
            language: .english
        )
    }

    private func reading(_ kind: SensorKind, id: String, temperature: Double, fresh: Bool = true) -> TemperatureReading {
        TemperatureReading(
            kind: kind,
            sourceIdentifier: id,
            temperatureCelsius: temperature,
            detail: nil,
            unavailableReason: nil,
            isFreshMeasurement: fresh
        )
    }

    private func snapshot(temperature: Double?, at date: Date) -> ThermalSnapshot {
        ThermalSnapshot(
            readings: [TemperatureReading(
                kind: .externalSSD,
                sourceIdentifier: "disk12",
                temperatureCelsius: temperature,
                detail: nil,
                unavailableReason: temperature == nil ? .smartTemperatureUnavailable : nil
            )],
            updatedAt: date
        )
    }
}
