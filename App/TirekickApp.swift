import AppKit
import SwiftUI

@main
struct TirekickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        Window("Tirekick", id: "main") {
            RootView()
                .environmentObject(model)
                .frame(width: 720, height: 560)
        }
        // The bay runs under the traffic lights and StepBar sits level with them (DESIGN.md §5.1). The window keeps
        // its "Tirekick" title for the Window menu, Mission Control and VoiceOver. VERIFY on a Mac: it still drags
        // from the top strip; if not, drop this line and RootView's ignoresSafeArea.
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            // No help book (its default item only says "Help isn't available"): the website instead.
            // Only .help is replaced; the Edit menu stays, so ⌘C and ⌘V keep working.
            CommandGroup(replacing: .help) {
                Button("Tirekick Help") { NSWorkspace.shared.open(Links.website) }
                Divider()
                // For beta testers: every command's output, serial masked, to send as a fixture.
                Button("Copy Raw Data") { model.copyRawData() }
            }
        }
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Before SwiftUI creates the window; didFinish would be too late to drop the Tab menu items.
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    /// One window, used once per purchase: closing it quits.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
