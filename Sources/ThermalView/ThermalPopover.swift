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

struct ThermalPopover: View {
    let service: SensorService
    let appUpdateService: AppUpdateService
    @Binding var selectedTheme: ThermalTheme
    @Binding var refreshInterval: Double
    @Binding var selectedLanguage: AppLanguage
    @Binding var visibleSensorKinds: Set<SensorKind>
    @Binding var menuBarDisplayMode: MenuBarDisplayMode
    @Binding var compactPopover: Bool
    @Binding var miniDisplayVisible: Bool
    @Binding var alwaysOnTop: Bool
    @Binding var alertsEnabled: Bool
    @Binding var cpuAlertThreshold: Double
    @Binding var gpuAlertThreshold: Double
    @Binding var internalSSDAlertThreshold: Double
    @Binding var externalSSDAlertThreshold: Double
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThermalThemePalette { selectedTheme.palette(for: colorScheme) }
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
                    Button { SystemInformationWindow.show(language: selectedLanguage, theme: selectedTheme) } label: {
                        Image(systemName: "thermometer.medium")
                            .font(compactPopover ? .title3.weight(.medium) : .title2.weight(.medium))
                            .foregroundStyle(palette.gpu)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .thermalGlassButtonStyle(
                        isEnabled: selectedTheme.usesFullWindowGlass,
                        tint: palette.gpu
                    )
                    .accessibilityLabel(selectedLanguage.systemInformationButtonLabel)
                    .help(selectedLanguage.systemInformationButtonLabel)
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
                .stroke(selectedTheme.usesFullWindowGlass ? Color.white.opacity(0.34) : palette.surfaceStroke(accent: palette.gpu, opacity: 0.16), lineWidth: 1)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: selectedTheme)
        .background(ThermalWindowConfigurator())
        .onAppear {
            refreshInterval = selectedRefreshInterval.rawValue
            service.setRefreshInterval(refreshInterval)
            service.setAlertConfiguration(alertConfiguration)
            PopoverWindowCoordinator.setAlwaysOnTop(alwaysOnTop)
        }
        .onChange(of: refreshInterval) { _, newValue in
            let normalizedInterval = RefreshIntervalOption.normalized(newValue).rawValue
            if refreshInterval != normalizedInterval {
                refreshInterval = normalizedInterval
            }
            service.setRefreshInterval(normalizedInterval)
        }
        .onChange(of: compactPopover) { _, isCompact in
            PopoverWindowCoordinator.adjustForCompactMode(isCompact)
        }
        .onChange(of: miniDisplayVisible) { _, _ in
            NotificationCenter.default.post(name: .thermalAtlasMiniDisplayVisibilityChanged, object: nil)
        }
        .onChange(of: alwaysOnTop) { _, isEnabled in
            PopoverWindowCoordinator.setAlwaysOnTop(isEnabled)
            NotificationCenter.default.post(name: .thermalAtlasMiniAlwaysOnTopChanged, object: nil)
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
        } else if palette.usesNeutralSurfaces {
            palette.windowBackground
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
            languageMenu
            exportMenu
            alwaysOnTopMenuItem
            startAtLoginMenu
            AppUpdatesMenu(service: appUpdateService, language: selectedLanguage)
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
            Button {
                compactPopover = false
                miniDisplayVisible = false
            } label: {
                Label(selectedLanguage.standardWindowSizeTitle, systemImage: compactPopover ? "rectangle" : "checkmark")
            }
            .menuActionDismissBehavior(.enabled)
            Button {
                compactPopover = true
                miniDisplayVisible = false
            } label: {
                Label(selectedLanguage.compactWindowSizeTitle, systemImage: compactPopover ? "checkmark" : "rectangle.compress.vertical")
            }
            .menuActionDismissBehavior(.enabled)
            Button { miniDisplayVisible.toggle() } label: {
                Label(
                    selectedLanguage.miniDisplayTitle,
                    systemImage: miniDisplayVisible ? "checkmark" : "rectangle"
                )
            }
            .menuActionDismissBehavior(.enabled)
        }
    }

    private var alwaysOnTopMenuItem: some View {
        Button { alwaysOnTop.toggle() } label: {
            Label(
                selectedLanguage.alwaysOnTopTitle,
                systemImage: alwaysOnTop ? "checkmark" : "pin"
            )
        }
        .menuActionDismissBehavior(.enabled)
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
        while true {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "ThermalAtlas-Readings.csv"
            panel.allowedContentTypes = [.commaSeparatedText]
            guard panel.runModal() == .OK, let url = panel.url else { return }
            let contents = TemperatureExport.csv(
                snapshot: service.snapshot,
                history: service.history,
                language: selectedLanguage
            )
            do {
                try contents.write(to: url, atomically: true, encoding: .utf8)
                return
            } catch {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = selectedLanguage.csvSaveErrorTitle
                alert.informativeText = selectedLanguage.csvSaveErrorMessage + "\n\n" + error.localizedDescription
                alert.addButton(withTitle: selectedLanguage.retryTitle)
                alert.addButton(withTitle: selectedLanguage.closeTitle)
                guard alert.runModal() == .alertFirstButtonReturn else { return }
            }
        }
    }

    private func copyDiagnosticReport() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            TemperatureExport.diagnosticReport(snapshot: service.snapshot, language: selectedLanguage),
            forType: .string
        )
    }

}

private struct SystemInformationWindowContent: View {
    let language: AppLanguage
    let theme: ThermalTheme
    let close: () -> Void
    @State private var systemInformation: SystemInformationSnapshot?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThermalThemePalette { theme.palette(for: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if let systemInformation {
                overviewCards(systemInformation)
                hardwareCards(systemInformation)
                operatingSystemCard(systemInformation)
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(language.systemInformationLoadingTitle)
                }
                .foregroundStyle(palette.secondary)
                .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            }

            HStack {
                Spacer()
                Button(language.closeTitle, action: close)
                    .tint(palette.gpu)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 470, alignment: .leading)
        .foregroundStyle(palette.title)
        .background { windowBackground }
        .task {
            guard systemInformation == nil else { return }
            systemInformation = await Task.detached(priority: .userInitiated) {
                SystemInformationReader.read()
            }.value
        }
    }

    @ViewBuilder
    private var windowBackground: some View {
        if theme.usesFullWindowGlass {
            ThermalMilkGlassBackdrop(
                isAnimated: !reduceTransparency,
                allowsTransparency: !reduceTransparency,
                colorScheme: colorScheme
            )
        } else if theme == .classic {
            Color(nsColor: .windowBackgroundColor)
        } else {
            palette.windowBackground
                .overlay {
                    LinearGradient(
                        colors: [palette.gpu.opacity(0.22), .clear, palette.cpu.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 13) {
            Image(systemName: "info.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(palette.gpu)
                .frame(width: 40, height: 40)
                .background(palette.gpu.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(language.systemInformationTitle)
                    .font(.title3.weight(.semibold))
                Text("ThermalAtlas")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.secondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func overviewCards(_ information: SystemInformationSnapshot) -> some View {
        LazyVGrid(columns: informationColumns, spacing: 8) {
            machineCard(information)
            thermalStateCard(information)
        }
    }

    private var informationColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    }

    @ViewBuilder
    private func machineCard(_ information: SystemInformationSnapshot) -> some View {
        HStack(spacing: 9) {
            Spacer(minLength: 0)
            Image(systemName: "desktopcomputer")
                .font(.headline.weight(.medium))
                .foregroundStyle(palette.gpu)
                .frame(width: 28, height: 28)
                .background(palette.gpu.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(language.macModelTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(palette.secondary)
                Text(information.macModel)
                    .font(.caption.weight(.semibold))
                    .textSelection(.enabled)
                Text(information.chip)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(palette.cpu)
                    .textSelection(.enabled)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 62, maxHeight: 62, alignment: .center)
        .padding(.horizontal, 10)
        .systemInformationCardSurface(palette: palette, theme: theme, cornerRadius: 31)
    }

    @ViewBuilder
    private func hardwareCards(_ information: SystemInformationSnapshot) -> some View {
        LazyVGrid(columns: informationColumns, spacing: 8) {
            informationCard(
                title: language.cpuCoresTitle,
                value: compactCPUCoreDescription(information),
                symbol: "cpu",
                color: palette.cpu
            )
            informationCard(
                title: language.gpuCoresTitle,
                value: language.gpuCoreDescription(information.gpuCoreCount),
                symbol: "rectangle.3.group.fill",
                color: palette.gpu
            )
            informationCard(
                title: language.memoryTitle,
                value: information.memory,
                symbol: "memorychip.fill",
                color: palette.internalSSD
            )
            informationCard(
                title: language.storageTitle,
                value: information.storage,
                symbol: "internaldrive.fill",
                color: palette.externalSSD
            )
        }
    }

    @ViewBuilder
    private func thermalStateCard(_ information: SystemInformationSnapshot) -> some View {
        informationCard(
            title: language.thermalStateTitle,
            value: language.thermalStateDescription(information.thermalState),
            symbol: "thermometer.medium",
            color: palette.cpu
        )
    }

    @ViewBuilder
    private func operatingSystemCard(_ information: SystemInformationSnapshot) -> some View {
        HStack(spacing: 11) {
            Spacer(minLength: 0)
            Image(systemName: "apple.logo")
                .font(.title3.weight(.medium))
                .foregroundStyle(palette.title)
                .frame(width: 34, height: 34)
                .background(palette.title.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(language.operatingSystemTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondary)
                Text(information.operatingSystem)
                    .font(.subheadline.weight(.medium))
                    .textSelection(.enabled)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .systemInformationCardSurface(palette: palette, theme: theme)
    }

    @ViewBuilder
    private func informationCard(title: String, value: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 9) {
            Spacer(minLength: 0)
            Image(systemName: symbol)
                .font(.headline.weight(.medium))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 62, maxHeight: 62, alignment: .center)
        .padding(.horizontal, 10)
        .systemInformationCardSurface(palette: palette, theme: theme, cornerRadius: 31)
    }

    private func compactCPUCoreDescription(_ information: SystemInformationSnapshot) -> String {
        guard let total = information.cpuCoreCount else { return language.notAvailable }
        guard let performance = information.performanceCoreCount, let efficiency = information.efficiencyCoreCount else {
            return language == .english ? "\(total) cores" : "\(total) Kerne"
        }
        return language == .english
            ? "\(total) cores · \(performance)P · \(efficiency)E"
            : "\(total) Kerne · \(performance)P · \(efficiency)E"
    }
}

private extension View {
    func systemInformationCardSurface(
        palette: ThermalThemePalette,
        theme: ThermalTheme,
        cornerRadius: CGFloat = 14
    ) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme == .classic ? Color(nsColor: .controlBackgroundColor).opacity(0.72) : palette.cardBase)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(palette.surfaceStroke(accent: palette.gpu, opacity: theme.usesFullWindowGlass ? 0.30 : palette.cardStrokeOpacity), lineWidth: 1)
        }
    }
}

/// Presents system information in its own AppKit window. A separate panel is
/// necessary here because a sheet attached to a window-style `MenuBarExtra`
/// can remain cached by macOS after the menu window is reopened.
@MainActor
private enum SystemInformationWindow {
    private static var panel: NSPanel?

    static func show(language: AppLanguage, theme: ThermalTheme) {
        if let panel {
            panel.title = language.systemInformationTitle
            panel.contentView = hostingView(language: language, theme: theme)
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 470, height: 470),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = language.systemInformationTitle
        panel.isReleasedWhenClosed = false
        panel.contentView = hostingView(language: language, theme: theme)
        panel.center()
        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    static func close() {
        panel?.close()
        panel = nil
    }

    private static func hostingView(language: AppLanguage, theme: ThermalTheme) -> NSHostingView<SystemInformationWindowContent> {
        NSHostingView(rootView: SystemInformationWindowContent(language: language, theme: theme, close: close))
    }
}

/// Connects the SwiftUI content to the independent AppKit window that owns its
/// frame and size. It deliberately does not restore or move the window: macOS
/// preserves an independent panel's position through minimize and restore.
private struct ThermalWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfigurationView {
        ConfigurationView(frame: .zero)
    }

    func updateNSView(_ nsView: ConfigurationView, context: Context) {
        nsView.configureWindow()
    }

    @MainActor
    final class ConfigurationView: NSView {
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
        }

        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureWindow()
        }

        func configureWindow() {
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window else { return }
                PopoverWindowCoordinator.window = window
                window.isMovable = true
                window.isMovableByWindowBackground = true
            }
        }
    }
}

/// Owns the outer `NSWindow` size while a card's chart is expanded. SwiftUI's
/// menu-bar window does not automatically adopt an asynchronously expanded
/// card, so resize the actual AppKit window at the same interaction boundary.
@MainActor
enum PopoverWindowCoordinator {
    weak static var window: NSWindow?

    static func adjustForHistory(isOpening: Bool, compact: Bool) {
        DispatchQueue.main.async {
            guard let window else { return }
            window.contentView?.layoutSubtreeIfNeeded()
            let previousFrame = window.frame
            let fallbackDelta: CGFloat = compact ? 126 : 178
            let fittedHeight = window.contentView?.fittingSize.height ?? 0
            let contentWidth = window.contentRect(forFrameRect: previousFrame).width
            let newHeight = fittedHeight > 0
                ? window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: contentWidth, height: fittedHeight)).height
                : max(1, previousFrame.height + (isOpening ? fallbackDelta : -fallbackDelta))
            let newFrame = NSRect(
                x: previousFrame.origin.x,
                y: previousFrame.maxY - newHeight,
                width: previousFrame.width,
                height: newHeight
            )
            window.setFrame(newFrame, display: true, animate: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        }
    }

    static func adjustForCompactMode(_ isCompact: Bool) {
        DispatchQueue.main.async {
            guard let window else { return }
            window.contentView?.layoutSubtreeIfNeeded()
            let currentFrame = window.frame
            let fittedContentSize = window.contentView?.fittingSize
                ?? window.contentRect(forFrameRect: currentFrame).size
            let contentSize = NSSize(
                width: isCompact ? 230 : 370,
                height: max(1, fittedContentSize.height)
            )
            var newFrame = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize))
            newFrame.origin = NSPoint(x: currentFrame.origin.x, y: currentFrame.maxY - newFrame.height)
            window.setFrame(newFrame, display: true, animate: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        }
    }

    static func setAlwaysOnTop(_ isEnabled: Bool) {
        guard let window else { return }
        window.level = isEnabled ? .floating : .normal
        if isEnabled {
            window.orderFrontRegardless()
        }
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

    @State private var selectedFanIndex: Int?
    @State private var showsContextHint = false

    private var context: SystemContext { service.systemContext }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 7) {
            HStack {
                Label(language.systemContextTitle, systemImage: "bolt.circle")
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                Spacer(minLength: 4)
                Button { showsContextHint = true } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(language.systemContextHint)
                .help(language.systemContextHint)
                .popover(isPresented: $showsContextHint) {
                    Text(language.systemContextHint)
                        .padding(12)
                        .frame(width: 260, alignment: .leading)
                        .fixedSize()
                }
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
                if context.fanSpeeds.isEmpty {
                    contextItem(
                        title: language.fanSpeedTitle,
                        value: language.notAvailable,
                        symbol: "fanblades.fill",
                        tint: palette.secondary
                    )
                } else {
                    ForEach(context.fanSpeeds, id: \.index) { fan in
                        fanButton(fan)
                    }
                }
                contextItem(
                    title: memoryTitle,
                    value: memoryUsageText,
                    symbol: "memorychip.fill",
                    tint: memoryTint
                )
                contextItem(
                    title: language == .german ? "Stromquelle" : language.powerSourceTitle,
                    value: powerText,
                    symbol: powerSymbol,
                    tint: palette.gpu
                )
                contextItem(
                    title: language == .german ? "Sparmodus" : "Low Power",
                    value: context.isLowPowerModeEnabled ? language.enabledTitle : language.disabledTitle,
                    symbol: "leaf.fill",
                    tint: context.isLowPowerModeEnabled ? .green : palette.secondary
                )
            }
        }
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, 8)
        .background(palette.title.opacity(0.055), in: RoundedRectangle(cornerRadius: compact ? 11 : 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: compact ? 11 : 14, style: .continuous)
                .stroke(palette.secondary.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func fanButton(_ fan: SMCFanSpeedReader.Fan) -> some View {
        let title = context.fanSpeeds.count == 1 ? language.fanSpeedTitle : "\(language.fanSpeedTitle) \(fan.index + 1)"
        return Button { selectedFanIndex = fan.index } label: {
            contextItem(title: title, value: "\(fan.rpm.formatted(.number.locale(language.locale))) RPM",
                        symbol: "fanblades.fill", tint: palette.secondary)
        }
        .buttonStyle(.plain)
        .help(language.fanHistoryTitle)
        .accessibilityLabel("\(title), \(fan.rpm) RPM")
        .accessibilityHint(language.fanHistoryTitle)
        .popover(isPresented: Binding(get: { selectedFanIndex == fan.index }, set: { if !$0 { selectedFanIndex = nil } })) {
            FanHistoryView(history: service.fanHistory, index: fan.index, title: title, palette: palette, language: language)
        }
    }

    private func contextItem(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: symbol)
                .font(.caption2)
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(value)
                .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                .foregroundStyle(palette.title)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
        .help("\(title): \(value)")
    }

    private var cpuUsageText: String {
        guard let usage = context.cpuUsagePercent else { return language.calculatingTitle }
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
        return "RAM · \(memory.loadStatus.title(for: language))"
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThermalThemePalette { selectedTheme.palette(for: colorScheme) }
    private var componentColor: Color { palette.componentColor(for: reading.kind) }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 10) {
            HStack(alignment: .bottom, spacing: compact ? 3 : 5) {
                Button(action: toggleHistory) {
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
                                    if reading.isLastVerifiedValue, let date = reading.lastVerifiedAt ?? reading.measuredAt {
                                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                                            Text("\(language.measurementAge(since: date, now: timeline.date)) · \(language == .english ? "Last reading" : "Letzter Wert")")
                                        }
                                    } else {
                                        Text(subtitle)
                                    }
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
                            statusIndicator
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(reading.title ?? reading.kind.title(for: language))
                .accessibilityValue("\(temperatureText), \(showsHistory ? language.sensorHistoryShownAccessibilityValue : language.sensorHistoryHiddenAccessibilityValue)")
                .accessibilityHint(language.sensorHistoryAccessibilityHint)
                sensorDetailsButton
            }
            if showsHistory {
                HistoryChart(
                    points: history.points(for: reading.id, range: historyRange).map { HistoryChartPoint(date: $0.date, value: $0.averageTemperature) },
                    range: $historyRange,
                    threshold: alertThreshold,
                    componentColor: componentColor,
                    palette: palette,
                    language: language,
                    compact: compact,
                    title: language.temperatureHistoryTitle,
                    unit: "°C",
                    fractionDigits: 1
                )
            }
        }
    }

    var body: some View {
        styledCard
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 7)
            .task { revealCard() }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: reading.temperatureCelsius)
            .contentShape(RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous))

    }

    private var styledCard: some View {
        cardContent
            .padding(.horizontal, compact ? 9 : 13)
            .padding(.vertical, compact ? 8 : 12)
            .background { cardBackground }
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous)
                    .stroke(palette.surfaceStroke(accent: componentColor), lineWidth: 1)
            }
            .shadow(color: palette.usesNeutralSurfaces ? .black.opacity(colorScheme == .dark ? 0.12 : 0.06) : componentColor.opacity(0.09), radius: compact ? 6 : 10, y: compact ? 2 : 4)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if palette.usesNeutralSurfaces {
            RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous)
                .fill(palette.cardBase)
        } else if selectedTheme == .classic {
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

    private func toggleHistory() {
        let isOpening = !showsHistory
        if reduceMotion {
            showsHistory.toggle()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { showsHistory.toggle() }
        }
        PopoverWindowCoordinator.adjustForHistory(isOpening: isOpening, compact: compact)
    }

    private func revealCard() {
        guard !hasAppeared else { return }
        if reduceMotion {
            hasAppeared = true
        } else {
            withAnimation(.easeOut(duration: 0.35)) { hasAppeared = true }
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: compact ? 3 : 5) {
            Circle().fill(statusColor).frame(width: compact ? 4 : 6, height: compact ? 4 : 6)
            Capsule().fill(statusColor).frame(width: compact ? 16 : 23, height: compact ? 3 : 4)
        }
        .accessibilityHidden(true)
    }

    private var sensorDetailsButton: some View {
        Button { showsDetails = true } label: {
            Image(systemName: "info.circle")
                .font(compact ? .caption : .caption.weight(.semibold))
                .padding(2)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(palette.secondary)
        .accessibilityLabel("\(reading.title ?? reading.kind.title(for: language)): \(language.sensorDetailsTitle)")
        .help(language.sensorDetailsTitle)
        .popover(isPresented: $showsDetails, arrowEdge: .trailing) {
            SensorDetailsView(reading: reading, snapshotUpdatedAt: snapshotUpdatedAt,
                              language: language, palette: palette)
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

private extension View {
    @ViewBuilder
    func thermalGlassButtonStyle(isEnabled: Bool, tint: Color) -> some View {
        if isEnabled, #available(macOS 27.0, *) {
            buttonStyle(.glass(.regular.tint(tint).interactive()))
        } else {
            buttonStyle(.plain)
        }
    }
}

private struct SensorDetailsView: View {
    let reading: TemperatureReading
    let snapshotUpdatedAt: Date
    let language: AppLanguage
    let palette: ThermalThemePalette

    private var title: String { reading.title ?? reading.kind.title(for: language) }
    private var chipName: String? {
        AppleSiliconSMCTemperatureBackend.detectedChipNameForDiagnostics()
    }
    private var lastValidAt: Date? {
        if let lastVerifiedAt = reading.lastVerifiedAt { return lastVerifiedAt }
        guard reading.temperatureCelsius != nil else { return nil }
        return reading.measuredAt ?? snapshotUpdatedAt
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: reading.kind.symbol)
                .font(.headline)
                .foregroundStyle(palette.componentColor(for: reading.kind))
            detailRow(language.sourceTitle, reading.kind.sourceDescription(for: language))
            if let chipName, reading.kind == .cpu || reading.kind == .gpu {
                detailRow(language.chipTitle, chipName)
            }
            if let sourceIdentifier = reading.sourceIdentifier {
                detailRow("ID", sourceIdentifier)
            }
            if reading.kind == .cpu || reading.kind == .gpu {
                detailRow(language.averageTemperatureTitle, temperatureText)
                detailRow(language.hotspotTemperatureTitle, hotspotText)
                if let validSensorCount = reading.validSensorCount {
                    detailRow(language.validSensorCountTitle, language.sensorCountDescription(validSensorCount))
                }
            } else {
                detailRow(language.lastValidValueTitle, temperatureText)
            }
            detailRow(language.lastValidTimeTitle, timeText)
            if let lastValidAt {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    detailRow(language.measurementAgeTitle, language.measurementAge(since: lastValidAt, now: timeline.date))
                }
            }
            if let detail = reading.detail, reading.kind != .cpu && reading.kind != .gpu {
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

    private var hotspotText: String {
        guard let hotspot = reading.hotspotTemperatureCelsius else { return language.notAvailable }
        return "\(hotspot.formatted(.number.precision(.fractionLength(1)))) °C"
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
