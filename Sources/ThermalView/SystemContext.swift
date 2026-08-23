import Foundation
import IOKit.ps
import MachO

/// Read-only operating context displayed separately from temperature sensors.
/// It never controls performance, battery charging, or macOS power settings.
struct SystemContext: Sendable, Equatable {
    enum PowerSource: Sendable, Equatable {
        case powerAdapter
        case battery(percentage: Int?)
        case unavailable
    }

    let cpuUsagePercent: Double?
    let powerSource: PowerSource
    let isLowPowerModeEnabled: Bool

    static let unavailable = SystemContext(
        cpuUsagePercent: nil,
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
