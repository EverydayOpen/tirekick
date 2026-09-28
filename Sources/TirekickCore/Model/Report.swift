import Foundation

/// Picked on the Welcome screen. Seller mode adds the "Ready to sell" checks and seller wording.
public enum Mode: String, Codable, CaseIterable, Sendable {
    case buying, selling
}

/// Everything the Report screen, the share card and the PDF show.
public struct Report: Codable, Hashable, Sendable {
    public var createdAt: Date
    public var mode: Mode
    public var facts: Facts
    public var checks: [Check]
    /// Finished tests only; a test that was never opened has no entry.
    public var tests: [HardwareTest: TestResult]

    public init(createdAt: Date, mode: Mode, facts: Facts, checks: [Check], tests: [HardwareTest: TestResult] = [:]) {
        self.createdAt = createdAt
        self.mode = mode
        self.facts = facts
        self.checks = checks
        self.tests = tests
    }

    /// Overall verdict of the checks and the finished tests; a skipped test counts as never opened.
    public var verdict: Verdict {
        Verdict.overall(checks.map(\.verdict) + tests.values.compactMap { $0.outcome == .skipped ? nil : $0.outcome.verdict })
    }
}

/// One "What you're buying" row, from `ReportText.specRows(_:maskSerial:)`: ("Memory", "18 GB").
public struct SpecRow: Hashable, Sendable {
    public var label: String
    public var value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

/// The shareable card (PNG), built by `ReportText.card(_:maskSerial:)` and drawn by the App's ReportCardView.
public struct ReportCard: Hashable, Sendable {
    public struct Row: Hashable, Sendable {
        public var verdict: Verdict
        public var text: String

        public init(verdict: Verdict, text: String) {
            self.verdict = verdict
            self.text = text
        }
    }

    /// "Tirekick report · MacBook Pro (14-inch, 2023) · M3 Pro 11-core · 18 GB · 512 GB".
    public var title: String
    public var verdict: Verdict
    /// `verdict.bannerTitle(for: mode)`: "Walk away".
    public var headline: String
    /// The worst finding in one or two sentences; nil when everything is clean.
    public var summary: String?
    public var rows: [Row]
    /// "Checked 12 Nov 2026 on this Mac · Serial ····G7QX · Only trust a check you run yourself: Tirekick (free)".
    public var footer: String

    public init(title: String, verdict: Verdict, headline: String, summary: String?, rows: [Row], footer: String) {
        self.title = title
        self.verdict = verdict
        self.headline = headline
        self.summary = summary
        self.rows = rows
        self.footer = footer
    }
}
