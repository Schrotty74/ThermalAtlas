import XCTest
@testable import ThermalAtlas

final class AppUpdateTests: XCTestCase {
    private func release(_ tag: String, beta: Bool = false, draft: Bool = false,
                         address: String? = nil) -> GitHubAppRelease {
        GitHubAppRelease(tagName: tag,
                         htmlURL: URL(string: address ?? "https://github.com/Schrotty74/ThermalAtlas/releases/tag/\(tag)")!,
                         draft: draft, prerelease: beta)
    }

    func testInstalledBetaIdentityPreservesBuildAndDetectsNextBetaAndFinal() throws {
        let version = AppInstalledVersion.value(version: "1.2.0", build: "5", identifier: "io.github.schrotty74.thermalatlas.beta")
        XCTAssertEqual(version, "1.2.0-beta.5")
        let installed = try XCTUnwrap(AppReleaseVersion(version))
        XCTAssertTrue(try XCTUnwrap(AppReleaseVersion("1.2.0-beta.6")) > installed)
        XCTAssertTrue(try XCTUnwrap(AppReleaseVersion("1.2.0")) > installed)
        XCTAssertEqual(AppInstalledVersion.value(version: "1.2.0", build: "5", identifier: "io.github.schrotty74.thermalatlas"), "1.2.0")
        XCTAssertEqual(AppInstalledVersion.value(version: "1.2.0", build: nil, identifier: "io.github.schrotty74.thermalatlas.beta"), "")
    }

    func testVersionOrderingHandlesNumericBetasAndFinalPromotion() throws {
        let tags = ["v1.1.0", "1.2.0-beta.4", "1.2.0-beta.10", "1.2.0", "1.10.0", "2.0.0"]
        let versions = try tags.map { try XCTUnwrap(AppReleaseVersion($0)) }
        XCTAssertEqual(versions.sorted(), versions)
        XCTAssertEqual(AppReleaseVersion("1.2.0+build.5"), AppReleaseVersion("v1.2.0"))
        for invalid in ["", "main", "1.2", "1.2.0-", "01.2.0", "1.2.0-beta.04", "1.2.0-ß", "1.2.0+", "1.2.0+bad+build"] {
            XCTAssertNil(AppReleaseVersion(invalid), invalid)
        }
    }

    func testSelectsHighestNewFinalAndBetaWithoutRelyingOnAPISortOrder() throws {
        let releases = [release("v1.2.0-beta.10", beta: true), release("v1.2.0"),
                        release("v1.2.0-beta.4", beta: true), release("v1.1.0"),
                        release("v9.0.0", draft: true), release("invalid"),
                        release("v8.0.0", address: "https://example.com/update"),
                        release("v7.0.0-beta.1")]
        XCTAssertEqual(GitHubAppRelease.updates(in: releases, installed: try XCTUnwrap(AppReleaseVersion("1.2.0-beta.4"))).map(\.tagName),
                       ["v1.2.0", "v1.2.0-beta.10"])
        XCTAssertTrue(GitHubAppRelease.updates(in: releases, installed: try XCTUnwrap(AppReleaseVersion("1.2.0"))).isEmpty)
    }

    func testNewerBetaCanBeOfferedToFinalButSameVersionBetaIsNotADowngrade() throws {
        let releases = [release("v1.2.0-beta.10", beta: true), release("v1.3.0-beta.1", beta: true)]
        XCTAssertEqual(GitHubAppRelease.updates(in: releases, installed: try XCTUnwrap(AppReleaseVersion("1.2.0"))).map(\.tagName),
                       ["v1.3.0-beta.1"])
    }

    func testMonthlyIntervalUsesCalendarMonthIncludingShortMonths() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let january = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12)))
        let february = try XCTUnwrap(AppUpdateInterval.monthly.nextCheck(after: january, calendar: calendar))
        XCTAssertEqual(calendar.component(.month, from: february), 2)
        XCTAssertEqual(calendar.component(.day, from: february), 28)
        XCTAssertEqual(AppUpdateInterval.daily.nextCheck(after: january, calendar: calendar), january.addingTimeInterval(86400))
        XCTAssertEqual(AppUpdateInterval.weekly.nextCheck(after: january, calendar: calendar), january.addingTimeInterval(7 * 86400))
        XCTAssertNil(AppUpdateInterval.off.nextCheck(after: january))
    }

    @MainActor
    private func isolatedDefaults() throws -> UserDefaults {
        try XCTUnwrap(UserDefaults(suiteName: "ThermalAtlasUpdateTests.\(UUID().uuidString)"))
    }

    @MainActor
    func testDefaultsOffAndPersistedScheduleSurvivesRestart() throws {
        let defaults = try isolatedDefaults()
        defer { defaults.removeObject(forKey: AppUpdateService.intervalKey); defaults.removeObject(forKey: AppUpdateService.lastSuccessKey) }
        let service = AppUpdateService(defaults: defaults, installedVersion: "1.1.0", fetch: { [] })
        XCTAssertEqual(service.interval, .off)
        XCTAssertFalse(service.isDue(at: Date()))
        let now = Date()
        defaults.set("weekly", forKey: AppUpdateService.intervalKey)
        defaults.set(now, forKey: AppUpdateService.lastSuccessKey)
        let restarted = AppUpdateService(defaults: defaults, installedVersion: "1.1.0", fetch: { [] })
        XCTAssertEqual(restarted.interval, .weekly)
        XCTAssertFalse(restarted.isDue(at: now.addingTimeInterval(6 * 86400)))
        XCTAssertTrue(restarted.isDue(at: now.addingTimeInterval(8 * 86400)))
    }

    @MainActor
    func testSuccessPersistsAndAutomaticNoticeIsNotRepeated() async throws {
        let defaults = try isolatedDefaults()
        defer {
            for key in [AppUpdateService.lastSuccessKey, AppUpdateService.lastAttemptKey, AppUpdateService.notifiedKey] { defaults.removeObject(forKey: key) }
        }
        let newer = release("v1.2.0-beta.4", beta: true)
        let service = AppUpdateService(defaults: defaults, installedVersion: "1.1.0", fetch: { [newer] })
        var reports = 0
        service.report = { _, _ in reports += 1 }
        await service.check(manual: false)?.value
        XCTAssertEqual(service.updates, [newer])
        XCTAssertEqual(reports, 1)
        XCTAssertNotNil(defaults.object(forKey: AppUpdateService.lastSuccessKey))
        await service.check(manual: false)?.value
        XCTAssertEqual(reports, 1)
        await service.check(manual: true)?.value
        XCTAssertEqual(reports, 2)
        let restarted = AppUpdateService(defaults: defaults, installedVersion: "1.1.0", fetch: { [newer] })
        restarted.report = { _, _ in reports += 1 }
        await restarted.check(manual: false)?.value
        XCTAssertEqual(reports, 2)
    }

    @MainActor
    func testFailureDoesNotClaimSuccessAndBacksOff() async throws {
        let defaults = try isolatedDefaults()
        defer { defaults.removeObject(forKey: AppUpdateService.lastAttemptKey); defaults.removeObject(forKey: AppUpdateService.intervalKey) }
        defaults.set("daily", forKey: AppUpdateService.intervalKey)
        let service = AppUpdateService(defaults: defaults, installedVersion: "1.1.0", fetch: { throw AppUpdateError.response })
        await service.check(manual: true)?.value
        XCTAssertTrue(service.failed)
        XCTAssertFalse(service.hasChecked)
        XCTAssertNil(service.lastSuccess)
        XCTAssertFalse(service.isDue(at: Date()))
        XCTAssertTrue(service.isDue(at: Date().addingTimeInterval(3601)))
    }

    @MainActor
    func testDisableCancelsInFlightCheckAndOverlappingChecksAreCoalesced() async throws {
        let defaults = try isolatedDefaults()
        defer { defaults.removeObject(forKey: AppUpdateService.lastAttemptKey); defaults.removeObject(forKey: AppUpdateService.intervalKey) }
        let service = AppUpdateService(defaults: defaults, installedVersion: "1.1.0", fetch: {
            try await Task.sleep(for: .seconds(30))
            return []
        })
        var reports = 0
        service.report = { _, _ in reports += 1 }
        let running = service.check(manual: false)
        XCTAssertNil(service.check(manual: true))
        service.setInterval(.off)
        await running?.value
        XCTAssertFalse(service.isChecking)
        XCTAssertFalse(service.failed)
        XCTAssertFalse(service.hasChecked)
        XCTAssertEqual(reports, 0)
    }

    func testGitHubPayloadDecodesAndUnsafeURLsAreRejected() throws {
        let json = Data("""
        [{"tag_name":"v1.2.0-beta.4","html_url":"https://github.com/Schrotty74/ThermalAtlas/releases/tag/v1.2.0-beta.4","draft":false,"prerelease":true}]
        """.utf8)
        XCTAssertEqual(try JSONDecoder().decode([GitHubAppRelease].self, from: json).first?.tagName, "v1.2.0-beta.4")
        for address in ["https://user:example@github.com/Schrotty74/ThermalAtlas/releases/tag/v2.0.0", "http://github.com/Schrotty74/ThermalAtlas/releases/tag/v2.0.0", "https://github.com/other/app/releases/tag/v2.0.0", "https://github.com.evil.example/Schrotty74/ThermalAtlas/releases/tag/v2.0.0"] {
            XCTAssertNil(release("v2.0.0", address: address).safeReleaseURL)
        }
    }

    func testLiveGitHubReleaseFetchWhenExplicitlyEnabled() async throws {
        guard ProcessInfo.processInfo.environment["THERMALATLAS_LIVE_UPDATE_TEST"] == "1" else {
            throw XCTSkip("Live network check is opt-in")
        }
        let releases = try await GitHubAppReleaseClient.fetch()
        XCTAssertTrue(releases.contains { $0.tagName == "v1.2.0-beta.4" && $0.prerelease && !$0.draft })
    }
}
