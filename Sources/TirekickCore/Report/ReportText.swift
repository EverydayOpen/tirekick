import Foundation

/// Words for the Checks screen, the share card, the PDF and the clipboard.
public enum ReportText {
    /// Findings Tirekick can't make from inside the Mac.
    public static let cantTell = [
        "Whether it's been reported lost or missing. There's no public list to check.",
        "Whether an Intel Mac has a firmware password. Checking needs administrator access.",
        "Which parts were replaced or repaired, and by whom.",
        "Liquid damage or wear inside the case.",
    ]

    /// Model, Identifier, Chip, CPU ("11 cores: 5 Performance + 6 Efficiency"), GPU (when known), Memory, Storage, Serial, macOS.
    public static func specRows(_ facts: Facts, maskSerial: Bool) -> [SpecRow] {
        let s = facts.specs
        var rows = [
            SpecRow(label: "Model", value: facts.model?.name ?? s?.modelName ?? "Unknown"),
            SpecRow(label: "Identifier", value: s?.modelIdentifier ?? "Unknown"),
            SpecRow(label: "Chip", value: s?.chip ?? "Unknown"),
            SpecRow(label: "CPU", value: s.map(cpu) ?? "Unknown"),
        ]
        if let gpu = s?.gpuCores { rows.append(SpecRow(label: "GPU", value: "\(gpu) cores")) }
        return rows + [
            SpecRow(label: "Memory", value: Format.memory(s?.memoryBytes)),
            SpecRow(label: "Storage", value: Format.storage(facts.storage?.capacityBytes)),
            SpecRow(label: "Serial", value: serial(s?.serial, masked: maskSerial)),
            SpecRow(label: "macOS", value: facts.os.description),
        ]
    }

    /// "Checked 9 things · 1 serious · 2 to check · 1 couldn't check" (zero parts left out).
    public static func summaryLine(_ checks: [Check]) -> String {
        func count(_ verdict: Verdict) -> Int { checks.filter { $0.verdict == verdict }.count }
        var parts = ["Checked \(checks.count) \(checks.count == 1 ? "thing" : "things")"]
        if count(.walkAway) > 0 { parts.append("\(count(.walkAway)) serious") }
        if count(.check) > 0 { parts.append("\(count(.check)) to check") }
        if count(.unknown) > 0 { parts.append("\(count(.unknown)) couldn't check") }
        return parts.joined(separator: " · ")
    }

    /// Leaves out the listing question (no card row) and the seller's prep checklist (advice for the seller, which a
    /// buyer could misread), so neither sets the headline; a skipped test reads like one never opened.
    public static func card(_ report: Report, maskSerial: Bool) -> ReportCard {
        let facts = report.facts, s = facts.specs
        let chip = [s?.chip.map(shortChip), s.flatMap(totalCores).map { "\($0)-core" }].compactMap { $0 }.joined(separator: " ")
        let title = ["Tirekick report", facts.model?.name ?? s?.modelName, chip.isEmpty ? nil : chip,
                     s?.memoryBytes.map { Format.memory($0) }, facts.storage?.capacityBytes.map { Format.storage($0) }]
            .compactMap { $0 }.joined(separator: " · ")

        var shown = report
        shown.checks = report.checks.filter { ![.specs, .iCloudSignedOut, .fileVault].contains($0.id) }
        func line(_ c: Check) -> String { c.detail.isEmpty ? c.title : "\(c.title). \(c.detail)" }
        let worst = shown.checks.max { $0.verdict < $1.verdict }
        let problem = HardwareTest.allCases.first { report.tests[$0]?.outcome == .problem }
        // Nothing wrong but something unknown: say what wasn't checked (CheckID order puts the hard facts first).
        let summary: String? = if let worst, worst.verdict >= .check {
            line(worst)
        } else if let problem {
            testLine(problem, report.tests[problem]!)
        } else {
            shown.checks.first { $0.verdict == .unknown }.map(line)
        }

        let rows = shown.checks.map { ReportCard.Row(verdict: $0.verdict, text: $0.title) }
            + HardwareTest.allCases.compactMap { test in
                report.tests[test].flatMap { $0.outcome == .skipped ? nil : ReportCard.Row(verdict: $0.outcome.verdict, text: testLine(test, $0)) }
            }
        return ReportCard(
            title: title,
            verdict: shown.verdict,
            headline: shown.verdict.bannerTitle(for: report.mode),
            summary: summary,
            rows: rows,
            footer: "Checked \(Format.date(report.createdAt)) on this Mac · Serial \(serial(s?.serial, masked: maskSerial)) · Only trust a check you run yourself: Tirekick (free)"
        )
    }

    /// Plain text for the PDF and Copy: header, verdict, specs, each check with its evidence (always redacted;
    /// maskSerial only shows the full serial in the Serial row and footer), tests, "What Tirekick can't tell you", footer.
    public static func full(_ report: Report, maskSerial: Bool) -> String {
        let top = card(report, maskSerial: maskSerial)
        let serial = report.facts.specs?.serial
        let clean: (String) -> String = { Redact.evidence($0, serial: serial) }
        // Unlike the card, the PDF lists every check, so its headline counts them all (as the Checks screen does).
        var out = [top.title, "\(report.verdict.bannerTitle(for: report.mode)) · \(summaryLine(report.checks))"]
        if let summary = top.summary { out.append(summary) }
        out += ["", report.mode == .buying ? "What you're buying" : "What you're selling"]
        out += specRows(report.facts, maskSerial: maskSerial).map { "  \($0.label): \($0.value)" }
        out += ["", "Checks"]
        for check in report.checks {
            out += ["", "[\(check.verdict.word)] \(check.title)"]
            if !check.detail.isEmpty { out.append(check.detail) }
            out += check.evidence.map { block($0, clean) }
        }
        // A skip isn't "couldn't check": nobody tried (the headline counts it as never opened).
        let tests = HardwareTest.allCases.compactMap { test in
            report.tests[test].map { $0.outcome == .skipped ? "[Skipped] \(test.title)" : "[\($0.outcome.verdict.word)] \(testLine(test, $0))" }
        }
        if !tests.isEmpty { out += ["", "Tests"] + tests }
        out += ["", "What Tirekick can't tell you"] + cantTell.map { "- \($0)" }
        out += ["", top.footer]
        return out.joined(separator: "\n") + "\n"
    }

    /// Every Evidence in RawData, always redacted: testers send this as a fixture.
    public static func rawData(_ raw: RawData) -> String {
        let serial = raw.hardware.flatMap { Parsers.specs(hardwareJSON: $0.rawOutput, sysctl: nil, displaysJSON: nil)?.serial }
        let all = [raw.hardware, raw.power, raw.storage, raw.nvme, raw.displays, raw.battery, raw.sysctl,
                   raw.enrollment, raw.fileVault, raw.iCloudAccounts, raw.abmPaste].compactMap { $0 }
        let blocks = all.map { e in block(e) { Redact.evidence($0, serial: serial) } }
        return (["Tirekick raw data · macOS \(raw.os) · \(Format.date(raw.collectedAt))"] + blocks).joined(separator: "\n\n") + "\n"
    }

    // MARK: - Helpers

    static func serial(_ serial: String?, masked: Bool) -> String {
        masked ? Redact.serial(serial) : serial ?? "Unknown"
    }

    static func totalCores(_ s: MacSpecs) -> Int? {
        let total = s.cpuCores ?? s.coreGroups.map(\.count).reduce(0, +)
        return total > 0 ? total : nil
    }

    static func cpu(_ s: MacSpecs) -> String {
        guard let total = totalCores(s) else { return "Unknown" }
        let groups = s.coreGroups.map { "\($0.count) \($0.name)" }.joined(separator: " + ")
        return groups.isEmpty ? "\(total) cores" : "\(total) cores: \(groups)"
    }

    /// "Apple M3 Pro" → "M3 Pro"; "Intel(R) Core(TM) i7-8850H CPU @ 2.60GHz" → "Intel Core i7-8850H".
    static func shortChip(_ chip: String) -> String {
        if chip.hasPrefix("Apple ") { return String(chip.dropFirst(6)) }
        let plain = chip.replacingOccurrences(of: "(R)", with: "").replacingOccurrences(of: "(TM)", with: "")
            .replacingOccurrences(of: " CPU", with: "")
        return String(plain[..<(plain.range(of: " @")?.lowerBound ?? plain.endIndex)]).trimmingCharacters(in: .whitespaces)
    }

    /// "Keyboard: 78 of 78 keys", "Display: passed".
    static func testLine(_ test: HardwareTest, _ result: TestResult) -> String {
        "\(test.title): \(result.note ?? result.outcome.rawValue)"
    }

    /// "$ command", the output, then stderr and a non-zero exit status when there are any.
    static func block(_ e: Evidence, _ clean: (String) -> String) -> String {
        var lines = ["$ \(e.command)", clean(e.rawOutput).trimmingCharacters(in: .newlines)]
        if !e.errorOutput.isEmpty { lines.append("[stderr] " + clean(e.errorOutput).trimmingCharacters(in: .newlines)) }
        if let status = e.exitStatus, status != 0 { lines.append("[exit status \(status)]") }
        return lines.joined(separator: "\n")
    }
}
