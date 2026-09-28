import Foundation
import XCTest
@testable import TirekickCore

final class RulesTests: XCTestCase {
    let os = OSVersion(26, 1)
    let air = MacSpecs(modelIdentifier: "MacBookAir10,1", modelName: "MacBook Air", chip: "Apple M1", isAppleSilicon: true, activationLock: .disabled)

    func check(_ id: CheckID, _ facts: Facts, raw: RawData? = nil, mode: Mode = .buying, listing: Bool? = nil) -> Check? {
        VerdictRules.evaluate(facts, raw: raw ?? RawData(os: os), mode: mode, listingMatches: listing).first { $0.id == id }
    }

    func facts(_ specs: MacSpecs? = nil, battery: BatteryInfo? = nil, storage: StorageInfo? = nil, enrollment: EnrollmentInfo? = nil,
               fileVault: Bool? = nil, iCloud: Bool? = nil, os: OSVersion? = nil) -> Facts {
        Facts(os: os ?? self.os, specs: specs, model: specs.flatMap { ModelCatalog.lookup($0.modelIdentifier) }, battery: battery,
              storage: storage, enrollment: enrollment, fileVaultOn: fileVault, iCloudSignedIn: iCloud)
    }

    func specs(_ id: String, lock: ActivationLock? = .disabled) -> MacSpecs {
        MacSpecs(modelIdentifier: id, modelName: id.hasPrefix("MacBook") ? "MacBook" : "Mac", isAppleSilicon: false, activationLock: lock)
    }

    func testActivationLock() throws {
        let raw = RawData(os: os, hardware: evidence(.hardware, F.m5Max))
        let on = try XCTUnwrap(check(.activationLock, Facts(raw), raw: raw))
        XCTAssertEqual(on.verdict, .walkAway)
        XCTAssertEqual(on.title, "Activation Lock is on")
        XCTAssertTrue(on.detail.hasPrefix("Don't pay while it's on."))
        XCTAssertEqual(on.evidence, [raw.hardware!])
        XCTAssertEqual(check(.activationLock, Facts(raw), raw: raw, mode: .selling)?.detail, "Turn off Find My, then choose Check Again.")

        XCTAssertEqual(check(.activationLock, facts(air))?.verdict, .clean)
        XCTAssertEqual(check(.activationLock, facts(air))?.title, "Activation Lock is off")
        let notReported = check(.activationLock, facts(specs("iMac18,3", lock: .notReported)))
        XCTAssertEqual(notReported?.verdict, .unknown)
        XCTAssertEqual(notReported?.title, "This Mac doesn't report Activation Lock")
        // Every Apple-silicon Mac has Activation Lock: no status there, or one Tirekick doesn't know, is unread.
        var m1 = air
        for lock in [.notReported, nil] as [ActivationLock?] {
            m1.activationLock = lock
            XCTAssertEqual(check(.activationLock, facts(m1))?.verdict, .check)
            XCTAssertEqual(check(.activationLock, facts(m1))?.title, "Couldn't check Activation Lock")
        }
        XCTAssertEqual(check(.activationLock, facts(specs("iMacPro1,1", lock: nil)))?.verdict, .check)
        let none = check(.activationLock, facts())
        XCTAssertEqual(none?.verdict, .check)
        XCTAssertEqual(none?.title, "Couldn't check Activation Lock")
        XCTAssertEqual(none?.detail, "The command didn't run. Choose Check Again.")
    }

    func testMDMEnrollment() throws {
        func run(_ name: String) -> Check? {
            let raw = RawData(os: os, enrollment: evidence(.enrollment, name))
            return check(.mdmEnrollment, Facts(raw), raw: raw)
        }
        XCTAssertEqual(run(F.notEnrolled)?.verdict, .clean)
        XCTAssertEqual(run(F.notEnrolled)?.title, "Not managed by any organization")
        XCTAssertEqual(run(F.mdm)?.verdict, .walkAway)
        XCTAssertEqual(run(F.mdm)?.title, "Managed by an organization (MDM)")
        XCTAssertEqual(run(F.mdmUserApproved)?.verdict, .walkAway)
        XCTAssertEqual(run(F.dep)?.verdict, .walkAway)
        XCTAssertEqual(run(F.dep)?.title, "Set up by an organization (Automated Device Enrollment)")
        XCTAssertTrue(try XCTUnwrap(run(F.depWithServer)).detail.hasSuffix("Its management server is applemdm.example.com."))
        XCTAssertEqual(check(.mdmEnrollment, facts(enrollment: EnrollmentInfo(enrolledViaDEP: false)))?.verdict, .check)
        XCTAssertEqual(check(.mdmEnrollment, facts(enrollment: EnrollmentInfo(enrolledViaDEP: nil, mdmEnrolled: true)))?.verdict, .walkAway)

        // profiles failed: the reason comes from its stderr.
        let failed = RawData(os: os, enrollment: Evidence(command: Command.enrollment.display, rawOutput: "", errorOutput: "profiles: this command requires root\n", exitStatus: 1))
        let unknown = try XCTUnwrap(check(.mdmEnrollment, Facts(failed), raw: failed))
        XCTAssertEqual(unknown.verdict, .check)
        XCTAssertEqual(unknown.title, "Couldn't check device management")
        XCTAssertEqual(unknown.detail, "The command said: “profiles: this command requires root”.")
        let odd = RawData(os: os, enrollment: Evidence(command: Command.enrollment.display, rawOutput: "something new", exitStatus: 0))
        XCTAssertTrue(try XCTUnwrap(check(.mdmEnrollment, Facts(odd), raw: odd)).detail.hasPrefix("The command's output wasn't what Tirekick expected."))
        XCTAssertEqual(check(.mdmEnrollment, facts())?.verdict, .check)
    }

    func testCompanyAssignment() throws {
        let notRun = try XCTUnwrap(check(.companyAssignment, facts()))
        XCTAssertEqual(notRun.verdict, .check)
        XCTAssertEqual(notRun.title, "Company check not run yet")
        XCTAssertEqual(notRun.evidence.map(\.command), [Command.abmHandoff])

        func run(_ text: String, mode: Mode = .buying) -> Check? {
            let raw = RawData(os: os, abmPaste: Evidence(command: Command.abmHandoff, rawOutput: text))
            return check(.companyAssignment, Facts(raw), raw: raw, mode: mode)
        }
        let assigned = try XCTUnwrap(run(fixture(F.abmAssigned)))
        XCTAssertEqual(assigned.verdict, .walkAway)
        XCTAssertEqual(assigned.title, "Assigned to “Twocanoes Software” in Apple Business")
        XCTAssertEqual(assigned.detail, "After it's erased, it will lock itself to them again. Only that organization can release it.")
        XCTAssertEqual(assigned.evidence.first?.rawOutput, fixture(F.abmAssigned))
        XCTAssertTrue(try XCTUnwrap(run(fixture(F.abmAssigned), mode: .selling)).detail.hasSuffix("before you sell."))
        XCTAssertEqual(run("Device Enrollment configuration:\n{\n}")?.title, "Assigned to an organization in Apple Business")

        XCTAssertEqual(run(fixture(F.abmNotDEP))?.verdict, .clean)
        XCTAssertEqual(run(fixture(F.abmNotDEP))?.title, "Not assigned to any company")
        let offline = try XCTUnwrap(run(fixture(F.abm34006)))
        XCTAssertEqual(offline.verdict, .check)
        XCTAssertEqual(offline.title, "Couldn't check company assignment")
        XCTAssertTrue(offline.detail.contains("(34006)"))
        let noRecord = try XCTUnwrap(run("Device Enrollment configuration:\n(null)\n"))
        XCTAssertEqual(noRecord.verdict, .check)
        XCTAssertEqual(noRecord.detail, "Terminal said: “(null)” Run the command exactly as copied, including sudo, type this Mac's administrator password, make sure the Mac is online, then paste the whole result.")
        XCTAssertEqual(run(fixture(F.abmNotDEP))?.detail, "Apple reports no organization has set this Mac to enroll in its device management.")

        // Copy Command leaves the command on the clipboard: pasting it back isn't "offline".
        let commandOnly = try XCTUnwrap(run("jane@Janes-MacBook-Pro ~ % sudo /usr/bin/profiles show -type enrollment\nPassword:\n"))
        XCTAssertEqual(commandOnly.verdict, .check)
        XCTAssertEqual(commandOnly.title, "Only the command was pasted")
        XCTAssertEqual(commandOnly.detail, "In Terminal, select everything the command printed, press ⌘C, then choose Paste Result.")
        XCTAssertEqual(run("hunter2")?.detail, Parsers.unrecognizedPaste)
    }

    func testSpecsAgainstListingIsBuyingOnly() {
        XCTAssertEqual(check(.specs, facts(air))?.verdict, .check)  // waiting for the buyer's answer
        XCTAssertEqual(check(.specs, facts(air))?.title, "Compare with the listing")
        XCTAssertEqual(check(.specs, facts(air))?.evidence, [])
        let raw = cleanRaw()
        XCTAssertEqual(check(.specs, facts(air), raw: raw, listing: true)?.verdict, .clean)
        XCTAssertEqual(check(.specs, facts(air), raw: raw, listing: true)?.evidence.count, 2)  // hardware, storage (no sysctl)
        XCTAssertEqual(check(.specs, facts(air), listing: false)?.verdict, .check)
        XCTAssertEqual(check(.specs, facts(air), listing: false)?.title, "Doesn't match the listing")
        XCTAssertNil(check(.specs, facts(air), mode: .selling, listing: false))
    }

    func testBattery() throws {
        let raw = RawData(os: os, power: evidence(.power, F.power83), battery: evidence(.battery, F.ioregM1Max))
        let good = try XCTUnwrap(check(.battery, Facts(raw), raw: raw))
        XCTAssertEqual(good.verdict, .clean)
        XCTAssertEqual(good.title, "Battery at 83%, 88 of 1,000 rated cycles")
        XCTAssertEqual(good.evidence.count, 2)

        let intel = RawData(os: os, power: evidence(.power, F.powerCheckBattery), battery: evidence(.battery, F.ioregIntel))
        let service = try XCTUnwrap(check(.battery, Facts(intel), raw: intel))
        XCTAssertEqual(service.verdict, .check)
        XCTAssertEqual(service.title, "Battery needs service (macOS says: Check Battery)")

        let worn = check(.battery, facts(air, battery: BatteryInfo(cycleCount: 540, condition: "Good", maximumCapacityPercent: 79)))
        XCTAssertEqual(worn?.verdict, .check)
        XCTAssertEqual(worn?.title, "Battery at 79%, 540 of 1,000 rated cycles")
        XCTAssertEqual(check(.battery, facts(air, battery: BatteryInfo(condition: "Good", maximumCapacityPercent: 80)))?.verdict, .clean)
        XCTAssertEqual(check(.battery, facts(air, battery: BatteryInfo(maximumCapacityPercent: 95, designCycleCount: 1500)))?.title, "Battery at 95%")
        XCTAssertEqual(check(.battery, facts(air, battery: BatteryInfo(cycleCount: 12, maximumCapacityPercent: 95, designCycleCount: 1500)))?.title,
                       "Battery at 95%, 12 of 1,500 rated cycles")
        let failed = check(.battery, facts(air, battery: BatteryInfo(condition: "Good", maximumCapacityPercent: 95, permanentFailure: true)))
        XCTAssertEqual(failed?.verdict, .check)
        XCTAssertEqual(failed?.title, "Battery reports a permanent failure")
        XCTAssertEqual(check(.battery, facts(air, battery: BatteryInfo(cycleCount: 7, condition: "Good")))?.title, "Battery condition is normal, 7 of 1,000 rated cycles")
        XCTAssertEqual(check(.battery, facts(air, battery: BatteryInfo(cycleCount: 7)))?.verdict, .unknown)

        // Desktops have no battery row; a laptop (or an unknown Mac) without battery data can't be checked.
        let desktop = RawData(os: os, hardware: evidence(.hardware, F.iMacPro))
        XCTAssertNil(check(.battery, Facts(desktop), raw: desktop))
        XCTAssertEqual(check(.battery, facts(air))?.title, "Couldn't check the battery")
        XCTAssertEqual(check(.battery, facts())?.verdict, .unknown)
    }

    func testStorageHealth() throws {
        let raw = RawData(os: os, storage: evidence(.storage, F.storage1TB))
        let verified = try XCTUnwrap(check(.storageHealth, Facts(raw), raw: raw))
        XCTAssertEqual(verified.verdict, .clean)
        XCTAssertEqual(verified.title, "SSD reports healthy (SMART: Verified)")
        XCTAssertEqual(verified.evidence, [raw.storage!])

        let failing = check(.storageHealth, facts(storage: StorageInfo(smartStatus: "Failing", medium: "ssd")))
        XCTAssertEqual(failing?.verdict, .walkAway)
        XCTAssertEqual(failing?.title, "SSD reports it's failing")
        XCTAssertEqual(check(.storageHealth, facts(storage: StorageInfo(smartStatus: "Not Supported")))?.verdict, .unknown)
        XCTAssertEqual(check(.storageHealth, facts(storage: StorageInfo()))?.title, "The SSD doesn't report its health")
        XCTAssertEqual(check(.storageHealth, facts(storage: StorageInfo(smartStatus: "Odd")))?.title, "The SSD reports SMART status “Odd”")
        XCTAssertEqual(check(.storageHealth, facts(storage: StorageInfo(smartStatus: "Odd")))?.verdict, .unknown)
        XCTAssertEqual(check(.storageHealth, facts(storage: StorageInfo(smartStatus: "Verified", medium: "rotational")))?.title, "Drive reports healthy (SMART: Verified)")
        XCTAssertEqual(check(.storageHealth, facts())?.title, "Couldn't check the SSD")
    }

    func testMacOSUpdates() throws {
        let current = try XCTUnwrap(check(.macOSUpdates, facts(specs("Mac15,6"))))
        XCTAssertEqual(current.verdict, .clean)
        XCTAssertEqual(current.title, "Gets macOS 27, the current version")
        XCTAssertEqual(current.evidence.first?.command, "Tirekick model list (built in)")
        XCTAssertEqual(current.evidence.first?.rawOutput, "Mac15,6 → MacBook Pro (14-inch, Nov 2023), last macOS: current")
        XCTAssertTrue(current.detail.hasSuffix("This Mac is running macOS 26.1."))
        XCTAssertEqual(check(.macOSUpdates, facts(specs("Mac15,6"), os: OSVersion(28)))?.title, "Gets macOS 28, the current version")

        let tahoe = try XCTUnwrap(check(.macOSUpdates, facts(specs("iMac20,1"))))
        XCTAssertEqual(tahoe.verdict, .check)
        XCTAssertEqual(tahoe.title, "macOS 26 is its last")
        XCTAssertTrue(tahoe.detail.hasPrefix("Security updates usually continue for about 2 years (not guaranteed)."))
        XCTAssertTrue(try XCTUnwrap(check(.macOSUpdates, facts(specs("Macmini8,1"), os: OSVersion(15, 7)))).detail.hasPrefix("Security updates usually continue for about 1 more year"))
        for (old, last) in [("MacBookAir8,1", 14), ("iMac18,3", 13)] {
            let c = try XCTUnwrap(check(.macOSUpdates, facts(specs(old), os: OSVersion(last, 7))))
            XCTAssertEqual(c.verdict, .check)
            XCTAssertTrue(c.detail.hasPrefix("Apple has most likely stopped its security updates."), old)
        }
        let unknown = try XCTUnwrap(check(.macOSUpdates, facts(specs("Mac99,1"))))
        XCTAssertEqual(unknown.verdict, .unknown)
        XCTAssertEqual(unknown.title, "Newer than this version of Tirekick")
        XCTAssertEqual(unknown.evidence.first?.rawOutput, "Mac99,1 → not in the list")
        let vm = try XCTUnwrap(check(.macOSUpdates, facts(specs("VirtualMac2,1"))))
        XCTAssertEqual(vm.verdict, .unknown)
        XCTAssertEqual(vm.title, "Not in Tirekick's list of Macs")
        // A 2015 Mac on macOS 13+ runs a patched macOS: a known fact, not "newer".
        let patched = try XCTUnwrap(check(.macOSUpdates, facts(specs("MacBookPro11,4"))))
        XCTAssertEqual(patched.verdict, .check)
        XCTAssertEqual(patched.title, "Apple doesn't support macOS 26 on this Mac")
        XCTAssertEqual(patched.evidence.first?.rawOutput, "MacBookPro11,4 → not in the list")
        // A catalog Mac past its last macOS (OpenCore Legacy Patcher) is patched too, not "macOS 13 is its last".
        let oclp = try XCTUnwrap(check(.macOSUpdates, facts(specs("MacBookPro14,1"), os: OSVersion(15))))
        XCTAssertEqual(oclp.verdict, .check)
        XCTAssertEqual(oclp.title, "Apple doesn't support macOS 15 on this Mac")
        XCTAssertTrue(oclp.detail.hasSuffix("Its last supported macOS is 13."), oclp.detail)
        XCTAssertEqual(check(.macOSUpdates, facts(specs("MacBookPro14,1"), os: OSVersion(13, 7)))?.title, "macOS 13 is its last")
        XCTAssertEqual(check(.macOSUpdates, facts())?.title, "Couldn't check macOS updates")
    }

    func testSellerChecks() {
        XCTAssertNil(check(.iCloudSignedOut, facts(iCloud: true)))
        XCTAssertNil(check(.fileVault, facts(fileVault: false)))
        func sell(_ id: CheckID, _ f: Facts) -> Check? { check(id, f, mode: .selling) }
        XCTAssertEqual(sell(.iCloudSignedOut, facts(iCloud: true))?.verdict, .check)
        XCTAssertEqual(sell(.iCloudSignedOut, facts(iCloud: true))?.title, "Still signed in to iCloud")
        XCTAssertEqual(sell(.iCloudSignedOut, facts(iCloud: false))?.verdict, .clean)
        XCTAssertEqual(sell(.iCloudSignedOut, facts())?.title, "Couldn't check iCloud sign-in")
        XCTAssertEqual(sell(.fileVault, facts(fileVault: false))?.verdict, .check)
        XCTAssertEqual(sell(.fileVault, facts(fileVault: false))?.title, "FileVault is off")
        XCTAssertEqual(sell(.fileVault, facts(fileVault: true))?.verdict, .clean)
        XCTAssertEqual(sell(.fileVault, facts())?.verdict, .unknown)
    }

    func testOrderAndPurity() {
        let raw = cleanRaw(), f = Facts(raw)
        let buying = VerdictRules.evaluate(f, raw: raw, mode: .buying, listingMatches: true)
        XCTAssertEqual(buying.map(\.id), [.activationLock, .mdmEnrollment, .companyAssignment, .specs, .battery, .storageHealth, .macOSUpdates])
        XCTAssertEqual(buying, VerdictRules.evaluate(f, raw: raw, mode: .buying, listingMatches: true))
        XCTAssertTrue(buying.allSatisfy { $0.verdict == .clean }, buying.filter { $0.verdict != .clean }.map(\.title).joined(separator: ", "))
        let selling = VerdictRules.evaluate(f, raw: raw, mode: .selling, listingMatches: nil)
        XCTAssertEqual(selling.map(\.id), [.activationLock, .mdmEnrollment, .companyAssignment, .battery, .storageHealth, .macOSUpdates, .iCloudSignedOut, .fileVault])
    }

    /// Many fact combinations: verdicts don't change with the mode, walk-away comes only from hard facts, and the copy
    /// follows BUILD_PLAN §8.
    func testVerdictsCopyAndWalkAwayAcrossScenarios() {
        var scenarios = [cleanRaw(), RawData(os: os)]
        for hardware in [F.m1, F.m1Rosetta, F.m5Max, F.iMacPro] {
            for enrollment in [F.notEnrolled, F.mdm, F.dep, F.depWithServer] {
                for paste in [F.abmAssigned, F.abmNotDEP, F.abm34006] {
                    var raw = cleanRaw()
                    raw.hardware = evidence(.hardware, hardware)
                    raw.enrollment = evidence(.enrollment, enrollment)
                    raw.abmPaste = Evidence(command: Command.abmHandoff, rawOutput: fixture(paste))
                    raw.power = evidence(.power, F.powerCheckBattery)
                    raw.fileVault = evidence(.fileVault, F.fileVaultOff)
                    scenarios.append(raw)
                }
            }
        }
        let hard: Set<CheckID> = [.activationLock, .mdmEnrollment, .companyAssignment, .storageHealth]
        let banned = ["!", "please", "Please", "certified", "safe to buy", "danger", "scam", "stolen", "oops", "N/A"]
        for raw in scenarios {
            let f = Facts(raw)
            for listing in [nil, true, false] as [Bool?] {
                let buying = VerdictRules.evaluate(f, raw: raw, mode: .buying, listingMatches: listing)
                let selling = VerdictRules.evaluate(f, raw: raw, mode: .selling, listingMatches: listing)
                for c in buying + selling {
                    if c.verdict == .walkAway { XCTAssertTrue(hard.contains(c.id), c.title) }
                    if c.id != .companyAssignment { XCTAssertLessThanOrEqual(c.title.count, 60, c.title) }
                    XCTAssertFalse(c.title.hasSuffix("."), c.title)
                    let text = c.title + " " + c.detail
                    for word in banned { XCTAssertFalse(text.contains(word), "\(word): \(text)") }
                    XCTAssertFalse(text.replacingOccurrences(of: "not guaranteed", with: "").contains("guaranteed"), text)
                    // At most 3 sentences, not counting quoted command output.
                    let unquoted = c.detail.replacingOccurrences(of: "“[^”]*”", with: "", options: .regularExpression)
                    XCTAssertLessThanOrEqual(unquoted.components(separatedBy: ". ").count, 3, c.detail)
                }
                for b in buying {
                    if let s = selling.first(where: { $0.id == b.id }) { XCTAssertEqual(b.verdict, s.verdict, b.title) }
                }
            }
        }
    }
}
