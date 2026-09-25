import Darwin
import Foundation
import IOKit

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
    let thermalState: ProcessInfo.ThermalState
}

enum SystemInformationReader {
    static func read() -> SystemInformationSnapshot {
        return SystemInformationSnapshot(
            macModel: systemString(named: "hw.model") ?? "Mac",
            chip: systemString(named: "machdep.cpu.brand_string") ?? "Apple silicon",
            cpuCoreCount: systemInteger(named: "hw.physicalcpu"),
            performanceCoreCount: systemInteger(named: "hw.perflevel0.physicalcpu"),
            efficiencyCoreCount: systemInteger(named: "hw.perflevel1.physicalcpu"),
            gpuCoreCount: gpuCoreCount(),
            memory: memoryDescription(),
            storage: storageDescription(),
            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
            thermalState: ProcessInfo.processInfo.thermalState
        )
    }

    private static func systemString(named name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else { return nil }
        var value = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return String(decoding: value.map { UInt8(bitPattern: $0) }.prefix(while: { $0 != 0 }), as: UTF8.self)
    }

    private static func systemInteger(named name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0, value > 0 else { return nil }
        return Int(value)
    }

    private static func gpuCoreCount() -> Int? {
        guard let matching = IOServiceMatching("AGXAccelerator") else { return nil }
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { return nil }
            defer { IOObjectRelease(service) }
            guard let value = IORegistryEntryCreateCFProperty(
                service,
                "gpu-core-count" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? NSNumber else { continue }
            let count = value.intValue
            if count > 0 { return Int(count) }
        }
    }

    private static func memoryDescription() -> String {
        guard let memoryBytes = systemMemoryBytes() else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(memoryBytes), countStyle: .memory)
    }

    private static func systemMemoryBytes() -> UInt64? {
        var value: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        guard sysctlbyname("hw.memsize", &value, &size, nil, 0) == 0, value > 0 else { return nil }
        return value
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
