import Foundation
import XCTest
@testable import TirekickCore

/// Fixture file names (Fixtures/README.md has each one's source).
enum F {
    static let m1 = "SPHardwareDataType_AppleSilicon_M1_lockDisabled.json"
    static let m1Rosetta = "SPHardwareDataType_AppleSilicon_M1_underRosetta.json"
    static let m5Max = "SPHardwareDataType_AppleSilicon_M5Max_lockEnabled.json"
    static let iMacPro = "SPHardwareDataType_Intel_iMacPro_lockDisabled.json"
    static let m5Sysctl = "sysctl_AppleSilicon_M5Max_perflevels.txt"
    static let displays = "SPDisplaysDataType_AppleSilicon_M1Pro_builtinPlus2.json"
    static let power83 = "SPPowerDataType_AppleSilicon_excerpt_83pct.json"
    static let powerCheckBattery = "SPPowerDataType_Intel_excerpt_checkBattery.json"
    static let ioregM1Max = "ioreg_AppleSmartBattery_AppleSilicon_M1Max_converted.plist"
    static let ioregM1MaxText = "ioreg_AppleSmartBattery_AppleSilicon_M1Max_text.txt"
    static let ioregIntel = "ioreg_AppleSmartBattery_Intel_excerpt.plist"
    static let storage1TB = "SPStorageDataType_AppleSilicon_1TB_withUSB.json"
    static let notEnrolled = "profiles_status_notEnrolled.txt"
    static let mdm = "profiles_status_mdm.txt"
    static let mdmUserApproved = "profiles_status_mdmUserApproved.txt"
    static let dep = "profiles_status_dep.txt"
    static let depWithServer = "profiles_status_depWithServer.txt"
    static let abmAssigned = "profiles_show_enrollment_assigned.txt"
    static let abmNotDEP = "profiles_show_enrollment_notDEP.txt"
    static let abm34006 = "profiles_show_enrollment_error34006.txt"
    static let fileVaultOn = "fdesetup_status_on.txt"
    static let fileVaultOff = "fdesetup_status_off.txt"
}

func fixture(_ name: String) -> String {
    let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures").appendingPathComponent(name)
    return try! String(contentsOf: url, encoding: .utf8)
}

func evidence(_ command: Command, _ name: String) -> Evidence {
    Evidence(command: command.display, rawOutput: fixture(name), exitStatus: 0)
}

/// A healthy M1 MacBook Air as the collector would return it, with the ABM paste done.
func cleanRaw() -> RawData {
    RawData(
        os: OSVersion(26, 1), collectedAt: Date(timeIntervalSince1970: 1_794_484_800),  // 12 Nov 2026 12:00 UTC
        hardware: evidence(.hardware, F.m1), power: evidence(.power, F.power83), storage: evidence(.storage, F.storage1TB),
        displays: evidence(.displays, F.displays), battery: evidence(.battery, F.ioregM1Max),
        enrollment: evidence(.enrollment, F.notEnrolled), fileVault: evidence(.fileVault, F.fileVaultOn),
        iCloudAccounts: Evidence(command: Command.iCloudAccountsFile, rawOutput: "Accounts: 0"),
        abmPaste: Evidence(command: Command.abmHandoff, rawOutput: fixture(F.abmNotDEP))
    )
}

final class ParserTests: XCTestCase {
    func testSpecsAppleSiliconM5MaxWithSysctl() throws {
        let s = try XCTUnwrap(Parsers.specs(hardwareJSON: fixture(F.m5Max), sysctl: fixture(F.m5Sysctl), displaysJSON: nil))
        XCTAssertEqual(s.modelIdentifier, "Mac17,6")
        XCTAssertEqual(s.modelName, "MacBook Pro")
        XCTAssertEqual(s.chip, "Apple M5 Max")
        XCTAssertTrue(s.isAppleSilicon)
        XCTAssertEqual(s.cpuCores, 18)
        XCTAssertEqual(s.coreGroups, [CoreGroup(name: "Super", count: 6), CoreGroup(name: "Performance", count: 12)])
        XCTAssertEqual(s.memoryBytes, 128 << 30)  // physical_memory; the sysctl fixture has no hw.memsize
        XCTAssertEqual(s.serial, "xxxxxxxxxxxxxxx")
        XCTAssertEqual(s.activationLock, .enabled)
        XCTAssertTrue(s.isLaptop)
    }

    func testSpecsAppleSiliconM1WithDisplays() throws {
        let s = try XCTUnwrap(Parsers.specs(hardwareJSON: fixture(F.m1), sysctl: nil, displaysJSON: fixture(F.displays)))
        XCTAssertEqual(s.modelIdentifier, "MacBookAir10,1")
        XCTAssertEqual(s.chip, "Apple M1")
        XCTAssertEqual(s.cpuCores, 8)
        XCTAssertEqual(s.coreGroups, [])
        XCTAssertEqual(s.gpuCores, 14)
        XCTAssertEqual(s.memoryBytes, 16 << 30)
        XCTAssertEqual(s.activationLock, .disabled)
    }

    func testSpecsUnderRosettaStillKnowsAppleSilicon() throws {
        let s = try XCTUnwrap(Parsers.specs(hardwareJSON: fixture(F.m1Rosetta), sysctl: nil, displaysJSON: nil))
        XCTAssertNil(s.chip)  // cpu_type "Unknown" is dropped
        XCTAssertTrue(s.isAppleSilicon)  // from the catalog
        XCTAssertEqual(s.cpuCores, 8)  // an Int here, not "proc 8:4:4"
    }

    func testSpecsIntel() throws {
        let s = try XCTUnwrap(Parsers.specs(hardwareJSON: fixture(F.iMacPro), sysctl: nil, displaysJSON: nil))
        XCTAssertEqual(s.modelIdentifier, "iMacPro1,1")
        XCTAssertEqual(s.chip, "8-Core Intel Xeon W")
        XCTAssertFalse(s.isAppleSilicon)
        XCTAssertFalse(s.isLaptop)
        XCTAssertEqual(s.cpuCores, 8)
        XCTAssertEqual(s.memoryBytes, 32 << 30)
        XCTAssertEqual(s.activationLock, .disabled)

        // sysctl wins for the chip name and memory when it ran.
        let sysctl = "hw.memsize: 34359738368\nmachdep.cpu.brand_string: Intel(R) Xeon(R) W-2140B CPU @ 3.20GHz\n"
        let withSysctl = try XCTUnwrap(Parsers.specs(hardwareJSON: fixture(F.iMacPro), sysctl: sysctl, displaysJSON: nil))
        XCTAssertEqual(withSysctl.chip, "Intel(R) Xeon(R) W-2140B CPU @ 3.20GHz")
        XCTAssertEqual(withSysctl.memoryBytes, 34_359_738_368)
        XCTAssertEqual(withSysctl.coreGroups, [])
    }

    func testSpecsMissingOrUnreadable() throws {
        XCTAssertNil(Parsers.specs(hardwareJSON: "", sysctl: nil, displaysJSON: nil))
        XCTAssertNil(Parsers.specs(hardwareJSON: "not json", sysctl: nil, displaysJSON: nil))
        XCTAssertNil(Parsers.specs(hardwareJSON: #"{"SPHardwareDataType": [{}]}"#, sysctl: nil, displaysJSON: nil))
        let noLockKey = #"{"SPHardwareDataType": [{"machine_model": "iMac18,3", "machine_name": "iMac"}]}"#
        XCTAssertEqual(Parsers.specs(hardwareJSON: noLockKey, sysctl: nil, displaysJSON: nil)?.activationLock, .notReported)
        // A value Tirekick doesn't know is unread, never "doesn't report".
        let newValue = #"{"SPHardwareDataType": [{"machine_model": "iMac18,3", "activation_lock_status": "activation_lock_pending"}]}"#
        XCTAssertNil(try XCTUnwrap(Parsers.specs(hardwareJSON: newValue, sysctl: nil, displaysJSON: nil)).activationLock)
        XCTAssertEqual(Parsers.specs(hardwareJSON: #"{"SPHardwareDataType": [{}]}"#, sysctl: "hw.model: Mac15,6", displaysJSON: nil)?.modelIdentifier, "Mac15,6")
    }

    func testBatteryAppleSiliconPrefersSystemProfiler() throws {
        let b = try XCTUnwrap(Parsers.battery(powerJSON: fixture(F.power83), ioregPlist: fixture(F.ioregM1Max)))
        XCTAssertEqual(b.maximumCapacityPercent, 83)
        XCTAssertEqual(b.cycleCount, 88)
        XCTAssertEqual(b.condition, "Good")
        XCTAssertEqual(b.designCapacity, 8694)
        XCTAssertEqual(b.rawMaxCapacity, 8179)
        XCTAssertEqual(b.designCycleCount, 1000)
        XCTAssertEqual(b.permanentFailure, false)
    }

    func testBatteryFromIoregAloneUsesRawMaxNotMaxCapacity() throws {
        let b = try XCTUnwrap(Parsers.battery(powerJSON: nil, ioregPlist: fixture(F.ioregM1Max)))
        XCTAssertEqual(b.maximumCapacityPercent, 94)  // 8179 / 8694, never MaxCapacity (100)
        XCTAssertEqual(b.cycleCount, 35)
        XCTAssertNil(b.condition)
        let nominalOnly = fixture(F.ioregM1Max).replacingOccurrences(of: "<key>AppleRawMaxCapacity</key>", with: "<key>Unused</key>")
        XCTAssertEqual(Parsers.battery(powerJSON: nil, ioregPlist: nominalOnly)?.maximumCapacityPercent, 97)  // 8423 / 8694
    }

    func testBatteryIntel() throws {
        let b = try XCTUnwrap(Parsers.battery(powerJSON: fixture(F.powerCheckBattery), ioregPlist: fixture(F.ioregIntel)))
        XCTAssertEqual(b.condition, "Check Battery")
        XCTAssertEqual(b.cycleCount, 745)
        XCTAssertEqual(b.maximumCapacityPercent, 67)  // Intel MaxCapacity is mAh: 3424 / 5088
        XCTAssertNil(Parsers.battery(powerJSON: fixture(F.powerCheckBattery), ioregPlist: nil)?.maximumCapacityPercent)
    }

    func testNoBattery() {
        XCTAssertNil(Parsers.battery(powerJSON: nil, ioregPlist: nil))
        let desktopPower = #"{"SPPowerDataType": [{"_name": "sppower_ac_charger_information"}]}"#
        let emptyIoreg = #"<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><array/></plist>"#
        XCTAssertNil(Parsers.battery(powerJSON: desktopPower, ioregPlist: emptyIoreg))
        // ioreg's text form (no -a) isn't a plist.
        XCTAssertNil(Parsers.battery(powerJSON: nil, ioregPlist: fixture(F.ioregM1MaxText)))
    }

    func testStorageUsesStartupVolume() throws {
        let s = try XCTUnwrap(Parsers.storage(storageJSON: fixture(F.storage1TB), nvmeJSON: nil))
        XCTAssertEqual(s.deviceName, "APPLE SSD AP1024Z")
        XCTAssertEqual(s.smartStatus, "Verified")
        XCTAssertEqual(s.capacityBytes, 994_662_584_320)
        XCTAssertTrue(s.capacityIsApproximate)
        XCTAssertEqual(s.medium, "ssd")
        XCTAssertNil(Parsers.storage(storageJSON: nil, nvmeJSON: nil))
        XCTAssertNil(Parsers.storage(storageJSON: #"{"SPStorageDataType": []}"#, nvmeJSON: "garbage"))
    }

    func testStorageFallsBackToInternalDiskAndPrefersNVMeSize() throws {
        let dataOnly = #"{"SPStorageDataType": [{"mount_point": "/Volumes/USB", "physical_drive": {"is_internal_disk": "no"}, "size_in_bytes": 1},"#
            + #"{"mount_point": "/System/Volumes/Data", "size_in_bytes": 994662584320, "physical_drive": {"is_internal_disk": "yes", "smart_status": "Verified"}}]}"#
        XCTAssertEqual(Parsers.storage(storageJSON: dataOnly, nvmeJSON: nil)?.capacityBytes, 994_662_584_320)
        // VERIFY: synthesized in the shape of gopsutil's parser; replace with the CI dump.
        let nvme = #"{"SPNVMeDataType": [{"_name": "Apple SSD Controller", "_items": [{"_name": "APPLE SSD AP1024Z", "#
            + #""device_model": "APPLE SSD AP1024Z", "size_in_bytes": 1000555581440, "smart_status": "Verified", "detachable_drive": "no"}]}]}"#
        let s = try XCTUnwrap(Parsers.storage(storageJSON: fixture(F.storage1TB), nvmeJSON: nvme))
        XCTAssertEqual(s.capacityBytes, 1_000_555_581_440)
        XCTAssertFalse(s.capacityIsApproximate)
        let nvmeOnly = try XCTUnwrap(Parsers.storage(storageJSON: nil, nvmeJSON: nvme))
        XCTAssertEqual(nvmeOnly.deviceName, "APPLE SSD AP1024Z")
        XCTAssertEqual(nvmeOnly.smartStatus, "Verified")

        // A second NVMe drive listed first (Mac Pro card, Thunderbolt enclosure): the startup drive's size wins.
        let twoDrives = #"{"SPNVMeDataType": [{"_name": "Generic SSD Controller", "_items": [{"_name": "Samsung SSD 990 PRO 4TB", "#
            + #""device_model": "Samsung SSD 990 PRO 4TB", "size_in_bytes": 4000787030016, "detachable_drive": "no"}]},"#
            + #"{"_name": "Apple SSD Controller", "_items": [{"_name": "APPLE SSD AP1024Z", "#
            + #""device_model": "APPLE SSD AP1024Z", "size_in_bytes": 1000555581440, "detachable_drive": "no"}]}]}"#
        XCTAssertEqual(Parsers.storage(storageJSON: fixture(F.storage1TB), nvmeJSON: twoDrives)?.capacityBytes, 1_000_555_581_440)
        XCTAssertEqual(Parsers.storage(storageJSON: nil, nvmeJSON: twoDrives)?.capacityBytes, 4_000_787_030_016)  // no startup volume: first non-detachable
    }

    func testEnrollmentStatus() {
        let none = Parsers.enrollment(status: fixture(F.notEnrolled))
        XCTAssertEqual(none, EnrollmentInfo(enrolledViaDEP: false, mdmEnrolled: false))
        XCTAssertEqual(Parsers.enrollment(status: fixture(F.mdm)), EnrollmentInfo(enrolledViaDEP: false, mdmEnrolled: true, userApproved: false))
        XCTAssertEqual(Parsers.enrollment(status: fixture(F.mdmUserApproved)), EnrollmentInfo(enrolledViaDEP: false, mdmEnrolled: true, userApproved: true))
        XCTAssertEqual(Parsers.enrollment(status: fixture(F.dep)), EnrollmentInfo(enrolledViaDEP: true, mdmEnrolled: true, userApproved: true))
        XCTAssertEqual(Parsers.enrollment(status: fixture(F.depWithServer)).mdmServer, "https://applemdm.example.com/some/path?foo=bar")
        XCTAssertEqual(none.abm, .notChecked)
        // Unknown values are unknown, never "No".
        XCTAssertEqual(Parsers.enrollment(status: "Enrolled via DEP: Maybe\nMDM enrollment: Pending"), EnrollmentInfo())
        XCTAssertEqual(Parsers.enrollment(status: ""), EnrollmentInfo())
    }

    func testABMPaste() {
        XCTAssertEqual(Parsers.abm(pasted: fixture(F.abmAssigned)), .assigned(organization: "Twocanoes Software", mdmUnremovable: false))
        XCTAssertEqual(Parsers.abm(pasted: fixture(F.abmNotDEP)), .notAssigned)
        guard case .couldNotCheck(let reason) = Parsers.abm(pasted: fixture(F.abm34006)) else { return XCTFail("34006 must not read as a result") }
        XCTAssertTrue(reason.hasPrefix("Error fetching Device Enrollment configuration: (34006)"))

        let config = "Device Enrollment configuration:\n{\n    IsMDMUnremovable = 1;\n    OrganizationName = \"Acme Corp\";\n}\n"
        XCTAssertEqual(Parsers.abm(pasted: config), .assigned(organization: "Acme Corp", mdmUnremovable: true))
        XCTAssertEqual(Parsers.abm(pasted: "Device Enrollment configuration:\n{\n}\n"), .assigned(organization: nil, mdmUnremovable: nil))
        XCTAssertEqual(Parsers.abm(pasted: "Device Enrollment configuration:\n{\n    OrganizationName = Acme;\n}"), .assigned(organization: "Acme", mdmUnremovable: nil))

        // Unrecognized text is never "not assigned".
        XCTAssertEqual(Parsers.abm(pasted: "(null)"), .couldNotCheck("(null)"))
        // Fleet sample: the header without a dictionary is no record, never "assigned".
        XCTAssertEqual(Parsers.abm(pasted: "Device Enrollment configuration:\n(null)\n"), .couldNotCheck("(null)"))
        XCTAssertEqual(Parsers.abm(pasted: "  \n"), .couldNotCheck("Nothing was pasted."))
        XCTAssertEqual(Parsers.abm(pasted: fixture(F.notEnrolled)), .couldNotCheck(Parsers.unrecognizedPaste))
        XCTAssertEqual(Parsers.abm(pasted: "Someone wrote: Client is not DEP enabled"), .couldNotCheck(Parsers.unrecognizedPaste))
        XCTAssertEqual(Parsers.abm(pasted: "Password:\nSorry, try again.\n"), .couldNotCheck("Sorry, try again."))
        // A first-ever sudo prints its lecture first; the reason is the real error.
        let lecture = "\nWe trust you have received the usual lecture from the local System\nAdministrator.\n\nPassword:\n"
        guard case .couldNotCheck(let offline) = Parsers.abm(pasted: lecture + fixture(F.abm34006)) else { return XCTFail() }
        XCTAssertTrue(offline.hasPrefix("Error fetching Device Enrollment configuration: (34006)"), offline)
    }

    /// The admin password copied for sudo's prompt, then pasted here by mistake, never reaches the Checks screen or the card.
    func testABMPasteNeverEchoesUnknownText() throws {
        XCTAssertEqual(Parsers.abm(pasted: "hunter2"), .couldNotCheck(Parsers.unrecognizedPaste))
        var raw = cleanRaw()
        raw.abmPaste = Evidence(command: Command.abmHandoff, rawOutput: "hunter2\n")
        let facts = Facts(raw)
        let report = Report(createdAt: raw.collectedAt, mode: .buying, facts: facts,
                            checks: VerdictRules.evaluate(facts, raw: raw, mode: .buying, listingMatches: true))
        let summary = try XCTUnwrap(ReportText.card(report, maskSerial: true).summary)
        XCTAssertFalse(summary.contains("hunter2"), summary)
        XCTAssertEqual(summary, "Couldn't check company assignment. " + Parsers.unrecognizedPaste)
    }

    func testABMPasteWithTerminalPromptKeepsUserAndHostOut() {
        let prompt = "jane@Janes-MacBook-Pro ~ % sudo /usr/bin/profiles show -type enrollment\nPassword:\n"
        XCTAssertEqual(Parsers.abm(pasted: prompt + fixture(F.abmNotDEP) + "jane@Janes-MacBook-Pro ~ % "), .notAssigned)
        guard case .couldNotCheck(let reason) = Parsers.abm(pasted: prompt + "jane is not in the sudoers file.  This incident will be reported.\n")
        else { return XCTFail() }
        XCTAssertFalse(reason.contains("jane"))
        XCTAssertEqual(Parsers.abm(pasted: "jane@Janes-MacBook-Pro ~ %"), .couldNotCheck("Nothing was pasted."))

        // macOS's default bash prompt has no "@"; a prompt can also precede a command other than sudo.
        for paste in ["Janes-MacBook-Pro:~ jane$ profiles show -type enrollment\n(null)\nJanes-MacBook-Pro:~ jane$ ",
                      "jane@Janes-MacBook-Pro ~ % profiles show -type enrollment\n(null)\n",
                      "(base) jane@Janes-MacBook-Pro ~ % profiles show -type enrollment\n(null)\n",
                      // fish and Powerlevel10k prompts end in neither % nor $.
                      "jane@Janes-MacBook-Pro ~> profiles show -type enrollment\n(null)\n",
                      "jane@Janes-MacBook-Pro ~ ❯ profiles show -type enrollment\n(null)\n"] {
            XCTAssertEqual(Parsers.abm(pasted: paste), .couldNotCheck("(null)"), paste)
            let clean = Redact.prompts(paste)
            XCTAssertFalse(clean.contains("jane") || clean.contains("Janes"), clean)
            XCTAssertTrue(clean.hasPrefix("% profiles show -type enrollment\n"), clean)
        }
        XCTAssertEqual(Parsers.abm(pasted: "Janes-MacBook-Pro:~ jane$ "), .couldNotCheck("Nothing was pasted."))
        for prompt in ["jane@Janes-MacBook-Pro ~ % ", "Janes-MacBook-Pro:~ jane$ ", "jane@Janes-MacBook-Pro ~> "] {
            XCTAssertEqual(Redact.prompts(prompt + "/usr/bin/profiles show -type enrollment"), "% /usr/bin/profiles show -type enrollment")
        }
    }

    /// A long pasted line (a list of addresses, a log) once backtracked for minutes in the prompt regex.
    func testABMPasteLongLineIsFast() {
        let start = Date()
        XCTAssertEqual(Parsers.abm(pasted: String(repeating: "a@b.com,", count: 8000)), .couldNotCheck(Parsers.unrecognizedPaste))
        XCTAssertLessThan(Date().timeIntervalSince(start), 1)
    }

    func testABMExcerpt() throws {
        for junk in ["+1 555 010 4477", "hunter2", "  \n", "jane@Janes-MacBook-Pro ~ %", "Password:",
                     "sudo /usr/bin/profiles show -type enrollment\nhunter2\n"] {
            XCTAssertNil(Parsers.abmExcerpt(junk), junk)
        }
        let scrollback = "Last login: Mon Sep 28 09:12:03 on ttys000\njane@Janes-MacBook-Pro ~ % cat notes.txt\nhunter2\n"
        let run = "jane@Janes-MacBook-Pro ~ % sudo /usr/bin/profiles show -type enrollment\nPassword:\n" + fixture(F.abmNotDEP)
        let excerpt = try XCTUnwrap(Parsers.abmExcerpt(scrollback + run))
        XCTAssertTrue(excerpt.hasPrefix("jane@Janes-MacBook-Pro ~ % sudo /usr/bin/profiles show"), excerpt)
        XCTAssertFalse(excerpt.contains("hunter2") || excerpt.contains("Last login"), excerpt)
        XCTAssertEqual(Parsers.abm(pasted: excerpt), .notAssigned)
        // Errors and a paste of just the command are kept, so the row can say what went wrong.
        XCTAssertEqual(Parsers.abmExcerpt("Password:\nSorry, try again.\n"), "Password:\nSorry, try again.")
        XCTAssertNotNil(Parsers.abmExcerpt("jane is not in the sudoers file.  This incident will be reported.\n"))
        XCTAssertEqual(Parsers.abmExcerpt(Command.abmHandoff), Command.abmHandoff)

        // With sudo's password cached there's no prompt, so a password typed anyway is echoed, during the run or at
        // the next prompt, and whatever ran next follows it. Only the command's own lines are kept.
        let prompt = "jane@Janes-MacBook-Pro ~ % "
        let after = prompt + "hunter2\nzsh: command not found: hunter2\n" + prompt + "ls ~/Documents\nTax Return 2025.pdf\n" + prompt
        let typed = try XCTUnwrap(Parsers.abmExcerpt(prompt + Command.abmHandoff + "\nhunter2\n" + fixture(F.abmNotDEP) + after))
        XCTAssertFalse(typed.contains("hunter2") || typed.contains("Tax Return") || typed.contains("Documents"), typed)
        XCTAssertEqual(typed, prompt + Command.abmHandoff + "\n" + fixture(F.abmNotDEP).trimmingCharacters(in: .newlines))
        XCTAssertEqual(Parsers.abm(pasted: typed), .notAssigned)
        let assigned = try XCTUnwrap(Parsers.abmExcerpt(prompt + Command.abmHandoff + "\nPassword:\n" + fixture(F.abmAssigned) + after))
        XCTAssertFalse(assigned.contains("hunter2") || assigned.contains("Tax Return"), assigned)
        XCTAssertTrue(assigned.hasSuffix("\n" + fixture(F.abmAssigned).trimmingCharacters(in: .newlines)), assigned)
        XCTAssertEqual(Parsers.abm(pasted: assigned), .assigned(organization: "Twocanoes Software", mdmUnremovable: false))
        let refused = try XCTUnwrap(Parsers.abmExcerpt(prompt + Command.abmHandoff + "\nPassword:\nSorry, try again.\nhunter2\n" + after))
        XCTAssertFalse(refused.contains("hunter2"), refused)
        XCTAssertEqual(Parsers.abm(pasted: refused), .couldNotCheck("Sorry, try again."))
    }

    func testABMOrganizationWithEscapedUnicode() {
        let paste = "Device Enrollment configuration:\n{\n    OrganizationName = \"\\U5317\\U4eac Caf\\U00e9\";\n}\n"
        XCTAssertEqual(Parsers.abm(pasted: paste), .assigned(organization: "北京 Café", mdmUnremovable: nil))
    }

    func testFileVault() {
        XCTAssertEqual(Parsers.fileVault(fixture(F.fileVaultOn)), true)
        XCTAssertEqual(Parsers.fileVault(fixture(F.fileVaultOff)), false)
        XCTAssertEqual(Parsers.fileVault("FileVault is Off, but will be enabled after the next restart."), false)
        XCTAssertNil(Parsers.fileVault(""))
        XCTAssertNil(Parsers.fileVault("Error: some failure"))
    }

    func testICloudSignedIn() {
        XCTAssertEqual(Parsers.iCloudSignedIn("Accounts: 0"), false)
        XCTAssertEqual(Parsers.iCloudSignedIn("Accounts: 2\n"), true)
        XCTAssertNil(Parsers.iCloudSignedIn("Accounts: many"))
        XCTAssertNil(Parsers.iCloudSignedIn(""))
    }

    func testSysctl() {
        let d = Parsers.sysctl(fixture(F.m5Sysctl))
        XCTAssertEqual(d["hw.perflevel0.name"], "Super")
        XCTAssertEqual(d["hw.perflevel1.physicalcpu"], "12")
        XCTAssertEqual(Parsers.sysctl("a: b: c\nno separator\n\r\nhw.model: Mac15,6\r\n"), ["a": "b: c", "hw.model": "Mac15,6"])
    }

    func testFactsFromRawData() {
        let facts = Facts(cleanRaw())
        XCTAssertEqual(facts.os, OSVersion(26, 1))
        XCTAssertEqual(facts.specs?.gpuCores, 14)
        XCTAssertEqual(facts.model?.name, "MacBook Air (M1, 2020)")
        XCTAssertEqual(facts.battery?.maximumCapacityPercent, 83)
        XCTAssertEqual(facts.storage?.smartStatus, "Verified")
        XCTAssertEqual(facts.enrollment, EnrollmentInfo(enrolledViaDEP: false, mdmEnrolled: false, abm: .notAssigned))
        XCTAssertEqual(facts.fileVaultOn, true)
        XCTAssertEqual(facts.iCloudSignedIn, false)

        let nothing = Facts(RawData(os: OSVersion(13)))
        XCTAssertEqual(nothing, Facts(os: OSVersion(13)))
        // A paste without `profiles status` still records the ABM result.
        let pasteOnly = Facts(RawData(os: OSVersion(13), abmPaste: Evidence(command: Command.abmHandoff, rawOutput: fixture(F.abmAssigned))))
        XCTAssertEqual(pasteOnly.enrollment, EnrollmentInfo(abm: .assigned(organization: "Twocanoes Software", mdmUnremovable: false)))
    }
}
