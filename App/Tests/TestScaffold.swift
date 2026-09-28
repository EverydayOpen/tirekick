import AppKit
import SwiftUI
import TirekickCore

/// Title, instruction, the test itself, then Skip / Problem / Pass. None is prominent or the default, so a stray
/// Return can't pass a test; Esc skips.
struct TestScaffold<Content: View>: View {
    let test: HardwareTest
    let instruction: String
    /// Recorded with Pass and Problem, and shown on the card: "78 of 78 keys".
    var note: String?
    @ViewBuilder let content: Content
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(test.title).font(.title2.weight(.semibold))
                Text(instruction)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .top], Space.xxl)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, Space.xxl)
                .padding(.vertical, Space.l)

            Divider()
            HStack {
                Button("Skip") { model.finish(test, TestResult(.skipped)) }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Problem") { model.finish(test, TestResult(.problem, note: note)) }
                Button("Pass") { model.finish(test, TestResult(.passed, note: note)) }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(Space.l)
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
