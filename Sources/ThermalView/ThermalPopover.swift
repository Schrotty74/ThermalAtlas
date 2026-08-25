import AppKit
import Charts
import SwiftUI

struct MenuBarLabel: View {
    let service: SensorService
    let visibleSensorKinds: Set<SensorKind>
    let displayMode: MenuBarDisplayMode
    let language: AppLanguage
    let alertConfiguration: TemperatureAlertConfiguration

    private var readings: [TemperatureReading] {
        service.snapshot.readings.filter { visibleSensorKinds.contains($0.kind) }
    }

    var body: some View {
        Image(nsImage: displayMode == .symbolOnly
              ? MenuBarStatusImage.symbolOnly()
              : MenuBarStatusImage.make(readings: readings, status: MenuBarTemperatureStatus.from(readings: readings, configuration: alertConfiguration)))
        .accessibilityLabel(menuBarAccessibilityLabel)
    }

    private var menuBarAccessibilityLabel: String {
        guard displayMode == .allValues else {
            return language == .english ? "ThermalAtlas menu bar symbol" : "ThermalAtlas-Menüleistensymbol"
        }
        let temperatures = readings.compactMap { reading -> String? in
            guard let temperature = reading.temperatureCelsius else { return nil }
            return "\(reading.kind.title(for: language)) \(Int(temperature.rounded()))"
        }

        guard !temperatures.isEmpty else { return "ThermalAtlas" }
        let unit = language == .english ? "degrees Celsius" : "Grad Celsius"
        return "ThermalAtlas: \(temperatures.joined(separator: ", ")) \(unit)"
    }
}

/// `MenuBarExtra` renders only the first direct child in its status item on
/// this macOS version. Draw all symbols and values into one image so the native
/// status item receives a single, compact label while keeping sensor groups
/// visually distinct.
enum MenuBarStatusImage {
    private static let height: CGFloat = 20
    private static let symbolWidth: CGFloat = 15
    private static let segmentSpacing: CGFloat = 3
    private static let separator = " · "
    private static let horizontalInset: CGFloat = 5

    static func symbolOnly() -> NSImage {
        let image = NSImage(systemSymbolName: "thermometer.medium", accessibilityDescription: "ThermalAtlas") ?? NSImage()
        image.isTemplate = true
        return image
    }

    static func make(readings: [TemperatureReading], status: MenuBarTemperatureStatus) -> NSImage {
        let segments = readings.compactMap { reading -> (symbol: String, value: String, color: NSColor)? in
            guard let temperature = reading.temperatureCelsius else { return nil }
            return (
                reading.kind.symbol,
                "\(Int(temperature.rounded()))°",
                menuBarColor(for: reading.kind)
            )
        }

        guard !segments.isEmpty else {
            return symbolOnly()
        }

        let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        let measurementAttributes: [NSAttributedString.Key: Any] = [.font: font]
        let separatorAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let separatorWidth = (separator as NSString).size(withAttributes: measurementAttributes).width
        let segmentWidths = segments.map {
            symbolWidth + segmentSpacing + ($0.value as NSString).size(withAttributes: measurementAttributes).width
        }
        let contentWidth = segmentWidths.reduce(0, +) + separatorWidth * CGFloat(segments.count - 1)
        let width = contentWidth + horizontalInset * 2
        let image = NSImage(size: NSSize(width: ceil(width), height: height))

        image.lockFocus()
        NSColor.black.withAlphaComponent(0.62).setFill()
        NSBezierPath(
            roundedRect: NSRect(x: 0, y: 1, width: ceil(width), height: height - 2),
            xRadius: 6,
            yRadius: 6
        ).fill()
        statusColor(for: status).withAlphaComponent(0.9).setStroke()
        let statusBorder = NSBezierPath(
            roundedRect: NSRect(x: 0.75, y: 1.75, width: ceil(width) - 1.5, height: height - 3.5),
            xRadius: 5,
            yRadius: 5
        )
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
            let symbol = NSImage(systemSymbolName: segment.symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(configuration)
            symbol?.draw(in: NSRect(x: x, y: 2, width: symbolWidth, height: symbolWidth))
            x += symbolWidth + segmentSpacing

            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: segment.color
            ]
            let valueWidth = (segment.value as NSString).size(withAttributes: measurementAttributes).width
            (segment.value as NSString).draw(at: NSPoint(x: x, y: 1), withAttributes: valueAttributes)
            x += valueWidth
        }
        image.unlockFocus()
        image.isTemplate = false
        return image
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

struct ThermalPopover: View {
    let service: SensorService
    @Binding var selectedTheme: ThermalTheme
    @Binding var refreshInterval: Double
    @Binding var selectedLanguage: AppLanguage
    @Binding var visibleSensorKinds: Set<SensorKind>
    @Binding var menuBarDisplayMode: MenuBarDisplayMode
    @Binding var compactPopover: Bool
    @Binding var alertsEnabled: Bool
    @Binding var cpuAlertThreshold: Double
    @Binding var gpuAlertThreshold: Double
    @Binding var internalSSDAlertThreshold: Double
    @Binding var externalSSDAlertThreshold: Double
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThermalThemePalette { selectedTheme.palette }
    private var footerMenuForeground: Color { palette.title }
    private var footerMenuBackgroundOpacity: Double {
        selectedTheme == .classic && colorScheme == .light ? 0.10 : 0.16
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: compactPopover ? 11 : 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ThermalAtlas").font(compactPopover ? .headline.weight(.semibold) : .title3.weight(.semibold))
                        Text(selectedLanguage.appSubtitle)
                            .font(compactPopover ? .caption : .subheadline)
                            .foregroundStyle(palette.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "thermometer.medium")
                        .font(compactPopover ? .title3.weight(.medium) : .title2.weight(.medium))
                        .foregroundStyle(palette.gpu)
                        .symbolRenderingMode(.hierarchical)
                }
                ThermalSensorCards(
                    service: service,
                    visibleSensorKinds: visibleSensorKinds,
                    selectedTheme: selectedTheme,
                    language: selectedLanguage,
                    compact: compactPopover,
                    history: service.history,
                    alertConfiguration: alertConfiguration
                )
                ThermalSystemContext(
                    service: service,
                    palette: palette,
                    language: selectedLanguage,
                    compact: compactPopover
                )
                HStack(spacing: 6) {
                    ThermalUpdateStatus(service: service, language: selectedLanguage)
                    Spacer()
                    footerActionsMenu
                }
                .font(compactPopover ? .caption2 : .caption).foregroundStyle(palette.secondary)
            }
            .padding(compactPopover ? 12 : 20)
        }
        .frame(width: compactPopover ? 230 : 370)
        .foregroundStyle(palette.title)
        .background { popoverBackground }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(selectedTheme.usesFullWindowGlass ? Color.white.opacity(0.34) : palette.gpu.opacity(0.16), lineWidth: 1)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: selectedTheme)
        .background(PopoverWindowPositioner(upwardOffset: 32))
        .onAppear {
            refreshInterval = selectedRefreshInterval.rawValue
            service.setRefreshInterval(refreshInterval)
            service.setAlertConfiguration(alertConfiguration)
        }
        .onChange(of: refreshInterval) { _, newValue in
            let normalizedInterval = RefreshIntervalOption.normalized(newValue).rawValue
            if refreshInterval != normalizedInterval {
                refreshInterval = normalizedInterval
            }
            service.setRefreshInterval(normalizedInterval)
        }
        .onChange(of: alertConfiguration) { _, configuration in
            service.setAlertConfiguration(configuration)
        }
    }

    @ViewBuilder
    private var popoverBackground: some View {
        if selectedTheme.usesFullWindowGlass {
            ThermalMilkGlassBackdrop(
                isAnimated: !reduceMotion,
                allowsTransparency: !reduceTransparency,
                colorScheme: colorScheme
            )
            .overlay { liquidGlassLightTint }
        } else if selectedTheme == .classic {
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.regularMaterial)
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(palette.windowBackground)
                .overlay {
                    LinearGradient(
                        colors: [palette.gpu.opacity(0.18), .clear, palette.cpu.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
    }

    private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.openApplication(at: url, configuration: .init()) { _, _ in }
    }

    private func toggleVisibility(of kind: SensorKind) {
        if visibleSensorKinds.contains(kind) {
            guard visibleSensorKinds.count > 1 else { return }
            visibleSensorKinds.remove(kind)
        } else {
            visibleSensorKinds.insert(kind)
        }
    }

    private func openGitHub() {
        openPublicURL("https://github.com/Schrotty74/ThermalAtlas")
    }

    private func openHomepage() {
        openPublicURL("https://schrotty74.github.io/Portfolio/")
    }

    private var manualBranch: String {
        Bundle.main.bundleIdentifier == "io.github.schrotty74.thermalatlas" ? "main" : "beta"
    }

    private func openEnglishManual() {
        openPublicURL("https://github.com/Schrotty74/ThermalAtlas/blob/\(manualBranch)/MANUAL.md")
    }

    private func openGermanManual() {
        openPublicURL("https://github.com/Schrotty74/ThermalAtlas/blob/\(manualBranch)/MANUAL.de.md")
    }

    private func openPublicURL(_ address: String) {
        guard let url = URL(string: address) else { return }
        NSWorkspace.shared.open(url)
    }

    private var selectedRefreshInterval: RefreshIntervalOption {
        RefreshIntervalOption.normalized(refreshInterval)
    }

    private var footerActionsMenu: some View {
        Menu {
            themesMenu
            refreshMenu
            windowSizeMenu
            visibleTemperaturesMenu
            menuBarDisplayMenu
            temperatureAlertsMenu
            startAtLoginMenu
            languageMenu
            exportMenu
            Divider()
            Button(action: openGitHub) { Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right") }
            Button(action: openHomepage) { Label("Homepage", systemImage: "globe") }
            Menu(selectedLanguage.manualsMenuTitle) {
                Button(action: openEnglishManual) { Label(selectedLanguage.englishManualTitle, systemImage: "book") }
                Button(action: openGermanManual) { Label(selectedLanguage.germanManualTitle, systemImage: "book") }
            }
            Divider()
            Button(action: openActivityMonitor) { Label(selectedLanguage.activityMonitorTitle, systemImage: "waveform.path.ecg") }
            Divider()
            Button(role: .destructive) { NSApplication.shared.terminate(nil) } label: {
                Label(selectedLanguage.quitTitle, systemImage: "power")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(compactPopover ? .body.weight(.semibold) : .title3.weight(.semibold))
                .foregroundStyle(footerMenuForeground)
                .frame(width: compactPopover ? 26 : 30, height: compactPopover ? 26 : 30)
                .background(footerMenuForeground.opacity(footerMenuBackgroundOpacity), in: Circle())
                .overlay {
                    Circle().stroke(footerMenuForeground.opacity(0.32), lineWidth: 1)
                }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .tint(footerMenuForeground)
        .accessibilityLabel(selectedLanguage.footerMenuAccessibilityLabel)
        .help(selectedLanguage.footerMenuHelp)
    }

    @ViewBuilder
    private var liquidGlassLightTint: some View {
        if colorScheme == .light {
            LinearGradient(
                colors: [
                    Color(red: 0.42, green: 0.78, blue: 1.0).opacity(0.30),
                    Color(red: 0.66, green: 0.54, blue: 1.0).opacity(0.18),
                    Color.white.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var themesMenu: some View {
        Menu(selectedLanguage.themesMenuTitle) {
            ForEach(ThermalTheme.allCases) { theme in
                Button { selectedTheme = theme } label: {
                    Label(theme.displayName(for: selectedLanguage), systemImage: theme == selectedTheme ? "checkmark" : theme.symbol)
                }
                .menuActionDismissBehavior(.enabled)
            }
        }
    }

    private var refreshMenu: some View {
        Menu(selectedLanguage.refreshMenuTitle) {
            ForEach(RefreshIntervalOption.allCases) { option in
                Button { refreshInterval = option.rawValue } label: {
                    Label(option.displayName(for: selectedLanguage), systemImage: option.rawValue == selectedRefreshInterval.rawValue ? "checkmark" : "timer")
                }
                .menuActionDismissBehavior(.enabled)
            }
        }
    }

    private var windowSizeMenu: some View {
        Menu(selectedLanguage.windowSizeMenuTitle) {
            Button { compactPopover = false } label: {
                Label(selectedLanguage.standardWindowSizeTitle, systemImage: compactPopover ? "rectangle" : "checkmark")
            }
            .menuActionDismissBehavior(.enabled)
            Button { compactPopover = true } label: {
                Label(selectedLanguage.compactWindowSizeTitle, systemImage: compactPopover ? "checkmark" : "rectangle.compress.vertical")
            }
            .menuActionDismissBehavior(.enabled)
        }
    }

    private var visibleTemperaturesMenu: some View {
        Menu(selectedLanguage.visibleSensorsMenuTitle) {
            ForEach(SensorKind.allCases) { kind in
                Button { toggleVisibility(of: kind) } label: {
                    Label(kind.title(for: selectedLanguage), systemImage: visibleSensorKinds.contains(kind) ? "checkmark" : kind.symbol)
                }
                .menuActionDismissBehavior(.enabled)
            }
        }
    }

    private var menuBarDisplayMenu: some View {
        Menu(selectedLanguage.menuBarDisplayMenuTitle) {
            ForEach(MenuBarDisplayMode.allCases) { mode in
                Button { menuBarDisplayMode = mode } label: {
                    Label(
                        mode.title(for: selectedLanguage),
                        systemImage: mode == menuBarDisplayMode ? "checkmark" : mode.symbol
                    )
                }
                .menuActionDismissBehavior(.enabled)
            }
        }
    }

    private var temperatureAlertsMenu: some View {
        Menu(selectedLanguage.temperatureAlertsMenuTitle) {
            Button {
                alertsEnabled.toggle()
                service.setAlertConfiguration(alertConfiguration)
            } label: {
                Label(alertsEnabled ? selectedLanguage.alertsEnabledTitle : selectedLanguage.alertsDisabledTitle,
                      systemImage: alertsEnabled ? "checkmark" : "bell.slash")
            }
            .menuActionDismissBehavior(.enabled)
            Divider()
            ForEach(SensorKind.allCases) { kind in
                Menu(kind.title(for: selectedLanguage)) {
                    ForEach(TemperatureAlertSettings.thresholdOptions(for: kind), id: \.self) { threshold in
                        Button {
                            thresholdBinding(for: kind).wrappedValue = threshold
                            service.setAlertConfiguration(alertConfiguration)
                        } label: {
                            Label("\(Int(threshold)) °C", systemImage: thresholdBinding(for: kind).wrappedValue == threshold ? "checkmark" : kind.symbol)
                        }
                        .menuActionDismissBehavior(.enabled)
                    }
                }
            }
        }
    }

    private var exportMenu: some View {
        Menu(selectedLanguage.exportMenuTitle) {
            Button(action: copyCurrentReadings) {
                Label(selectedLanguage.copiedReadingsTitle, systemImage: "doc.on.doc")
            }
            Button(action: exportCSV) {
                Label(selectedLanguage.exportCSVTitle, systemImage: "tablecells")
            }
            Button(action: copyDiagnosticReport) {
                Label(selectedLanguage.copyDiagnosticReportTitle, systemImage: "stethoscope")
            }
        }
    }

    private var startAtLoginMenu: some View {
        Button {
            LaunchAtLogin.setEnabled(!launchAtLoginEnabled)
            launchAtLoginEnabled = LaunchAtLogin.isEnabled
        } label: {
            Label(
                "\(selectedLanguage.startAtLoginMenuTitle): \(launchAtLoginEnabled ? selectedLanguage.startAtLoginEnabledTitle : selectedLanguage.startAtLoginDisabledTitle)",
                systemImage: launchAtLoginEnabled ? "checkmark" : "arrow.right.circle"
            )
        }
        .menuActionDismissBehavior(.enabled)
    }

    private var languageMenu: some View {
        Menu(selectedLanguage.languageMenuTitle) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    selectedLanguage = language
                } label: {
                    Label(
                        language.displayName,
                        systemImage: language == selectedLanguage ? "checkmark" : "character.bubble"
                    )
                }
                .menuActionDismissBehavior(.enabled)
            }
        }
    }

    private var alertConfiguration: TemperatureAlertConfiguration {
        TemperatureAlertConfiguration(
            isEnabled: alertsEnabled,
            cpuThreshold: cpuAlertThreshold,
            gpuThreshold: gpuAlertThreshold,
            internalSSDThreshold: internalSSDAlertThreshold,
            externalSSDThreshold: externalSSDAlertThreshold,
            language: selectedLanguage
        )
    }

    private func thresholdBinding(for kind: SensorKind) -> Binding<Double> {
        switch kind {
        case .cpu: $cpuAlertThreshold
        case .gpu: $gpuAlertThreshold
        case .internalSSD: $internalSSDAlertThreshold
        case .externalSSD: $externalSSDAlertThreshold
        }
    }

    private func copyCurrentReadings() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            TemperatureExport.plainText(snapshot: service.snapshot, language: selectedLanguage),
            forType: .string
        )
    }

    private func exportCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "ThermalAtlas-Readings.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let contents = TemperatureExport.csv(
            snapshot: service.snapshot,
            history: service.history,
            language: selectedLanguage
        )
        try? contents.write(to: url, atomically: true, encoding: .utf8)
    }

    private func copyDiagnosticReport() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            TemperatureExport.diagnosticReport(snapshot: service.snapshot, language: selectedLanguage),
            forType: .string
        )
    }

}

/// Keeps the window-style menu extra close to its status item instead of
/// leaving the large default vertical gap used by macOS for this style.
private struct PopoverWindowPositioner: NSViewRepresentable {
    let upwardOffset: CGFloat

    func makeNSView(context: Context) -> PositioningView {
        PositioningView(upwardOffset: upwardOffset)
    }

    func updateNSView(_ nsView: PositioningView, context: Context) {
        nsView.upwardOffset = upwardOffset
        nsView.positionIfNeeded()
    }

    final class PositioningView: NSView {
        var upwardOffset: CGFloat
        private var appliedInitialOffset = false

        init(upwardOffset: CGFloat) {
            self.upwardOffset = upwardOffset
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            appliedInitialOffset = false
            positionIfNeeded()
        }

        func positionIfNeeded() {
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window else { return }
                PopoverWindowCoordinator.window = window

                guard !appliedInitialOffset, let screen = window.screen else { return }
                let highestOriginY = screen.visibleFrame.maxY - window.frame.height
                let raisedOriginY = min(window.frame.origin.y + upwardOffset, highestOriginY)
                if raisedOriginY > window.frame.origin.y {
                    window.setFrameOrigin(NSPoint(x: window.frame.origin.x, y: raisedOriginY))
                }
                appliedInitialOffset = true
            }
        }
    }
}

/// Owns the outer `NSWindow` size while a card's chart is expanded. SwiftUI's
/// menu-bar window does not automatically adopt an asynchronously expanded
/// card, so resize the actual AppKit window at the same interaction boundary.
@MainActor
private enum PopoverWindowCoordinator {
    weak static var window: NSWindow?

    static func adjustForHistory(isOpening: Bool, compact: Bool) {
        guard let window else { return }
        let delta: CGFloat = compact ? 126 : 178
        let previousFrame = window.frame
        let newHeight = max(1, previousFrame.height + (isOpening ? delta : -delta))
        let newFrame = NSRect(
            x: previousFrame.origin.x,
            y: previousFrame.maxY - newHeight,
            width: previousFrame.width,
            height: newHeight
        )
        window.setFrame(newFrame, display: true, animate: true)
    }
}

/// Keeps sensor-refresh observation out of `ThermalPopover` itself, so an
/// open footer submenu is not recreated each time the readings refresh.
private struct ThermalSensorCards: View {
    let service: SensorService
    let visibleSensorKinds: Set<SensorKind>
    let selectedTheme: ThermalTheme
    let language: AppLanguage
    let compact: Bool
    let history: TemperatureHistoryStore
    let alertConfiguration: TemperatureAlertConfiguration

    var body: some View {
        let snapshot = service.snapshot
        VStack(spacing: compact ? 7 : 11) {
            ForEach(snapshot.readings.filter { visibleSensorKinds.contains($0.kind) }) {
                SensorCard(
                    reading: $0,
                    snapshotUpdatedAt: snapshot.updatedAt,
                    selectedTheme: selectedTheme,
                    language: language,
                    compact: compact,
                    history: history,
                    alertThreshold: alertConfiguration.threshold(for: $0.kind)
                )
            }
        }
    }
}

/// Keeps the timestamp responsive without invalidating the footer's action menu.
private struct ThermalUpdateStatus: View {
    let service: SensorService
    let language: AppLanguage

    private var formattedUpdateTime: String {
        service.snapshot.updatedAt.formatted(
            .dateTime.hour().minute().second().locale(language.locale)
        )
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.clockwise")
            Text("\(language.updatedPrefix) \(formattedUpdateTime)")
                .lineLimit(1)
                .accessibilityLabel(language == .english ? "Last updated \(formattedUpdateTime)" : "Zuletzt aktualisiert \(formattedUpdateTime)")
        }
    }
}

/// A separate read-only system-status area. Its values provide interpretation
/// for temperatures, but are deliberately not presented as sensor readings.
private struct ThermalSystemContext: View {
    let service: SensorService
    let palette: ThermalThemePalette
    let language: AppLanguage
    let compact: Bool

    private var context: SystemContext { service.systemContext }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 7) {
            HStack(spacing: 5) {
                Image(systemName: "bolt.circle")
                Text(language.systemContextTitle)
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                Spacer()
                Text(language.systemContextHint)
                    .font(.caption2)
                    .foregroundStyle(palette.secondary.opacity(0.75))
                    .lineLimit(1)
            }
            .foregroundStyle(palette.secondary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: compact ? 7 : 10), count: compact ? 2 : 3),
                alignment: .leading,
                spacing: compact ? 7 : 10
            ) {
                contextItem(
                    title: language.cpuLoadTitle,
                    value: cpuUsageText,
                    symbol: "chart.bar.fill",
                    tint: palette.cpu
                )
                contextItem(
                    title: language.gpuLoadTitle,
                    value: gpuUsageText,
                    symbol: "rectangle.3.group.fill",
                    tint: palette.gpu
                )
                contextItem(
                    title: memoryTitle,
                    value: memoryUsageText,
                    symbol: "memorychip.fill",
                    tint: memoryTint
                )
                contextItem(
                    title: language.powerSourceTitle,
                    value: powerText,
                    symbol: powerSymbol,
                    tint: palette.gpu
                )
                contextItem(
                    title: language.lowPowerModeTitle,
                    value: context.isLowPowerModeEnabled ? language.enabledTitle : language.disabledTitle,
                    symbol: "leaf.fill",
                    tint: context.isLowPowerModeEnabled ? .green : palette.secondary
                )
            }
        }
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, compact ? 8 : 10)
        .background(palette.title.opacity(0.055), in: RoundedRectangle(cornerRadius: compact ? 11 : 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: compact ? 11 : 14, style: .continuous)
                .stroke(palette.secondary.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func contextItem(title: String, value: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: compact ? 4 : 6) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption2).foregroundStyle(palette.secondary)
                Text(value)
                    .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cpuUsageText: String {
        guard let usage = context.cpuUsagePercent else { return language.calculatingTitle }
        return usage.formatted(.number.precision(.fractionLength(0))) + " %"
    }

    private var gpuUsageText: String {
        guard let usage = context.gpuUsagePercent else { return language.notAvailable }
        return usage.formatted(.number.precision(.fractionLength(0))) + " %"
    }

    private var memoryUsageText: String {
        guard let memory = context.memoryUsage else { return language.notAvailable }
        let gigabyte = Double(1 << 30)
        let used = Double(memory.usedBytes) / gigabyte
        let total = Double(memory.totalBytes) / gigabyte
        if total >= 10 {
            return "\(used.formatted(.number.precision(.fractionLength(0)))) / \(total.formatted(.number.precision(.fractionLength(0)))) GB"
        }
        return "\(used.formatted(.number.precision(.fractionLength(1)))) / \(total.formatted(.number.precision(.fractionLength(1)))) GB"
    }

    private var memoryTitle: String {
        guard let memory = context.memoryUsage else { return language.memoryUsageTitle }
        return "\(language.memoryUsageTitle) · \(memory.loadStatus.title(for: language))"
    }

    private var memoryTint: Color {
        guard let memory = context.memoryUsage else { return palette.internalSSD }
        return switch memory.loadStatus {
        case .normal: Color.green
        case .elevated: Color.orange
        case .high: Color.red
        }
    }

    private var powerText: String {
        switch context.powerSource {
        case .powerAdapter:
            return language.powerAdapterTitle
        case let .battery(percentage):
            guard let percentage else { return language.batteryTitle }
            return "\(language.batteryTitle) \(percentage) %"
        case .unavailable:
            return language.notAvailable
        }
    }

    private var powerSymbol: String {
        switch context.powerSource {
        case .powerAdapter: "powerplug.fill"
        case .battery: "battery.75percent"
        case .unavailable: "battery.0"
        }
    }
}

private struct SensorCard: View {
    let reading: TemperatureReading
    let snapshotUpdatedAt: Date
    let selectedTheme: ThermalTheme
    let language: AppLanguage
    let compact: Bool
    let history: TemperatureHistoryStore
    let alertThreshold: Double
    @State private var hasAppeared = false
    @State private var showsHistory = false
    @State private var showsDetails = false
    @State private var historyRange: TemperatureHistoryRange = .oneHour
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThermalThemePalette { selectedTheme.palette }
    private var componentColor: Color { palette.componentColor(for: reading.kind) }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 10) {
            HStack(spacing: compact ? 8 : 12) {
            Image(systemName: reading.kind.symbol)
                .font(compact ? .subheadline.weight(.semibold) : .headline.weight(.semibold))
                .frame(width: compact ? 24 : 30, height: compact ? 24 : 30)
                .foregroundStyle(componentColor)
                .background(componentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: compact ? 7 : 9, style: .continuous))
            VStack(alignment: .leading, spacing: compact ? 1 : 3) {
                Text(reading.title ?? reading.kind.title(for: language))
                    .font(compact ? .subheadline.weight(.medium) : .body.weight(.medium))
                    .foregroundStyle(palette.title)
                if let subtitle {
                    HStack(spacing: compact ? 2 : 4) {
                        if reading.isLastVerifiedValue {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        Text(subtitle)
                    }
                    .font(compact ? .caption2.weight(.medium) : .caption.weight(.medium))
                    .foregroundStyle(reading.isLastVerifiedValue ? .orange : palette.title.opacity(0.76))
                    .lineLimit(1)
                }
                if let smartStatus = reading.smartStatus {
                    Text(smartStatus.localized(for: language))
                        .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                        .foregroundStyle(smartStatusColor(for: smartStatus))
                        .lineLimit(1)
                    if let smartHealthPercentage = reading.smartHealthPercentage {
                        Text("\(language.healthPrefix): \(smartHealthPercentage) %")
                            .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                            .foregroundStyle(palette.title.opacity(0.90))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: compact ? 2 : 4) {
                Text(temperatureText)
                    .font(compact ? .title3.weight(.semibold) : .title2.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                statusAndDetails
            }
        }
            if showsHistory {
                TemperatureHistoryChart(
                    points: history.points(for: reading.id, range: historyRange),
                    range: $historyRange,
                    threshold: alertThreshold,
                    componentColor: componentColor,
                    palette: palette,
                    language: language,
                    compact: compact
                )
            }
        }
        .padding(.horizontal, compact ? 9 : 13).padding(.vertical, compact ? 8 : 12)
        .background {
            cardBackground
        }
        .overlay {
            RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous)
                .stroke(componentColor.opacity(palette.cardStrokeOpacity), lineWidth: 1)
        }
        .shadow(color: componentColor.opacity(0.09), radius: compact ? 6 : 10, y: compact ? 2 : 4)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 7)
        .task {
            guard !hasAppeared else { return }
            withAnimation(.easeOut(duration: 0.35)) { hasAppeared = true }
        }
        .animation(.easeInOut(duration: 0.3), value: reading.temperatureCelsius)
        .contentShape(RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous))
        .onTapGesture {
            let isOpening = !showsHistory
            withAnimation(.easeInOut(duration: 0.2)) { showsHistory.toggle() }
            PopoverWindowCoordinator.adjustForHistory(isOpening: isOpening, compact: compact)
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if selectedTheme == .classic {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .overlay { cardTint }
        } else if selectedTheme.usesFullWindowGlass {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(reduceTransparency ? AnyShapeStyle(liquidGlassFallback) : AnyShapeStyle(.ultraThinMaterial))
                .overlay { liquidGlassReflection }
                .overlay { cardTint }
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.cardBase)
                .overlay { cardTint }
        }
    }

    private var liquidGlassFallback: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.11, blue: 0.16)
            : Color(red: 0.82, green: 0.93, blue: 0.99)
    }

    private var liquidGlassReflection: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.24),
                colorScheme == .dark ? Color.white.opacity(0.025) : Color.cyan.opacity(0.12),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(reduceTransparency ? 0.35 : 1)
    }

    private var cardTint: some View {
        LinearGradient(
            colors: [componentColor.opacity(0.18), componentColor.opacity(0.035)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var subtitle: String? {
        if reading.isLastVerifiedValue { return language.lastRealGPUValue }
        guard reading.temperatureCelsius != nil else { return reading.unavailableReason?.localized(for: language) }
        switch reading.kind {
        case .cpu: return language.averageCPUSensors
        case .gpu: return language.averageGPUSensors
        case .internalSSD, .externalSSD: return nil
        }
    }

    private var statusAndDetails: some View {
        HStack(spacing: compact ? 3 : 5) {
            Circle().fill(statusColor).frame(width: compact ? 4 : 6, height: compact ? 4 : 6)
            Capsule().fill(statusColor).frame(width: compact ? 16 : 23, height: compact ? 3 : 4)
            Button {
                showsDetails = true
            } label: {
                Image(systemName: "info.circle")
                    .font(compact ? .caption : .caption.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(palette.secondary)
            .accessibilityLabel(language.sensorDetailsTitle)
            .popover(isPresented: $showsDetails, arrowEdge: .trailing) {
                SensorDetailsView(
                    reading: reading,
                    snapshotUpdatedAt: snapshotUpdatedAt,
                    language: language,
                    palette: palette
                )
            }
        }
    }

    private func smartStatusColor(for status: SMARTStatus) -> Color {
        if status == .verified { return .green }
        if status == .failing { return .red }
        return palette.secondary
    }
    private var temperatureText: String {
        guard let temperature = reading.temperatureCelsius else { return language.notAvailable }
        return "\(temperature.formatted(.number.precision(.fractionLength(1))))°"
    }
    private var statusColor: Color {
        guard let temperature = reading.temperatureCelsius else { return .gray }
        switch temperature {
        case ..<55: return Color.green
        case ..<75: return Color.orange
        default: return Color.red
        }
    }
}

private struct TemperatureHistoryChart: View {
    let points: [TemperatureHistoryPoint]
    @Binding var range: TemperatureHistoryRange
    let threshold: Double
    let componentColor: Color
    let palette: ThermalThemePalette
    let language: AppLanguage
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            if compact {
                Text(language.temperatureHistoryTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(palette.title.opacity(0.9))
                historyRangePicker
                    .frame(maxWidth: .infinity)
            } else {
                HStack {
                    Text(language.temperatureHistoryTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.title.opacity(0.9))
                    Spacer()
                    historyRangePicker
                        .frame(width: 172)
                }
            }

            if points.count < 2 {
                Text(language.collectingHistoryTitle)
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(palette.secondary)
                    .frame(maxWidth: .infinity, minHeight: compact ? 42 : 58, alignment: .center)
            } else {
                Chart {
                    ForEach(points) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Temperature", point.averageTemperature)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(componentColor)
                        .lineStyle(StrokeStyle(lineWidth: compact ? 1.5 : 2, lineCap: .round, lineJoin: .round))
                    }
                    RuleMark(y: .value("Warning threshold", threshold))
                        .foregroundStyle(.orange.opacity(0.65))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                            .foregroundStyle(palette.secondary.opacity(0.25))
                        AxisValueLabel(format: .dateTime.hour().minute())
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
                .frame(height: compact ? 72 : 96)
            }

            Text(language.historyHint)
                .font(.caption2)
                .foregroundStyle(palette.secondary.opacity(0.8))
        }
        .padding(.top, compact ? 1 : 2)
    }

    private var historyRangePicker: some View {
        Picker(language.temperatureHistoryTitle, selection: $range) {
            ForEach(TemperatureHistoryRange.allCases) { value in
                Text(value.title(for: language)).tag(value)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .controlSize(.small)
    }
}

private struct SensorDetailsView: View {
    let reading: TemperatureReading
    let snapshotUpdatedAt: Date
    let language: AppLanguage
    let palette: ThermalThemePalette

    private var title: String { reading.title ?? reading.kind.title(for: language) }
    private var lastValidAt: Date? {
        guard reading.temperatureCelsius != nil else { return nil }
        return reading.lastVerifiedAt ?? snapshotUpdatedAt
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: reading.kind.symbol)
                .font(.headline)
                .foregroundStyle(palette.componentColor(for: reading.kind))
            detailRow(language.sourceTitle, reading.kind.sourceDescription(for: language))
            if let sourceIdentifier = reading.sourceIdentifier {
                detailRow("ID", sourceIdentifier)
            }
            detailRow(language.lastValidValueTitle, temperatureText)
            detailRow(language.lastValidTimeTitle, timeText)
            if let detail = reading.detail {
                detailRow(language == .english ? "Reading" : "Messwert", detail)
            }
        }
        .padding(14)
        .frame(width: 280, alignment: .leading)
    }

    private var temperatureText: String {
        guard let temperature = reading.temperatureCelsius else { return language.notAvailable }
        return "\(temperature.formatted(.number.precision(.fractionLength(1)))) °C"
    }

    private var timeText: String {
        guard let lastValidAt else { return language.notAvailable }
        return lastValidAt.formatted(.dateTime.hour().minute().second().locale(language.locale))
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.callout).textSelection(.enabled)
        }
    }
}
