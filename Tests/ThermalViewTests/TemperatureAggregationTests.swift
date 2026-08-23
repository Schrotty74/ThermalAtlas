import XCTest
@testable import ThermalAtlas

final class TemperatureAggregationTests: XCTestCase {
    func testArithmeticMeanMatchesAverageSemantics() throws {
        let zones = [36.8, 36.8, 36.7, 32.7, 37.0, 33.0, 37.1, 41.3]

        XCTAssertEqual(try XCTUnwrap(TemperatureAggregation.arithmeticMean(zones)), 36.425, accuracy: 0.000_001)
    }

    func testMedianRemainsAvailableForSensorDeduplication() throws {
        XCTAssertEqual(try XCTUnwrap(TemperatureAggregation.median([33, 36.7, 36.8, 37])), 36.75, accuracy: 0.000_001)
    }

    func testEmptySensorGroupHasNoAggregate() {
        XCTAssertNil(TemperatureAggregation.arithmeticMean([]))
        XCTAssertNil(TemperatureAggregation.median([]))
    }

    func testFourThemesIncludeTheFullWindowMilkGlassTheme() {
        XCTAssertEqual(ThermalTheme.allCases.count, 4)
        XCTAssertTrue(ThermalTheme.milkGlass.usesFullWindowGlass)
        XCTAssertFalse(ThermalTheme.classic.usesFullWindowGlass)
    }

    func testRefreshIntervalOptionsCoverOneSecondStepsFromOneToFourSeconds() {
        XCTAssertEqual(
            RefreshIntervalOption.allCases.map(\.rawValue),
            [1.0, 2.0, 3.0, 4.0]
        )
        XCTAssertEqual(RefreshIntervalOption.defaultOption, .twoSeconds)
    }

    func testRefreshIntervalNormalizesToNearestSupportedStep() {
        XCTAssertEqual(RefreshIntervalOption.normalized(0.1), .oneSecond)
        XCTAssertEqual(RefreshIntervalOption.normalized(2.4), .twoSeconds)
        XCTAssertEqual(RefreshIntervalOption.normalized(4.8), .fourSeconds)
    }

    func testSSDHealthUsesOnlyReportedNVMePercentageUsed() {
        XCTAssertEqual(SSDHealth.remainingPercentage(fromPercentageUsed: 1), 99)
        XCTAssertEqual(SSDHealth.remainingPercentage(fromPercentageUsed: 2), 98)
        XCTAssertEqual(SSDHealth.remainingPercentage(fromPercentageUsed: 120), 0)
        XCTAssertNil(SSDHealth.remainingPercentage(fromPercentageUsed: nil))
        XCTAssertNil(SSDHealth.remainingPercentage(fromPercentageUsed: -1))
    }

    func testExternalSSDsWithDifferentSourcesHaveDistinctStableIDs() {
        let first = TemperatureReading(
            kind: .externalSSD,
            sourceIdentifier: "disk4",
            temperatureCelsius: 33,
            detail: "First SSD",
            unavailableReason: nil
        )
        let second = TemperatureReading(
            kind: .externalSSD,
            sourceIdentifier: "disk6",
            temperatureCelsius: 41,
            detail: "Second SSD",
            unavailableReason: nil
        )

        XCTAssertNotEqual(first.id, second.id)
    }

    func testVisibleSensorSelectionPersistsOnlySelectedKinds() {
        let selection: Set<SensorKind> = [.cpu, .externalSSD]
        let stored = SensorVisibility.storageValue(for: selection)

        XCTAssertEqual(stored, "cpu,externalSSD")
        XCTAssertEqual(SensorVisibility.selectedKinds(from: stored), selection)
    }

    func testMenuBarDisplayOffersAllValuesAndSymbolOnly() {
        XCTAssertEqual(MenuBarDisplayMode.allCases, [.allValues, .symbolOnly])
        XCTAssertEqual(MenuBarDisplayMode.defaultMode, .allValues)
        XCTAssertEqual(MenuBarDisplayMode.symbolOnly.title(for: .german), "Nur Symbol")
    }

    func testInvalidVisibleSensorSelectionFallsBackToAllSensorKinds() {
        XCTAssertEqual(SensorVisibility.selectedKinds(from: "invalid"), Set(SensorKind.allCases))
    }

    func testEnglishIsTheDefaultAppLanguage() {
        XCTAssertEqual(AppLanguage.defaultLanguage, .english)
        XCTAssertEqual(AppLanguage.english.appSubtitle, "Temperatures on this Mac")
        XCTAssertEqual(AppLanguage.english.notAvailable, "Not available")
    }

    func testGermanLanguageProvidesLocalizedSensorAndMenuText() {
        XCTAssertEqual(AppLanguage.german.appSubtitle, "Temperaturen dieses Macs")
        XCTAssertEqual(AppLanguage.german.activityMonitorTitle, "Aktivitätsanzeige öffnen")
        XCTAssertEqual(SensorAvailabilityReason.smartTemperatureUnavailable.localized(for: .german), "SMART-Temperatur wird nicht bereitgestellt")
        XCTAssertEqual(SMARTStatus.verified.localized(for: .german), "SMART: Verifiziert")
        XCTAssertEqual(AppLanguage.german.systemContextTitle, "Systemkontext")
    }

    func testSystemContextKeepsPowerStateSeparateFromSensorKinds() {
        XCTAssertFalse(SensorKind.allCases.map(\.rawValue).contains("power"))
        XCTAssertEqual(SystemContext.PowerSource.battery(percentage: 73), .battery(percentage: 73))
    }

    func testTemperatureAlertOnlyFiresAfterOneMinuteAndResetsAfterRecovery() {
        var engine = TemperatureAlertEngine()
        let configuration = TemperatureAlertConfiguration(
            isEnabled: true,
            cpuThreshold: 95,
            gpuThreshold: 95,
            internalSSDThreshold: 70,
            externalSSDThreshold: 70,
            language: .english
        )
        let reading = TemperatureReading(kind: .cpu, temperatureCelsius: 96, detail: nil, unavailableReason: nil)
        let base = Date(timeIntervalSinceReferenceDate: 10_000)

        XCTAssertTrue(engine.evaluate(readings: [reading], configuration: configuration, now: base).isEmpty)
        XCTAssertTrue(engine.evaluate(readings: [reading], configuration: configuration, now: base.addingTimeInterval(59)).isEmpty)
        XCTAssertEqual(engine.evaluate(readings: [reading], configuration: configuration, now: base.addingTimeInterval(60)).count, 1)
        XCTAssertTrue(engine.evaluate(readings: [reading], configuration: configuration, now: base.addingTimeInterval(120)).isEmpty)

        let recovered = TemperatureReading(kind: .cpu, temperatureCelsius: 80, detail: nil, unavailableReason: nil)
        XCTAssertTrue(engine.evaluate(readings: [recovered], configuration: configuration, now: base.addingTimeInterval(121)).isEmpty)
        XCTAssertTrue(engine.evaluate(readings: [reading], configuration: configuration, now: base.addingTimeInterval(122)).isEmpty)
        XCTAssertEqual(engine.evaluate(readings: [reading], configuration: configuration, now: base.addingTimeInterval(182)).count, 1)
    }

    @MainActor
    func testExportIncludesCurrentAndHistoryReadingsAndEscapesCSVFields() throws {
        let timestamp = Date(timeIntervalSinceReferenceDate: 20_000)
        let snapshot = ThermalSnapshot(readings: [
            TemperatureReading(
                kind: .externalSSD,
                sourceIdentifier: "disk4",
                title: "Support, SSD",
                temperatureCelsius: 41.5,
                detail: nil,
                unavailableReason: nil
            )
        ], updatedAt: timestamp)

        let text = TemperatureExport.plainText(snapshot: snapshot, language: .english)
        let suiteName = "ThermalAtlasTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let history = TemperatureHistoryStore(defaults: defaults, storageKey: "history")
        history.record(ThermalSnapshot(readings: snapshot.readings, updatedAt: timestamp.addingTimeInterval(-60)))
        let csv = TemperatureExport.csv(snapshot: snapshot, history: history, language: .english)

        XCTAssertTrue(text.contains("Support, SSD: 41.5 °C"))
        XCTAssertTrue(csv.contains("\"Support, SSD\""))
        XCTAssertTrue(csv.contains("\"41.5\""))
        XCTAssertTrue(csv.contains("\"history_average\""))
        XCTAssertTrue(csv.contains("\"current_snapshot\""))
    }

    @MainActor
    func testTemperatureHistoryUsesMinuteAveragesAndKeepsReadingIDsSeparate() throws {
        let suiteName = "ThermalAtlasTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = TemperatureHistoryStore(defaults: defaults, storageKey: "history")
        let firstMinute = Date(timeIntervalSinceReferenceDate: 12_000)
        let cpu60 = TemperatureReading(kind: .cpu, temperatureCelsius: 60, detail: nil, unavailableReason: nil)
        let cpu70 = TemperatureReading(kind: .cpu, temperatureCelsius: 70, detail: nil, unavailableReason: nil)
        let gpu80 = TemperatureReading(kind: .gpu, temperatureCelsius: 80, detail: nil, unavailableReason: nil)

        store.record(ThermalSnapshot(readings: [cpu60, gpu80], updatedAt: firstMinute))
        store.record(ThermalSnapshot(readings: [cpu70], updatedAt: firstMinute.addingTimeInterval(20)))
        let cpuPoints = store.points(for: cpu60.id, range: .oneHour, now: firstMinute.addingTimeInterval(20))

        XCTAssertEqual(cpuPoints.count, 1)
        XCTAssertEqual(try XCTUnwrap(cpuPoints.first).averageTemperature, 65, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(cpuPoints.first).sampleCount, 2)
        XCTAssertEqual(store.points(for: gpu80.id, range: .oneHour, now: firstMinute.addingTimeInterval(20)).count, 1)
    }
}
