import Foundation
import Observation

/// Read-only boundary between macOS hardware data and SwiftUI.
/// `diskutil info -plist` exposes NVMe SMART `TEMPERATURE` when a controller passes it on.
@MainActor
@Observable
final class SensorService {
    private(set) var snapshot = ThermalSnapshot.unavailable
    private var refreshTask: Task<Void, Never>?
    private var lastVerifiedGPU: (temperature: Double, measuredAt: Date)?

    init() {
        start()
    }

    private func start() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { break }
                await self?.refresh()
            }
        }
    }

    func refresh() async {
        let freshSnapshot = await Task.detached(priority: .utility) { SensorProbe.readSnapshot() }.value
        let readings = applyingTransientGPUFallback(to: freshSnapshot.readings, now: freshSnapshot.updatedAt)
        snapshot = ThermalSnapshot(readings: readings, updatedAt: freshSnapshot.updatedAt)
    }

    /// Preserve only a recent, previously verified GPU measurement when the
    /// private SMC transport rejects an otherwise normal refresh. This is not a
    /// synthetic value: the UI explicitly labels it as the last real reading,
    /// and it expires after 15 seconds. A continuously unavailable sensor still
    /// becomes `Nicht verfügbar`.
    private func applyingTransientGPUFallback(
        to readings: [TemperatureReading],
        now: Date
    ) -> [TemperatureReading] {
        readings.map { reading in
            guard reading.kind == .gpu else { return reading }

            if let temperature = reading.temperatureCelsius {
                lastVerifiedGPU = (temperature, now)
                return reading
            }

            guard let lastVerifiedGPU,
                  now.timeIntervalSince(lastVerifiedGPU.measuredAt) <= 15 else {
                return reading
            }

            let seconds = max(0, Int(now.timeIntervalSince(lastVerifiedGPU.measuredAt).rounded()))
            return TemperatureReading(
                kind: .gpu,
                temperatureCelsius: lastVerifiedGPU.temperature,
                detail: "Letzter echter GPU-Wert vor \(seconds) s · Sensor antwortet kurz nicht",
                unavailableReason: nil,
                isLastVerifiedValue: true
            )
        }
    }
}

private enum SensorProbe {
    static func readSnapshot() -> ThermalSnapshot {
        let disks = DiskUtility.physicalDisks()
        let internalDisk = disks.first(where: { $0.isInternal && $0.solidState })
        let externalDisk = disks.first(where: { !$0.isInternal && $0.solidState })
        return ThermalSnapshot(readings: [
            processorReading(.cpu), processorReading(.gpu),
            diskReading(.internalSSD, disk: internalDisk), diskReading(.externalSSD, disk: externalDisk)
        ], updatedAt: .now)
    }

    private static func processorReading(_ kind: SensorKind) -> TemperatureReading {
        if kind == .gpu {
            let result = AppleSiliconSMCTemperatureBackend().gpuTemperature()
            return TemperatureReading(
                kind: kind,
                temperatureCelsius: result.celsius,
                detail: result.detail,
                unavailableReason: result.celsius == nil ? result.unavailableReason : nil
            )
        }

        let result = AppleSiliconSMCTemperatureBackend().cpuTemperature()
        return TemperatureReading(
            kind: kind,
            temperatureCelsius: result.celsius,
            detail: result.detail,
            unavailableReason: result.celsius == nil ? result.unavailableReason : nil
        )
    }

    private static func diskReading(_ kind: SensorKind, disk: DiskInfo?) -> TemperatureReading {
        guard let disk else {
            return TemperatureReading(kind: kind, temperatureCelsius: nil, detail: nil,
                                     unavailableReason: "Kein passendes Laufwerk erkannt")
        }
        guard let kelvin = disk.smartTemperatureKelvin, (200...450).contains(kelvin) else {
            return TemperatureReading(kind: kind, temperatureCelsius: nil, detail: disk.displayName,
                                     unavailableReason: "SMART-Temperatur wird nicht bereitgestellt")
        }
        return TemperatureReading(kind: kind, temperatureCelsius: kelvin - 273.15,
                                 detail: disk.displayName, unavailableReason: nil)
    }
}

private struct DiskInfo {
    let identifier: String
    let isInternal: Bool
    let solidState: Bool
    let mediaName: String
    let volumeName: String?
    let smartTemperatureKelvin: Double?

    var displayName: String { volumeName?.isEmpty == false ? volumeName! : mediaName }
}

private enum DiskUtility {
    static func physicalDisks() -> [DiskInfo] {
        guard let list = propertyList(arguments: ["list", "-plist"]),
              let identifiers = list["AllDisks"] as? [String] else { return [] }
        return identifiers.compactMap { identifier in
            guard let info = propertyList(arguments: ["info", "-plist", identifier]),
                  (info["WholeDisk"] as? Bool) == true,
                  let internalDrive = info["Internal"] as? Bool,
                  let solidState = info["SolidState"] as? Bool else { return nil }
            let smart = info["SMARTDeviceSpecificKeysMayVaryNotGuaranteed"] as? [String: Any]
            let kelvin = (smart?["TEMPERATURE"] as? NSNumber)?.doubleValue
            return DiskInfo(identifier: identifier, isInternal: internalDrive, solidState: solidState,
                            mediaName: (info["MediaName"] as? String) ?? identifier,
                            volumeName: info["VolumeName"] as? String, smartTemperatureKelvin: kelvin)
        }.sorted { $0.identifier.localizedStandardCompare($1.identifier) == .orderedAscending }
    }

    private static func propertyList(arguments: [String]) -> [String: Any]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        do { try process.run() } catch { return nil }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
    }
}
