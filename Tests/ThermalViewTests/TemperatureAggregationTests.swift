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
}
