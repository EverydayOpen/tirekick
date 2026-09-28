import SwiftUI
import TirekickCore

/// The company-assignment check needs admin rights and the internet, so the user runs it in Terminal and pastes
/// the output back. Tirekick itself never runs it and never sees the password (BUILD_PLAN §3).
struct ABMHandoffView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(model.mode == .buying
                 ? "1. Copy this command and paste it into Terminal, then press Return. It needs the internet and an administrator password: the seller's, or the one for the account made during setup (Terminal doesn't show it). Run it from a local account you created yourself. That lowers the risk that the seller set Terminal up to print a fake answer, but doesn't remove it: some Terminal settings apply to every account."
                 : "1. Copy this command and paste it into Terminal, then press Return. It needs the internet and your admin password (Terminal doesn't show it).")
            Text(Command.abmHandoff)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .padding(Space.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .terminal()
            Text("2. When it finishes, select everything it printed and press ⌘C.")
            Text("If a notification asks to enroll this Mac in device management, don't. It means an organization owns this Mac.")
            Text("3. Come back here and choose Paste Result or press ⌘V.")
            HStack(spacing: Space.xs) {
                CopyButton(title: "Copy Command") { model.copyABMCommand() }
                Button("Open Terminal") { model.openTerminal() }
                // No text field has focus here, so Edit › Paste is disabled and ⌘V would only beep.
                Button("Paste Result") { model.pasteABMResult() }
                    .keyboardShortcut("v", modifiers: .command)
            }
            .buttonStyle(.bordered)
            if model.pasteRejected {
                Text(Parsers.unrecognizedPaste).foregroundStyle(.secondary)
            }
        }
        .font(.callout)
        .fixedSize(horizontal: false, vertical: true)
    }
}
