import SwiftUI
import TirekickCore

struct ChecksView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Check rows shown so far. Only after the first run's spinner do they arrive one by one; coming back to this
    /// screen shows them all at once.
    @State private var revealed = Int.max

    var body: some View {
        if let facts = model.facts {
            let checks = model.checks
            Form {
                Section { banner(checks) }

                Section("Checks") {
                    ForEach(checks.prefix(revealed)) { check in
                        CheckRow(check: check)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                    }
                }

                Section(model.mode == .buying ? "What you're buying" : "This Mac") {
                    ForEach(ReportText.specRows(facts, maskSerial: false), id: \.label) {
                        LabeledContent($0.label, value: $0.value)
                    }
                    if model.mode == .buying {
                        Picker("Matches the listing?", selection: $model.listingMatches) {
                            Text("Yes").tag(Bool?.some(true))
                            Text("No").tag(Bool?.some(false))
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .textSelection(.enabled)
            }
            .formStyle(.grouped)
            .task { try? await reveal(checks.count) }
        } else {
            VStack(spacing: Space.m) {
                ProgressView().controlSize(.large)
                Text("Checking this Mac…").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { revealed = 0 }
        }
    }

    private func banner(_ checks: [Check]) -> some View {
        let verdict = Verdict.overall(checks.map(\.verdict))
        return HStack(spacing: Space.s) {
            HStack(spacing: Space.s) {
                VerdictIcon(verdict: verdict, size: 28, showsWord: false)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(verdict.bannerTitle(for: model.mode))
                        .font(.title2.weight(.semibold))
                    Text(ReportText.summaryLine(checks))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: Space.xs)
            if model.phase == .running {
                ProgressView().controlSize(.small)
            }
            Button("Check Again") { model.runChecks() }
                .buttonStyle(.bordered)
                .disabled(model.phase == .running)
        }
        .padding(.vertical, Space.xs)
    }

    private func reveal(_ count: Int) async throws {
        guard revealed == 0 else { return }
        if reduceMotion {
            withAnimation(Motion.standard(true)) { revealed = .max }
            return
        }
        for i in 0..<count {
            withAnimation(Motion.standard(false)) { revealed = i + 1 }
            try await Task.sleep(for: .milliseconds(70))
        }
        revealed = .max
    }
}

/// Verdict, the fact, what it means; the commands and raw output behind Details.
private struct CheckRow: View {
    let check: Check
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s) {
            VerdictIcon(verdict: check.verdict, showsWord: false)
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(check.title).fontWeight(.medium)
                Text(check.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if check.id == .companyAssignment && needsHandoff {
                    ABMHandoffView().padding(.vertical, Space.xs)
                }
                if !check.evidence.isEmpty {
                    DisclosureGroup("Details") {
                        VStack(alignment: .leading, spacing: Space.m) {
                            ForEach(check.evidence, id: \.self) { EvidenceView(evidence: $0) }
                        }
                    }
                    .font(.callout)
                }
            }
        }
        .padding(.vertical, Space.xxs)
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
            .padding(Space.xs)
        return Group {
            if lines.count > 12 {
                ScrollView { box }.frame(height: 180)
            } else {
                box
            }
        }
        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.quaternary))
    }
}
