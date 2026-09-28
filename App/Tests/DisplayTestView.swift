import AppKit
import SwiftUI
import TirekickCore

struct DisplayTestView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var fills = ScreenFills()

    var body: some View {
        TestScaffold(
            test: .display,
            instruction: "The screen fills with white, black, red, green, blue, gray and a checkerboard. On each, look for dead or stuck pixels, lines and uneven patches. Click or press any key for the next; Esc stops."
                + (model.isAllInOne == false ? " This Mac has no built-in screen: test the one that comes with it, or choose Skip." : "")
        ) {
            VStack(spacing: Space.m) {
                Button(fills.finished ? "Run Again" : "Start") { fills.start() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                if fills.finished {
                    Text("Did every fill look even, with no odd pixels?")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onDisappear { fills.stop() }
    }
}

/// A borderless window over the whole screen, above the menu bar and Dock, cycling solid fills.
/// VERIFY on a notched MacBook: the area beside the notch should fill too.
@MainActor final class ScreenFills: ObservableObject {
    /// True once a run has ended, so the question and "Run Again" show.
    @Published private(set) var finished = false
    private var window: NSWindow?
    private var monitor: Any?
    private var index = 0

    private static let colors: [NSColor] = [
        .white, .black, .red, .green, .blue, NSColor(white: 0.5, alpha: 1),
        NSColor(patternImage: NSImage(size: NSSize(width: 8, height: 8), flipped: false) { _ in
            NSColor.white.setFill()
            NSBezierPath.fill(NSRect(x: 0, y: 0, width: 8, height: 8))
            NSColor.black.setFill()
            NSBezierPath.fill(NSRect(x: 0, y: 0, width: 4, height: 4))
            NSBezierPath.fill(NSRect(x: 4, y: 4, width: 4, height: 4))
            return true
        }),
    ]

    /// On the screen with Tirekick's window, so moving the window picks the display to test.
    func start() {
        guard window == nil, let screen = NSScreen.main else { return }
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.level = .screenSaver
        window.isReleasedWhenClosed = false
        index = 0
        window.backgroundColor = Self.colors[0]
        window.orderFrontRegardless()
        self.window = window
        NSCursor.hide()
        // A borderless window can't become key, so keys still go to the main window; the monitor sees both.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown && event.keyCode == 53 { self.stop() } else { self.advance() }   // 53: Esc
            return nil
        }
    }

    func stop() {
        guard let window else { return }
        window.orderOut(nil)
        self.window = nil
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        NSCursor.unhide()
        finished = true
    }

    private func advance() {
        index += 1
        if index < Self.colors.count { window?.backgroundColor = Self.colors[index] } else { stop() }
    }
}
