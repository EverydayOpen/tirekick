import AppKit
import SwiftUI
import TirekickCore

enum TrackpadMove: CaseIterable {
    case click, forceClick, scroll

    var title: String {
        switch self {
        case .click: "Click"
        case .forceClick: "Force click"
        case .scroll: "Two-finger scroll"
        }
    }
}

struct TrackpadTestView: View {
    @EnvironmentObject private var model: AppModel
    @State private var seen: Set<TrackpadMove> = []

    var body: some View {
        TestScaffold(
            test: .trackpad,
            instruction: "In the box, click, then press harder until you feel a second click (force click), then scroll with two fingers. Try the corners too."
                + (model.facts?.specs?.isLaptop == false ? " No trackpad? Choose Skip." : "")
        ) {
            VStack(spacing: Space.m) {
                TrackpadArea { move in
                    withAnimation { _ = seen.insert(move) }
                }
                .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(.quaternary))
                .overlay(Text("Try it here").foregroundStyle(.secondary).allowsHitTesting(false))
                .accessibilityLabel("Trackpad test area")

                HStack(spacing: Space.xl) {
                    ForEach(TrackpadMove.allCases, id: \.self) { move in
                        let done = seen.contains(move)
                        Label {
                            Text(move.title)
                        } icon: {
                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(done ? Color.green : Color.secondary)
                        }
                        .accessibilityValue(done ? "Done" : "Not yet")
                    }
                }
            }
        }
    }
}

/// An AppKit view, because SwiftUI has no force-click (pressure stage) or precise-scroll events on macOS 13.
private struct TrackpadArea: NSViewRepresentable {
    let onMove: (TrackpadMove) -> Void

    func makeNSView(context: Context) -> PadView { PadView() }

    func updateNSView(_ view: PadView, context: Context) { view.onMove = onMove }

    final class PadView: NSView {
        var onMove: ((TrackpadMove) -> Void)?

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override func mouseDown(with event: NSEvent) { onMove?(.click) }
        override func pressureChange(with event: NSEvent) {
            if event.stage == 2 { onMove?(.forceClick) }
        }
        /// Precise deltas come from a trackpad (or Magic Mouse), not a scroll wheel.
        override func scrollWheel(with event: NSEvent) {
            if event.hasPreciseScrollingDeltas { onMove?(.scroll) }
        }
    }
}
