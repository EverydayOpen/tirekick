import AppKit
import SwiftUI
import TirekickCore

/// Title, instruction, the test itself, then Skip / Problem / Pass. None is prominent or the default, so a stray
/// Return can't pass a test; Esc skips. Still (DESIGN.md §5.3): the feedback is the hardware. RootView paints the bay.
struct TestScaffold<Content: View>: View {
    let test: HardwareTest
    let instruction: String
    /// Recorded with Pass and Problem, and shown on the card: "78 of 78 keys".
    var note: String?
    @ViewBuilder let content: Content
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Space.s) {
                // The tile's well, so the test reads as the key you just pressed.
                HStack(spacing: Space.s) {
                    Image(systemName: test.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Brand.hiVisInk)
                        .well(.secondary, size: 36)
                        .accessibilityHidden(true)
                    Text(test.title)
                        .font(.system(size: 22, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                }
                Text(instruction)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.horizontal, .top], Space.xxl)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, Space.xxl)
                .padding(.vertical, Space.l)

            // The main bottom bar (DESIGN.md §5.1), without a hi-vis button.
            HStack {
                Button("Skip") { model.finish(test, TestResult(.skipped)) }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Problem") { model.finish(test, TestResult(.problem, note: note)) }
                Button("Pass") { model.finish(test, TestResult(.passed, note: note)) }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .floatingBar()
        }
    }
}

/// Why the camera or microphone didn't start; `pane` links to that Privacy & Security pane.
struct PermissionProblem: View {
    let text: String
    var pane: String?

    var body: some View {
        VStack(spacing: Space.m) {
            Text(text)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 440)
            // VERIFY: this System Settings deep link still opens the right pane on macOS 26 and 27.
            if let pane, let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
                Button("Open Privacy Settings") { NSWorkspace.shared.open(url) }
            }
        }
    }
}

extension View {
    /// Sets the part under test (keys, pad, meter, speaker buttons) into the deck, like the Welcome tip's note well
    /// (DESIGN.md §5.3): a dark recess in dark mode, the quaternary fill in light, shaded along the top edge.
    func recessedPanel(cornerRadius: CGFloat = 14) -> some View {
        modifier(RecessedPanel(cornerRadius: cornerRadius))
    }
}

private struct RecessedPanel: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        // ShapeStyle.shadow(.inner) is macOS 13 (VERIFY on CI).
        let fill = scheme == .dark
            ? AnyShapeStyle(Color.black.opacity(0.25).shadow(.inner(color: .black.opacity(0.5), radius: 2, y: 1)))
            : AnyShapeStyle(HierarchicalShapeStyle.quaternary.shadow(.inner(color: .black.opacity(0.12), radius: 2, y: 1)))
        return content
            .background(shape.fill(fill))
            .overlay { if contrast == .increased { shape.strokeBorder(Color.primary.opacity(0.4), lineWidth: 1) } }
    }
}
