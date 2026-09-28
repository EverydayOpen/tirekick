/// The guided tests on the Tests screen. Declaration order is tile order.
public enum HardwareTest: String, Codable, CaseIterable, Sendable {
    case keyboard, display, speakers, microphone, camera, trackpad

    public var title: String {
        switch self {
        case .keyboard: "Keyboard"
        case .display: "Display"
        case .speakers: "Speakers"
        case .microphone: "Microphone"
        case .camera: "Camera"
        case .trackpad: "Trackpad"
        }
    }
}

/// How the user ended a test.
public enum TestOutcome: String, Codable, Sendable {
    case passed, problem, skipped

    /// A problem counts as "Check these". Report.verdict and the card leave skipped tests out, as if never opened.
    public var verdict: Verdict {
        switch self {
        case .passed: .clean
        case .problem: .check
        case .skipped: .unknown
        }
    }
}

public struct TestResult: Codable, Hashable, Sendable {
    public var outcome: TestOutcome
    /// Shown on the card: "78 of 78 keys", "Right speaker silent".
    public var note: String?

    public init(_ outcome: TestOutcome, note: String? = nil) {
        self.outcome = outcome
        self.note = note
    }
}

/// One key of the keyboard test.
public struct Key: Hashable, Sendable {
    /// Virtual key code as `NSEvent.keyCode` reports it (the Carbon `kVK_*` values).
    public let code: UInt16
    public let label: String
    /// Width in key units (a letter key is 1).
    public let width: Double

    public init(_ code: UInt16, _ label: String, width: Double = 1) {
        self.code = code
        self.label = label
        self.width = width
    }
}

/// Built-in keyboard layouts the test draws. JIS is out of scope for v1.
/// Rows come from `KeyboardLayout.rows(touchBar:)` in TirekickCore/Keyboard.
public enum KeyboardLayout: String, Codable, CaseIterable, Sendable {
    case ansi, iso
}
