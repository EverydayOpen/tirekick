import Foundation
import XCTest
@testable import TirekickCore

final class ReportTests: XCTestCase {
    func report(_ raw: RawData, mode: Mode = .buying, listing: Bool? = true, tests: [HardwareTest: TestResult] = [:]) -> Report {
        let facts = Facts(raw)
        return Report(createdAt: raw.collectedAt, mode: mode, facts: facts,
                      checks: VerdictRules.evaluate(facts, raw: raw, mode: mode, listingMatches: listing), tests: tests)
    }

    func testFormat() {
        XCTAssertEqual(Format.storage(994_662_584_320), "1 TB")
        XCTAssertEqual(Format.storage(1_000_555_581_440), "1 TB")
        XCTAssertEqual(Format.storage(500_277_790_720), "512 GB")
        XCTAssertEqual(Format.storage(251_000_193_024), "256 GB")
        XCTAssertEqual(Format.storage(121_332_826_112), "128 GB")
        XCTAssertEqual(Format.storage(3_000_000_000_000), "3 TB")
        XCTAssertEqual(Format.storage(nil), "Unknown")
        XCTAssertEqual(Format.storage(0), "Unknown")
        XCTAssertEqual(Format.memory(17_179_869_184), "16 GB")
        XCTAssertEqual(Format.memory(18 << 30), "18 GB")
        XCTAssertEqual(Format.memory(1536 << 30), "1.5 TB")
        XCTAssertEqual(Format.memory(nil), "Unknown")
        XCTAssertEqual(Format.date(Date(timeIntervalSince1970: 1_794_484_800)), "12 Nov 2026")
        XCTAssertEqual(Format.count(5), "5")
        XCTAssertEqual(Format.count(1000), "1,000")
        XCTAssertEqual(Format.count(1_234_005), "1,234,005")
    }

    func testRedactSerialAndPrompts() {
        XCTAssertEqual(Redact.serial("C02XK1ZZG5J7"), "····G5J7")
        XCTAssertEqual(Redact.serial(nil), "Unknown")
        XCTAssertEqual(Redact.serial(""), "Unknown")
        let paste = "jane@Janes-MacBook-Pro ~ % sudo /usr/bin/profiles show -type enrollment\nPassword:\n"
            + "Sorry, user jane may not run sudo on Janes-MacBook-Pro.\njane@Janes-MacBook-Pro ~ % \n"
            + "Janes-MacBook-Pro:~ jane$ \njane@Janes-MacBook-Pro ~ % profiles show -type enrollment\n"
            + "Device Enrollment configuration:\n{\n    OrganizationEmail = \"it@acme.com\";\n}\n"
        let clean = Redact.evidence(paste, serial: nil)
        XCTAssertFalse(clean.contains("jane"), clean)
        XCTAssertFalse(clean.contains("Janes"), clean)
        XCTAssertTrue(clean.contains("% sudo /usr/bin/profiles show -type enrollment"))
        XCTAssertTrue(clean.contains("\n% profiles show -type enrollment\n"), clean)
        XCTAssertTrue(clean.contains("    OrganizationEmail = \"it@acme.com\";"), "indented output is never a prompt")
        XCTAssertEqual(Redact.evidence(#"{"serial_number" : "C02XK1ZZG5J7", "x": "C02XK1ZZG5J7 again"}"#, serial: "C02XK1ZZG5J7"),
                       #"{"serial_number" : "····G5J7", "x": "····G5J7 again"}"#)
        XCTAssertEqual(Redact.evidence("<key>Serial</key>\n<string>F8Y1234567ABC</string>", serial: nil), "<key>Serial</key>\n<string>····7ABC</string>")
        XCTAssertFalse(Redact.evidence("FileVault is Off.\nDeferred enablement appears to be active for user 'jane'.\n", serial: nil).contains("jane"))
    }

    /// BUILD_PLAN §4.7: no fixture serial or identifier survives "Copy raw data".
    func testRawDataRedactsEveryFixtureIdentifier() {
        var raw = cleanRaw()
        raw.battery = evidence(.battery, F.ioregM1MaxText)
        var intel = RawData(os: OSVersion(15, 7), hardware: evidence(.hardware, F.iMacPro))
        intel.power = evidence(.power, F.powerCheckBattery)
        let m5 = RawData(os: OSVersion(27), hardware: evidence(.hardware, F.m5Max), sysctl: evidence(.sysctl, F.m5Sysctl))
        let text = [raw, intel, m5].map(ReportText.rawData).joined()
        for secret in ["XXXXXXXXQ6LR", "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", "XXXXXXXX-XXXXXXXXXXXXXXXX", "XXXXXXXXXXXXXLWBD",
                       "C02VT3******", "E664D52B-5FBC-5A68-******", "xxxxxxxxxxxxxxx", "fd626d62", "7012B685-7F5C-4233-B297-1760B99624C3"] {
            XCTAssertFalse(text.contains(secret), secret)
        }
        XCTAssertTrue(text.contains("····Q6LR"))
        XCTAssertTrue(text.hasPrefix("Tirekick raw data · macOS 26.1 · 12 Nov 2026"))
        XCTAssertTrue(text.contains("$ /usr/sbin/system_profiler -json SPHardwareDataType\n{"))
        XCTAssertTrue(text.contains("$ sudo /usr/bin/profiles show -type enrollment\nError fetching Device Enrollment configuration: Client is not DEP enabled."))
        XCTAssertTrue(text.contains("$ ~/Library/Preferences/MobileMeAccounts.plist\nAccounts: 0"))
    }

    func testSpecRows() throws {
        let raw = RawData(os: OSVersion(27), hardware: evidence(.hardware, F.m5Max), sysctl: evidence(.sysctl, F.m5Sysctl))
        let rows = ReportText.specRows(Facts(raw), maskSerial: true)
        let values = Dictionary(uniqueKeysWithValues: rows.map { ($0.label, $0.value) })
        XCTAssertEqual(rows.map(\.label), ["Model", "Identifier", "Chip", "CPU", "Memory", "Storage", "Serial", "macOS"])
        XCTAssertEqual(values["Model"], "MacBook Pro (16-inch, M5 Pro or M5 Max)")
        XCTAssertEqual(values["CPU"], "18 cores: 6 Super + 12 Performance")
        XCTAssertEqual(values["Memory"], "128 GB")
        XCTAssertEqual(values["Storage"], "Unknown")
        XCTAssertEqual(values["Serial"], "····xxxx")
        XCTAssertEqual(values["macOS"], "27.0")
        XCTAssertEqual(ReportText.specRows(Facts(raw), maskSerial: false).first { $0.label == "Serial" }?.value, "xxxxxxxxxxxxxxx")

        let m1 = ReportText.specRows(Facts(cleanRaw()), maskSerial: true)
        XCTAssertEqual(m1.first { $0.label == "GPU" }?.value, "14 cores")
        XCTAssertEqual(m1.first { $0.label == "CPU" }?.value, "8 cores")
        XCTAssertEqual(ReportText.specRows(Facts(RawData(os: OSVersion(13))), maskSerial: true).first?.value, "Unknown")
    }

    func testSummaryLine() {
        func c(_ v: Verdict) -> Check { Check(id: .battery, verdict: v, title: "", detail: "") }
        XCTAssertEqual(ReportText.summaryLine([c(.clean), c(.walkAway), c(.check), c(.check), c(.unknown)]),
                       "Checked 5 things · 1 serious · 2 to check · 1 couldn't check")
        XCTAssertEqual(ReportText.summaryLine([c(.clean)]), "Checked 1 thing")
        XCTAssertEqual(ReportText.summaryLine([]), "Checked 0 things")
    }

    func testBadNewsCard() {
        var raw = cleanRaw()
        raw.abmPaste = Evidence(command: Command.abmHandoff, rawOutput: "Device Enrollment configuration:\n{\n    OrganizationName = \"Acme Corp\";\n}\n")
        let r = report(raw, tests: [.keyboard: TestResult(.passed, note: "77 of 77 keys"), .camera: TestResult(.skipped)])
        let card = ReportText.card(r, maskSerial: true)
        XCTAssertEqual(card.title, "Tirekick report · MacBook Air (M1, 2020) · M1 8-core · 16 GB · 1 TB")
        XCTAssertEqual(card.verdict, .walkAway)
        XCTAssertEqual(card.headline, "Walk away")
        XCTAssertEqual(card.summary, "Assigned to “Acme Corp” in Apple Business. After it's erased, it will lock itself to them again. Only that organization can release it.")
        XCTAssertEqual(card.rows.count, r.checks.count - 1 + 1)  // no specs row; a skipped test reads like one never opened
        XCTAssertFalse(card.rows.contains { $0.text == "Matches the listing" })
        XCTAssertEqual(card.rows.last?.text, "Keyboard: 77 of 77 keys")
        XCTAssertTrue(ReportText.full(r, maskSerial: true).contains("\n[Skipped] Camera\n"), "the PDF keeps it, never as couldn't check")
        XCTAssertEqual(card.footer, "Checked 12 Nov 2026 on this Mac · Serial ····Q6LR · Only trust a check you run yourself: Tirekick (free)")
        XCTAssertTrue(ReportText.card(r, maskSerial: false).footer.contains("Serial XXXXXXXXQ6LR"))
        XCTAssertEqual(ReportText.card(report(raw, mode: .selling), maskSerial: true).headline, "Fix before selling")
    }

    func testCleanCardAndTestProblem() {
        let clean = ReportText.card(report(cleanRaw()), maskSerial: true)
        XCTAssertEqual(clean.headline, "Clean")
        XCTAssertNil(clean.summary)
        XCTAssertTrue(clean.rows.allSatisfy { $0.verdict == .clean })

        let problem = ReportText.card(report(cleanRaw(), tests: [.speakers: TestResult(.problem, note: "Right speaker silent")]), maskSerial: true)
        XCTAssertEqual(problem.headline, "Check these")
        XCTAssertEqual(problem.summary, "Speakers: Right speaker silent")

        // The company check not run is never "Clean", on the card or the Checks screen.
        var noPaste = cleanRaw()
        noPaste.abmPaste = nil
        let notRun = ReportText.card(report(noPaste), maskSerial: true)
        XCTAssertEqual(notRun.headline, "Check these")
        XCTAssertEqual(notRun.summary, "Company check not run yet. One Terminal command asks Apple whether a company owns this Mac. It needs an administrator password and internet.")
        XCTAssertEqual(ReportText.card(report(noPaste, mode: .selling), maskSerial: true).headline, "Check these")
        XCTAssertEqual(report(noPaste).verdict, .check)

        // Nothing wrong but something unread: say so, and say what.
        var noStorage = cleanRaw()
        noStorage.storage = nil
        let partial = ReportText.card(report(noStorage), maskSerial: true)
        XCTAssertEqual(partial.verdict, .unknown)
        XCTAssertEqual(partial.headline, "Couldn't check everything")
        XCTAssertEqual(partial.summary, "Couldn't check the SSD. The command didn't run. Choose Check Again.")

        // An unanswered listing question has no card row, so it doesn't set the card's headline.
        let unanswered = report(cleanRaw(), listing: nil)
        XCTAssertEqual(unanswered.verdict, .check)
        XCTAssertEqual(ReportText.card(unanswered, maskSerial: true).headline, "Clean")

        // The seller's prep checklist stays off the listing card.
        var stillSignedIn = cleanRaw()
        stillSignedIn.iCloudAccounts = Evidence(command: Command.iCloudAccountsFile, rawOutput: "Accounts: 1")
        stillSignedIn.fileVault = evidence(.fileVault, F.fileVaultOff)
        let listing = ReportText.card(report(stillSignedIn, mode: .selling), maskSerial: true)
        XCTAssertEqual(listing.headline, "Ready to sell")
        XCTAssertNil(listing.summary)
        XCTAssertFalse(listing.rows.contains { $0.text == "Still signed in to iCloud" || $0.text == "FileVault is off" })

        let intel = RawData(os: OSVersion(15), hardware: evidence(.hardware, F.iMacPro),
                            sysctl: Evidence(command: Command.sysctl.display, rawOutput: "machdep.cpu.brand_string: Intel(R) Xeon(R) W-2140B CPU @ 3.20GHz"))
        XCTAssertEqual(ReportText.card(report(intel), maskSerial: true).title, "Tirekick report · iMac Pro (2017) · Intel Xeon W-2140B 8-core · 32 GB")
    }

    func testFullReport() {
        let r = report(cleanRaw(), tests: [.display: TestResult(.passed)])
        let masked = ReportText.full(r, maskSerial: true)
        XCTAssertTrue(masked.hasPrefix("Tirekick report · MacBook Air (M1, 2020)"))
        XCTAssertTrue(masked.contains("Clean · Checked 7 things"))
        XCTAssertTrue(masked.contains("What you're buying\n  Model: MacBook Air (M1, 2020)"))
        XCTAssertTrue(masked.contains("[OK] Activation Lock is off"))
        XCTAssertTrue(masked.contains("$ /usr/sbin/system_profiler -json SPHardwareDataType"))
        XCTAssertTrue(masked.contains("Tests\n[OK] Display: passed"))
        XCTAssertTrue(masked.contains("What Tirekick can't tell you\n- " + ReportText.cantTell[0]))
        XCTAssertTrue(masked.hasSuffix("Only trust a check you run yourself: Tirekick (free)\n"))
        XCTAssertFalse(masked.contains("XXXXXXXXQ6LR"))
        XCTAssertFalse(masked.lowercased().contains("certified"))
        let unmasked = ReportText.full(r, maskSerial: false)
        XCTAssertTrue(unmasked.contains("Serial: XXXXXXXXQ6LR"))
        XCTAssertFalse(unmasked.contains("\"XXXXXXXXQ6LR\""), "evidence stays masked")
        XCTAssertFalse(unmasked.contains("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"), "platform_UUID stays masked")
        XCTAssertTrue(ReportText.full(report(cleanRaw(), mode: .selling), maskSerial: true).contains("What you're selling"))

        // The PDF lists every check, so its headline counts the listing answer and the seller's prep too.
        XCTAssertTrue(ReportText.full(report(cleanRaw(), listing: false), maskSerial: true).contains("\nCheck these · Checked 7 things · 1 to check\n"))
        XCTAssertTrue(ReportText.full(report(cleanRaw(), listing: nil), maskSerial: true).contains("\nCheck these · Checked 7 things · 1 to check\n"))
        var prep = cleanRaw()
        prep.fileVault = evidence(.fileVault, F.fileVaultOff)
        XCTAssertTrue(ReportText.full(report(prep, mode: .selling), maskSerial: true).contains("\nCheck these · Checked 8 things · 1 to check\n"))
        XCTAssertEqual(ReportText.cantTell.count, 4)
    }

    func testCatalog() {
        let ids = ModelCatalog.models.map(\.identifier)
        XCTAssertEqual(Set(ids).count, ids.count, "identifiers are unique")
        XCTAssertEqual(ModelCatalog.macOSReleases, [13, 14, 15, 26, 27])
        XCTAssertEqual(ModelCatalog.macOSReleases.last, ModelCatalog.newestMacOS)
        // Apple silicon: every "MacN,N" plus the first-generation names. macOS 27 runs only on Apple silicon.
        let legacyAppleSilicon: Set = ["MacBookAir10,1", "MacBookPro17,1", "MacBookPro18,1", "MacBookPro18,2", "MacBookPro18,3",
                                       "MacBookPro18,4", "Macmini9,1", "iMac21,1", "iMac21,2"]
        for m in ModelCatalog.models {
            let appleSilicon = legacyAppleSilicon.contains(m.identifier) || m.identifier.range(of: #"^Mac\d+,\d+$"#, options: .regularExpression) != nil
            if appleSilicon {
                XCTAssertNil(m.lastMacOS, m.identifier)
            } else if let last = m.lastMacOS {
                XCTAssertTrue(ModelCatalog.macOSReleases.contains(last), m.identifier)
                XCTAssertLessThan(last, ModelCatalog.newestMacOS, m.identifier)
            } else {
                XCTFail("\(m.identifier) is Intel, so macOS 27 isn't its")
            }
            XCTAssertTrue((2017...2026).contains(m.year), m.identifier)
            if m.touchBar { XCTAssertTrue(m.name.hasPrefix("MacBook Pro"), m.identifier) }
        }
        XCTAssertEqual(ModelCatalog.lookup("Mac17,6")?.name, "MacBook Pro (16-inch, M5 Pro or M5 Max)")
        XCTAssertEqual(ModelCatalog.lookup("MacBookPro15,1")?.lastMacOS, 15)
        XCTAssertEqual(ModelCatalog.lookup("MacBookPro14,2")?.touchBar, true)
        XCTAssertEqual(ModelCatalog.lookup("MacBookPro14,1")?.touchBar, false)
        XCTAssertNil(ModelCatalog.lookup("MacBookPro13,3"), "2016 Macs top out at macOS 12 and can't run Tirekick")
        for fixtureID in ["MacBookAir10,1", "iMacPro1,1", "Mac17,6"] { XCTAssertNotNil(ModelCatalog.lookup(fixtureID), fixtureID) }
    }

    func testKeyboardLayouts() {
        for layout in KeyboardLayout.allCases {
            for touchBar in [false, true] {
                let keys = layout.rows(touchBar: touchBar).flatMap { $0 }
                XCTAssertEqual(Set(keys.map(\.code)).count, keys.count, "\(layout) codes are unique")
                XCTAssertTrue(keys.contains { $0.code == 0x35 }, "Esc stays")
                XCTAssertEqual(keys.contains { $0.code == 0x7A }, !touchBar, "F1")
                XCTAssertTrue(keys.contains { $0.code == 0x32 }, "grave")
                XCTAssertEqual(layout.rows(touchBar: touchBar).count, 6)
            }
        }
        XCTAssertEqual(KeyboardLayout.ansi.rows(touchBar: false).joined().count, 77)
        XCTAssertEqual(KeyboardLayout.iso.rows(touchBar: false).joined().count, 78)
        XCTAssertFalse(KeyboardLayout.ansi.rows(touchBar: false).joined().contains { $0.code == 0x0A })
        XCTAssertTrue(KeyboardLayout.iso.rows(touchBar: false).joined().contains { $0.code == 0x0A })
    }
}
