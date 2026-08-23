import Foundation
import Observation

/// Read-only boundary between macOS hardware data and SwiftUI.
/// `diskutil info -plist` exposes NVMe SMART `TEMPERATURE` when a controller passes it on.
@MainActor
@Observable
final class SensorService {
    private(set) var snapshot = ThermalSnapshot.unavailable
    private(set) var systemContext = SystemContext.unavailable
    private(set) var refreshInterval: TimeInterval
    let history = TemperatureHistoryStore()
    private var refreshTask: Task<Void, Never>?
    private var lastVerifiedGPU: (temperature: Double, measuredAt: Date)?
    private var alertConfiguration = TemperatureAlertConfiguration(
        isEnabled: false,
        cpuThreshold: TemperatureAlertSettings.defaultThreshold(for: .cpu),
        gpuThreshold: TemperatureAlertSettings.defaultThreshold(for: .gpu),
        internalSSDThreshold: TemperatureAlertSettings.defaultThreshold(for: .internalSSD),
        externalSSDThreshold: TemperatureAlertSettings.defaultThreshold(for: .externalSSD),
        language: .defaultLanguage
    )
    private var alertEngine = TemperatureAlertEngine()
    private var systemContextReader = SystemContextReader()

    init(refreshInterval: TimeInterval = RefreshIntervalOption.defaultOption.rawValue) {
        self.refreshInterval = RefreshIntervalOption.normalized(refreshInterval).rawValue
        start()
    }

    func setRefreshInterval(_ interval: TimeInterval) {
        let normalizedInterval = RefreshIntervalOption.normalized(interval).rawValue
        guard refreshInterval != normalizedInterval else { return }

        refreshInterval = normalizedInterval
        refreshTask?.cancel()
        refreshTask = nil
        start()
    }

    func setAlertConfiguration(_ configuration: TemperatureAlertConfiguration) {
        alertConfiguration = configuration
        if configuration.isEnabled {
            Task { await TemperatureAlertNotifier.requestAuthorizationIfNeeded() }
        }
    }

    private func start() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                let interval = self?.refreshInterval ?? RefreshIntervalOption.defaultOption.rawValue
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await self?.refresh()
            }
        }
    }

    func refresh() async {
        let freshSnapshot = await Task.detached(priority: .utility) { SensorProbe.readSnapshot() }.value
        let readings = applyingTransientGPUFallback(to: freshSnapshot.readings, now: freshSnapshot.updatedAt)
        snapshot = ThermalSnapshot(readings: readings, updatedAt: freshSnapshot.updatedAt)
        systemContext = systemContextReader.read()
        history.record(snapshot)
        let alerts = alertEngine.evaluate(
            readings: readings,
            configuration: alertConfiguration,
            now: freshSnapshot.updatedAt
        )
        for alert in alerts {
            let language = alertConfiguration.language
            Task { await TemperatureAlertNotifier.send(alert, language: language) }
        }
    }

    /// Preserve only a recent, previously verified GPU measurement when the
    /// private SMC transport rejects an otherwise normal refresh. This is not a
    /// synthetic value: the UI explicitly labels it as the last real reading,
    /// and it expires after 15 seconds. A continuously unavailable sensor still
    /// becomes unavailable again.
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
                detail: "Last verified GPU reading is \(seconds) seconds old",
                unavailableReason: nil,
                isLastVerifiedValue: true,
                lastVerifiedAt: lastVerifiedGPU.measuredAt
            )
        }
    }
}

private enum SensorProbe {
    static func readSnapshot() -> ThermalSnapshot {
        let disks = DiskUtility.physicalDisks()
        let internalDisk = disks.first(where: { $0.isInternal && $0.solidState })
        let externalDisks = disks.filter { !$0.isInternal && $0.solidState && !$0.isVirtual }
        let externalReadings = externalDisks.isEmpty
            ? [diskReading(.externalSSD, disk: nil)]
            : externalDisks.map { diskReading(.externalSSD, disk: $0) }
        return ThermalSnapshot(readings: [
            processorReading(.cpu), processorReading(.gpu),
            diskReading(.internalSSD, disk: internalDisk)
        ] + externalReadings, updatedAt: .now)
    }

    private static func processorReading(_ kind: SensorKind) -> TemperatureReading {
        if kind == .gpu {
            let result = AppleSiliconSMCTemperatureBackend().gpuTemperature()
            return TemperatureReading(
                kind: kind,
                temperatureCelsius: result.celsius,
                detail: result.detail,
                unavailableReason: result.celsius == nil ? .gpuSensorUnavailable : nil
            )
        }

        let result = AppleSiliconSMCTemperatureBackend().cpuTemperature()
        return TemperatureReading(
            kind: kind,
            temperatureCelsius: result.celsius,
            detail: result.detail,
            unavailableReason: result.celsius == nil ? .cpuSensorUnavailable : nil
        )
    }

    private static func diskReading(
        _ kind: SensorKind,
        disk: DiskInfo?
    ) -> TemperatureReading {
        guard let disk else {
            return TemperatureReading(kind: kind, temperatureCelsius: nil, detail: nil,
                                     unavailableReason: .noMatchingDrive)
        }
        guard let kelvin = disk.smartTemperatureKelvin, (200...450).contains(kelvin) else {
            return TemperatureReading(kind: kind, sourceIdentifier: disk.identifier, title: disk.displayName,
                                     temperatureCelsius: nil, detail: nil,
                                     smartStatus: disk.smartStatusValue,
                                     smartHealthPercentage: disk.smartHealthPercentage,
                                     unavailableReason: .smartTemperatureUnavailable)
        }
        return TemperatureReading(kind: kind, sourceIdentifier: disk.identifier, title: disk.displayName,
                                 temperatureCelsius: kelvin - 273.15,
                                 detail: nil, smartStatus: disk.smartStatusValue,
                                 smartHealthPercentage: disk.smartHealthPercentage,
                                 unavailableReason: nil)
    }
}

private struct DiskInfo {
    let identifier: String
    let isInternal: Bool
    let solidState: Bool
    let mediaName: String
    let volumeName: String?
    let smartTemperatureKelvin: Double?
    let smartStatus: String?
    let smartHealthPercentage: Int?
    let isVirtual: Bool

    var displayName: String { volumeName?.isEmpty == false ? volumeName! : mediaName }

    var smartStatusValue: SMARTStatus {
        guard let smartStatus, !smartStatus.isEmpty else { return .unavailable }
        switch smartStatus.lowercased() {
        case "verified": return .verified
        case "failing": return .failing
        case "not supported": return .unsupported
        default: return .reported(smartStatus)
        }
    }
}

private enum DiskUtility {
    static func physicalDisks() -> [DiskInfo] {
        guard let list = propertyList(arguments: ["list", "-plist"]),
              let identifiers = list["AllDisks"] as? [String] else { return [] }

        let infos = identifiers.reduce(into: [String: [String: Any]]()) { result, identifier in
            if let info = propertyList(arguments: ["info", "-plist", identifier]) {
                result[identifier] = info
            }
        }

        return identifiers.compactMap { identifier in
            guard let info = infos[identifier],
                  (info["WholeDisk"] as? Bool) == true,
                  let internalDrive = info["Internal"] as? Bool,
                  let solidState = info["SolidState"] as? Bool else { return nil }
            let smart = info["SMARTDeviceSpecificKeysMayVaryNotGuaranteed"] as? [String: Any]
            let kelvin = (smart?["TEMPERATURE"] as? NSNumber)?.doubleValue
            let percentageUsed = (smart?["PERCENTAGE_USED"] as? NSNumber)?.doubleValue
            return DiskInfo(identifier: identifier, isInternal: internalDrive, solidState: solidState,
                            mediaName: (info["MediaName"] as? String) ?? identifier,
                            volumeName: internalDrive
                                ? nonEmptyString(info["VolumeName"])
                                : volumeName(for: identifier, ownInfo: info, allInfos: infos),
                            smartTemperatureKelvin: kelvin,
                            smartStatus: info["SMARTStatus"] as? String,
                            smartHealthPercentage: SSDHealth.remainingPercentage(fromPercentageUsed: percentageUsed),
                            isVirtual: (info["VirtualOrPhysical"] as? String) == "Virtual")
        }.sorted { $0.identifier.localizedStandardCompare($1.identifier) == .orderedAscending }
    }

    /// A whole APFS disk has no volume name itself. Resolve its physical-store
    /// partition through the APFS container to the mounted user-visible volume.
    private static func volumeName(
        for physicalDiskIdentifier: String,
        ownInfo: [String: Any],
        allInfos: [String: [String: Any]]
    ) -> String? {
        if let ownName = nonEmptyString(ownInfo["VolumeName"]) { return ownName }

        let partitions = Set(allInfos.compactMap { identifier, info in
            (info["ParentWholeDisk"] as? String) == physicalDiskIdentifier ? identifier : nil
        })
        let containers = Set(allInfos.compactMap { identifier, info -> String? in
            guard let stores = info["APFSPhysicalStores"] as? [[String: Any]],
                  stores.contains(where: { store in
                      guard let physicalStore = store["APFSPhysicalStore"] as? String else { return false }
                      return partitions.contains(physicalStore)
                  }) else { return nil }
            return identifier
        })

        let apfsVolumeNames = allInfos.compactMap { _, info -> String? in
            guard let container = info["APFSContainerReference"] as? String,
                  containers.contains(container) else { return nil }
            return nonEmptyString(info["VolumeName"])
        }
        if let apfsVolumeName = apfsVolumeNames.first { return apfsVolumeName }

        return allInfos.values.lazy.compactMap { info in
            guard (info["ParentWholeDisk"] as? String) == physicalDiskIdentifier else { return nil }
            return nonEmptyString(info["VolumeName"])
        }.first
    }

    private static func nonEmptyString(_ value: Any?) -> String? {
        guard let value = value as? String, !value.isEmpty else { return nil }
        return value
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
