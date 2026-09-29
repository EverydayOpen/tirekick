import Foundation

/// Facts → plain-English checks (docs/BUILD_PLAN.md §4.4, copy rules §8). "Walk away" only for hard facts:
/// Activation Lock on, DEP or MDM enrolled, an ABM organization found, SMART failing.
/// Verdicts never depend on the mode; only some details do.
public enum VerdictRules {
    public static let ratedCycles = 1000

    /// One Check per applicable CheckID, in CheckID order. Pure: same input, same output.
    public static func evaluate(_ facts: Facts, raw: RawData, mode: Mode, listingMatches: Bool?) -> [Check] {
        let selling = mode == .selling
        var checks = [activationLock(facts, raw, selling), mdm(facts, raw, selling), company(facts, raw, selling)]
        if !selling { checks.append(specs(raw, listingMatches)) }
        if let battery = battery(facts, raw, selling) { checks.append(battery) }
        checks += [storage(facts, raw, selling), updates(facts, raw)]
        if selling { checks += [iCloud(facts, raw), fileVault(facts, raw)] }
        return checks
    }

    static func activationLock(_ facts: Facts, _ raw: RawData, _ selling: Bool) -> Check {
        let e = list(raw.hardware)
        switch facts.specs?.activationLock {
        case .enabled?:
            return Check(id: .activationLock, verdict: .walkAway, title: "Activation Lock is on", detail: selling
                ? "Turn off Find My, then choose Check Again."
                : "Don't pay while it's on. Ask the seller to turn off Find My in front of you, then choose Check Again.", evidence: e)
        case .disabled?:
            return Check(id: .activationLock, verdict: .clean, title: "Activation Lock is off", detail: selling
                ? "A buyer can set it up with their own Apple Account."
                : "This Mac reports it isn't locked to anyone's Apple Account.", evidence: e)
        // Every Apple-silicon Mac has Activation Lock, so a missing status there is unread, not absent.
        case .notReported? where facts.specs?.isAppleSilicon == true:
            return couldnt(.activationLock, "Activation Lock", raw.hardware, .check)
        case .notReported?:
            return Check(id: .activationLock, verdict: .unknown, title: "This Mac doesn't report Activation Lock",
                         detail: "Only Macs with Apple silicon or a T2 chip report it, so Tirekick can't mark this Mac clean. Check that Find My is off in System Settings.", evidence: e)
        case nil:
            return couldnt(.activationLock, "Activation Lock", raw.hardware, .check)
        }
    }

    static func mdm(_ facts: Facts, _ raw: RawData, _ selling: Bool) -> Check {
        let e = list(raw.enrollment)
        guard let info = facts.enrollment else { return couldnt(.mdmEnrollment, "device management", raw.enrollment, .check) }
        if info.enrolledViaDEP == true || info.mdmEnrolled == true {
            let server = info.mdmServer.map { " Its management server is \(URL(string: $0)?.host ?? $0)." } ?? ""
            return Check(id: .mdmEnrollment, verdict: .walkAway,
                         title: info.enrolledViaDEP == true ? "Set up by an organization (Automated Device Enrollment)" : "Managed by an organization (MDM)",
                         detail: (selling
                            ? "Buyers will see this. Ask the organization to release the Mac before you sell it."
                            : "An organization can manage this Mac remotely, including locking or erasing it. Unless it's your employer's Mac, don't buy it until they release it.") + server,
                         evidence: e)
        }
        if info.enrolledViaDEP == false && info.mdmEnrolled == false {
            return Check(id: .mdmEnrollment, verdict: .clean, title: "Not managed by any organization",
                         detail: "This Mac reports it isn't enrolled in any organization's device management.", evidence: e)
        }
        return couldnt(.mdmEnrollment, "device management", raw.enrollment, .check)
    }

    static func company(_ facts: Facts, _ raw: RawData, _ selling: Bool) -> Check {
        // Before a paste, the evidence still shows the command to run.
        let e = [raw.abmPaste ?? Evidence(command: Command.abmHandoff, rawOutput: "")]
        switch facts.enrollment?.abm ?? .notChecked {
        case .assigned(let organization, _):
            return Check(id: .companyAssignment, verdict: .walkAway,
                         title: organization.map { "Assigned to “\($0)” in Apple Business" } ?? "Assigned to an organization in Apple Business",
                         detail: selling
                            ? "After it's erased, it will lock itself to them again. Ask the organization to release it before you sell."
                            : "After it's erased, it will lock itself to them again. Only that organization can release it.",
                         evidence: e)
        case .notAssigned:
            return Check(id: .companyAssignment, verdict: .clean, title: "Not assigned to any company",
                         detail: "Terminal reported that no organization has set this Mac to enroll in its device management. On a Mac you don't control, Terminal output can be faked.", evidence: e)
        case .couldNotCheck("Nothing was pasted."):
            return Check(id: .companyAssignment, verdict: .check, title: "Only the command was pasted",
                         detail: "In Terminal, select everything the command printed, press ⌘C, then choose Paste Result.", evidence: e)
        case .couldNotCheck(Parsers.unrecognizedPaste):
            return Check(id: .companyAssignment, verdict: .check, title: "Couldn't check company assignment", detail: Parsers.unrecognizedPaste, evidence: e)
        case .couldNotCheck(let reason):
            return Check(id: .companyAssignment, verdict: .check, title: "Couldn't check company assignment",
                         detail: "Terminal said: “\(reason)” Run the command exactly as copied, including sudo, type this Mac's administrator password, make sure the Mac is online, then paste the whole result.", evidence: e)
        case .notChecked:
            return Check(id: .companyAssignment, verdict: .check, title: "Company check not run yet",
                         detail: "One Terminal command asks Apple whether a company owns this Mac. It needs an administrator password and internet.", evidence: e)
        }
    }

    static func specs(_ raw: RawData, _ listingMatches: Bool?) -> Check {
        switch listingMatches {
        case true?:
            return Check(id: .specs, verdict: .clean, title: "Matches the listing",
                         detail: "You confirmed the specs match the seller's listing.", evidence: list(raw.hardware, raw.sysctl, raw.storage))
        case false?:
            return Check(id: .specs, verdict: .check, title: "Doesn't match the listing",
                         detail: "Ask the seller about the difference before you pay.", evidence: list(raw.hardware, raw.sysctl, raw.storage))
        // Waiting for the buyer's answer, not something Tirekick couldn't read.
        case nil:
            return Check(id: .specs, verdict: .check, title: "Compare with the listing",
                         detail: "Check the model, chip, memory and storage in What you're buying against the seller's listing.")
        }
    }

    /// nil for a desktop without a battery.
    static func battery(_ facts: Facts, _ raw: RawData, _ selling: Bool) -> Check? {
        guard let b = facts.battery else {
            return facts.specs?.isLaptop == false ? nil : couldnt(.battery, "the battery", raw.power ?? raw.battery)
        }
        let e = list(raw.power, raw.battery)
        let rated = b.designCycleCount ?? ratedCycles
        let cycles = b.cycleCount.map { ", \(Format.count($0)) of \(Format.count(rated)) rated cycles" } ?? ""
        let worn = selling ? "Buyers will see this, so mention it in your listing." : "Expect shorter battery life, and factor a replacement into the price."
        let condition = b.condition == "Good" ? nil : b.condition
        if b.permanentFailure == true {
            return Check(id: .battery, verdict: .check, title: "Battery reports a permanent failure", detail: worn, evidence: e)
        }
        if let condition {
            return Check(id: .battery, verdict: .check, title: "Battery needs service (macOS says: \(condition))", detail: worn, evidence: e)
        }
        if let percent = b.maximumCapacityPercent {
            let holds = "It holds \(percent)% of its original capacity."
            return percent < 80
                ? Check(id: .battery, verdict: .check, title: "Battery at \(percent)%\(cycles)", detail: "\(holds) \(worn)", evidence: e)
                : Check(id: .battery, verdict: .clean, title: "Battery at \(percent)%\(cycles)",
                        detail: "\(holds) Apple designs it to keep up to 80% at \(Format.count(rated)) cycles.", evidence: e)
        }
        if b.condition == "Good" {
            return Check(id: .battery, verdict: .clean, title: "Battery condition is normal\(cycles)",
                         detail: "macOS reports the battery condition as Good.", evidence: e)
        }
        return couldnt(.battery, "the battery", raw.power ?? raw.battery)
    }

    static func storage(_ facts: Facts, _ raw: RawData, _ selling: Bool) -> Check {
        guard let s = facts.storage else { return couldnt(.storageHealth, "the SSD", raw.storage ?? raw.nvme) }
        let e = list(raw.storage, raw.nvme)
        let (drive, theDrive) = s.medium == "rotational" ? ("Drive", "The drive") : ("SSD", "The SSD")
        switch s.smartStatus {
        case "Verified"?:
            return Check(id: .storageHealth, verdict: .clean, title: "\(drive) reports healthy (SMART: Verified)",
                         detail: "SMART is the drive's own self-check. It reports failures, not wear.", evidence: e)
        // VERIFY: "Failing" is diskutil's wording; no system_profiler sample yet.
        case let status? where status.lowercased().hasPrefix("fail"):
            return Check(id: .storageHealth, verdict: .walkAway, title: "\(drive) reports it's failing", detail: selling
                ? "Back up your data now. Buyers will see this."
                : "The drive's own self-check says it's failing, and data on it could be lost. Replacing it usually means a costly repair.", evidence: e)
        case nil, "Not Supported"?:
            return Check(id: .storageHealth, verdict: .unknown, title: "\(theDrive) doesn't report its health",
                         detail: "It doesn't support SMART self-checks, so Tirekick can't tell.", evidence: e)
        case let status?:
            return Check(id: .storageHealth, verdict: .unknown, title: "\(theDrive) reports SMART status “\(status)”",
                         detail: "Tirekick doesn't recognize this status. Details show exactly what macOS reported.", evidence: e)
        }
    }

    static func updates(_ facts: Facts, _ raw: RawData) -> Check {
        guard let specs = facts.specs else { return couldnt(.macOSUpdates, "macOS updates", raw.hardware) }
        let running = " This Mac is running macOS \(facts.os)."
        func builtIn(_ line: String) -> [Evidence] { [Evidence(command: "Tirekick model list (built in)", rawOutput: line)] }
        guard let model = facts.model else {
            let missing = builtIn("\(specs.modelIdentifier) → not in the list")
            // Not in the catalog but an older family name: a Mac Apple dropped before macOS 13, on a patched macOS (OpenCore Legacy Patcher).
            if specs.modelIdentifier.range(of: #"^(MacBookPro|MacBookAir|MacBook|iMacPro|iMac|Macmini|MacPro)\d+,\d+$"#, options: .regularExpression) != nil {
                return Check(id: .macOSUpdates, verdict: .check, title: "Apple doesn't support macOS \(facts.os.major) on this Mac",
                             detail: "It's most likely running a patched macOS, so it gets no official updates from Apple.",
                             evidence: missing)
            }
            // Only a "MacN,M" identifier can be a Mac released after this catalog; anything else (VirtualMac2,1) isn't "newer".
            let newer = specs.modelIdentifier.range(of: #"^Mac\d+,\d+$"#, options: .regularExpression) != nil
            return Check(id: .macOSUpdates, verdict: .unknown, title: newer ? "Newer than this version of Tirekick" : "Not in Tirekick's list of Macs",
                         detail: "Tirekick doesn't know \(specs.modelIdentifier), so it can't tell how long it gets updates." + running,
                         evidence: missing)
        }
        let e = builtIn("\(model.identifier) → \(model.name), last macOS: \(model.lastMacOS.map(String.init) ?? "current")")
        guard let last = model.lastMacOS else {
            return Check(id: .macOSUpdates, verdict: .clean, title: "Gets macOS \(max(ModelCatalog.newestMacOS, facts.os.major)), the current version",
                         detail: "Apple lists it as supported by the current macOS." + running, evidence: e)
        }
        if facts.os.major > last {
            return Check(id: .macOSUpdates, verdict: .check, title: "Apple doesn't support macOS \(facts.os.major) on this Mac",
                         detail: "It's most likely running a patched macOS, so it gets no official updates from Apple. Its last supported macOS is \(last).",
                         evidence: e)
        }
        let releases = ModelCatalog.macOSReleases
        let distance = (releases.firstIndex(of: ModelCatalog.newestMacOS) ?? releases.count) - (releases.firstIndex(of: last) ?? 0)
        let detail = switch distance {
        case ...1: "Security updates usually continue for about 2 years (not guaranteed)."
        case 2: "Security updates usually continue for about 1 more year (not guaranteed)."
        default: "Apple has most likely stopped its security updates."
        }
        return Check(id: .macOSUpdates, verdict: .check, title: "macOS \(last) is its last", detail: detail + running, evidence: e)
    }

    static func iCloud(_ facts: Facts, _ raw: RawData) -> Check {
        let e = list(raw.iCloudAccounts)
        switch facts.iCloudSignedIn {
        case true?:
            return Check(id: .iCloudSignedOut, verdict: .check, title: "Still signed in to iCloud",
                         detail: "Sign out of your Apple Account in System Settings before you erase this Mac.", evidence: e)
        case false?:
            return Check(id: .iCloudSignedOut, verdict: .clean, title: "Signed out of iCloud",
                         detail: "No Apple Account is signed in for this user. Other users on this Mac aren't checked.", evidence: e)
        case nil:
            return couldnt(.iCloudSignedOut, "iCloud sign-in", raw.iCloudAccounts)
        }
    }

    static func fileVault(_ facts: Facts, _ raw: RawData) -> Check {
        let e = list(raw.fileVault)
        switch facts.fileVaultOn {
        case false?:
            return Check(id: .fileVault, verdict: .check, title: "FileVault is off",
                         detail: "Turn it on in System Settings › Privacy & Security, so nobody can read your data without your password before you erase the Mac.", evidence: e)
        case true?:
            return Check(id: .fileVault, verdict: .clean, title: "FileVault is on", detail: "Your data is encrypted.", evidence: e)
        case nil:
            return couldnt(.fileVault, "FileVault", raw.fileVault)
        }
    }

    // MARK: - Helpers

    static func list(_ evidence: Evidence?...) -> [Evidence] { evidence.compactMap { $0 } }

    /// "Couldn't check …" with the reason: no run, the command's own error, or output Tirekick didn't expect.
    /// Activation Lock and MDM pass `.check`: an unread hard fact must not look like a mere gap.
    static func couldnt(_ id: CheckID, _ what: String, _ evidence: Evidence?, _ verdict: Verdict = .unknown) -> Check {
        let error = evidence?.errorOutput.split(whereSeparator: \.isNewline).first.map(String.init)
        let detail = if evidence == nil {
            "The command didn't run. Choose Check Again."
        } else if let error {
            "The command said: “\(error)”."
        } else {
            "The command's output wasn't what Tirekick expected. Details show exactly what it printed."
        }
        return Check(id: id, verdict: verdict, title: "Couldn't check \(what)", detail: detail, evidence: list(evidence))
    }
}
