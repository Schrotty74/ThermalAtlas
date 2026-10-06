import XCTest
@testable import ThermalAtlas

final class ChartSelectionTests: XCTestCase {
    private let base = Date(timeIntervalSinceReferenceDate: 60_000)

    func testNearestMinuteHandlesEmptySingleEdgesGapsAndTies() {
        let points = [0.0, 60, 180].map { HistoryChartPoint(date: base.addingTimeInterval($0), value: 30) }
        XCTAssertNil(HistoryPointSelection.nearestIndex(to: base, in: []))
        XCTAssertEqual(HistoryPointSelection.nearestIndex(to: base.addingTimeInterval(999), in: [points[0]]), 0)
        XCTAssertEqual(HistoryPointSelection.nearestIndex(to: base.addingTimeInterval(-10), in: points), 0)
        XCTAssertEqual(HistoryPointSelection.nearestIndex(to: base.addingTimeInterval(999), in: points), 2)
        XCTAssertEqual(HistoryPointSelection.nearestIndex(to: base.addingTimeInterval(120), in: points), 1)
        XCTAssertEqual(HistoryPointSelection.nearestIndex(to: base.addingTimeInterval(121), in: points), 2)
    }

    func testKeyboardSelectionBeginsAtEitherEndAndClampsAtEdges() {
        let points = [0.0, 60, 180].map { HistoryChartPoint(date: base.addingTimeInterval($0), value: 30) }
        XCTAssertNil(HistoryPointSelection.movedIndex(from: nil, offset: 1, in: []))
        XCTAssertEqual(HistoryPointSelection.movedIndex(from: nil, offset: 1, in: points), 0)
        XCTAssertEqual(HistoryPointSelection.movedIndex(from: nil, offset: -1, in: points), 2)
        XCTAssertEqual(HistoryPointSelection.movedIndex(from: points[0].date, offset: -1, in: points), 0)
        XCTAssertEqual(HistoryPointSelection.movedIndex(from: points[1].date, offset: 1, in: points), 2)
        XCTAssertEqual(HistoryPointSelection.movedIndex(from: points[2].date, offset: 1, in: points), 2)
    }
}
