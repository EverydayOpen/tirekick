import Foundation
import XCTest
@testable import TirekickCore

/// Real output from GitHub's macOS runners (Fixtures/README.md). They are virtual machines: no battery, no NVMe, a
/// VirtualMac or old Mac mini identifier. Each folder goes through Facts and VerdictRules the way the app would.
final class RunnerFixtureTests: XCTestCase {
    static let arm = "runner-macos-26", intel = "runner-macos-15-intel"

    func read(_ dir: String, _ name: String) -> String { fixture("\(dir)/\(name)") }

    /// RawData as Collector.collectAll() builds it: stdout → rawOutput, stderr → errorOutput, plus the exit status.
    /// Neither runner had MobileMeAccounts.plist, which Collector.iCloudAccounts reports as "Accounts: 0".
    /// The ABM paste is what AppModel.pasteABMResult keeps (Parsers.abmExcerpt) of a Terminal run of Command.abmHandoff.
    func collect(_ dir: String, os: OSVersion) throws -> RawData {
        func run(_ command: Command, _ name: String) -> Evidence {
            Evidence(command: command.display, rawOutput: read(dir, name + ".stdout"), errorOutput: read(dir, name + ".stderr"),
                     exitStatus: Int32(read(dir, name + ".status").trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        XCTAssertTrue(read(dir, "about.txt").contains("ProductVersion:\t\t\(os)\n"), dir)
        XCTAssertEqual(read(dir, "MobileMeAccounts_exists.status"), "1\n", dir)
        let terminal = "jane@Janes-MacBook ~ % \(Command.abmHandoff)\nPassword:\n"
            + read(dir, "profiles_show_enrollment.stdout") + read(dir, "profiles_show_enrollment.stderr")
        let paste = try XCTUnwrap(Parsers.abmExcerpt(terminal))
        return RawData(
            os: os, hardware: run(.hardware, "SPHardwareDataType"), power: run(.power, "SPPowerDataType"),
            storage: run(.storage, "SPStorageDataType"), nvme: run(.nvme, "SPNVMeDataType"),
            displays: run(.displays, "SPDisplaysDataType"), battery: run(.battery, "ioreg_AppleSmartBattery"),
            sysctl: run(.sysctl, "sysctl"), enrollment: run(.enrollment, "profiles_status"), fileVault: run(.fileVault, "fdesetup_status"),
            iCloudAccounts: Evidence(command: Command.iCloudAccountsFile, rawOutput: "Accounts: 0", errorOutput: "The file doesn't exist."),
            abmPaste: Evidence(command: Command.abmHandoff, rawOutput: paste)
        )
    }

    /// What holds on every runner, in one mode: nothing walks away, not managed, not assigned, no battery row on a
    /// desktop without one, never "newer" for an old or virtual identifier, and the report text renders.
    func checks(_ facts: Facts, _ raw: RawData, _ mode: Mode) -> [CheckID: Check] {
        let all = VerdictRules.evaluate(facts, raw: raw, mode: mode, listingMatches: nil)
        XCTAssertEqual(all.filter { $0.verdict == .walkAway }.map(\.title), [], "\(mode)")
        let c = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        XCTAssertNil(c[.battery], "\(mode)")
        XCTAssertEqual(c[.mdmEnrollment]?.verdict, .clean)
        XCTAssertEqual(c[.mdmEnrollment]?.title, "Not managed by any organization")
        XCTAssertEqual(c[.companyAssignment]?.verdict, .clean)
        XCTAssertEqual(c[.companyAssignment]?.title, "Not assigned to any company")
        XCTAssertNotEqual(c[.macOSUpdates]?.title, "Newer than this version of Tirekick")
        let report = Report(createdAt: raw.collectedAt, mode: mode, facts: facts, checks: all)
        XCTAssertFalse(ReportText.full(report, maskSerial: true).isEmpty)
        XCTAssertFalse(ReportText.card(report, maskSerial: true).rows.isEmpty)
        XCTAssertFalse(ReportText.rawData(raw).isEmpty)
        return c
    }

    func testAppleSiliconRunner() throws {
        let raw = try collect(Self.arm, os: OSVersion(26, 6, 2))
        let facts = Facts(raw)
        let s = try XCTUnwrap(facts.specs)
        XCTAssertEqual(s.modelIdentifier, "VirtualMac2,1")
        XCTAssertEqual(s.chip, "Apple M1 (Virtual)")
        XCTAssertTrue(s.isAppleSilicon)
        XCTAssertFalse(s.isLaptop)
        XCTAssertEqual(s.cpuCores, 3)  // number_processors is a plain Int here, not "proc 8:4:4"
        XCTAssertEqual(s.coreGroups, [])  // sysctl reports one "Standard" level
        XCTAssertNil(s.gpuCores)  // SPDisplaysDataType is an empty list
        XCTAssertEqual(s.memoryBytes, 7_516_192_768)
        XCTAssertEqual(s.activationLock, .disabled)
        XCTAssertNil(facts.model)
        XCTAssertNil(facts.battery)  // ioreg printed nothing; SPPowerDataType has no battery item
        // The startup volume, not the Cryptex disk images listed around it. No NVMe list, so the size is the container's.
        XCTAssertEqual(facts.storage, StorageInfo(capacityBytes: 343_073_095_680, capacityIsApproximate: true, medium: "ssd"))
        for mode in Mode.allCases {
            let c = checks(facts, raw, mode)
            XCTAssertEqual(c[.activationLock]?.verdict, .clean)
            XCTAssertEqual(c[.activationLock]?.title, "Activation Lock is off")
            XCTAssertEqual(c[.storageHealth]?.verdict, .unknown)
            XCTAssertEqual(c[.storageHealth]?.title, "The SSD doesn't report its health")
            XCTAssertEqual(c[.macOSUpdates]?.verdict, .unknown)
            XCTAssertEqual(c[.macOSUpdates]?.title, "Not in Tirekick's list of Macs")
        }
        let selling = checks(facts, raw, .selling)
        XCTAssertEqual(selling[.iCloudSignedOut]?.verdict, .clean)
        XCTAssertEqual(selling[.fileVault]?.title, "FileVault is off")
    }

    func testIntelRunner() throws {
        let raw = try collect(Self.intel, os: OSVersion(15, 7, 9))
        let facts = Facts(raw)
        let s = try XCTUnwrap(facts.specs)
        XCTAssertEqual(s.modelIdentifier, "Macmini6,2")
        XCTAssertEqual(s.chip, "Intel(R) Core(TM) i7-8700B CPU @ 3.20GHz")  // cpu_type is "Unknown" here
        XCTAssertFalse(s.isAppleSilicon)
        XCTAssertFalse(s.isLaptop)
        XCTAssertEqual(s.cpuCores, 4)
        XCTAssertEqual(s.coreGroups, [])  // Intel reports one "Standard" level too
        XCTAssertNil(s.gpuCores)
        XCTAssertEqual(s.memoryBytes, 15_032_385_536)
        XCTAssertEqual(s.activationLock, .notReported)  // no activation_lock_status key at all
        XCTAssertNil(facts.model)
        XCTAssertNil(facts.battery)
        XCTAssertEqual(facts.storage, StorageInfo(deviceName: "VEERTU ANKA", capacityBytes: 348_622_118_912,
                                                  capacityIsApproximate: true, medium: "rotational"))
        for mode in Mode.allCases {
            let c = checks(facts, raw, mode)
            // Not reported is neither a walk-away nor a clean result.
            XCTAssertEqual(c[.activationLock]?.verdict, .unknown)
            XCTAssertEqual(c[.activationLock]?.title, "This Mac doesn't report Activation Lock")
            XCTAssertEqual(c[.activationLock]?.detail.contains("can't mark this Mac clean"), true)
            XCTAssertEqual(c[.storageHealth]?.title, "The drive doesn't report its health")
            // Macmini6,2 is a 2012 Mac, older than the catalog: patched-macOS wording, never "newer".
            XCTAssertEqual(c[.macOSUpdates]?.verdict, .check)
            XCTAssertEqual(c[.macOSUpdates]?.title, "Apple doesn't support macOS 15 on this Mac")
        }
    }

    /// `profiles status` and `fdesetup status` need no root (run as `nobody`), and both runners' ABM answers parse.
    func testEnrollmentAndPastes() {
        for dir in [Self.arm, Self.intel] {
            XCTAssertEqual(read(dir, "profiles_status.stdout"), "Enrolled via DEP: No\nMDM enrollment: No\n", dir)
            XCTAssertEqual(read(dir, "profiles_status_nobody.stdout"), read(dir, "profiles_status.stdout"), dir)
            XCTAssertEqual(read(dir, "profiles_status_nobody.status"), "0\n", dir)
            XCTAssertEqual(Parsers.enrollment(status: read(dir, "profiles_status_nobody.stdout")), EnrollmentInfo(enrolledViaDEP: false, mdmEnrolled: false))
            XCTAssertEqual(Parsers.fileVault(read(dir, "fdesetup_status_nobody.stdout")), false, dir)

            let notDEP = read(dir, "profiles_show_enrollment.stderr")
            XCTAssertEqual(notDEP, "Error fetching Device Enrollment configuration: Client is not DEP enabled.\n", dir)
            XCTAssertEqual(Parsers.abm(pasted: notDEP), .notAssigned, dir)
            // Without sudo, profiles refuses: say so rather than "that isn't the command's output".
            let noSudo = read(dir, "profiles_show_enrollment_nobody.stderr")
            XCTAssertEqual(Parsers.abm(pasted: noSudo), .couldNotCheck("Must be running as root"), dir)
            XCTAssertEqual(Parsers.abmExcerpt("% /usr/bin/profiles show -type enrollment\n" + noSudo),
                           "% /usr/bin/profiles show -type enrollment\nMust be running as root", dir)
        }
    }
}
