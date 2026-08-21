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
}
