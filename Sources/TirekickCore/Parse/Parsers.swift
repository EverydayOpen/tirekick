import Foundation

/// Turns raw command output into Facts. Every parser tolerates missing and extra keys; nil means "couldn't tell".
/// Formats are documented in docs/BUILD_PLAN.md §2 and sampled in Tests/TirekickCoreTests/Fixtures.
public enum Parsers {
    /// SPHardwareDataType JSON (+ sysctl stdout, + SPDisplaysDataType JSON for GPU cores). nil if the hardware JSON is unreadable.
    public static func specs(hardwareJSON: String, sysctl: String?, displaysJSON: String?) -> MacSpecs? {
        guard let hw = items(hardwareJSON, "SPHardwareDataType")?.first else { return nil }
        let sys = Parsers.sysctl(sysctl ?? "")
        guard let id = hw["machine_model"] as? String ?? sys["hw.model"] else { return nil }
        let chipType = hw["chip_type"] as? String
        let brand = sys["machdep.cpu.brand_string"]
        // "Unknown" when system_profiler runs under Rosetta.
        let cpuType = (hw["cpu_type"] as? String).flatMap { $0 == "Unknown" ? nil : $0 }
        // "Apple " not "Apple M": the MacBook Neo has an A18 Pro. Under Rosetta neither string says Apple,
        // so fall back to the catalog (only Apple-silicon Macs run the newest macOS).
        let appleChip = [chipType, brand].contains { $0?.hasPrefix("Apple ") == true }
        let levels = int(sys["hw.nperflevels"]) ?? 0
        let groups = (0..<levels).compactMap { n -> CoreGroup? in
            guard let name = sys["hw.perflevel\(n).name"], let count = int(sys["hw.perflevel\(n).physicalcpu"]) else { return nil }
            return CoreGroup(name: name, count: count)
        }
        // A value Tirekick doesn't know is nil (couldn't read), never "doesn't report".
        let activation: ActivationLock? = switch hw["activation_lock_status"] as? String {
        case "activation_lock_enabled": .enabled
        case "activation_lock_disabled": .disabled
        case nil: .notReported
        default: nil
        }
        return MacSpecs(
            modelIdentifier: id,
            modelName: hw["machine_name"] as? String,
            chip: chipType ?? brand ?? cpuType,
            isAppleSilicon: appleChip || ModelCatalog.lookup(id).map { $0.lastMacOS == nil } ?? false,
            // Int on Intel and under Rosetta, "proc 18:6:0:12" on Apple silicon: the first number is the total.
            cpuCores: int(hw["number_processors"]),
            coreGroups: groups,
            gpuCores: items(displaysJSON, "SPDisplaysDataType")?.lazy.compactMap { int($0["sppci_cores"]) }.first,
            memoryBytes: Int64(sys["hw.memsize"] ?? "") ?? int(hw["physical_memory"]).map { Int64($0) << 30 },
            serial: hw["serial_number"] as? String,
            activationLock: activation
        )
    }

    /// nil when neither source has a battery.
    public static func battery(powerJSON: String?, ioregPlist: String?) -> BatteryInfo? {
        let sp = items(powerJSON, "SPPowerDataType")?.lazy.compactMap { $0["sppower_battery_health_info"] as? [String: Any] }.first
        let io = ioreg(ioregPlist)
        guard sp != nil || io != nil else { return nil }
        let design = int(io?["DesignCapacity"])
        let rawMax = int(io?["AppleRawMaxCapacity"])
        // MaxCapacity is mAh on Intel but 100 (a percent) on Apple silicon; only a value above 100 can be mAh.
        let intelMax = int(io?["MaxCapacity"]).flatMap { $0 > 100 ? $0 : nil }
        var percent = int(sp?["sppower_battery_health_maximum_capacity"])
        if percent == nil, let design, design > 0, let capacity = rawMax ?? int(io?["NominalChargeCapacity"]) ?? intelMax {
            percent = Int((Double(capacity) * 100 / Double(design)).rounded())
        }
        return BatteryInfo(
            cycleCount: int(sp?["sppower_battery_cycle_count"]) ?? int(io?["CycleCount"]),
            condition: sp?["sppower_battery_health"] as? String,
            maximumCapacityPercent: percent,
            designCapacity: design,
            rawMaxCapacity: rawMax,
            designCycleCount: int(io?["DesignCycleCount9C"]),
            permanentFailure: int(io?["PermanentFailureStatus"]).map { $0 != 0 }
        )
    }

    public static func storage(storageJSON: String?, nvmeJSON: String?) -> StorageInfo? {
        let volumes = items(storageJSON, "SPStorageDataType") ?? []
        let volume = volumes.first { $0["mount_point"] as? String == "/" }
            ?? volumes.first { ($0["physical_drive"] as? [String: Any])?["is_internal_disk"] as? String == "yes" }
        let drive = volume?["physical_drive"] as? [String: Any]
        // VERIFY: SPNVMeDataType keys come from gopsutil's parser (controllers → "_items" → drives).
        let drives = (items(nvmeJSON, "SPNVMeDataType") ?? []).flatMap { $0["_items"] as? [[String: Any]] ?? [] }
        // The startup drive, not a second internal or Thunderbolt NVMe drive that happens to be listed first.
        let name = drive?["device_name"] as? String
        let nvme = drives.first { name != nil && ($0["device_model"] as? String == name || $0["_name"] as? String == name) }
            ?? drives.first { $0["detachable_drive"] as? String != "yes" }
        guard volume != nil || nvme != nil else { return nil }
        let exact = int(nvme?["size_in_bytes"]).map(Int64.init)
        return StorageInfo(
            deviceName: drive?["device_name"] as? String ?? nvme?["device_model"] as? String,
            smartStatus: drive?["smart_status"] as? String ?? nvme?["smart_status"] as? String,
            capacityBytes: exact ?? int(volume?["size_in_bytes"]).map(Int64.init),
            capacityIsApproximate: exact == nil,
            medium: drive?["medium_type"] as? String
        )
    }

    /// `profiles status -type enrollment`; `abm` is `.notChecked`. Unknown values stay nil, never "No".
    public static func enrollment(status: String) -> EnrollmentInfo {
        let lines = sysctl(status)
        let mdm = lines["MDM enrollment"]
        return EnrollmentInfo(
            enrolledViaDEP: ["No": false, "Yes": true][lines["Enrolled via DEP"] ?? ""],
            mdmEnrolled: ["No": false, "Yes": true, "Yes (User Approved)": true][mdm ?? ""],
            userApproved: ["Yes": false, "Yes (User Approved)": true][mdm ?? ""],
            mdmServer: lines["MDM server"]
        )
    }

    /// What the user pasted from `Command.abmHandoff`. Anything unrecognized is `.couldNotCheck`, never "not assigned".
    public static func abm(pasted: String) -> ABMAssignment {
        let lines = Redact.prompts(pasted).split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
        // Only with the dictionary: the header followed by "(null)" is Apple returning no record.
        if let i = lines.firstIndex(of: abmHeader), lines.dropFirst(i + 1).first(where: { !$0.isEmpty }) == "{" {
            func value(_ key: String) -> String? {
                lines.first { $0.hasPrefix(key + " = ") }.map { plistString(String($0.dropFirst(key.count + 3).dropLast($0.hasSuffix(";") ? 1 : 0))) }
            }
            return .assigned(organization: value("OrganizationName").flatMap { $0.isEmpty ? nil : $0 },
                             mdmUnremovable: value("IsMDMUnremovable").map { $0 == "1" })
        }
        if lines.contains(where: { $0.hasPrefix("Error fetching Device Enrollment configuration:") && $0.contains("Client is not DEP enabled") }) {
            return .notAssigned
        }
        let output = lines.filter { !$0.isEmpty && !$0.hasPrefix("%") && !$0.hasPrefix("Password:") && $0 != abmHeader }
        guard !output.isEmpty else { return .couldNotCheck("Nothing was pasted.") }
        // Echo only known command output: anything else may be a password or address copied by mistake (or sudo's lecture).
        let reason = output.first { line in line == "(null)" || abmErrors.contains { line.hasPrefix($0) } }
        return .couldNotCheck(reason ?? unrecognizedPaste)
    }

    static let abmHeader = "Device Enrollment configuration:"
    static let abmErrors = ["Error fetching Device Enrollment configuration:", "sudo:", "profiles:", "(sudo refused", "Sorry, try again"]

    /// The `.couldNotCheck` reason for a paste that isn't the command's output. The App doesn't store such a paste.
    public static let unrecognizedPaste = "That doesn't look like the command's output. Copy everything Terminal printed after the command."

    /// The part of a Paste Result kept as evidence (it reaches the report and Copy Raw Data): from the last line
    /// with the command on, only the lines `abm` reads (the command, sudo's prompt and errors, profiles' output).
    /// That drops scrollback, "Last login:" and anything typed during or after the run: with sudo's password cached
    /// there's no Password: prompt, so a password typed anyway is echoed in clear. nil when `abm` wouldn't
    /// recognize it, or it is blank or only a prompt, so a password or address copied by mistake is never stored.
    public static func abmExcerpt(_ text: String) -> String? {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let command = lines.lastIndex { $0.contains("profiles show") }
        let run = lines[(command ?? lines.startIndex)...]
        switch abm(pasted: run.joined(separator: "\n")) {
        case .couldNotCheck(unrecognizedPaste): return nil
        case .couldNotCheck("Nothing was pasted.") where command == nil: return nil
        default: break
        }
        var kept: [Substring] = [], afterHeader = false, inBlock = false
        for i in run.indices {
            let line = lines[i], l = line.trimmingCharacters(in: .whitespaces)
            if inBlock {
                inBlock = l != "}"  // profiles' dictionary, through its closing brace
            } else if afterHeader && l == "{" {
                inBlock = true
            } else if afterHeader && l.isEmpty {
                continue
            } else if !(i == command || l == abmHeader || l == "Password:" || l == "(null)" || abmErrors.contains(where: { l.hasPrefix($0) })
                        || line.contains("sudoers") || line.contains("may not run sudo")) {
                afterHeader = false
                continue
            }
            afterHeader = l == abmHeader
            kept.append(line)
        }
        return kept.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func fileVault(_ output: String) -> Bool? {
        let text = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("FileVault is On") { return true }
        if text.hasPrefix("FileVault is Off") { return false }
        return nil
    }

    /// "Accounts: N" → N > 0.
    public static func iCloudSignedIn(_ summary: String) -> Bool? {
        let text = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasPrefix("Accounts: "), let n = Int(text.dropFirst(10)) else { return nil }
        return n > 0
    }

    /// "name: value" lines → dictionary (split on the first ": "). Also reads `profiles status`.
    public static func sysctl(_ output: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            guard let sep = line.range(of: ": ") else { continue }
            result[line[..<sep.lowerBound].trimmingCharacters(in: .whitespaces)] = line[sep.upperBound...].trimmingCharacters(in: .whitespaces)
        }
        return result
    }

    // MARK: - Helpers

    /// `{ "<DataType>": [ … ] }` → the items.
    static func items(_ json: String?, _ dataType: String) -> [[String: Any]]? {
        guard let data = json?.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return object[dataType] as? [[String: Any]]
    }

    /// The first dictionary of `ioreg -a` output; nil when there is none (desktops print an empty array).
    static func ioreg(_ plist: String?) -> [String: Any]? {
        guard let data = plist?.data(using: .utf8),
              let object = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) else { return nil }
        let dict = (object as? [[String: Any]])?.first ?? object as? [String: Any]
        return dict?.isEmpty == false ? dict : nil
    }

    /// An Int, or the first run of digits in a string: "83%" → 83, "16 GB" → 16, "proc 8:4:4" → 8.
    static func int(_ value: Any?) -> Int? {
        if let n = value as? Int { return n }
        if let n = value as? NSNumber { return n.intValue }
        guard let s = value as? String else { return nil }
        return s.split { !($0.isASCII && $0.isNumber) }.first.flatMap { Int($0) }
    }

    /// One old-style plist value from `profiles show`: `"Twocanoes Software"`, `Naperville`, `"\U5317\U4eac"`.
    static func plistString(_ text: String) -> String {
        (try? PropertyListSerialization.propertyList(from: Data(text.utf8), options: [], format: nil)) as? String
            ?? text.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}

extension Facts {
    /// Runs every parser on its Evidence.rawOutput (nil evidence → nil field) and ModelCatalog.lookup.
    public init(_ raw: RawData) {
        let specs = raw.hardware.flatMap {
            Parsers.specs(hardwareJSON: $0.rawOutput, sysctl: raw.sysctl?.rawOutput, displaysJSON: raw.displays?.rawOutput)
        }
        var enrollment = raw.enrollment.map { Parsers.enrollment(status: $0.rawOutput) }
        if let paste = raw.abmPaste {
            enrollment = enrollment ?? EnrollmentInfo()
            enrollment?.abm = Parsers.abm(pasted: paste.rawOutput)
        }
        self.init(
            os: raw.os,
            specs: specs,
            model: specs.flatMap { ModelCatalog.lookup($0.modelIdentifier) },
            battery: Parsers.battery(powerJSON: raw.power?.rawOutput, ioregPlist: raw.battery?.rawOutput),
            storage: Parsers.storage(storageJSON: raw.storage?.rawOutput, nvmeJSON: raw.nvme?.rawOutput),
            enrollment: enrollment,
            fileVaultOn: raw.fileVault.flatMap { Parsers.fileVault($0.rawOutput) },
            iCloudSignedIn: raw.iCloudAccounts.flatMap { Parsers.iCloudSignedIn($0.rawOutput) }
        )
    }
}
