import AppKit
import SwiftUI
import TirekickCore

/// Spacing in points (Whydunit UI_SPEC §2.1). `xxl` is the screen padding, `l` the bottom bar's.
enum Space {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

enum Radius {
    static let card: CGFloat = 12
}

enum Motion {
    /// `.smooth` is macOS 14. Under Reduce Motion callers also drop movement and keep only the fade.
    static func standard(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.15) : .easeInOut(duration: 0.28)
    }
}

extension Verdict {
    var color: Color {
        switch self {
        case .unknown: .secondary
        case .clean: .green
        case .check: .orange
        case .walkAway: .red
        }
    }

    var symbol: String {
        switch self {
        case .unknown: "questionmark.circle"
        case .clean: "checkmark.circle.fill"
        case .check: "exclamationmark.triangle.fill"
        case .walkAway: "xmark.octagon.fill"
        }
    }
}

extension HardwareTest {
    /// VERIFY each in the SF Symbols app (Info › Availability: macOS 13 or earlier).
    var symbol: String {
        switch self {
        case .keyboard: "keyboard"
        case .display: "display"
        case .speakers: "speaker.wave.2"
        case .microphone: "mic"
        case .camera: "camera"
        case .trackpad: "rectangle.and.hand.point.up.left"
        }
    }
}

extension TestOutcome {
    var word: String {
        switch self {
        case .passed: "Passed"
        case .problem: "Problem"
        case .skipped: "Skipped"
        }
    }
}

/// The Welcome choices and the Tests tiles: a plain rounded fill that darkens while pressed.
struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        return configuration.label
            .frame(maxWidth: .infinity)
            .padding(Space.m)
            .background(shape.fill(configuration.isPressed ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.quaternary)))
            .contentShape(shape)
    }
}

/// Copying has no visible effect, so the title reads "Copied" for a moment.
struct CopyButton: View {
    var title = "Copy"
    let action: () -> Void
    @State private var copied = false

    var body: some View {
        Button(copied ? "Copied" : title) {
            action()
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                copied = false
            }
        }
    }
}

@MainActor func copyToPasteboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}
