import SwiftUI
import TirekickCore

/// The verdict on the bay without a box, then the checks as readout rows in one porcelain surface, then the specs in
/// another (DESIGN.md §5.3). The flip-ins and the checking beam are MOTION §5.4's.
struct ChecksView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Check rows shown so far. Only after the first run's spinner do they arrive one by one; coming back to this
    /// screen shows them all at once.
    @State private var revealed = Int.max

    var body: some View {
        if let facts = model.facts {
            let checks = model.checks
            ScrollView {
                VStack(alignment: .leading, spacing: Space.l) {
                    header(checks)

                    section("Checks") {
                        ForEach(checks.prefix(revealed)) { check in
                            CheckRow(check: check, first: check.id == checks.first?.id)
                                .transition(.flip(reduceMotion))
                        }
                    }

                    section(model.mode == .buying ? "What you're buying" : "This Mac") {
                        ForEach(Array(ReportText.specRows(facts, maskSerial: false).enumerated()), id: \.element.label) { i, row in
                            HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                                Text(row.label).foregroundStyle(.secondary)
                                Spacer(minLength: Space.s)
                                Text(row.value).font(.callout.monospaced()).multilineTextAlignment(.trailing)
                            }
                            .readoutRow(first: i == 0, inset: Space.m)
                            .accessibilityElement(children: .combine)
                        }
                        if model.mode == .buying {
                            HStack {
                                Text("Matches the listing?").accessibilityHidden(true)   // the picker carries the label
                                Spacer(minLength: Space.s)
                                Picker("Matches the listing?", selection: $model.listingMatches) {
                                    Text("Yes").tag(Bool?.some(true))
                                    Text("No").tag(Bool?.some(false))
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .fixedSize()
                            }
                            .readoutRow(first: false, inset: Space.m)
                        }
                    }
                    .textSelection(.enabled)
                }
                .padding(.horizontal, Space.xxl)
                .padding(.top, Space.s)
                .padding(.bottom, Space.l)
            }
            .task { try? await reveal(checks.count) }
        } else {
            VStack(spacing: Space.xxl) {
                LaptopView(scanning: true)
                    .background(alignment: .bottom) { Horizon(tint: Brand.hiVis, width: 440, soft: false).frame(height: 0) }
                HStack(spacing: Space.xs) {
                    ProgressView().controlSize(.small)
                    Text("Checking this Mac…").foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { revealed = 0 }
        }
    }

    /// The verdict sits on the bay, unboxed: a System Settings tile, the word, the count in mono. A new verdict turns
    /// down over the old one like a split-flap (MOTION.md §5.4). The tile never glows: severity never does.
    private func header(_ checks: [Check]) -> some View {
        let verdict = Verdict.overall(checks.map(\.verdict))
        return HStack(spacing: Space.m) {
            ZStack(alignment: .leading) {
                HStack(spacing: Space.m) {
                    VerdictIcon(verdict: verdict, size: 60, showsWord: false, tile: true)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Space.xxs) {
                        Text(verdict.bannerTitle(for: model.mode))
                            .font(.system(size: 34, weight: .bold))
                            .tracking(-0.8)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)                 // "Couldn't check everything" beside Check Again
                        Text(ReportText.summaryLine(checks))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .id(verdict)
                .transition(.flip(reduceMotion))
            }
            .animation(Motion.spring(reduceMotion), value: verdict)
            Spacer(minLength: Space.xs)
            if model.phase == .running {
                ProgressView().controlSize(.small)
            }
            Button("Check Again") { model.runChecks() }
                .buttonStyle(.bordered)
                .capsuleBorder()                                     // Compat: a capsule on macOS 14+
                .disabled(model.phase == .running)
        }
    }

    /// A small-caps header over one porcelain surface of hairline-separated rows.
    private func section<Content: View>(_ title: String, @ViewBuilder _ rows: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .font(.system(size: 12, weight: .semibold).smallCaps())   // VERIFY small caps with SF
                .tracking(0.5)
                .foregroundStyle(.secondary)
                .padding(.leading, 40)                                   // where the row titles and hairlines start
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0, content: rows)
                .surface(16)
        }
    }

    private func reveal(_ count: Int) async throws {
        guard revealed == 0 else { return }
        if reduceMotion {
            withAnimation(Motion.standard(true)) { revealed = .max }
            return
        }
        for i in 0..<count {
            withAnimation(Motion.spring(false)) { revealed = i + 1 }
            try await Task.sleep(for: .milliseconds(70))
        }
        revealed = .max
    }
}

private extension View {
    /// A row of a surface: padded, with a 0.5pt hairline above it (from `inset`, where its text starts) unless first.
    func readoutRow(first: Bool, inset: CGFloat) -> some View {
        padding(.horizontal, Space.m)
            .padding(.vertical, Space.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                if !first {
                    Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 0.5).padding(.leading, inset).allowsHitTesting(false)
                }
            }
    }
}

/// A readout row: a 3pt status tick on the leading edge, the verdict symbol, the fact and what it means, then the
/// mono readout, then the tag. The commands and raw output behind Details.
private struct CheckRow: View {
    let check: Check
    let first: Bool
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
            VerdictIcon(verdict: check.verdict, showsWord: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(check.title).font(.system(size: 13, weight: .semibold))
                Text(check.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if check.id == .companyAssignment && needsHandoff {
                    ABMHandoffView().padding(.vertical, Space.xs)
                }
                if !check.evidence.isEmpty {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: Space.m) {
                            ForEach(check.evidence, id: \.self) { EvidenceView(evidence: $0) }
                        }
                    } label: {
                        // Secondary on the label only: the commands and their output stay primary (terminal()).
                        Text("Details").foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    .controlSize(.small)
                }
            }
            Spacer(minLength: Space.xs)
            // VerdictIcon already speaks the word, and the title already says the readout.
            HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                if let readout {
                    Text(readout).font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
                }
                Tag(text: check.verdict.word, tint: check.verdict.color)
            }
            .accessibilityHidden(true)
        }
        // 16pt padding + the 16pt symbol + 8pt: the hairline starts where the text does.
        .readoutRow(first: first, inset: 40)
        .overlay(alignment: .leading) {
            // Inset 4pt so the first and last ticks stay inside the surface's corner curve.
            Capsule().fill(check.verdict.color).frame(width: 3).padding(.vertical, 10).padding(.leading, Space.xxs)
                .accessibilityHidden(true)
        }
    }

    /// The fact as a spec-sheet readout ("88%", "Off"), from the same Facts as the title; nil where only the title
    /// can say it honestly.
    private var readout: String? {
        guard let facts = model.facts else { return nil }
        switch check.id {
        case .activationLock:
            switch facts.specs?.activationLock {
            case .enabled?: return "On"
            case .disabled?: return "Off"
            default: return nil
            }
        case .battery: return facts.battery?.maximumCapacityPercent.map { "\($0)%" }
        case .storageHealth: return facts.storage?.smartStatus
        case .fileVault: return facts.fileVaultOn.map { $0 ? "On" : "Off" }
        default: return nil
        }
    }

    /// The Terminal steps stay until the paste gives an answer.
    private var needsHandoff: Bool {
        switch model.facts?.enrollment?.abm {
        case .assigned?, .notAssigned?: false
        default: true
        }
    }
}

private struct EvidenceView: View {
    let evidence: Evidence
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(evidence.command)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                Spacer(minLength: Space.xs)
                // Copied text can end up in a post, so it's always redacted; the screen shows everything.
                CopyButton {
                    let text = [evidence.command, evidence.rawOutput, evidence.errorOutput].filter { !$0.isEmpty }.joined(separator: "\n")
                    copyToPasteboard(Redact.evidence(text, serial: model.facts?.specs?.serial))
                }
                .controlSize(.small)
            }
            output(evidence.rawOutput.isEmpty ? "No output" : evidence.rawOutput)
            if !evidence.errorOutput.isEmpty {
                output(evidence.errorOutput)
            }
            if let status = evidence.exitStatus, status != 0 {
                Text("Exit status \(status)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Long output scrolls in a fixed box, capped at 200 lines on screen; Copy gets all of it.
    private func output(_ text: String) -> some View {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let shown = lines.count > 200
            ? lines.prefix(200).joined(separator: "\n") + "\n… \(lines.count - 200) more lines. Copy gets all of them."
            : text
        let box = Text(shown)
            .font(.caption.monospaced())
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.s)
        return Group {
            if lines.count > 12 {
                ScrollView { box }.frame(height: 180)
            } else {
                box
            }
        }
        .terminal()
    }
}
