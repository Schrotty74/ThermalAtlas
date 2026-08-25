import AppKit
import Foundation
import Observation

/// Read-only boundary between macOS hardware data and SwiftUI.
/// `diskutil info -plist` exposes NVMe SMART `TEMPERATURE` when a controller passes it on.
@MainActor
@Observable
final class SensorService {
    private static let topologyRefreshInterval: TimeInterval = 60 * 60
    private static let ssdTemperatureRefreshInterval: TimeInterval = 60
    private static let smartRefreshInterval: TimeInterval = 24 * 60 * 60
    private static let systemContextRefreshInterval: TimeInterval = 0.5

    private(set) var snapshot = ThermalSnapshot.unavailable
    private(set) var systemContext = SystemContext.unavailable
    private(set) var refreshInterval: TimeInterval
    let history = TemperatureHistoryStore()
    private var refreshTask: Task<Void, Never>?
    private var systemContextRefreshTask: Task<Void, Never>?
    private var topologyRefreshTask: Task<Void, Never>?
    private var ssdTemperatureRefreshTask: Task<Void, Never>?
    private var smartRefreshTask: Task<Void, Never>?
    private var processorRefreshInFlight = false
    private var processorRefreshPending = false
    private var diskTopologyRefreshInFlight = false
    private var diskTopologyRefreshPending = false
    private var diskReadingsRefreshInFlight = false
    private var diskTemperatureRefreshPending = false
    private var smartRefreshPending = false
    private var processorReadings = SensorKind.allCases.prefix(2).map {
        TemperatureReading(kind: $0, temperatureCelsius: nil, detail: nil, unavailableReason: .checking)
    }
    private var diskTopology: [DiskTopology] = []
    private var hasCompletedInitialDiskRefresh = false
    private var diskReadings = [
        TemperatureReading(kind: .internalSSD, temperatureCelsius: nil, detail: nil, unavailableReason: .checking),
        TemperatureReading(kind: .externalSSD, temperatureCelsius: nil, detail: nil, unavailableReason: .checking)
    ]
    @ObservationIgnored private var diskTopologyNotifier: DiskTopologyNotifier?
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
    private let systemContextSampler = SystemContextSampler()

    init(refreshInterval: TimeInterval = RefreshIntervalOption.defaultOption.rawValue) {
        self.refreshInterval = RefreshIntervalOption.normalized(refreshInterval).rawValue
        diskTopologyNotifier = DiskTopologyNotifier { [weak self] in
            Task { @MainActor [weak self] in
                await self?.refreshDiskTopology()
            }
        }
        startProcessorRefresh()
        startSystemContextRefresh()
        startDiskRefreshes()
    }

    func setRefreshInterval(_ interval: TimeInterval) {
        let normalizedInterval = RefreshIntervalOption.normalized(interval).rawValue
        guard refreshInterval != normalizedInterval else { return }

        refreshInterval = normalizedInterval
        refreshTask?.cancel()
        refreshTask = nil
        startProcessorRefresh()
    }

    func setAlertConfiguration(_ configuration: TemperatureAlertConfiguration) {
        alertConfiguration = configuration
        if configuration.isEnabled {
            Task { await TemperatureAlertNotifier.requestAuthorizationIfNeeded() }
        }
    }

    private func startProcessorRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            await self?.refreshProcessors()
            while !Task.isCancelled {
                let interval = self?.refreshInterval ?? RefreshIntervalOption.defaultOption.rawValue
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                guard let self else { break }
                await self.refreshProcessors()
            }
        }
    }

    /// Context load is intentionally independent of temperature scans: load
    /// changes quickly, whereas the user may choose a slower temperature rate.
    private func startSystemContextRefresh() {
        guard systemContextRefreshTask == nil else { return }
        systemContextRefreshTask = Task { [weak self] in
            await self?.refreshSystemContext()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.systemContextRefreshInterval))
                guard !Task.isCancelled, let self else { break }
                await self.refreshSystemContext()
            }
        }
    }

    private func startDiskRefreshes() {
        topologyRefreshTask = Task { [weak self] in
            await self?.refreshDiskTopology()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.topologyRefreshInterval))
                guard !Task.isCancelled else { break }
                guard let self else { break }
                await self.refreshDiskTopology()
            }
        }
        ssdTemperatureRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.ssdTemperatureRefreshInterval))
                guard !Task.isCancelled, let self else { break }
                await self.refreshSSDTemperatures()
            }
        }
        smartRefreshTask = Task { [weak self] in
            // The initial topology pass triggers the first SMART poll. Later
            // SMART reads are intentionally limited to once per day.
            try? await Task.sleep(for: .seconds(Self.smartRefreshInterval))
            while !Task.isCancelled {
                guard let self else { break }
                await self.refreshSMART()
                try? await Task.sleep(for: .seconds(Self.smartRefreshInterval))
            }
        }
    }

    private func refreshProcessors() async {
        guard !processorRefreshInFlight else {
            processorRefreshPending = true
            return
        }

        processorRefreshInFlight = true
        defer { processorRefreshInFlight = false }
        repeat {
            processorRefreshPending = false
            let now = Date.now
            let readings = await Task.detached(priority: .utility) {
                SensorProbe.processorReadings(measuredAt: now)
            }.value
            processorReadings = applyingTransientGPUFallback(to: readings, now: now)
            publishSnapshot(at: now)
            processorReadings = processorReadings.map { $0.cached() }
        } while processorRefreshPending && !Task.isCancelled
    }

    private func refreshSystemContext() async {
        let updatedContext = await systemContextSampler.read()
        guard updatedContext != systemContext else { return }
        systemContext = updatedContext
    }

    private func refreshDiskTopology() async {
        guard !diskTopologyRefreshInFlight else {
            diskTopologyRefreshPending = true
            return
        }

        diskTopologyRefreshInFlight = true
        defer { diskTopologyRefreshInFlight = false }
        repeat {
            diskTopologyRefreshPending = false
            let topology = await Task.detached(priority: .utility) { DiskUtility.topology() }.value
            let topologyChanged = diskTopology != topology
            diskTopology = topology
            if !hasCompletedInitialDiskRefresh || topologyChanged {
                await refreshSMART()
            }
        } while diskTopologyRefreshPending && !Task.isCancelled
    }

    private func refreshSMART() async {
        await refreshDiskReadings(includingSMARTMetadata: true)
    }

    private func refreshSSDTemperatures() async {
        guard hasCompletedInitialDiskRefresh else { return }
        await refreshDiskReadings(includingSMARTMetadata: false)
    }

    private func refreshDiskReadings(includingSMARTMetadata: Bool) async {
        guard !diskReadingsRefreshInFlight else {
            if includingSMARTMetadata {
                smartRefreshPending = true
            } else {
                diskTemperatureRefreshPending = true
            }
            return
        }

        diskReadingsRefreshInFlight = true
        defer { diskReadingsRefreshInFlight = false }
        var needsSMARTMetadata = includingSMARTMetadata
        while true {
            let now = Date.now
            let topology = diskTopology
            let readings = await Task.detached(priority: .utility) {
                DiskUtility.readings(for: topology, measuredAt: now)
            }.value
            if needsSMARTMetadata {
                diskReadings = readings
                hasCompletedInitialDiskRefresh = true
            } else {
                diskReadings = readings.map { reading in
                    guard let previous = diskReadings.first(where: { $0.id == reading.id }) else { return reading }
                    return reading.replacingSMARTMetadata(from: previous)
                }
            }
            publishSnapshot(at: now)
            diskReadings = diskReadings.map { $0.cached() }

            if smartRefreshPending {
                smartRefreshPending = false
                needsSMARTMetadata = true
            } else if diskTemperatureRefreshPending {
                diskTemperatureRefreshPending = false
                needsSMARTMetadata = false
            } else {
                break
            }
            guard !Task.isCancelled else { break }
        }
    }

    private func publishSnapshot(at date: Date) {
        let readings = processorReadings + diskReadings
        snapshot = ThermalSnapshot(readings: readings, updatedAt: date)
        history.record(snapshot)
        let alerts = alertEngine.evaluate(
            readings: readings,
            configuration: alertConfiguration,
            now: date
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
                measuredAt: lastVerifiedGPU.measuredAt,
                isFreshMeasurement: false,
                isLastVerifiedValue: true,
                lastVerifiedAt: lastVerifiedGPU.measuredAt
            )
        }
    }
}

/// Bridges public workspace mount and unmount notifications to the isolated
/// sensor service. Keeping the observer outside the main-actor service lets it
/// unregister itself safely when the service goes away.
private final class DiskTopologyNotifier {
    private let notificationCenter = NSWorkspace.shared.notificationCenter
    private var tokens: [NSObjectProtocol] = []

    init(onTopologyChange: @escaping @Sendable () -> Void) {
        let names: [NSNotification.Name] = [NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification]
        tokens = names.map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { _ in
                onTopologyChange()
            }
        }
    }

    deinit {
        tokens.forEach(notificationCenter.removeObserver)
    }
}

private enum SensorProbe {
    static func processorReadings(measuredAt: Date) -> [TemperatureReading] {
        [processorReading(.cpu, measuredAt: measuredAt), processorReading(.gpu, measuredAt: measuredAt)]
    }

    private static func processorReading(_ kind: SensorKind, measuredAt: Date) -> TemperatureReading {
        if kind == .gpu {
            let result = AppleSiliconSMCTemperatureBackend().gpuTemperature()
            return TemperatureReading(
                kind: kind,
                temperatureCelsius: result.celsius,
                detail: result.detail,
                unavailableReason: result.celsius == nil ? .gpuSensorUnavailable : nil,
                measuredAt: measuredAt
            )
        }

        let result = AppleSiliconSMCTemperatureBackend().cpuTemperature()
        return TemperatureReading(
            kind: kind,
            temperatureCelsius: result.celsius,
            detail: result.detail,
            unavailableReason: result.celsius == nil ? .cpuSensorUnavailable : nil,
            measuredAt: measuredAt
        )
    }
}

private struct DiskTopology: Sendable, Equatable {
    let identifier: String
    let isInternal: Bool
    let solidState: Bool
    let mediaName: String
    let volumeName: String?
    let hasMountedVolume: Bool
    let isVirtual: Bool
    let connectionType: String?

    var displayName: String { volumeName?.isEmpty == false ? volumeName! : mediaName }
    var connectionDescription: String? {
        guard !isInternal, let connectionType else { return nil }
        return connectionType
    }
}

private struct DiskInfo {
    let topology: DiskTopology
    let smartTemperatureKelvin: Double?
    let smartStatus: String?
    let smartHealthPercentage: Int?

    var identifier: String { topology.identifier }
    var displayName: String { topology.displayName }

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
    private static let commandRunner = TimedProcessRunner(
        executableURL: URL(fileURLWithPath: "/usr/sbin/diskutil"),
        timeout: 8
    )

    static func topology() -> [DiskTopology] {
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
            return DiskTopology(
                identifier: identifier,
                isInternal: internalDrive,
                solidState: solidState,
                mediaName: (info["MediaName"] as? String) ?? identifier,
                volumeName: internalDrive
                    ? nonEmptyString(info["VolumeName"])
                    : volumeName(for: identifier, ownInfo: info, allInfos: infos),
                hasMountedVolume: internalDrive || hasMountedVolume(
                    for: identifier, ownInfo: info, allInfos: infos
                ),
                isVirtual: (info["VirtualOrPhysical"] as? String) == "Virtual",
                connectionType: connectionType(in: info)
            )
        }.sorted { $0.identifier.localizedStandardCompare($1.identifier) == .orderedAscending }
    }

    static func readings(for topology: [DiskTopology], measuredAt: Date) -> [TemperatureReading] {
        let internalDisk = topology.first(where: { $0.isInternal && $0.solidState })
        let externalDisks = topology.filter {
            !$0.isInternal && $0.solidState && !$0.isVirtual && $0.hasMountedVolume
        }
        let externalReadings = externalDisks.isEmpty
            ? [diskReading(.externalSSD, disk: nil, measuredAt: measuredAt)]
            : externalDisks.map { diskReading(.externalSSD, disk: $0, measuredAt: measuredAt) }
        return [diskReading(.internalSSD, disk: internalDisk, measuredAt: measuredAt)] + externalReadings
    }

    private static func diskReading(
        _ kind: SensorKind,
        disk topology: DiskTopology?,
        measuredAt: Date
    ) -> TemperatureReading {
        guard let topology else {
            return TemperatureReading(
                kind: kind, temperatureCelsius: nil, detail: nil,
                unavailableReason: .noMatchingDrive, measuredAt: measuredAt
            )
        }

        let info = propertyList(arguments: ["info", "-plist", topology.identifier])
        let smart = info?["SMARTDeviceSpecificKeysMayVaryNotGuaranteed"] as? [String: Any]
        let disk = DiskInfo(
            topology: topology,
            smartTemperatureKelvin: (smart?["TEMPERATURE"] as? NSNumber)?.doubleValue,
            smartStatus: info?["SMARTStatus"] as? String,
            smartHealthPercentage: SSDHealth.remainingPercentage(
                fromPercentageUsed: (smart?["PERCENTAGE_USED"] as? NSNumber)?.doubleValue
            )
        )
        guard let kelvin = disk.smartTemperatureKelvin, (200...450).contains(kelvin) else {
            return TemperatureReading(
                kind: kind, sourceIdentifier: disk.identifier, title: disk.displayName,
                temperatureCelsius: nil, detail: disk.topology.connectionDescription, smartStatus: disk.smartStatusValue,
                smartHealthPercentage: disk.smartHealthPercentage,
                unavailableReason: .smartTemperatureUnavailable, measuredAt: measuredAt
            )
        }
        return TemperatureReading(
            kind: kind, sourceIdentifier: disk.identifier, title: disk.displayName,
            temperatureCelsius: kelvin - 273.15, detail: disk.topology.connectionDescription,
            smartStatus: disk.smartStatusValue, smartHealthPercentage: disk.smartHealthPercentage,
            unavailableReason: nil, measuredAt: measuredAt
        )
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

    private static func hasMountedVolume(
        for physicalDiskIdentifier: String,
        ownInfo: [String: Any],
        allInfos: [String: [String: Any]]
    ) -> Bool {
        if nonEmptyString(ownInfo["VolumeName"]) != nil {
            return isMounted(ownInfo)
        }

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

        return allInfos.values.contains { info in
            guard isMounted(info) else { return false }
            if (info["ParentWholeDisk"] as? String) == physicalDiskIdentifier { return true }
            guard let container = info["APFSContainerReference"] as? String else { return false }
            return containers.contains(container)
        }
    }

    private static func isMounted(_ info: [String: Any]) -> Bool {
        nonEmptyString(info["MountPoint"]) != nil
    }

    private static func nonEmptyString(_ value: Any?) -> String? {
        guard let value = value as? String, !value.isEmpty else { return nil }
        return value
    }

    private static func connectionType(in info: [String: Any]) -> String? {
        ["BusProtocol", "Protocol", "DeviceProtocol"]
            .compactMap { nonEmptyString(info[$0]) }
            .first
    }

    private static func propertyList(arguments: [String]) -> [String: Any]? {
        guard let data = commandRunner.output(arguments: arguments) else { return nil }
        return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
    }
}
