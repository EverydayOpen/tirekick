#if DEBUG
import AppKit
import TirekickCore

/// Screenshots (.github/workflows/screens.yml), DEBUG builds only: `-demoScreen <name>` opens that screen on sample
/// output, and `-demoAppearance light|dark` sets the look. The output is Tests/TirekickCoreTests/Fixtures, copied
/// verbatim: nothing is collected and no command runs (AppModel.runChecks returns early).
enum Demo {
    enum Screen: String { case welcome, checks, checksWalkAway, tests, keyboard, report }

    /// nil on a normal launch. An unknown name stops the app, so a typo in the workflow fails its capture.
    static let screen: Screen? = argument("-demoScreen").map {
        guard let screen = Screen(rawValue: $0) else { fatalError("Unknown -demoScreen \($0)") }
        return screen
    }

    /// Called by AppModel.init.
    @MainActor static func start(_ model: AppModel) {
        guard let screen = Self.screen else { return }
        if let look = argument("-demoAppearance") {
            NSApplication.shared.appearance = NSAppearance(named: look == "dark" ? .darkAqua : .aqua)
        }
        let walkAway = screen == .checksWalkAway
        model.loadDemo(walkAway ? companyMac : cleanMac)
        model.listingMatches = walkAway ? nil : true
        switch screen {
        case .welcome: break
        case .checks, .checksWalkAway: model.step = .checks
        case .tests:
            model.step = .tests
            pass(model, [.keyboard, .display, .speakers])
        case .keyboard:
            model.step = .tests
            model.openTest = .keyboard
        case .report:
            model.step = .report
            pass(model, HardwareTest.allCases)
        }
    }

    /// With the keyboard note the test itself would write for this Mac: "78 of 78 keys".
    @MainActor private static func pass(_ model: AppModel, _ tests: [HardwareTest]) {
        let keys = Set(model.keyboardLayout.rows(touchBar: model.facts?.model?.touchBar ?? false).joined().map(\.code)).count
        for test in tests {
            model.finish(test, TestResult(.passed, note: test == .keyboard ? "\(keys) of \(keys) keys" : nil))
        }
    }

    /// A healthy MacBook Air (M1), company check done: the Core tests' cleanRaw() minus its display and ioreg output,
    /// which come from other Macs (they'd give an M1 Air a 14-core GPU).
    private static let cleanMac = RawData(
        os: os, hardware: evidence(.hardware, F.m1), power: evidence(.power, F.power83),
        storage: evidence(.storage, F.storage1TB), enrollment: evidence(.enrollment, F.notEnrolled),
        fileVault: evidence(.fileVault, F.fileVaultOn),
        iCloudAccounts: Evidence(command: Command.iCloudAccountsFile, rawOutput: "Accounts: 0"),
        abmPaste: Evidence(command: Command.abmHandoff, rawOutput: F.abmNotDEP))

    /// An organization's MacBook Pro (M5 Max): Activation Lock on, enrolled by its company, company check not run yet.
    private static let companyMac = RawData(
        os: os, hardware: evidence(.hardware, F.m5Max), power: evidence(.power, F.power83),
        storage: evidence(.storage, F.storage1TB), sysctl: evidence(.sysctl, F.m5Sysctl),
        enrollment: evidence(.enrollment, F.depWithServer))

    /// The macos-26 runner's version (Fixtures/runner-macos-26/about.txt).
    private static let os = OSVersion(26, 6, 2)

    private static func evidence(_ command: Command, _ output: String) -> Evidence {
        Evidence(command: command.display, rawOutput: output, exitStatus: 0)
    }

    /// The value after `name` in the launch arguments (never a stored setting: v1 has none).
    private static func argument(_ name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let i = arguments.firstIndex(of: name), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    /// Tests/TirekickCoreTests/Fixtures, named as in the Core tests' `F`.
    private enum F {
        // SPHardwareDataType_AppleSilicon_M1_lockDisabled.json
        static let m1 = """
            {
              "SPHardwareDataType" : [
                {
                  "_name" : "hardware_overview",
                  "activation_lock_status" : "activation_lock_disabled",
                  "boot_rom_version" : "7429.41.5",
                  "chip_type" : "Apple M1",
                  "machine_model" : "MacBookAir10,1",
                  "machine_name" : "MacBook Air",
                  "number_processors" : "proc 8:4:4",
                  "os_loader_version" : "7429.41.5",
                  "physical_memory" : "16 GB",
                  "platform_UUID" : "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
                  "provisioning_UDID" : "XXXXXXXX-XXXXXXXXXXXXXXXX",
                  "serial_number" : "XXXXXXXXQ6LR"
                }
              ]
            }
            """

        // SPHardwareDataType_AppleSilicon_M5Max_lockEnabled.json
        static let m5Max = """
            {
              "SPHardwareDataType" : [
                {
                  "_name" : "hardware_overview",
                  "activation_lock_status" : "activation_lock_enabled",
                  "boot_rom_version" : "18000.101.6",
                  "chip_type" : "Apple M5 Max",
                  "machine_model" : "Mac17,6",
                  "machine_name" : "MacBook Pro",
                  "model_number" : "Z1N20001GLL/A",
                  "number_processors" : "proc 18:6:0:12",
                  "os_loader_version" : "18000.101.6",
                  "physical_memory" : "128 GB",
                  "platform_UUID" : "xxxxxxxxxxxxxxx",
                  "provisioning_UDID" : "xxxxxxxxxxxxxxx",
                  "serial_number" : "xxxxxxxxxxxxxxx"
                }
              ]
            }
            """

        // sysctl_AppleSilicon_M5Max_perflevels.txt
        static let m5Sysctl = """
            hw.nperflevels: 2
            hw.perflevel0.physicalcpu: 6
            hw.perflevel0.physicalcpu_max: 6
            hw.perflevel0.logicalcpu: 6
            hw.perflevel0.logicalcpu_max: 6
            hw.perflevel0.l1icachesize: 196608
            hw.perflevel0.l1dcachesize: 131072
            hw.perflevel0.l2cachesize: 16777216
            hw.perflevel0.cpusperl2: 6
            hw.perflevel0.name: Super
            hw.perflevel1.physicalcpu: 12
            hw.perflevel1.physicalcpu_max: 12
            hw.perflevel1.logicalcpu: 12
            hw.perflevel1.logicalcpu_max: 12
            hw.perflevel1.l1icachesize: 131072
            hw.perflevel1.l1dcachesize: 65536
            hw.perflevel1.l2cachesize: 8388608
            hw.perflevel1.cpusperl2: 6
            hw.perflevel1.name: Performance
            """

        // SPPowerDataType_AppleSilicon_excerpt_83pct.json
        static let power83 = """
            {
              "SPPowerDataType" : [
                {
                  "sppower_battery_health_info" : {
                    "sppower_battery_cycle_count" : 88,
                    "sppower_battery_health" : "Good",
                    "sppower_battery_health_maximum_capacity" : "83%"
                  }
                }
              ]
            }
            """

        // SPStorageDataType_AppleSilicon_1TB_withUSB.json
        static let storage1TB = """
            {
              "SPStorageDataType" : [
                {
                  "_name" : "Macintosh HD - Data",
                  "bsd_name" : "disk3s5",
                  "file_system" : "APFS",
                  "free_space_in_bytes" : 437436678144,
                  "ignore_ownership" : "no",
                  "mount_point" : "/System/Volumes/Data",
                  "physical_drive" : {
                    "device_name" : "APPLE SSD AP1024Z",
                    "is_internal_disk" : "yes",
                    "media_name" : "AppleAPFSMedia",
                    "medium_type" : "ssd",
                    "partition_map_type" : "unknown_partition_map_type",
                    "protocol" : "Apple Fabric",
                    "smart_status" : "Verified"
                  },
                  "size_in_bytes" : 994662584320,
                  "volume_uuid" : "7012B685-7F5C-4233-B297-1760B99624C3",
                  "writable" : "yes"
                },
                {
                  "_name" : "USB_TM_1TB",
                  "bsd_name" : "disk7s2",
                  "file_system" : "Case-sensitive APFS",
                  "free_space_in_bytes" : 555120910336,
                  "ignore_ownership" : "no",
                  "mount_point" : "/Volumes/USB_TM_1TB",
                  "physical_drive" : {
                    "is_internal_disk" : "no",
                    "media_name" : "AppleAPFSMedia",
                    "partition_map_type" : "unknown_partition_map_type",
                    "protocol" : "USB"
                  },
                  "size_in_bytes" : 999995129856,
                  "volume_uuid" : "FEBE33E6-7660-4035-B4EC-A37678C57473",
                  "writable" : "yes"
                },
                {
                  "_name" : "Macintosh HD",
                  "bsd_name" : "disk3s1s1",
                  "file_system" : "APFS",
                  "free_space_in_bytes" : 437436678144,
                  "ignore_ownership" : "no",
                  "mount_point" : "/",
                  "physical_drive" : {
                    "device_name" : "APPLE SSD AP1024Z",
                    "is_internal_disk" : "yes",
                    "media_name" : "AppleAPFSMedia",
                    "medium_type" : "ssd",
                    "partition_map_type" : "unknown_partition_map_type",
                    "protocol" : "Apple Fabric",
                    "smart_status" : "Verified"
                  },
                  "size_in_bytes" : 994662584320,
                  "volume_uuid" : "800AC495-E5D5-4F28-8FEE-692284AF3157",
                  "writable" : "no"
                }
              ]
            }
            """

        // profiles_status_notEnrolled.txt
        static let notEnrolled = """
            Enrolled via DEP: No
            MDM enrollment: No
            """

        // profiles_status_depWithServer.txt
        static let depWithServer = """
            Enrolled via DEP: Yes
            MDM enrollment: Yes (User Approved)
            MDM server: https://applemdm.example.com/some/path?foo=bar
            """

        // profiles_show_enrollment_notDEP.txt
        static let abmNotDEP = """
            Error fetching Device Enrollment configuration: Client is not DEP enabled.
            """

        // fdesetup_status_on.txt
        static let fileVaultOn = """
            FileVault is On.
            """
    }
}
#endif
