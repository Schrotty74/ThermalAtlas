import XCTest
@testable import ThermalAtlas

final class MenuBarAccessibilityTests: XCTestCase {
    @MainActor
    func testAccessibilityDescriptionIncludesEveryAvailableValueAndStatus() {
        let readings = [
            TemperatureReading(
                kind: .cpu,
                temperatureCelsius: 72.4,
                detail: nil,
                unavailableReason: nil
            ),
            TemperatureReading(
                kind: .gpu,
                temperatureCelsius: 84,
                detail: nil,
                unavailableReason: nil
            )
        ]

        let description = MenuBarStatusImage.accessibilityDescription(
            readings: readings,
            status: .warning,
            language: .english
        )

        XCTAssertTrue(description.contains("CPU: 72 degrees Celsius"))
        XCTAssertTrue(description.contains("GPU: 84 degrees Celsius"))
        XCTAssertTrue(description.contains("Status: Warning threshold reached"))
    }

    @MainActor
    func testAccessibilityDescriptionLocalizesUnavailableValues() {
        let reading = TemperatureReading(
            kind: .internalSSD,
            temperatureCelsius: nil,
            detail: nil,
            unavailableReason: .smartTemperatureUnavailable
        )

        let description = MenuBarStatusImage.accessibilityDescription(
            readings: [reading],
            status: .normal,
            language: .german
        )

        XCTAssertTrue(description.contains("Interne SSD: SMART-Temperatur wird nicht bereitgestellt"))
        XCTAssertTrue(description.contains("Status: Normal"))
    }
}
