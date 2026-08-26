import Dispatch
import Foundation

/// Runs a bounded local process on a utility thread. `Process.waitUntilExit()`
/// has no timeout and ignores Swift task cancellation, so it is unsafe for an
/// external-drive query that can stall on failing hardware.
struct TimedProcessRunner: Sendable {
    let executableURL: URL
    let timeout: TimeInterval

    func output(arguments: [String]) -> Data? {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        let finished = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in finished.signal() }

        do {
            try process.run()
        } catch {
            return nil
        }
        guard finished.wait(timeout: .now() + timeout) == .success else {
            process.terminate()
            _ = finished.wait(timeout: .now() + 1)
            return nil
        }
        guard process.terminationStatus == 0 else { return nil }
        return output.fileHandleForReading.readDataToEndOfFile()
    }
}
