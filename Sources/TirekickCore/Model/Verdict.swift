/// How one check came out, ordered by how much it matters.
/// "Walk away" is reserved for hard facts: Activation Lock on, MDM or DEP enrolled, an ABM organization, SMART failing.
public enum Verdict: Int, Codable, Comparable, CaseIterable, Sendable {
    case unknown, clean, check, walkAway

    public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }

    /// The worst verdict, but an unknown is never hidden behind "Clean": clean + unknown is `.unknown`.
    public static func overall(_ verdicts: [Verdict]) -> Verdict {
        let worst = verdicts.max() ?? .unknown
        return worst >= .check ? worst : (verdicts.contains(.unknown) ? .unknown : worst)
    }

    /// Shown and spoken next to the symbol, so a verdict never relies on color alone.
    public var word: String {
        switch self {
        case .unknown: "Couldn't check"
        case .clean: "OK"
        case .check: "Check"
        case .walkAway: "Walk away"
        }
    }

    /// The verdict banner on the Checks screen and the report card.
    public func bannerTitle(for mode: Mode) -> String {
        switch (self, mode) {
        case (.unknown, _): "Couldn't check everything"
        case (.clean, .buying): "Clean"
        case (.clean, .selling): "Ready to sell"
        case (.check, _): "Check these"
        case (.walkAway, .buying): "Walk away"
        case (.walkAway, .selling): "Fix before selling"
        }
    }
}
