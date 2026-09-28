import Foundation
import TirekickCore

/// Runs the allowlisted commands and reads the iCloud account count. The only caller of ProcessRunner.run.
/// Never throws: a failure becomes Evidence with empty `rawOutput`, which Core parses as "couldn't check".
public enum Collector {
    /// Runs Command.all concurrently plus iCloudAccounts().
    public static func collectAll() async -> RawData {
        async let hardware = run(.hardware)
        async let power = run(.power)
        async let storage = run(.storage)
        async let nvme = run(.nvme)
        async let displays = run(.displays)
        async let battery = run(.battery)
        async let sysctl = run(.sysctl)
        async let enrollment = run(.enrollment)
        async let fileVault = run(.fileVault)
        return await RawData(
            os: SystemInfo.osVersion(), hardware: hardware, power: power, storage: storage, nvme: nvme,
            displays: displays, battery: battery, sysctl: sysctl, enrollment: enrollment, fileVault: fileVault,
            iCloudAccounts: iCloudAccounts())
    }

    /// Launch errors and timeouts go to `errorOutput`. A timed-out run keeps no stdout, so half an output is never parsed.
    public static func run(_ command: Command, timeout: TimeInterval = 60) async -> Evidence {
        precondition(isAllowed(command), "Not on the allowlist: \(command.display)")
        do {
            let result = try await ProcessRunner.run(command.executable, command.arguments, timeout: timeout)
            if result.timedOut {
                return Evidence(command: command.display, rawOutput: "",
                                errorOutput: "Timed out after \(Int(timeout)) s", exitStatus: result.status)
            }
            return Evidence(command: command.display, rawOutput: result.stdout, errorOutput: result.stderr,
                            exitStatus: result.status)
        } catch {
            return Evidence(command: command.display, rawOutput: "", errorOutput: "Couldn't run it: \(error.localizedDescription)")
        }
    }

    /// BUILD_PLAN §3. Checks the executable rules as well as Command.all, so a bad entry added there still can't run.
    static func isAllowed(_ command: Command) -> Bool {
        guard Command.all.contains(command) else { return false }
        switch command.executable {
        case "/usr/sbin/system_profiler", "/usr/sbin/ioreg", "/usr/sbin/sysctl": return true
        case "/usr/bin/profiles", "/usr/bin/fdesetup": return command.arguments.first == "status"
        default: return false
        }
    }

    /// Reads Command.iCloudAccountsFile (never writes). rawOutput is "Accounts: N" and nothing else.
    public static func iCloudAccounts() -> Evidence {
        iCloudAccounts(at: NSString(string: Command.iCloudAccountsFile).expandingTildeInPath)
    }

    /// Only the count leaves this function, never an Apple Account.
    // VERIFY: the file still exists on macOS 13–27, and how soon cfprefsd writes a sign-out to disk.
    static func iCloudAccounts(at path: String) -> Evidence {
        func evidence(_ raw: String, _ error: String = "") -> Evidence {
            Evidence(command: Command.iCloudAccountsFile, rawOutput: raw, errorOutput: error)
        }
        guard FileManager.default.fileExists(atPath: path) else { return evidence("Accounts: 0", "The file doesn't exist.") }
        guard let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else { return evidence("", "Couldn't read the file.") }
        guard let accounts = plist["Accounts"] as? [Any] else { return evidence("", "The Accounts list wasn't in the file.") }
        return evidence("Accounts: \(accounts.count)")
    }
}
