/// Everything Tirekick learned about this Mac, parsed from `RawData` by `Facts(_ raw:)` (TirekickCore/Parse).
/// nil always means "couldn't tell", never "fine".
public struct Facts: Codable, Hashable, Sendable {
    public var specs: MacSpecs?
    /// nil: the identifier isn't in ModelCatalog (a newer Mac, or an older one on a patched macOS).
    public var model: ModelInfo?
    /// nil: no battery found (a desktop) or unreadable; VerdictRules tells them apart with `MacSpecs.isLaptop`.
    public var battery: BatteryInfo?
    public var storage: StorageInfo?
    public var enrollment: EnrollmentInfo?
    public var fileVaultOn: Bool?
    public var iCloudSignedIn: Bool?
    public var os: OSVersion

    public init(
        os: OSVersion, specs: MacSpecs? = nil, model: ModelInfo? = nil, battery: BatteryInfo? = nil,
        storage: StorageInfo? = nil, enrollment: EnrollmentInfo? = nil, fileVaultOn: Bool? = nil,
        iCloudSignedIn: Bool? = nil
    ) {
        self.os = os
        self.specs = specs
        self.model = model
        self.battery = battery
        self.storage = storage
        self.enrollment = enrollment
        self.fileVaultOn = fileVaultOn
        self.iCloudSignedIn = iCloudSignedIn
    }
}

/// SPHardwareDataType `activation_lock_status`.
public enum ActivationLock: String, Codable, Sendable {
    case enabled      // "activation_lock_enabled"
    case disabled     // "activation_lock_disabled"
    case notReported  // key absent (VERIFY: Intel Macs without a T2 chip)
}

/// A group of CPU cores from sysctl `hw.perflevelN.name` / `.physicalcpu`: ("Performance", 8), ("Super", 6).
public struct CoreGroup: Codable, Hashable, Sendable {
    public var name: String
    public var count: Int

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

/// What you're buying, for comparison with the listing.
public struct MacSpecs: Codable, Hashable, Sendable {
    /// `machine_model` / sysctl `hw.model`: "Mac17,6", "MacBookPro14,3".
    public var modelIdentifier: String
    /// `machine_name`: "MacBook Pro".
    public var modelName: String?
    /// `chip_type` ("Apple M5 Max", "Apple A18 Pro") or sysctl `machdep.cpu.brand_string` on Intel.
    public var chip: String?
    public var isAppleSilicon: Bool
    public var cpuCores: Int?
    /// Empty on Intel.
    public var coreGroups: [CoreGroup]
    /// SPDisplaysDataType `sppci_cores` (Apple silicon only).
    public var gpuCores: Int?
    /// sysctl `hw.memsize`, else `physical_memory`.
    public var memoryBytes: Int64?
    /// Full serial. Masked by `Redact.serial` on the card and in copied raw data.
    public var serial: String?
    /// nil: a value Tirekick doesn't recognize.
    public var activationLock: ActivationLock?

    public init(
        modelIdentifier: String, modelName: String? = nil, chip: String? = nil, isAppleSilicon: Bool,
        cpuCores: Int? = nil, coreGroups: [CoreGroup] = [], gpuCores: Int? = nil, memoryBytes: Int64? = nil,
        serial: String? = nil, activationLock: ActivationLock?
    ) {
        self.modelIdentifier = modelIdentifier
        self.modelName = modelName
        self.chip = chip
        self.isAppleSilicon = isAppleSilicon
        self.cpuCores = cpuCores
        self.coreGroups = coreGroups
        self.gpuCores = gpuCores
        self.memoryBytes = memoryBytes
        self.serial = serial
        self.activationLock = activationLock
    }

    public var isLaptop: Bool { (modelName ?? modelIdentifier).contains("MacBook") }
}

/// One row of ModelCatalog, hand-built from Apple's "Identify your Mac" and macOS compatibility pages.
public struct ModelInfo: Codable, Hashable, Sendable {
    /// "MacBookPro18,3".
    public var identifier: String
    /// Apple's marketing name, exactly as on the Identify page: "MacBook Pro (14-inch, 2021)".
    public var name: String
    public var year: Int
    /// The last major macOS it can install; nil when the newest macOS (ModelCatalog.newestMacOS) supports it.
    public var lastMacOS: Int?
    /// No physical function-key row (the keyboard test leaves it out).
    public var touchBar: Bool

    public init(identifier: String, name: String, year: Int, lastMacOS: Int? = nil, touchBar: Bool = false) {
        self.identifier = identifier
        self.name = name
        self.year = year
        self.lastMacOS = lastMacOS
        self.touchBar = touchBar
    }
}

/// SPPowerDataType plus ioreg AppleSmartBattery.
public struct BatteryInfo: Codable, Hashable, Sendable {
    /// `sppower_battery_cycle_count`, else ioreg `CycleCount`.
    public var cycleCount: Int?
    /// `sppower_battery_health` as JSON reports it: "Good", "Check Battery" (the text report says "Normal",
    /// "Service Recommended"). Anything but "Good" is a Check.
    public var condition: String?
    /// `sppower_battery_health_maximum_capacity` ("88%"), else ioreg AppleRawMaxCapacity / DesignCapacity (Intel).
    public var maximumCapacityPercent: Int?
    /// ioreg `DesignCapacity`, mAh.
    public var designCapacity: Int?
    /// ioreg `AppleRawMaxCapacity`, mAh. Never ioreg `MaxCapacity`: that is 100 (a percent) on Apple silicon.
    public var rawMaxCapacity: Int?
    /// ioreg `DesignCycleCount9C`; rules fall back to VerdictRules.ratedCycles (1,000).
    public var designCycleCount: Int?
    /// ioreg `PermanentFailureStatus` != 0.
    public var permanentFailure: Bool?

    public init(
        cycleCount: Int? = nil, condition: String? = nil, maximumCapacityPercent: Int? = nil,
        designCapacity: Int? = nil, rawMaxCapacity: Int? = nil, designCycleCount: Int? = nil,
        permanentFailure: Bool? = nil
    ) {
        self.cycleCount = cycleCount
        self.condition = condition
        self.maximumCapacityPercent = maximumCapacityPercent
        self.designCapacity = designCapacity
        self.rawMaxCapacity = rawMaxCapacity
        self.designCycleCount = designCycleCount
        self.permanentFailure = permanentFailure
    }
}

/// The internal startup drive.
public struct StorageInfo: Codable, Hashable, Sendable {
    /// `physical_drive.device_name` / NVMe `device_model`: "APPLE SSD AP1024Z".
    public var deviceName: String?
    /// `physical_drive.smart_status`: "Verified"; "Failing" (VERIFY string); "Not Supported"; nil when absent.
    public var smartStatus: String?
    /// NVMe `size_in_bytes` of the internal drive; else the startup volume's container `size_in_bytes`.
    public var capacityBytes: Int64?
    /// True when `capacityBytes` came from the APFS container (a bit below the drive's size).
    public var capacityIsApproximate: Bool
    /// `physical_drive.medium_type`: "ssd", "rotational".
    public var medium: String?

    public init(
        deviceName: String? = nil, smartStatus: String? = nil, capacityBytes: Int64? = nil,
        capacityIsApproximate: Bool = false, medium: String? = nil
    ) {
        self.deviceName = deviceName
        self.smartStatus = smartStatus
        self.capacityBytes = capacityBytes
        self.capacityIsApproximate = capacityIsApproximate
        self.medium = medium
    }
}

/// Result of the Terminal handoff (`Command.abmHandoff`).
public enum ABMAssignment: Codable, Hashable, Sendable {
    /// The user hasn't pasted anything yet.
    case notChecked
    /// "Error fetching Device Enrollment configuration: Client is not DEP enabled."
    case notAssigned
    /// "Device Enrollment configuration: { … OrganizationName = …; IsMDMUnremovable = 1; … }"
    case assigned(organization: String?, mdmUnremovable: Bool?)
    /// Any other output (no internet: "(34006) … cloud configuration server is unavailable", wrong password,
    /// "(null)", text that isn't profiles output). The reason is shown to the user.
    case couldNotCheck(String)
}

/// `profiles status -type enrollment` plus the ABM handoff.
public struct EnrollmentInfo: Codable, Hashable, Sendable {
    /// "Enrolled via DEP: Yes|No".
    public var enrolledViaDEP: Bool?
    /// "MDM enrollment: No|Yes|Yes (User Approved)".
    public var mdmEnrolled: Bool?
    public var userApproved: Bool?
    /// "MDM server: https://…" when enrolled.
    public var mdmServer: String?
    public var abm: ABMAssignment

    public init(
        enrolledViaDEP: Bool? = nil, mdmEnrolled: Bool? = nil, userApproved: Bool? = nil, mdmServer: String? = nil,
        abm: ABMAssignment = .notChecked
    ) {
        self.enrolledViaDEP = enrolledViaDEP
        self.mdmEnrolled = mdmEnrolled
        self.userApproved = userApproved
        self.mdmServer = mdmServer
        self.abm = abm
    }
}
