import AppKit
import SwiftUI
import TirekickCore
import TirekickMac

/// The single source of truth (BUILD_PLAN §6). Views read it from the environment.
@MainActor final class AppModel: ObservableObject {
    enum Step: Int, CaseIterable { case welcome, checks, tests, report }
    enum Phase: Equatable { case idle, running, done }

    @Published var step: Step = .welcome
    @Published var mode: Mode = .buying
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var raw: RawData? {
        didSet { facts = raw.map { Facts($0) } }
    }
    @Published private(set) var facts: Facts?
    @Published var listingMatches: Bool?
    /// Non-nil: that test fills the window.
    @Published var openTest: HardwareTest?
    @Published private(set) var testResults: [HardwareTest: TestResult] = [:]
    @Published var maskSerial = true
    @Published var keyboardLayout: KeyboardLayout = keyboardIsISO() ? .iso : .ansi
    /// The last Paste Result wasn't the command's output; the handoff says so under the buttons.
    @Published private(set) var pasteRejected = false

    /// [] before the first run.
    var checks: [Check] {
        guard let raw, let facts else { return [] }
        return VerdictRules.evaluate(facts, raw: raw, mode: mode, listingMatches: listingMatches)
    }

    var report: Report? {
        guard let raw, let facts else { return nil }
        return Report(createdAt: raw.collectedAt, mode: mode, facts: facts, checks: checks, tests: testResults)
    }

    var card: ReportCard? { report.map { ReportText.card($0, maskSerial: maskSerial) } }

    /// Going back to switch mode doesn't re-run: every verdict is computed from the same raw data.
    func start(_ mode: Mode) {
        self.mode = mode
        step = .checks
        if phase == .idle { runChecks() }
    }

    /// Also "Check Again". Keeps the pasted ABM result, which only Terminal can refresh.
    func runChecks() {
        guard phase != .running else { return }
        phase = .running
        Task {
            var fresh = await Collector.collectAll()
            fresh.abmPaste = raw?.abmPaste
            raw = fresh
            phase = .done
            announce(Verdict.overall(checks.map(\.verdict)).bannerTitle(for: mode))
        }
    }

    func copyABMCommand() { copyToPasteboard(Command.abmHandoff) }

    func openTerminal() {
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"),
                                           configuration: NSWorkspace.OpenConfiguration())
    }

    /// Only the Terminal output of `Command.abmHandoff` is kept (`Parsers.abmExcerpt`), since it ends up in the
    /// report and Copy Raw Data; anything else on the pasteboard beeps and is dropped. Capped so a stray paste
    /// can't stall the Details view; the last 64 KB, since the latest run ends a long Terminal selection.
    func pasteABMResult() {
        guard let text = NSPasteboard.general.string(forType: .string),
              let excerpt = Parsers.abmExcerpt(String(text.suffix(65_536))) else {
            NSSound.beep()
            pasteRejected = true
            announce(Parsers.unrecognizedPaste)
            return
        }
        pasteRejected = false
        raw?.abmPaste = Evidence(command: Command.abmHandoff, rawOutput: excerpt)
        // The row (and maybe the banner) changes away from focus, and Paste Result can vanish, so say what changed.
        announce(checks.first { $0.id == .companyAssignment }.map {
            "\($0.title). \(Verdict.overall(checks.map(\.verdict)).bannerTitle(for: mode))"
        } ?? "")
    }

    /// A MacBook or iMac: built-in camera, microphone and stereo speakers. nil when the model is unknown.
    var isAllInOne: Bool? {
        guard let specs = facts?.specs else { return nil }
        return specs.isLaptop || (facts?.model?.name ?? specs.modelName ?? "").contains("iMac")
    }

    /// Skip never replaces an earlier Pass or Problem: leaving a test is the only way out after just looking.
    func finish(_ test: HardwareTest, _ result: TestResult) {
        if result.outcome != .skipped || testResults[test] == nil { testResults[test] = result }
        openTest = nil
    }

    func copyReport() {
        guard let report else { return }
        copyToPasteboard(ReportText.full(report, maskSerial: maskSerial))
    }

    func copyRawData() {
        guard let raw else {
            NSSound.beep()
            return
        }
        copyToPasteboard(ReportText.rawData(raw))
    }

    func back() { step = Step(rawValue: step.rawValue - 1) ?? step }
    func next() { step = Step(rawValue: step.rawValue + 1) ?? step }

    /// The spinner has no text of its own, so VoiceOver hears the verdict when the checks finish.
    private func announce(_ text: String) {
        guard let window = NSApp.mainWindow else { return }
        NSAccessibility.post(element: window, notification: .announcementRequested,
                             userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.high.rawValue])
    }
}
