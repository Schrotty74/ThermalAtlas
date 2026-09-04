import Foundation

struct SystemInformationSnapshot: Sendable {
    let macModel: String
    let chip: String
    let cpuCoreCount: Int?
    let performanceCoreCount: Int?
    let efficiencyCoreCount: Int?
    let gpuCoreCount: Int?
    let memory: String
    let storage: String
    let operatingSystem: String
}

enum SystemInformationReader {
    static func read() -> SystemInformationSnapshot {
        let profiler = profilerData()
        let hardware = firstDictionary(in: profiler, key: "SPHardwareDataType")
        let display = firstDictionary(in: profiler, key: "SPDisplaysDataType")

        let machineName = stringValue("machine_name", in: hardware)
        let machineIdentifier = stringValue("machine_model", in: hardware)
        let macModel = [machineName, machineIdentifier]
            .compactMap { $0 }
            .joined(separator: " · ")
        let cpuCounts = cpuCoreCounts(from: stringValue("number_processors", in: hardware))

        return SystemInformationSnapshot(
            macModel: macModel.isEmpty ? localizedHardwareModel() : macModel,
            chip: stringValue("chip_type", in: hardware) ?? localizedHardwareModel(),
            cpuCoreCount: cpuCounts.total,
            performanceCoreCount: cpuCounts.performance,
            efficiencyCoreCount: cpuCounts.efficiency,
            gpuCoreCount: Int(stringValue("sppci_cores", in: display) ?? ""),
            memory: stringValue("physical_memory", in: hardware) ?? memoryDescription(),
            storage: storageDescription(),
            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString
        )
    }

    private static func profilerData() -> [String: Any] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPHardwareDataType", "SPDisplaysDataType", "-json"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return [:] }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        } catch {
            return [:]
        }
    }

    private static func firstDictionary(in profiler: [String: Any], key: String) -> [String: Any] {
        (profiler[key] as? [[String: Any]])?.first ?? [:]
    }

    private static func stringValue(_ key: String, in dictionary: [String: Any]) -> String? {
        dictionary[key] as? String
    }

    private static func cpuCoreCounts(from value: String?) -> (total: Int?, performance: Int?, efficiency: Int?) {
        guard let value else { return (nil, nil, nil) }
        let counts = value
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
        guard let total = counts.first else { return (nil, nil, nil) }
        return (total, counts.count > 1 ? counts[1] : nil, counts.count > 2 ? counts[2] : nil)
    }

    private static func localizedHardwareModel() -> String {
        var size = MemoryLayout<Int>.size
        var value = [CChar](repeating: 0, count: 256)
        guard sysctlbyname("hw.model", &value, &size, nil, 0) == 0 else { return "Mac" }
        let bytes = value.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    private static func memoryDescription() -> String {
        var memoryBytes: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        guard sysctlbyname("hw.memsize", &memoryBytes, &size, nil, 0) == 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(memoryBytes), countStyle: .memory)
    }

    private static func storageDescription() -> String {
        let rootURL = URL(fileURLWithPath: "/")
        let values = try? rootURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])
        guard let totalCapacity = values?.volumeTotalCapacity else { return "—" }
        let total = ByteCountFormatter.string(fromByteCount: Int64(totalCapacity), countStyle: .file)
        guard let availableCapacity = values?.volumeAvailableCapacityForImportantUsage else { return total }
        let available = ByteCountFormatter.string(fromByteCount: availableCapacity, countStyle: .file)
        return "\(total) · \(available) available"
    }
}
