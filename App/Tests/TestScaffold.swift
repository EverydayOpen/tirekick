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
                        .font(.system(size: 18, weight: .medium))
                        .well(.secondary, size: 40)
                        .accessibilityHidden(true)
                    Text(test.title)
                        .font(.system(size: 28, weight: .semibold))
                        .tracking(-0.5)
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

/// Why the camera or microphone didn't start, on a porcelain surface; `pane` links to that Privacy & Security pane.
struct PermissionProblem: View {
    let text: String
    var pane: String?

    var body: some View {
        VStack(spacing: Space.m) {
            Text(text)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            // VERIFY: this System Settings deep link still opens the right pane on macOS 26 and 27.
            if let pane, let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
                Button("Open Privacy Settings") { NSWorkspace.shared.open(url) }
            }
        }
        .padding(Space.xl)
        .frame(maxWidth: 440)
        .surface(16)
    }
}

/// A key-cap's 5pt LED at its top right: lime once the key has done its job (a test run, a tone playing), dark
/// otherwise. Lime means "tested" or "on", never a verdict; the tag or the label says it in words, so it's hidden.
struct KeyLED: View {
    let lit: Bool

    var body: some View {
        Circle()
            .fill(lit ? Brand.hiVis : Color.primary.opacity(0.12))
            .overlay(Circle().strokeBorder(Color.black.opacity(lit ? 0.2 : 0), lineWidth: 0.5))   // holds its edge on white
            .frame(width: 5, height: 5)
            .offset(x: 4, y: -4)          // 12pt from the cap's corner: KeyCapStyle pads its label by Space.m
            .accessibilityHidden(true)
    }
}

extension View {
    /// Sets the part under test (keys, pad, meter, speaker keys) into the deck: a dark recess in dark mode, the
    /// quaternary fill in light, shaded along the top edge and lit along the lower lip. Pass the outer radius
    /// (inner + padding).
    func recessedPanel(cornerRadius: CGFloat = 14) -> some View {
        modifier(RecessedPanel(cornerRadius: cornerRadius))
    }

    /// A dark screen bezel with a lit top rim, lifted: the one object on the camera and display tests. The shadow is
    /// on the bezel, not on the content, so an AppKit preview inside still renders. `radius` is the outer one.
    func screenBezel(_ radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return padding(Space.xs)
            .background(
                shape.fill(Color(white: 0.08))
                    .overlay(shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                                                               startPoint: .top, endPoint: .bottom), lineWidth: 1))
                    .lifted()
            )
    }
}

private struct RecessedPanel: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let dark = scheme == .dark
        // ShapeStyle.shadow(.inner) is macOS 13 (VERIFY on CI).
        let fill = dark
            ? AnyShapeStyle(Color.black.opacity(0.25).shadow(.inner(color: .black.opacity(0.5), radius: 2, y: 1)))
            : AnyShapeStyle(HierarchicalShapeStyle.quaternary.shadow(.inner(color: .black.opacity(0.12), radius: 2, y: 1)))
        return content
            .background(shape.fill(fill))
            .overlay {
                if contrast == .increased {
                    shape.strokeBorder(Color.primary.opacity(0.4), lineWidth: 1)
                } else {
                    // A recess is shaded under its top edge and catches the light on its lower lip.
                    shape.strokeBorder(LinearGradient(colors: [Color.black.opacity(dark ? 0.35 : 0.08), Color.white.opacity(dark ? 0.06 : 0.7)],
                                                      startPoint: .top, endPoint: .bottom), lineWidth: 0.5)
                }
            }
    }
}
