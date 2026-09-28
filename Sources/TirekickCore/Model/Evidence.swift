import Foundation

/// One command the app may run. Every command is defined here and nowhere else (docs/BUILD_PLAN.md §3):
/// absolute path, argument array, no shell. `profiles` and `fdesetup` only ever get `status`.
public struct Command: Hashable, Sendable {
    public let executable: String
    public let arguments: [String]

    init(_ executable: String, _ arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }

    /// Exactly what ran, shown on every check's evidence row.
    public var display: String { ([executable] + arguments).joined(separator: " ") }

    public static let hardware = Command("/usr/sbin/system_profiler", ["-json", "SPHardwareDataType"])
    public static let power = Command("/usr/sbin/system_profiler", ["-json", "SPPowerDataType"])
    public static let storage = Command("/usr/sbin/system_profiler", ["-json", "SPStorageDataType"])
    public static let nvme = Command("/usr/sbin/system_profiler", ["-json", "SPNVMeDataType"])
    public static let displays = Command("/usr/sbin/system_profiler", ["-json", "SPDisplaysDataType"])
    public static let battery = Command("/usr/sbin/ioreg", ["-r", "-c", "AppleSmartBattery", "-a"])
    public static let sysctl = Command("/usr/sbin/sysctl", [
        "hw.model", "hw.memsize", "hw.nperflevels",
        "hw.perflevel0.name", "hw.perflevel0.physicalcpu", "hw.perflevel1.name", "hw.perflevel1.physicalcpu",
        "machdep.cpu.brand_string",
    ])
    public static let enrollment = Command("/usr/bin/profiles", ["status", "-type", "enrollment"])
    public static let fileVault = Command("/usr/bin/fdesetup", ["status"])

    /// The allowlist: everything the app may run.
    public static let all: [Command] = [hardware, power, storage, nvme, displays, battery, sysctl, enrollment, fileVault]

    /// The ABM check. The user runs this in Terminal and pastes the output back; the app never runs it.
    public static let abmHandoff = "sudo /usr/bin/profiles show -type enrollment"

    /// Read (never written) for the seller checklist. Only an account count leaves the Mac layer, never the Apple Account.
    public static let iCloudAccountsFile = "~/Library/Preferences/MobileMeAccounts.plist"
}

/// What a check is based on: the command and its raw output, shown when a check row is expanded.
public struct Evidence: Codable, Hashable, Sendable {
    /// `Command.display`, `Command.abmHandoff` or `Command.iCloudAccountsFile`.
    public var command: String
    /// stdout (or the text the user pasted). Parsers read only this.
    public var rawOutput: String
    /// stderr, a launch error or "Timed out after 30 s". Shown, never parsed.
    public var errorOutput: String
    /// nil when nothing was run (pasted text, a file read, or the launch failed).
    public var exitStatus: Int32?

    public init(command: String, rawOutput: String, errorOutput: String = "", exitStatus: Int32? = nil) {
        self.command = command
        self.rawOutput = rawOutput
        self.errorOutput = errorOutput
        self.exitStatus = exitStatus
    }
}

/// Everything collected on this Mac, before parsing. nil means "not collected".
public struct RawData: Codable, Hashable, Sendable {
    public var hardware: Evidence?
    public var power: Evidence?
    public var storage: Evidence?
    public var nvme: Evidence?
    public var displays: Evidence?
    /// ioreg AppleSmartBattery (plist XML).
    public var battery: Evidence?
    public var sysctl: Evidence?
    public var enrollment: Evidence?
    public var fileVault: Evidence?
    /// "Accounts: N" summary of `Command.iCloudAccountsFile`.
    public var iCloudAccounts: Evidence?
    /// The Terminal output the user pasted for `Command.abmHandoff`.
    public var abmPaste: Evidence?
    public var os: OSVersion
    public var collectedAt: Date

    public init(
        os: OSVersion, collectedAt: Date = Date(),
        hardware: Evidence? = nil, power: Evidence? = nil, storage: Evidence? = nil, nvme: Evidence? = nil,
        displays: Evidence? = nil, battery: Evidence? = nil, sysctl: Evidence? = nil, enrollment: Evidence? = nil,
        fileVault: Evidence? = nil, iCloudAccounts: Evidence? = nil, abmPaste: Evidence? = nil
    ) {
        self.os = os
        self.collectedAt = collectedAt
        self.hardware = hardware
        self.power = power
        self.storage = storage
        self.nvme = nvme
        self.displays = displays
        self.battery = battery
        self.sysctl = sysctl
        self.enrollment = enrollment
        self.fileVault = fileVault
        self.iCloudAccounts = iCloudAccounts
        self.abmPaste = abmPaste
    }
}
