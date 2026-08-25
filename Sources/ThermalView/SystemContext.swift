import Foundation
import IOKit
import IOKit.ps
import MachO

/// Read-only operating context displayed separately from temperature sensors.
/// It never controls performance, battery charging, or macOS power settings.
struct SystemContext: Sendable, Equatable {
    struct MemoryUsage: Sendable, Equatable {
        let usedBytes: UInt64
        let totalBytes: UInt64

        var usagePercent: Double {
            guard totalBytes > 0 else { return 0 }
            return min(100, max(0, Double(usedBytes) / Double(totalBytes) * 100))
        }

        var loadStatus: MemoryLoadStatus {
            switch usagePercent {
            case ..<70: .normal
            case ..<85: .elevated
            default: .high
            }
        }
    }

    enum MemoryLoadStatus: Sendable, Equatable {
        case normal
        case elevated
        case high

        func title(for language: AppLanguage) -> String {
            switch (self, language) {
            case (.normal, .english): "Normal"
            case (.elevated, .english): "Elevated"
            case (.high, .english): "High"
            case (.normal, .german): "Normal"
            case (.elevated, .german): "Erhöht"
            case (.high, .german): "Hoch"
            }
        }
    }

    enum PowerSource: Sendable, Equatable {
        case powerAdapter
        case battery(percentage: Int?)
        case unavailable
    }

    let cpuUsagePercent: Double?
    let gpuUsagePercent: Double?
    let memoryUsage: MemoryUsage?
    let powerSource: PowerSource
    let isLowPowerModeEnabled: Bool

    static let unavailable = SystemContext(
        cpuUsagePercent: nil,
        gpuUsagePercent: nil,
        memoryUsage: nil,
        powerSource: .unavailable,
        isLowPowerModeEnabled: false
    )
}

/// Computes CPU load from successive public Mach CPU-tick snapshots. A single
/// snapshot has no elapsed interval, so the first value intentionally remains
/// unavailable until the following regular sensor refresh.
struct CPUUsageSampler {
    private var previousTicks: (busy: UInt64, total: UInt64)?

    mutating func sample() -> Double? {
        guard let ticks = Self.currentTicks() else { return nil }
        defer { previousTicks = ticks }
        guard let previousTicks else { return nil }

        let busyDelta = ticks.busy >= previousTicks.busy ? ticks.busy - previousTicks.busy : 0
        let totalDelta = ticks.total >= previousTicks.total ? ticks.total - previousTicks.total : 0
        guard totalDelta > 0 else { return nil }
        return min(100, max(0, Double(busyDelta) / Double(totalDelta) * 100))
    }

    private static func currentTicks() -> (busy: UInt64, total: UInt64)? {
        var processorInfo: processor_info_array_t?
        var processorCount: mach_msg_type_number_t = 0
        var infoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &processorInfo,
            &infoCount
        )
        guard result == KERN_SUCCESS, let processorInfo else { return nil }
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: processorInfo),
                vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            )
        }

        let ticksPerProcessor = Int(CPU_STATE_MAX)
        var busy: UInt64 = 0
        var total: UInt64 = 0
        for index in 0..<Int(processorCount) {
            let offset = index * ticksPerProcessor
            let user = UInt64(processorInfo[offset + Int(CPU_STATE_USER)])
            let system = UInt64(processorInfo[offset + Int(CPU_STATE_SYSTEM)])
            let nice = UInt64(processorInfo[offset + Int(CPU_STATE_NICE)])
            let idle = UInt64(processorInfo[offset + Int(CPU_STATE_IDLE)])
            busy += user + system + nice
            total += user + system + nice + idle
        }
        return (busy, total)
    }
}

struct SystemContextReader {
    private var cpuUsageSampler = CPUUsageSampler()

    mutating func read() -> SystemContext {
        SystemContext(
            cpuUsagePercent: cpuUsageSampler.sample(),
            gpuUsagePercent: GPUUsageReader.currentUsagePercent(),
            memoryUsage: MemoryUsageReader.currentUsage(),
            powerSource: Self.powerSource(),
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
    }

    private static func powerSource() -> SystemContext.PowerSource {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return .unavailable
        }
        let sources = IOPSCopyPowerSourcesList(blob).takeRetainedValue() as [CFTypeRef]
        guard !sources.isEmpty else { return .powerAdapter }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
                  (description[kIOPSPowerSourceStateKey] as? String) == kIOPSBatteryPowerValue else { continue }
            let percentage = description[kIOPSCurrentCapacityKey] as? Int
            return .battery(percentage: percentage)
        }
        return .powerAdapter
    }
}

/// Reads the memory pages currently occupied by apps, the system and the
/// compressed-memory store. File cache pages are intentionally excluded, so
/// the value describes actual RAM pressure rather than available cache.
enum MemoryUsageReader {
    static func currentUsage() -> SystemContext.MemoryUsage? {
        var statistics = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &statistics) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else { return nil }
        let usedPages = UInt64(statistics.active_count)
            + UInt64(statistics.wire_count)
            + UInt64(statistics.compressor_page_count)
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        guard totalBytes > 0 else { return nil }
        return SystemContext.MemoryUsage(
            usedBytes: min(totalBytes, usedPages * UInt64(pageSize)),
            totalBytes: totalBytes
        )
    }
}

/// Reads the aggregate utilization currently published by Apple's integrated
/// GPU driver. This is observational only; the registry value is not present
/// on every macOS or Apple-silicon generation, so absence is represented by
/// `nil` rather than an estimate.
enum GPUUsageReader {
    static func currentUsagePercent() -> Double? {
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

            guard let statistics = IORegistryEntryCreateCFProperty(
                service,
                "PerformanceStatistics" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? [String: Any] else {
                continue
            }
            if let usage = usagePercent(from: statistics) {
                return usage
            }
        }
    }

    static func usagePercent(from statistics: [String: Any]) -> Double? {
        guard let number = statistics["Device Utilization %"] as? NSNumber else { return nil }
        return min(100, max(0, number.doubleValue))
    }
}
