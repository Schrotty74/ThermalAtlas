import AppKit

@MainActor
enum MenuBarStatusImage {
    private static let height: CGFloat = 20
    private static let symbolWidth: CGFloat = 15
    private static let segmentSpacing: CGFloat = 3
    private static let separator = " · "
    private static let horizontalInset: CGFloat = 5
    private static var cachedAllValuesImage: (signature: String, image: NSImage)?
    private static var cachedSymbolOnlyImage: NSImage?

    static func symbolOnly() -> NSImage {
        if let cachedSymbolOnlyImage { return cachedSymbolOnlyImage }
        let image = NSImage(systemSymbolName: "thermometer.medium", accessibilityDescription: "ThermalAtlas") ?? NSImage()
        image.isTemplate = true
        cachedSymbolOnlyImage = image
        return image
    }

    static func make(readings: [TemperatureReading], status: MenuBarTemperatureStatus) -> NSImage {
        let signature = imageSignature(readings: readings, status: status)
        if let cachedAllValuesImage, cachedAllValuesImage.signature == signature {
            return cachedAllValuesImage.image
        }
        let segments = readings.compactMap { reading -> (symbol: String, value: String, color: NSColor)? in
            guard let temperature = reading.temperatureCelsius else { return nil }
            return (reading.kind.symbol, "\(Int(temperature.rounded()))°", menuBarColor(for: reading.kind))
        }
        guard !segments.isEmpty else { return symbolOnly() }

        let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        let measurementAttributes: [NSAttributedString.Key: Any] = [.font: font]
        let separatorAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.secondaryLabelColor]
        let separatorWidth = (separator as NSString).size(withAttributes: measurementAttributes).width
        let segmentWidths = segments.map { symbolWidth + segmentSpacing + ($0.value as NSString).size(withAttributes: measurementAttributes).width }
        let contentWidth = segmentWidths.reduce(0, +) + separatorWidth * CGFloat(segments.count - 1)
        let width = contentWidth + horizontalInset * 2
        let image = NSImage(size: NSSize(width: ceil(width), height: height))

        image.lockFocus()
        NSColor.black.withAlphaComponent(0.62).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 1, width: ceil(width), height: height - 2), xRadius: 6, yRadius: 6).fill()
        statusColor(for: status).withAlphaComponent(0.9).setStroke()
        let statusBorder = NSBezierPath(roundedRect: NSRect(x: 0.75, y: 1.75, width: ceil(width) - 1.5, height: height - 3.5), xRadius: 5, yRadius: 5)
        statusBorder.lineWidth = 1.2
        statusBorder.stroke()

        var x = horizontalInset
        for (index, segment) in segments.enumerated() {
            if index > 0 {
                (separator as NSString).draw(at: NSPoint(x: x, y: 1), withAttributes: separatorAttributes)
                x += separatorWidth
            }
            let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                .applying(NSImage.SymbolConfiguration(paletteColors: [segment.color]))
            NSImage(systemSymbolName: segment.symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(configuration)?
                .draw(in: NSRect(x: x, y: 2, width: symbolWidth, height: symbolWidth))
            x += symbolWidth + segmentSpacing
            let valueAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: segment.color]
            let valueWidth = (segment.value as NSString).size(withAttributes: measurementAttributes).width
            (segment.value as NSString).draw(at: NSPoint(x: x, y: 1), withAttributes: valueAttributes)
            x += valueWidth
        }
        image.unlockFocus()
        image.isTemplate = false
        cachedAllValuesImage = (signature, image)
        return image
    }

    static func imageSignature(readings: [TemperatureReading], status: MenuBarTemperatureStatus) -> String {
        readings.map { reading in
            "\(reading.id):\(reading.temperatureCelsius.map { Int($0.rounded()) } ?? -999)"
        }.joined(separator: "|") + "|\(status)"
    }

    static func accessibilityDescription(
        readings: [TemperatureReading],
        status: MenuBarTemperatureStatus,
        language: AppLanguage
    ) -> String {
        let values = readings.map { reading -> String in
            let title = reading.title ?? reading.kind.title(for: language)
            guard let temperature = reading.temperatureCelsius else {
                let reason = reading.unavailableReason?.localized(for: language) ?? language.notAvailable
                return "\(title): \(reason)"
            }
            let value = Int(temperature.rounded())
            let temperatureText = language == .english
                ? "\(value) degrees Celsius"
                : "\(value) Grad Celsius"
            return "\(title): \(temperatureText)"
        }
        let statusText: String
        switch (status, language) {
        case (.normal, .english): statusText = "Status: Normal"
        case (.warm, .english): statusText = "Status: Approaching warning threshold"
        case (.warning, .english): statusText = "Status: Warning threshold reached"
        case (.normal, .german): statusText = "Status: Normal"
        case (.warm, .german): statusText = "Status: Warnschwelle wird erreicht"
        case (.warning, .german): statusText = "Status: Warnschwelle erreicht"
        }
        return (["ThermalAtlas"] + values + [statusText]).joined(separator: ". ")
    }

    private static func menuBarColor(for kind: SensorKind) -> NSColor {
        switch kind {
        case .cpu: .systemYellow
        case .gpu: .systemBlue
        case .internalSSD: .systemTeal
        case .externalSSD: .systemGreen
        }
    }

    private static func statusColor(for status: MenuBarTemperatureStatus) -> NSColor {
        switch status {
        case .normal: .systemGreen
        case .warm: .systemYellow
        case .warning: .systemRed
        }
    }
}
