import AppKit
import SwiftUI
import TirekickCore

/// Every key press inside Tirekick lights its key. The local monitor swallows key events (⌘Q and Return included);
/// Tab, Space and Esc act normally once they've lit, so Esc (Skip) and Full Keyboard Access can leave the test.
/// Keys macOS keeps for itself get ticked by hand.
struct KeyboardTestView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pressed: Set<UInt16> = []
    @State private var ticked: Set<UInt16> = []
    @State private var down: Set<UInt16> = []
    @State private var monitor: Any?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let layoutRows = model.keyboardLayout.rows(touchBar: model.facts?.model?.touchBar ?? false)
        let codes = Set(layoutRows.joined().map(\.code))
        let byHand = codes.intersection(ticked).subtracting(pressed).count
        let note = "\(codes.intersection(pressed.union(ticked)).count) of \(codes.count) keys" + (byHand > 0 ? " (\(byHand) by hand)" : "")
        TestScaffold(
            test: .keyboard,
            instruction: "Press every key once; each lights up as it registers. If macOS uses a key itself (like brightness or Mission Control) and it stays dark, check that it works, then click it to tick it by hand. Pressing Esc a second time skips this test; choose Pass or Problem to keep the result."
                + (model.facts?.specs?.isLaptop == false ? " This Mac has no built-in keyboard: test the one that comes with it, or choose Skip." : ""),
            note: note
        ) {
            VStack(spacing: Space.m) {
                HStack {
                    Picker("Layout", selection: $model.keyboardLayout) {
                        Text("ANSI (US)").tag(KeyboardLayout.ansi)
                        Text("ISO (UK, Europe)").tag(KeyboardLayout.iso)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    Spacer()
                    Text(note)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                GeometryReader { geometry in
                    keyboard(layoutRows, in: geometry.size)
                }
            }
        }
        .onAppear(perform: startListening)
        .onDisappear(perform: stopListening)
    }

    /// The keys set into a recessed deck; the deck's corners follow the keys' (concentric).
    private func keyboard(_ rows: [[Key]], in size: CGSize) -> some View {
        let widest = CGFloat(rows.map { row in row.reduce(0) { $0 + $1.width } }.max() ?? 1)
        let inset = Space.xs
        let unit = max(0, min((size.width - 2 * inset) / widest, (size.height - 2 * inset) / CGFloat(max(rows.count, 1))))
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(rows[r].indices, id: \.self) { i in
                        keyView(rows[r][i], unit: unit)
                    }
                }
            }
        }
        .padding(inset)
        .recessedPanel(cornerRadius: unit * 0.15 + 2 + inset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Mini key-caps like a Mac's, graphite in both appearances (DESIGN.md §5.3): a face lit along its top rim over a
    /// side wall. A registered key's face turns lime with a 1pt lime rim: lime means "registered", never "passed".
    /// Ticked by hand is outlined, not lit, so it reads differently from a real press. A held key's face sinks onto
    /// its wall (MOTION.md §5.5); under Reduce Motion the dimmer held fill is the only cue.
    private func keyView(_ key: Key, unit: CGFloat) -> some View {
        let isPressed = pressed.contains(key.code)
        let isTicked = !isPressed && ticked.contains(key.code)
        let isHeld = down.contains(key.code)
        let sinks = isHeld && !reduceMotion
        let shape = RoundedRectangle(cornerRadius: unit * 0.15, style: .continuous)
        let wall = max(1.5, unit * 0.05)
        return Button {
            if isTicked { ticked.remove(key.code) } else if !isPressed { ticked.insert(key.code) }
        } label: {
            Text(key.label)
                .font(.system(size: max(9, unit * 0.24), weight: isPressed ? .semibold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(isPressed ? Color.black : isTicked ? Brand.hiVis : Color.white.opacity(0.85))
                .background {
                    ZStack {
                        shape.fill(LinearGradient(colors: [Self.capTop, Self.capBottom], startPoint: .top, endPoint: .bottom))
                        if isPressed {
                            shape.fill(Brand.hiVis)
                                .overlay(shape.fill(LinearGradient(colors: [.clear, Color.black.opacity(0.1)], startPoint: .top, endPoint: .bottom)))
                                .opacity(isHeld ? 0.7 : 1)
                        }
                    }
                }
                .overlay {
                    if isPressed || isTicked {
                        shape.strokeBorder(Brand.hiVis, lineWidth: isTicked ? 1.5 : 1)
                    } else {
                        shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.03)], startPoint: .top, endPoint: .bottom), lineWidth: 0.75)
                    }
                }
                .contentShape(shape)
                .offset(y: sinks ? wall - 0.5 : 0)
                .animation(Motion.pop, value: sinks)
                .background(shape.fill(Self.capWall).offset(y: wall))   // the key's side wall stays put; the face sinks onto it
        }
        .buttonStyle(.plain)
        .padding(2)
        .frame(width: CGFloat(key.width) * unit, height: unit)
        .accessibilityLabel(key.label)
        .accessibilityValue(isPressed ? "Pressed" : isTicked ? "Ticked by hand" : "Not pressed")
    }

    // DESIGN.md §5.2's dark key-cap: face #262622 → #1B1B18 on a #050504 wall.
    private static let capTop = Color(red: 0.149, green: 0.149, blue: 0.133)
    private static let capBottom = Color(red: 0.106, green: 0.106, blue: 0.094)
    private static let capWall = Color(red: 0.02, green: 0.02, blue: 0.016)

    private func startListening() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged, .systemDefined]) {
            handle($0)
        }
    }

    private func stopListening() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .keyDown:
            // Tab, Space, Esc: once lit, they act normally, so the test is no keyboard trap. A held Esc's repeats
            // are swallowed, so only a second press leaves (Skip).
            if [48, 49, 53].contains(event.keyCode) && pressed.contains(event.keyCode) {
                return event.keyCode == 53 && event.isARepeat ? nil : event
            }
            pressed.insert(event.keyCode)
            down.insert(event.keyCode)
        case .keyUp:
            down.remove(event.keyCode)
            // VERIFY: whether a focused button acts on Space's key up; passing it is harmless either way.
            if [48, 49, 53].contains(event.keyCode) { return event }
        case .flagsChanged:
            // A modifier (Shift, Control, Option, Command, Caps Lock, fn/Globe) reports its own key code.
            pressed.insert(event.keyCode)
        case .systemDefined:
            // Brightness and media keys arrive as NX aux-control events (subtype 8) when macOS passes them on
            // at all (VERIFY which do). They're never swallowed, so volume and brightness still work.
            if event.subtype.rawValue == 8, let code = Self.mediaKeys[(event.data1 & 0xFFFF_0000) >> 16] {
                pressed.insert(code)
            }
            return event
        default:
            return event
        }
        return nil
    }

    /// NX_KEYTYPE_* (IOKit ev_keymap.h) → the kVK_F* key it's printed on. The same on every Mac laptop keyboard
    /// since 2016 (VERIFY); F3–F6 differ between models, so they're left to a tick by hand.
    private static let mediaKeys: [Int: UInt16] = [
        3: 122,           // brightness down → F1
        2: 120,           // brightness up → F2
        20: 98, 18: 98,   // rewind, previous → F7
        16: 100,          // play → F8
        19: 101, 17: 101, // fast, next → F9
        7: 109,           // mute → F10
        1: 103,           // volume down → F11
        0: 111,           // volume up → F12
    ]
}
