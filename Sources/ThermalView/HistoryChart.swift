import SwiftUI
import Charts

struct HistoryChart: View {
    let points: [HistoryChartPoint]
    let segmentedPoints: [HistoryChartPoint]
    let summary: HistorySummary?
    @Binding var range: TemperatureHistoryRange
    let threshold: Double?
    let componentColor: Color
    let palette: ThermalThemePalette
    let language: AppLanguage
    let compact: Bool
    let title: String
    let unit: String
    let fractionDigits: Int
    @State private var selectedPointDate: Date?

    init(points: [HistoryChartPoint], range: Binding<TemperatureHistoryRange>, threshold: Double?,
         componentColor: Color, palette: ThermalThemePalette, language: AppLanguage,
         compact: Bool, title: String, unit: String, fractionDigits: Int) {
        let ordered = points.sorted { $0.date < $1.date }
        self.points = ordered
        self.segmentedPoints = HistoryChartPoint.segmented(ordered)
        self.summary = HistorySummary(values: ordered.map(\.value))
        self._range = range
        self.threshold = threshold
        self.componentColor = componentColor
        self.palette = palette
        self.language = language
        self.compact = compact
        self.title = title
        self.unit = unit
        self.fractionDigits = fractionDigits
    }

    private var timeDomain: ClosedRange<Date> {
        let first = points.first?.date ?? .now
        let last = points.last?.date ?? first
        return first.addingTimeInterval(-30)...last.addingTimeInterval(30)
    }

    private var valueDomain: ClosedRange<Double> {
        let largest = max(summary?.maximum ?? 0, threshold ?? 0)
        let step = unit == "RPM" ? 500.0 : 10.0
        // A zero-RPM point still needs a non-empty axis; positive points get
        // enough headroom to keep their selection marker inside the plot.
        let upper = max(step, ceil(largest * 1.05 / step) * step)
        return 0...upper
    }

    private var selectedPoint: HistoryChartPoint? {
        guard let selectedPointDate,
              let index = HistoryPointSelection.nearestIndex(to: selectedPointDate, in: points),
              points[index].date == selectedPointDate else { return nil }
        return points[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            if compact {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(palette.title.opacity(0.9))
                historyRangePicker
                    .frame(maxWidth: .infinity)
            } else {
                HStack {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.title.opacity(0.9))
                    Spacer()
                    historyRangePicker
                        .frame(width: 172)
                }
            }

            if points.isEmpty {
                Text(language.collectingHistoryTitle)
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(palette.secondary)
                    .frame(maxWidth: .infinity, minHeight: compact ? 42 : 58, alignment: .center)
            } else {
                Chart {
                    ForEach(segmentedPoints) { point in
                        LineMark(
                            x: .value(language.chartTimeTitle, point.date),
                            y: .value(unit, point.value),
                            series: .value(language.chartSegmentTitle, point.segment)
                        )
                        .interpolationMethod(.linear)
                        .foregroundStyle(componentColor)
                        .lineStyle(StrokeStyle(lineWidth: compact ? 1.5 : 2, lineCap: .round, lineJoin: .round))
                        if point.isIsolated {
                            PointMark(x: .value(language.chartTimeTitle, point.date), y: .value(unit, point.value))
                                .foregroundStyle(componentColor)
                                .symbolSize(16)
                        }
                    }
                    if let threshold {
                        RuleMark(y: .value(language.alertThresholdTitle, threshold))
                            .foregroundStyle(.orange.opacity(0.65))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                    if let selectedPoint {
                        RuleMark(x: .value(language.chartSelectedTimeTitle, selectedPoint.date))
                            .foregroundStyle(palette.title.opacity(0.55))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        PointMark(
                            x: .value(language.chartSelectedTimeTitle, selectedPoint.date),
                            y: .value(unit, selectedPoint.value)
                        )
                        .foregroundStyle(componentColor)
                        .symbolSize(compact ? 36 : 50)
                    }
                }
                .chartXScale(domain: timeDomain)
                .chartYScale(domain: valueDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                            .foregroundStyle(palette.secondary.opacity(0.25))
                        AxisValueLabel(format: .dateTime.hour().minute().locale(language.locale))
                            .foregroundStyle(palette.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                            .foregroundStyle(palette.secondary.opacity(0.25))
                        AxisValueLabel()
                            .foregroundStyle(palette.secondary)
                    }
                }
                .chartLegend(.hidden)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        guard let plotFrame = proxy.plotFrame else { return }
                                        let plot = geometry[plotFrame]
                                        let x = gesture.location.x - plot.origin.x
                                        guard x >= 0, x <= plot.width,
                                              let date: Date = proxy.value(atX: x) else { return }
                                        if let index = HistoryPointSelection.nearestIndex(to: date, in: points) {
                                            let selected = points[index].date
                                            if selectedPointDate != selected { selectedPointDate = selected }
                                        }
                                    }
                            )
                    }
                }
                .frame(height: compact ? 72 : 96)
            }

            if let summary {
                HStack {
                    summaryValue("Min", summary.minimum)
                    Spacer(minLength: 4)
                    summaryValue("Max", summary.maximum)
                    Spacer(minLength: 4)
                    summaryValue("Ø", summary.average)
                }
                .font(.caption2)
                .foregroundStyle(palette.title)
                .monospacedDigit()
                .accessibilityElement(children: .combine)
                .accessibilityHint(language.minuteAveragesTitle)
            }

            HStack(spacing: 6) {
                Button { moveSelection(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel(language.chartPreviousPointTitle)
                    .help(language.chartPreviousPointTitle)
                    .disabled(points.isEmpty)
                Text(selectedPoint.map { point in
                    let time = point.date.formatted(.dateTime.hour().minute().locale(language.locale))
                    let temperature = point.value.formatted(.number.precision(.fractionLength(fractionDigits)).locale(language.locale))
                    let average = language == .german ? "Ø" : "Avg."
                    return "\(time) · \(average) \(temperature) \(unit)"
                } ?? language.minuteAveragesTitle)
                    .font(.caption2)
                    .foregroundStyle(selectedPoint == nil ? palette.secondary.opacity(0.8) : palette.title)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { moveSelection(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel(language.chartNextPointTitle)
                    .help(language.chartNextPointTitle)
                    .disabled(points.isEmpty)
            }
            .buttonStyle(.borderless)

        }
        .padding(.top, compact ? 1 : 2)
        .environment(\.locale, language.locale)
        .focusable(!points.isEmpty)
        .onKeyPress(.leftArrow) { moveSelection(-1); return points.isEmpty ? .ignored : .handled }
        .onKeyPress(.rightArrow) { moveSelection(1); return points.isEmpty ? .ignored : .handled }
        .onKeyPress(.escape) {
            guard selectedPointDate != nil else { return .ignored }
            selectedPointDate = nil
            return .handled
        }
        .accessibilityHint(language.chartPointNavigationHint)
        .accessibilityAction(named: Text(language.chartPreviousPointTitle)) { moveSelection(-1) }
        .accessibilityAction(named: Text(language.chartNextPointTitle)) { moveSelection(1) }
        .onChange(of: range) { _, _ in selectedPointDate = nil }
    }

    private func moveSelection(_ offset: Int) {
        guard let index = HistoryPointSelection.movedIndex(from: selectedPointDate, offset: offset, in: points) else { return }
        selectedPointDate = points[index].date
    }

    private func summaryValue(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).foregroundStyle(palette.secondary)
            Text("\(value.formatted(.number.precision(.fractionLength(fractionDigits)).locale(language.locale))) \(unit)")
        }
    }

    private var historyRangePicker: some View {
        Picker(title, selection: $range) {
            ForEach(TemperatureHistoryRange.allCases) { value in
                Text("\(value.rawValue) h")
                    .accessibilityLabel(value.title(for: language))
                    .tag(value)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .controlSize(.small)
    }
}

struct FanHistoryView: View {
    let history: FanHistoryStore
    let index: Int
    let title: String
    let palette: ThermalThemePalette
    let language: AppLanguage
    @State private var range: TemperatureHistoryRange = .oneHour

    var body: some View {
        HistoryChart(points: history.points(for: index, range: range).map { HistoryChartPoint(date: $0.date, value: $0.averageRPM) },
                     range: $range, threshold: nil, componentColor: palette.secondary,
                     palette: palette, language: language, compact: false,
                     title: "\(title) · \(language.fanHistoryTitle)", unit: "RPM", fractionDigits: 0)
            .padding(14)
            .frame(width: 360)
            .background(palette.cardBase)
    }
}

