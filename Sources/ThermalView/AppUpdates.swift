import AppKit
import Foundation
import Observation
import SwiftUI

/// Release tags use SemVer; a final is newer than any beta of the same version.
struct AppReleaseVersion: Comparable, Sendable {
    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: [String]

    init?(_ tag: String) {
        let value = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let buildParts = value.split(separator: "+", maxSplits: 1, omittingEmptySubsequences: false)
        if buildParts.count == 2 {
            let identifiers = buildParts[1].split(separator: ".", omittingEmptySubsequences: false)
            guard identifiers.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") } }) else { return nil }
        }
        let withoutBuild = buildParts[0]
        let parts = withoutBuild.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let numbers = parts[0].split(separator: ".", omittingEmptySubsequences: false)
        guard numbers.count == 3,
              numbers.allSatisfy({ !$0.isEmpty && $0.allSatisfy({ $0.isASCII && $0.isNumber }) && ($0.count == 1 || $0.first != "0") }),
              let major = Int(numbers[0]), let minor = Int(numbers[1]), let patch = Int(numbers[2]) else { return nil }
        let identifiers = parts.count == 2 ? parts[1].split(separator: ".", omittingEmptySubsequences: false).map(String.init) : []
        guard identifiers.allSatisfy({ identifier in
            !identifier.isEmpty && identifier.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
                && (!identifier.allSatisfy(\.isNumber) || identifier.count == 1 || identifier.first != "0")
        }) else { return nil }
        self.major = major
        self.minor = minor
        self.patch = patch
        prerelease = identifiers
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        if lhs.prerelease.isEmpty || rhs.prerelease.isEmpty {
            return !lhs.prerelease.isEmpty && rhs.prerelease.isEmpty
        }
        for (left, right) in zip(lhs.prerelease, rhs.prerelease) where left != right {
            let leftNumeric = left.allSatisfy(\.isNumber)
            let rightNumeric = right.allSatisfy(\.isNumber)
            if leftNumeric && rightNumeric {
                return left.count == right.count ? left < right : left.count < right.count
            }
            if leftNumeric != rightNumeric { return leftNumeric }
            return left < right
        }
        return lhs.prerelease.count < rhs.prerelease.count
    }
}

enum AppUpdateInterval: String, CaseIterable, Identifiable, Sendable {
    case off, daily, weekly, monthly
    var id: String { rawValue }

    func nextCheck(after date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .off: nil
        case .daily: calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly: calendar.date(byAdding: .day, value: 7, to: date)
        case .monthly: calendar.date(byAdding: .month, value: 1, to: date)
        }
    }

    func title(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.off, .english): "Off"
        case (.off, .german): "Aus"
        case (.daily, .english): "Daily"
        case (.daily, .german): "Täglich"
        case (.weekly, .english): "Weekly"
        case (.weekly, .german): "Wöchentlich"
        case (.monthly, .english): "Monthly"
        case (.monthly, .german): "Monatlich"
        }
    }
}

struct GitHubAppRelease: Decodable, Sendable, Equatable {
    let tagName: String
    let htmlURL: URL
    let draft: Bool
    let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name", htmlURL = "html_url", draft, prerelease
    }

    var safeReleaseURL: URL? {
        guard htmlURL.scheme == "https", htmlURL.host == "github.com",
              nil == htmlURL.user, nil == htmlURL.password, htmlURL.port == nil,
              htmlURL.path.hasPrefix("/Schrotty74/ThermalAtlas/releases/tag/") else { return nil }
        return htmlURL
    }

    static func updates(in releases: [Self], installed: AppReleaseVersion) -> [Self] {
        [false, true].compactMap { isBeta in
            releases.filter {
                !$0.draft && $0.prerelease == isBeta && $0.safeReleaseURL != nil
                    && AppReleaseVersion($0.tagName).map { $0 > installed } == true
                    && (isBeta || AppReleaseVersion($0.tagName)?.prerelease.isEmpty == true)
            }.max {
                AppReleaseVersion($0.tagName)! < AppReleaseVersion($1.tagName)!
            }
        }
    }
}

enum AppInstalledVersion {
    static func value(version: String, build: String?, identifier: String?) -> String {
        guard identifier == "io.github.schrotty74.thermalatlas.beta",
              AppReleaseVersion(version)?.prerelease.isEmpty == true else { return version }
        guard let build, !build.isEmpty, build.allSatisfy({ $0.isASCII && $0.isNumber }),
              build.count == 1 || build.first != "0" else { return "" }
        return "\(version)-beta.\(build)"
    }

    static var current: String {
        value(version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
              build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
              identifier: Bundle.main.bundleIdentifier)
    }
}

enum AppUpdateError: Error { case response, paginationLimit, installedVersion }

enum GitHubAppReleaseClient {
    static func fetch() async throws -> [GitHubAppRelease] {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        var releases: [GitHubAppRelease] = []
        for page in 1...10 {
            try Task.checkCancellation()
            let url = URL(string: "https://api.github.com/repos/Schrotty74/ThermalAtlas/releases?per_page=100&page=\(page)")!
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            request.setValue("ThermalAtlas-UpdateCheck", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                throw AppUpdateError.response
            }
            let batch = try JSONDecoder().decode([GitHubAppRelease].self, from: data)
            releases += batch
            if batch.count < 100 { return releases }
        }
        throw AppUpdateError.paginationLimit
    }
}

@MainActor
@Observable
final class AppUpdateService {
    static let intervalKey = "thermalatlas.appUpdateInterval"
    static let lastSuccessKey = "thermalatlas.appUpdateLastSuccess"
    static let lastAttemptKey = "thermalatlas.appUpdateLastAttempt"
    static let notifiedKey = "thermalatlas.appUpdateNotifiedTags"
    private(set) var interval: AppUpdateInterval
    private(set) var isChecking = false
    private(set) var hasChecked = false
    private(set) var failed = false
    private(set) var updates: [GitHubAppRelease] = []
    private(set) var lastSuccess: Date?
    let installedVersion: String
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let fetch: @Sendable () async throws -> [GitHubAppRelease]
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored var report: ((AppUpdateService, Bool) -> Void)?

    init(defaults: UserDefaults = .standard,
         installedVersion: String = AppInstalledVersion.current,
         fetch: @escaping @Sendable () async throws -> [GitHubAppRelease] = GitHubAppReleaseClient.fetch) {
        self.defaults = defaults
        self.installedVersion = installedVersion
        self.fetch = fetch
        interval = AppUpdateInterval(rawValue: defaults.string(forKey: Self.intervalKey) ?? "") ?? .off
        lastSuccess = defaults.object(forKey: Self.lastSuccessKey) as? Date
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkIfDue() }
        }
        checkIfDue()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        task?.cancel()
        task = nil
    }

    func setInterval(_ value: AppUpdateInterval) {
        interval = value
        defaults.set(value.rawValue, forKey: Self.intervalKey)
        if value == .off {
            task?.cancel()
        } else {
            checkIfDue()
        }
    }

    func isDue(at now: Date) -> Bool {
        guard interval != .off else { return false }
        // Failed requests retry at most hourly, including across app restarts.
        if let attempt = defaults.object(forKey: Self.lastAttemptKey) as? Date,
           now.timeIntervalSince(attempt) < 3600 { return false }
        guard let lastSuccess else { return true }
        return interval.nextCheck(after: lastSuccess).map { now >= $0 } ?? false
    }

    func checkIfDue() {
        if isDue(at: Date()) { check(manual: false) }
    }

    @discardableResult
    func check(manual: Bool) -> Task<Void, Never>? {
        guard !isChecking else { return nil }
        isChecking = true
        failed = false
        defaults.set(Date(), forKey: Self.lastAttemptKey)
        task = Task {
            defer { isChecking = false; task = nil }
            do {
                guard let installed = AppReleaseVersion(installedVersion) else { throw AppUpdateError.installedVersion }
                let releases = try await fetch()
                try Task.checkCancellation()
                updates = GitHubAppRelease.updates(in: releases, installed: installed)
                lastSuccess = Date()
                defaults.set(lastSuccess, forKey: Self.lastSuccessKey)
                hasChecked = true
                var notified = Set(defaults.stringArray(forKey: Self.notifiedKey) ?? [])
                let unseen = updates.contains { !notified.contains($0.tagName) }
                if manual || unseen {
                    report?(self, manual)
                    notified.formUnion(updates.map(\.tagName))
                    defaults.set(Array(notified), forKey: Self.notifiedKey)
                }
            } catch is CancellationError {
                // Turning automatic checks off must not produce a late update notice.
            } catch {
                guard !Task.isCancelled else { return }
                failed = true
                if manual { report?(self, true) }
            }
        }
        return task
    }
}

extension AppLanguage {
    var appUpdatesTitle: String { self == .english ? "App Updates" : "App-Updates" }
    var checkUpdatesTitle: String { self == .english ? "Check Now…" : "Jetzt prüfen …" }
    var checkingUpdatesTitle: String { self == .english ? "Checking GitHub…" : "GitHub wird geprüft …" }
    var automaticUpdatesTitle: String { self == .english ? "Automatic Checks" : "Automatisch prüfen" }
    var updatesFailedTitle: String { self == .english ? "Check failed. Please try again later." : "Prüfung fehlgeschlagen. Bitte später erneut versuchen." }
    var noUpdatesTitle: String { self == .english ? "No newer Final or Beta version available." : "Keine neuere Final- oder Beta-Version verfügbar." }
    var updatesAvailableTitle: String { self == .english ? "New version available" : "Neue Version verfügbar" }
    var updatePrivacyHint: String { self == .english ? "Checks contact GitHub. No sensor or device data is sent." : "Prüfungen kontaktieren GitHub. Es werden keine Sensor- oder Gerätedaten gesendet." }
    var updatesNotCheckedTitle: String { self == .english ? "Not checked yet" : "Noch nicht geprüft" }
    var installedVersionTitle: String { self == .english ? "Installed version" : "Installierte Version" }
    var lastUpdateCheckTitle: String { self == .english ? "Last successful check" : "Letzte erfolgreiche Prüfung" }
}

struct AppUpdatesMenu: View {
    let service: AppUpdateService
    let language: AppLanguage

    var body: some View {
        Menu(language.appUpdatesTitle) {
            Button(service.isChecking ? language.checkingUpdatesTitle : language.checkUpdatesTitle) {
                service.check(manual: true)
            }
            .disabled(service.isChecking)
            Menu(language.automaticUpdatesTitle) {
                ForEach(AppUpdateInterval.allCases) { interval in
                    Button { service.setInterval(interval) } label: {
                        Label(interval.title(for: language), systemImage: interval == service.interval ? "checkmark" : "calendar")
                    }
                }
            }
            Text(language.updatePrivacyHint)
            Divider()
            Text("\(language.installedVersionTitle): \(service.installedVersion)")
            if let date = service.lastSuccess {
                Text("\(language.lastUpdateCheckTitle): \(date.formatted(.dateTime.day().month().year().hour().minute().locale(language.locale)))")
            }
            if service.failed {
                Text(language.updatesFailedTitle)
            } else if service.hasChecked && service.updates.isEmpty {
                Text(language.noUpdatesTitle)
            } else if !service.hasChecked {
                Text(language.updatesNotCheckedTitle)
            }
            ForEach(service.updates, id: \.tagName) { release in
                Button("\(release.prerelease ? "Beta" : "Final"): \(release.tagName)") {
                    if let url = release.safeReleaseURL { NSWorkspace.shared.open(url) }
                }
            }
        }
    }
}

@MainActor
enum AppUpdateWindow {
    private static var panel: NSPanel?

    static func show(service: AppUpdateService, manual: Bool) {
        let language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "thermalatlas.language") ?? "") ?? .defaultLanguage
        let panel = panel ?? NSPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 200),
                                    styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        panel.title = language.appUpdatesTitle
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(rootView: AppUpdateResultView(service: service, language: language, close: { panel.close() }))
        panel.contentView?.layoutSubtreeIfNeeded()
        if let size = panel.contentView?.fittingSize { panel.setContentSize(size) }
        if self.panel == nil { panel.center() }
        self.panel = panel
        panel.orderFrontRegardless()
        if manual { panel.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    }
}

private struct AppUpdateResultView: View {
    let service: AppUpdateService
    let language: AppLanguage
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(service.failed ? language.updatesFailedTitle : service.updates.isEmpty ? language.noUpdatesTitle : language.updatesAvailableTitle)
                .font(.headline)
            Text("\(language.installedVersionTitle): \(service.installedVersion)")
            if !service.failed {
                ForEach(service.updates, id: \.tagName) { release in
                    Button("\(release.prerelease ? "Beta" : "Final"): \(release.tagName) ↗") {
                        if let url = release.safeReleaseURL { NSWorkspace.shared.open(url) }
                    }
                }
            }
            HStack { Spacer(); Button(language.closeTitle, action: close).keyboardShortcut(.defaultAction) }
        }
        .padding(20)
        .frame(width: 420, alignment: .leading)
    }
}
