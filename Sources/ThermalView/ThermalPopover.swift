import AppKit
import SwiftUI

struct MenuBarLabel: View {
    let highestTemperature: Double?

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "thermometer.medium")
            if let highestTemperature { Text("\(Int(highestTemperature.rounded()))°").monospacedDigit() }
        }
        .accessibilityLabel(highestTemperature.map { "Höchste Temperatur \(Int($0.rounded())) Grad Celsius" } ?? "ThermalAtlas")
    }
}

struct ThermalPopover: View {
    let service: SensorService
    @Binding var selectedTheme: ThermalTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThermalThemePalette { selectedTheme.palette }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ThermalAtlas").font(.title3.weight(.semibold))
                        Text("Temperaturen dieses Macs").font(.subheadline).foregroundStyle(palette.secondary)
                    }
                    Spacer()
                    Image(systemName: "thermometer.medium")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(palette.gpu)
                        .symbolRenderingMode(.hierarchical)
                }
                VStack(spacing: 11) {
                    ForEach(service.snapshot.readings) { SensorCard(reading: $0, selectedTheme: selectedTheme) }
                }
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Aktualisiert \(service.snapshot.updatedAt, format: .dateTime.hour().minute().second())")
                    Spacer()
                    Menu {
                        ForEach(ThermalTheme.allCases) { theme in
                            Button {
                                selectedTheme = theme
                            } label: {
                                Label(
                                    theme.name,
                                    systemImage: theme == selectedTheme ? "checkmark" : theme.symbol
                                )
                            }
                            .menuActionDismissBehavior(.enabled)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintpalette")
                    }
                    .menuStyle(.borderlessButton)
                    .help("Darstellung auswählen")
                    Button {
                        openActivityMonitor()
                    } label: {
                        Image(systemName: "waveform.path.ecg")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Aktivitätsanzeige öffnen")
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "power")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("ThermalAtlas beenden")
                }
                .font(.caption).foregroundStyle(palette.secondary)
            }
            .padding(20)
        }
        .frame(width: 370)
        .foregroundStyle(palette.title)
        .background { popoverBackground }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(selectedTheme.usesFullWindowGlass ? Color.white.opacity(0.34) : palette.gpu.opacity(0.16), lineWidth: 1)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: selectedTheme)
    }

    @ViewBuilder
    private var popoverBackground: some View {
        if selectedTheme.usesFullWindowGlass {
            ThermalMilkGlassBackdrop(
                isAnimated: !reduceMotion,
                allowsTransparency: !reduceTransparency,
                colorScheme: colorScheme
            )
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
}

private struct SensorCard: View {
    let reading: TemperatureReading
    let selectedTheme: ThermalTheme
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThermalThemePalette { selectedTheme.palette }
    private var componentColor: Color { palette.componentColor(for: reading.kind) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reading.kind.symbol)
                .font(.headline.weight(.semibold))
                .frame(width: 30, height: 30)
                .foregroundStyle(componentColor)
                .background(componentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(reading.kind.title).font(.body.weight(.medium)).foregroundStyle(palette.title)
                HStack(spacing: 4) {
                    if reading.isLastVerifiedValue {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    Text(subtitle)
                }
                .font(.caption)
                .foregroundStyle(reading.isLastVerifiedValue ? .orange : palette.secondary)
                .lineLimit(1)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 4) {
                Text(temperatureText)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                HStack(spacing: 5) {
                    Circle().fill(statusColor).frame(width: 6, height: 6)
                    Capsule().fill(statusColor).frame(width: 23, height: 4)
                }
            }
        }
        .padding(.horizontal, 13).padding(.vertical, 12)
        .background {
            cardBackground
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(componentColor.opacity(palette.cardStrokeOpacity), lineWidth: 1)
        }
        .shadow(color: componentColor.opacity(0.09), radius: 10, y: 4)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 7)
        .task {
            guard !hasAppeared else { return }
            withAnimation(.easeOut(duration: 0.35)) { hasAppeared = true }
        }
        .animation(.easeInOut(duration: 0.3), value: reading.temperatureCelsius)
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
        colorScheme == .dark ? Color(red: 0.08, green: 0.11, blue: 0.16) : Color.white
    }

    private var liquidGlassReflection: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.30),
                Color.white.opacity(0.025),
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

    private var subtitle: String { reading.detail ?? reading.unavailableReason ?? "Sensor bereit" }
    private var temperatureText: String {
        guard let temperature = reading.temperatureCelsius else { return "Nicht verfügbar" }
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
