import Foundation
import UserNotifications

struct TemperatureAlertConfiguration: Equatable, Sendable {
    var isEnabled: Bool
    var cpuThreshold: Double
    var gpuThreshold: Double
    var internalSSDThreshold: Double
    var externalSSDThreshold: Double
    var language: AppLanguage

    func threshold(for kind: SensorKind) -> Double {
        switch kind {
        case .cpu: cpuThreshold
        case .gpu: gpuThreshold
        case .internalSSD: internalSSDThreshold
        case .externalSSD: externalSSDThreshold
        }
    }
}

enum TemperatureAlertSettings {
    static let enabledKey = "thermalatlas.temperatureAlertsEnabled"
    static let cpuThresholdKey = "thermalatlas.cpuAlertThreshold"
    static let gpuThresholdKey = "thermalatlas.gpuAlertThreshold"
    static let internalSSDThresholdKey = "thermalatlas.internalSSDAlertThreshold"
    static let externalSSDThresholdKey = "thermalatlas.externalSSDAlertThreshold"

    static func thresholdOptions(for kind: SensorKind) -> [Double] {
        switch kind {
        case .cpu, .gpu: [85, 90, 95, 100]
        case .internalSSD, .externalSSD: [60, 65, 70, 75]
        }
    }

    static func defaultThreshold(for kind: SensorKind) -> Double {
        switch kind {
        case .cpu, .gpu: 95
        case .internalSSD, .externalSSD: 70
        }
    }
}

struct TemperatureAlert: Sendable {
    let reading: TemperatureReading
    let threshold: Double
}

/// Alerts only after a genuine reading stayed above its selected threshold for
/// a full minute. A reading needs to recover before the same episode can alert
/// again, so short spikes and continuously hot readings do not create spam.
struct TemperatureAlertEngine {
    static let requiredDuration: TimeInterval = 60

    private struct ActiveEpisode {
        let beganAt: Date
        var wasReported: Bool
    }

    private var episodes: [String: ActiveEpisode] = [:]

    mutating func evaluate(
        readings: [TemperatureReading],
        configuration: TemperatureAlertConfiguration,
        now: Date
    ) -> [TemperatureAlert] {
        guard configuration.isEnabled else {
            episodes.removeAll()
            return []
        }

        var alerts: [TemperatureAlert] = []
        for reading in readings {
            let identifier = reading.id
            guard !reading.isLastVerifiedValue,
                  let temperature = reading.temperatureCelsius,
                  temperature >= configuration.threshold(for: reading.kind) else {
                episodes.removeValue(forKey: identifier)
                continue
            }

            var episode = episodes[identifier] ?? ActiveEpisode(beganAt: now, wasReported: false)
            if !episode.wasReported, now.timeIntervalSince(episode.beganAt) >= Self.requiredDuration {
                episode.wasReported = true
                alerts.append(TemperatureAlert(reading: reading, threshold: configuration.threshold(for: reading.kind)))
            }
            episodes[identifier] = episode
        }
        return alerts
    }
}

@MainActor
enum TemperatureAlertNotifier {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    static func send(_ alert: TemperatureAlert, language: AppLanguage) async {
        let content = UNMutableNotificationContent()
        let title = alert.reading.title ?? alert.reading.kind.title(for: language)
        let value = Int(alert.reading.temperatureCelsius?.rounded() ?? alert.threshold)
        if language == .german {
            content.title = "Temperaturwarnung: \(title)"
            content.body = "Seit mindestens einer Minute bei oder über \(Int(alert.threshold)) °C (aktuell \(value) °C)."
        } else {
            content.title = "Temperature alert: \(title)"
            content.body = "At or above \(Int(alert.threshold)) °C for at least one minute (currently \(value) °C)."
        }
        content.sound = .default
        let request = UNNotificationRequest(identifier: "thermalatlas.\(alert.reading.id).\(UUID().uuidString)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
