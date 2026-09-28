/// Stable identity of a check. Declaration order is display order (VerdictRules.evaluate returns this order).
public enum CheckID: String, Codable, CaseIterable, Sendable {
    case activationLock
    case mdmEnrollment
    /// ABM/ASM assignment, from the Terminal handoff.
    case companyAssignment
    /// Specs vs. the listing, answered by the user.
    case specs
    case battery
    case storageHealth
    case macOSUpdates
    /// Seller mode only.
    case iCloudSignedOut
    /// Seller mode only.
    case fileVault
}

/// One plain-English finding with its evidence. Findings, not guarantees.
public struct Check: Identifiable, Codable, Hashable, Sendable {
    public var id: CheckID
    public var verdict: Verdict
    /// The fact, sentence case, no trailing period, at most 60 characters. Also the report-card row text:
    /// "Activation Lock is off", "Assigned to “Acme Corp” in Apple Business".
    public var title: String
    /// What it means and what to do. At most 3 sentences.
    public var detail: String
    /// The commands behind it and their raw output. Empty only for `.specs` before the user answers.
    public var evidence: [Evidence]

    public init(id: CheckID, verdict: Verdict, title: String, detail: String, evidence: [Evidence] = []) {
        self.id = id
        self.verdict = verdict
        self.title = title
        self.detail = detail
        self.evidence = evidence
    }
}
