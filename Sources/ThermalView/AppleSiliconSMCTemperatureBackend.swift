import Darwin
import Foundation
import IOKit

/// Read-only access to private Apple Silicon SMC temperature keys.
///
/// This adapter only uses the SMC read-key-info and read-bytes commands. It
/// contains no write command, fan operation, or energy-management operation.
struct AppleSiliconSMCTemperatureBackend {
    struct Result {
        let celsius: Double?
        let detail: String?
        let unavailableReason: String
    }

    func cpuTemperature() -> Result {
        result(
            keys: Self.m4MaxCPUKeys,
            label: "CPU-Kerne",
            unavailablePrefix: "Keine lesbaren CPU-Temperatursensoren"
        )
    }

    func gpuTemperature() -> Result {
        result(
            keys: Self.m4MaxGPUKeys,
            label: "GPU-Zonen",
            unavailablePrefix: "Keine lesbaren GPU-Temperatursensoren",
            retryEmptyBatchAfterReconnect: true
        )
    }

    private func result(
        keys: [String],
        label: String,
        unavailablePrefix: String,
        retryEmptyBatchAfterReconnect: Bool = false
    ) -> Result {
        for attempt in 0..<3 {
            let sample = SMCConnection.shared.sample(
                keys: keys,
                retryEmptyBatchAfterReconnect: retryEmptyBatchAfterReconnect
            )
            if let average = TemperatureAggregation.arithmeticMean(sample.values) {
                return Result(
                    celsius: average,
                    detail: "Apple-Silicon \(label) · Mittelwert aus \(sample.values.count) Sensoren",
                    unavailableReason: ""
                )
            }
            if attempt < 2 { usleep(30_000) }
        }

        let reason = SMCConnection.shared.lastFailureDescription ?? "SMC-Sensorzugriff nicht verfügbar"
        return Result(celsius: nil, detail: nil, unavailableReason: "\(unavailablePrefix) (\(reason))")
    }

    // These M4 Max CPU-core and GPU-zone keys were verified against the local
    // sensor registry. Their arithmetic mean intentionally matches the
    // "Average CPU" / "Average GPU" semantics used by Stats.
    private static let m4MaxCPUKeys = [
        "Te05", "Te0S", "Te09", "Te0H",
        "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0V", "Tp0Y", "Tp0b", "Tp0e"
    ]

    private static let m4MaxGPUKeys = ["Tg1U", "Tg1k", "Tg0K", "Tg0L", "Tg0d", "Tg0e", "Tg0j", "Tg0k"]
}

private final class SMCReader: @unchecked Sendable {
    private let connection: io_connect_t

    init?() {
        // Older Apple Silicon releases register this service as AppleSMC, while
        // current releases expose the same read-only user client via this
        // endpoint. Try both names without assuming that either will exist.
        let names = ["AppleSMC", "AppleSMCKeysEndpoint"]
        var openedConnection: io_connect_t = 0

        for name in names {
            let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(name))
            guard service != IO_OBJECT_NULL else { continue }
            defer { IOObjectRelease(service) }
            if IOServiceOpen(service, mach_task_self_, 0, &openedConnection) == KERN_SUCCESS {
                connection = openedConnection
                return
            }
        }
        return nil
    }

    deinit { IOServiceClose(connection) }

    func temperature(for key: String) -> SMCReadResult {
        guard key.utf8.count == 4 else { return SMCReadResult(value: nil, failure: .invalidKey) }

        var infoRequest = SMCKeyData()
        infoRequest.key = fourCharacterCode(key)
        infoRequest.data8 = SMCCommand.readKeyInfo.rawValue
        var infoResponse = SMCKeyData()
        let infoStatus = call(input: &infoRequest, output: &infoResponse)
        guard infoStatus == KERN_SUCCESS else {
            return SMCReadResult(value: nil, failure: .transport(infoStatus))
        }
        guard infoResponse.result == 0 else {
            return SMCReadResult(value: nil, failure: .firmware(infoResponse.result))
        }
        guard infoResponse.keyInfo.dataSize > 0, infoResponse.keyInfo.dataSize <= 32 else {
            return SMCReadResult(value: nil, failure: .invalidResponse)
        }

        var readRequest = SMCKeyData()
        readRequest.key = fourCharacterCode(key)
        readRequest.keyInfo.dataSize = infoResponse.keyInfo.dataSize
        readRequest.data8 = SMCCommand.readBytes.rawValue
        var readResponse = SMCKeyData()
        let readStatus = call(input: &readRequest, output: &readResponse)
        guard readStatus == KERN_SUCCESS else {
            return SMCReadResult(value: nil, failure: .transport(readStatus))
        }
        guard readResponse.result == 0 else {
            return SMCReadResult(value: nil, failure: .firmware(readResponse.result))
        }

        let value = decodeTemperature(
            bytes: bytes(of: readResponse.bytes),
            type: fourCharacterString(infoResponse.keyInfo.dataType)
        )
        return SMCReadResult(value: value, failure: value == nil ? .unsupportedValue : nil)
    }

    private func call(input: inout SMCKeyData, output: inout SMCKeyData) -> kern_return_t {
        var outputSize = MemoryLayout<SMCKeyData>.stride
        return IOConnectCallStructMethod(
            connection, 2, &input, MemoryLayout<SMCKeyData>.stride, &output, &outputSize
        )
    }

    private func decodeTemperature(bytes: [UInt8], type: String) -> Double? {
        guard bytes.count >= 2 else { return nil }
        let unsigned = Double(Int(bytes[0]) << 8 | Int(bytes[1]))
        let value: Double?
        switch type {
        case "sp78": value = unsigned / 256
        case "sp87": value = unsigned / 128
        case "sp96": value = unsigned / 64
        case "sp5a": value = unsigned / 1024
        case "sp69": value = unsigned / 512
        case "flt ":
            guard bytes.count >= MemoryLayout<Float>.size else { return nil }
            let float = bytes.withUnsafeBytes { $0.loadUnaligned(as: Float.self) }
            value = Double(float)
        default: value = nil
        }
        guard let value, value.isFinite, (15...125).contains(value) else { return nil }
        return value
    }

    private func fourCharacterCode(_ string: String) -> UInt32 {
        string.utf8.reduce(0) { ($0 << 8) | UInt32($1) }
    }

    private func fourCharacterString(_ code: UInt32) -> String {
        String(bytes: [
            UInt8((code >> 24) & 0xFF), UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF), UInt8(code & 0xFF)
        ], encoding: .ascii) ?? ""
    }

    private func bytes(of tuple: SMCKeyData.Bytes) -> [UInt8] {
        withUnsafeBytes(of: tuple) { Array($0) }
    }
}

private final class SMCConnection: @unchecked Sendable {
    static let shared = SMCConnection()

    private let lock = NSLock()
    private var reader: SMCReader? = SMCReader()
    private(set) var lastFailureDescription: String?

    func sample(keys: [String], retryEmptyBatchAfterReconnect: Bool) -> SMCBatch {
        lock.lock()
        defer { lock.unlock() }

        let first = read(keys: keys)
        guard first.values.isEmpty,
              (first.hasTransportFailure || retryEmptyBatchAfterReconnect) else { return first }

        // A private GPU SMC client can stop returning its whole sensor family
        // without surfacing an IOKit transport error. Reopen it after that
        // specific empty batch and retry once; CPU retains its existing
        // transport-error-only recovery path.
        reader = nil
        reader = SMCReader()
        return read(keys: keys)
    }

    private func read(keys: [String]) -> SMCBatch {
        guard let reader else {
            lastFailureDescription = "SMC-Client konnte nicht geöffnet werden"
            return SMCBatch(values: [], hasTransportFailure: true)
        }

        var values: [Double] = []
        var failures: [SMCReadFailure] = []
        for key in keys {
            let result = reader.temperature(for: key)
            if let value = result.value { values.append(value) }
            if let failure = result.failure { failures.append(failure) }
        }
        lastFailureDescription = failures.first?.description
        return SMCBatch(values: values, hasTransportFailure: failures.contains(where: { $0.isTransportFailure }) )
    }
}

private struct SMCBatch {
    let values: [Double]
    let hasTransportFailure: Bool
}

private struct SMCReadResult {
    let value: Double?
    let failure: SMCReadFailure?
}

private enum SMCReadFailure {
    case invalidKey
    case transport(kern_return_t)
    case firmware(UInt8)
    case invalidResponse
    case unsupportedValue

    var isTransportFailure: Bool {
        if case .transport = self { return true }
        return false
    }

    var description: String {
        switch self {
        case .invalidKey: "ungültiger Sensor-Key"
        case .transport(let status): "IOKit-Fehler 0x\(String(UInt32(bitPattern: status), radix: 16))"
        case .firmware(let status): "SMC-Fehler 0x\(String(status, radix: 16))"
        case .invalidResponse: "ungültige SMC-Antwort"
        case .unsupportedValue: "unbekanntes SMC-Temperaturformat"
        }
    }
}

private enum SMCCommand: UInt8 {
    case readBytes = 5
    case readKeyInfo = 9
}

private struct SMCKeyData {
    typealias Bytes = (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )

    struct Version {
        var major: UInt8 = 0
        var minor: UInt8 = 0
        var build: UInt8 = 0
        var reserved: UInt8 = 0
        var release: UInt16 = 0
    }

    struct PowerLimit {
        var version: UInt16 = 0
        var length: UInt16 = 0
        var cpu: UInt32 = 0
        var gpu: UInt32 = 0
        var memory: UInt32 = 0
    }

    struct KeyInfo {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var attributes: UInt8 = 0
    }

    var key: UInt32 = 0
    var version = Version()
    var powerLimit = PowerLimit()
    var keyInfo = KeyInfo()
    var padding: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: Bytes = (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
}
