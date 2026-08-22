import AppKit
import SwiftUI

enum ThermalTheme: String, CaseIterable, Identifiable {
    case classic
    case milkGlass
    case aurora
    case ember

    var id: String { rawValue }

    func displayName(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.classic, .english): "Classic"
        case (.classic, .german): "Klassisch"
        case (.milkGlass, _): "Liquid Glass"
        case (.aurora, _): "Aurora"
        case (.ember, _): "Ember"
        }
    }

    var symbol: String {
        switch self {
        case .classic: "moon.stars.fill"
        case .milkGlass: "sparkles"
        case .aurora: "globe.europe.africa.fill"
        case .ember: "flame.fill"
        }
    }

    var usesFullWindowGlass: Bool { self == .milkGlass }

    var palette: ThermalThemePalette {
        switch self {
        case .classic:
            ThermalThemePalette(
                windowBackground: Color.clear,
                cardBase: Color.clear,
                cardStrokeOpacity: 0.18,
                title: .primary,
                secondary: .secondary,
                cpu: .purple, gpu: .blue, internalSSD: .teal, externalSSD: .green
            )
        case .milkGlass:
            ThermalThemePalette(
                windowBackground: Color.white.opacity(0.12),
                cardBase: Color.white.opacity(0.13),
                cardStrokeOpacity: 0.30,
                title: .primary,
                secondary: .secondary,
                cpu: Color(red: 0.72, green: 0.54, blue: 1.0),
                gpu: Color(red: 0.38, green: 0.78, blue: 1.0),
                internalSSD: Color(red: 0.30, green: 0.86, blue: 0.78),
                externalSSD: Color(red: 0.52, green: 0.88, blue: 0.48)
            )
        case .aurora:
            ThermalThemePalette(
                windowBackground: Color(red: 0.035, green: 0.055, blue: 0.13),
                cardBase: Color(red: 0.08, green: 0.10, blue: 0.20),
                cardStrokeOpacity: 0.28,
                title: Color(red: 0.91, green: 0.96, blue: 1.0),
                secondary: Color(red: 0.61, green: 0.72, blue: 0.86),
                cpu: Color(red: 0.68, green: 0.46, blue: 1.0),
                gpu: Color(red: 0.24, green: 0.72, blue: 1.0),
                internalSSD: Color(red: 0.19, green: 0.85, blue: 0.69),
                externalSSD: Color(red: 0.56, green: 0.88, blue: 0.34)
            )
        case .ember:
            ThermalThemePalette(
                windowBackground: Color(red: 0.12, green: 0.045, blue: 0.035),
                cardBase: Color(red: 0.19, green: 0.07, blue: 0.05),
                cardStrokeOpacity: 0.30,
                title: Color(red: 1.0, green: 0.93, blue: 0.88),
                secondary: Color(red: 0.85, green: 0.68, blue: 0.58),
                cpu: Color(red: 1.0, green: 0.46, blue: 0.28),
                gpu: Color(red: 1.0, green: 0.68, blue: 0.24),
                internalSSD: Color(red: 0.96, green: 0.35, blue: 0.42),
                externalSSD: Color(red: 0.83, green: 0.78, blue: 0.30)
            )
        }
    }
}

struct ThermalThemePalette {
    let windowBackground: Color
    let cardBase: Color
    let cardStrokeOpacity: Double
    let title: Color
    let secondary: Color
    let cpu: Color
    let gpu: Color
    let internalSSD: Color
    let externalSSD: Color

    func componentColor(for kind: SensorKind) -> Color {
        switch kind {
        case .cpu: cpu
        case .gpu: gpu
        case .internalSSD: internalSSD
        case .externalSSD: externalSSD
        }
    }
}

/// The milk-glass theme uses one AppKit visual-effect view behind the complete
/// popover. Foreground cards remain translucent SwiftUI surfaces, preventing
/// stacked materials and keeping the text legible in light and dark mode.
struct ThermalMilkGlassBackdrop: NSViewRepresentable {
    let isAnimated: Bool
    let allowsTransparency: Bool
    let colorScheme: ColorScheme

    func makeNSView(context: Context) -> ThermalMilkGlassBackdropView {
        let view = ThermalMilkGlassBackdropView()
        view.configure(
            isAnimated: isAnimated,
            allowsTransparency: allowsTransparency,
            colorScheme: colorScheme
        )
        return view
    }

    func updateNSView(_ view: ThermalMilkGlassBackdropView, context: Context) {
        view.configure(
            isAnimated: isAnimated,
            allowsTransparency: allowsTransparency,
            colorScheme: colorScheme
        )
    }
}

final class ThermalMilkGlassBackdropView: NSVisualEffectView {
    private let glowLayer = CAGradientLayer()
    private var allowsTransparency = true
    private var colorScheme: ColorScheme = .dark

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func layout() {
        super.layout()
        let inset = max(bounds.width, bounds.height) * 0.6
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        glowLayer.frame = bounds.insetBy(dx: -inset, dy: -inset)
        CATransaction.commit()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyAppearance()
    }

    func configure(isAnimated: Bool, allowsTransparency: Bool, colorScheme: ColorScheme) {
        self.allowsTransparency = allowsTransparency
        self.colorScheme = colorScheme
        applyAppearance()
    }

    private func configure() {
        material = .hudWindow
        blendingMode = .behindWindow
        state = .followsWindowActiveState
        wantsLayer = true
        layer?.masksToBounds = true
        glowLayer.startPoint = CGPoint(x: 0.05, y: 0.05)
        glowLayer.endPoint = CGPoint(x: 0.95, y: 0.95)
        layer?.insertSublayer(glowLayer, at: 0)
        applyAppearance()
    }

    private func applyAppearance() {
        let darkAppearance = colorScheme == .dark
        material = allowsTransparency ? .hudWindow : .windowBackground
        blendingMode = allowsTransparency ? .behindWindow : .withinWindow
        glowLayer.colors = [
            NSColor.systemTeal.withAlphaComponent(darkAppearance ? 0.30 : 0.18).cgColor,
            NSColor.systemCyan.withAlphaComponent(darkAppearance ? 0.23 : 0.14).cgColor,
            NSColor.systemBlue.withAlphaComponent(darkAppearance ? 0.18 : 0.10).cgColor,
            NSColor.systemPurple.withAlphaComponent(darkAppearance ? 0.14 : 0.08).cgColor
        ]
        glowLayer.opacity = allowsTransparency ? 0.46 : 0.18
    }
}
