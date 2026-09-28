import Foundation
import XCTest
@testable import TirekickCore

final class ModelTests: XCTestCase {
    func testOverallVerdictNeverShowsUnknownAsClean() {
        XCTAssertEqual(Verdict.overall([]), .unknown)
        XCTAssertEqual(Verdict.overall([.clean]), .clean)
        XCTAssertEqual(Verdict.overall([.unknown, .clean]), .unknown)
        XCTAssertEqual(Verdict.overall([.unknown, .check, .clean]), .check)
        XCTAssertEqual(Verdict.overall([.clean, .walkAway, .check, .unknown]), .walkAway)
        XCTAssertEqual(Verdict.unknown.bannerTitle(for: .selling), "Couldn't check everything")
    }

    func testCommandsStayOnTheAllowlist() {
        let allowed: Set = ["/usr/sbin/system_profiler", "/usr/bin/profiles", "/usr/sbin/ioreg", "/usr/sbin/sysctl", "/usr/bin/fdesetup"]
        for command in Command.all {
            XCTAssertTrue(allowed.contains(command.executable), command.display)
            if ["/usr/bin/profiles", "/usr/bin/fdesetup"].contains(command.executable) {
                XCTAssertEqual(command.arguments.first, "status", command.display)
            }
        }
    }

    func testReportRoundTripsAndCountsTestProblems() throws {
        let raw = Evidence(command: Command.enrollment.display, rawOutput: "Enrolled via DEP: No\nMDM enrollment: No\n", exitStatus: 0)
        let specs = MacSpecs(modelIdentifier: "Mac15,6", modelName: "MacBook Pro", chip: "Apple M3 Pro", isAppleSilicon: true,
                             coreGroups: [CoreGroup(name: "Performance", count: 5)], activationLock: .disabled)
        let facts = Facts(os: OSVersion(27), specs: specs, enrollment: EnrollmentInfo(abm: .assigned(organization: "Acme Corp", mdmUnremovable: true)))
        var report = Report(createdAt: Date(timeIntervalSince1970: 1_800_000_000), mode: .buying, facts: facts,
                            checks: [Check(id: .mdmEnrollment, verdict: .clean, title: "Not enrolled in device management",
                                           detail: "", evidence: [raw])])
        XCTAssertEqual(report.verdict, .clean)
        report.tests = [.camera: TestResult(.skipped)]
        XCTAssertEqual(report.verdict, .clean, "a skipped test counts as never opened")
        report.tests = [.keyboard: TestResult(.problem, note: "77 of 78 keys"), .camera: TestResult(.skipped)]
        XCTAssertEqual(report.verdict, .check)

        let decoded = try JSONDecoder().decode(Report.self, from: JSONEncoder().encode(report))
        XCTAssertEqual(decoded, report)
    }

    /// Every fixture parses as what its extension says, on Linux too (JSONSerialization, PropertyListSerialization).
    func testFixturesAreWellFormed() throws {
        let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        var checked = 0
        // The runner-* folders hold raw .stdout files; RunnerFixtureTests parses those.
        for name in names where name.hasSuffix(".json") || name.hasSuffix(".plist") {
            let data = try Data(contentsOf: dir.appendingPathComponent(name))
            if name.hasSuffix(".json") {
                XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data), name)
            } else {
                XCTAssertNoThrow(try PropertyListSerialization.propertyList(from: data, options: [], format: nil), name)
            }
            checked += 1
        }
        XCTAssertGreaterThanOrEqual(checked, 10)
    }
}
