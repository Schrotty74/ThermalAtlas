import Foundation

enum TemperatureAggregation {
    /// Matches the "Average" semantics used by common sensor tools: every
    /// currently readable zone contributes equally to the overall value.
    static func arithmeticMean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let ordered = values.sorted()
        let middle = ordered.count / 2
        return ordered.count.isMultiple(of: 2)
            ? (ordered[middle - 1] + ordered[middle]) / 2
            : ordered[middle]
    }
}
