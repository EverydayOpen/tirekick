import Foundation
@testable import TirekickCore
@testable import TirekickMac
import XCTest

// Seeded from Whydunit's PlatformTests (ProcessRunner is a verbatim copy). Tests may run any tool;
// the allowlist applies to Sources/ and App/ only.
final class PlatformTests: XCTestCase {
    func testRunsEcho() async throws {
        let result = try await ProcessRunner.run("/bin/echo", ["hello", "world"])
        XCTAssertEqual(result.status, 0)
        XCTAssertEqual(result.stdout, "hello world\n")
        XCTAssertEqual(result.stderr, "")
        XCTAssertFalse(result.timedOut)
    }

    func testTimeoutTerminates() async throws {
        let start = Date()
        let result = try await ProcessRunner.run("/bin/sleep", ["30"], timeout: 0.5)
        XCTAssertTrue(result.timedOut)
        XCTAssertLessThan(Date().timeIntervalSince(start), 10)
    }

    /// The backgrounded sleep inherits the pipe and ignores SIGTERM, so killing the direct child never closes it.
    /// Without the trap it died with the child on CI (0.52 s) and this test never reached the give-up path.
    func testTimeoutReturnsWhileAHelperHoldsThePipe() async throws {
        let start = Date()
        let result = try await ProcessRunner.run("/bin/sh", ["-c", "trap '' TERM; sleep 30 & sleep 30"], timeout: 0.5)
        XCTAssertTrue(result.timedOut)
        XCTAssertLessThan(Date().timeIntervalSince(start), 10)
    }

    func testLargeOutputDrainsAndCaps() async throws {
        let full = try await ProcessRunner.run("/usr/bin/seq", ["1", "200000"]) // ~1.3 MB, far past the 64 KB pipe buffer
        XCTAssertEqual(full.status, 0)
        XCTAssertTrue(full.stdout.hasSuffix("\n200000\n"))
        let capped = try await ProcessRunner.run("/usr/bin/seq", ["1", "200000"], maxOutputBytes: 1000)
        XCTAssertEqual(capped.stdout.utf8.count, 1000)
    }

    func testMissingExecutableThrows() async {
        do {
            _ = try await ProcessRunner.run("/nonexistent/tirekick-tool", [])
            XCTFail("expected an error")
        } catch {}
    }

    func testOSVersionIsAtLeastTheDeploymentTarget() {
        XCTAssertGreaterThanOrEqual(SystemInfo.osVersion().major, 13)
    }

    func testAllowlistRefusesEverythingElse() {
        for command in Command.all { XCTAssertTrue(Collector.isAllowed(command), command.display) }
        let refused = [
            Command("/bin/sh", ["-c", "true"]),
            Command("/usr/bin/profiles", ["show", "-type", "enrollment"]),
            Command("/usr/bin/fdesetup", ["disable"]),
            Command("/usr/sbin/sysctl", ["-w", "kern.hostname=x"]),
        ]
        for command in refused { XCTAssertFalse(Collector.isAllowed(command), command.display) }
    }

    func testTimeoutKeepsNoOutput() async {
        let evidence = await Collector.run(.displays, timeout: 0.01)
        XCTAssertEqual(evidence.rawOutput, "")
        XCTAssertTrue(evidence.errorOutput.hasPrefix("Timed out"), evidence.errorOutput)
    }

    func testICloudAccountsLeavesOnlyTheCount() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("MobileMeAccounts.plist")
        let plist: [String: Any] = ["Accounts": [["AccountID": "someone@example.com", "DisplayName": "Someone"]]]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0).write(to: file)
        XCTAssertEqual(Collector.iCloudAccounts(at: file.path).rawOutput, "Accounts: 1")
        XCTAssertEqual(Collector.iCloudAccounts(at: dir.appendingPathComponent("missing.plist").path).rawOutput, "Accounts: 0")
        try PropertyListSerialization.data(fromPropertyList: ["Other": 1], format: .binary, options: 0).write(to: file)
        XCTAssertEqual(Collector.iCloudAccounts(at: file.path).rawOutput, "")
        try Data("not a plist".utf8).write(to: file)
        XCTAssertEqual(Collector.iCloudAccounts(at: file.path).rawOutput, "")
    }

    /// Runs the real commands on the CI Mac. A failure on enrollment means `profiles status` needs root (BUILD_PLAN §2.4).
    func testCollectAllOnThisMac() async {
        let raw = await Collector.collectAll()
        XCTAssertNotNil(Facts(raw).specs, raw.hardware?.errorOutput ?? "no hardware evidence")
        XCTAssertFalse(raw.enrollment?.rawOutput.isEmpty ?? true, raw.enrollment?.errorOutput ?? "no enrollment evidence")
        XCTAssertTrue(raw.iCloudAccounts?.rawOutput.hasPrefix("Accounts: ") ?? false)
    }
}
