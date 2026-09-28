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

/// docs/MOTION.md §1.2, spelled for macOS 13: the duration-and-bounce springs are macOS 14, these are the same curves.
enum Motion {
    /// `.smooth` is macOS 14. Under Reduce Motion callers also drop movement and keep only the fade.
    static func standard(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.15) : .easeInOut(duration: 0.28)
    }
    /// Surfaces: flips, deal-ins, a tilt settling back.
    static func spring(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.15) : .spring(response: 0.45, dampingFraction: 0.78)
    }
    static let hero = Animation.spring(response: 0.9, dampingFraction: 0.8)
    static let pop = Animation.spring(response: 0.32, dampingFraction: 0.62)
    static let follow = Animation.interactiveSpring(response: 0.25, dampingFraction: 0.86)
}

/// docs/DESIGN.md §5.2. The app keeps the user's accent for controls; lime is only the one prominent button, the
/// beam, the lit step and registered keys.
enum Brand {
    /// Hi-vis lime, always with black text on it.
    static let hiVis = Color(red: 0.776, green: 0.949, blue: 0.235)                        // #C6F23C
    /// Lime text is unreadable on white, so lime-coloured symbols and text use this (olive in light mode).
    static let hiVisInk = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.804, green: 0.961, blue: 0.290, alpha: 1)                  // #CDF54A
            : NSColor(srgbRed: 0.247, green: 0.384, blue: 0.071, alpha: 1)                  // #3F6212, about 7:1 on white
    })
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

// MARK: - Surfaces (docs/DESIGN.md §3.1, §5.2)

/// The bay: warm graphite with an overhead key light (dark), a daylight workshop (light). Static, drawn once.
/// RootView paints it behind every screen. Increase Contrast gets the plain window background.
struct Bay: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let dark = scheme == .dark
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            if contrast != .increased {
                LinearGradient(colors: dark ? [Color(red: 0.075, green: 0.075, blue: 0.07), Color(red: 0.04, green: 0.04, blue: 0.035)]
                                            : [Color(white: 0.97), Color(white: 0.91)],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Color.white.opacity(dark ? 0.07 : 0.6), .clear], center: .top, startRadius: 0, endRadius: 420)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// A symbol in a recessed, tinted squircle: the site's icon well. Pure fills, so ImageRenderer-safe.
    func well(_ tint: Color, size: CGFloat = 44) -> some View {
        modifier(Well(tint: tint, size: size))
    }

    /// A raised object (the laptop, the report card; never a row): a tight contact shadow plus a wide soft one.
    /// compositingGroup so glyphs don't cast their own shadows (MOTION.md §1.4).
    func lifted() -> some View {
        compositingGroup()
            .shadow(color: .black.opacity(0.10), radius: 1.5, y: 1)
            .shadow(color: .black.opacity(0.20), radius: 24, y: 14)
    }

    /// Commands and their output: a recessed terminal well. The text stays primary and selectable.
    func terminal() -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        return background(Color.primary.opacity(0.04), in: shape)
            .overlay(shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
    }
}

/// Increase Contrast draws a 1pt primary edge (DESIGN.md §3.2).
private struct Well: ViewModifier {
    let tint: Color
    let size: CGFloat
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        let increased = contrast == .increased
        return content
            .frame(width: size, height: size)
            // The inner shadow is what makes it read as recessed (ShapeStyle.shadow is macOS 13).
            .background(shape.fill(tint.opacity(0.16).gradient.shadow(.inner(color: .black.opacity(0.22), radius: 1.5, y: 1))))
            .overlay(shape.strokeBorder(increased ? Color.primary : tint.opacity(0.24), lineWidth: increased ? 1 : 0.5))
    }
}

/// A count or a word in a tinted capsule. Colour sits in the dot and the fill; the text stays primary, so it always
/// has full contrast ("only symbols carry colour"). Increase Contrast adds a stroke.
struct Tag: View {
    let text: String
    var tint: Color = .secondary
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(tint).frame(width: 6, height: 6).accessibilityHidden(true)
            Text(text).font(.caption.weight(.semibold)).monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tint.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(contrast == .increased ? Color.primary.opacity(0.4) : tint.opacity(0.3), lineWidth: contrast == .increased ? 1 : 0.5))
    }
}

/// Where you are, Mole-style: the four steps in one capsule, the current one lit. Not a control (Back and Continue
/// move), so AppModel doesn't change. VoiceOver: "Step 2 of 4: Checks".
struct StepBar: View {
    let current: AppModel.Step
    @Namespace private var lit
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppModel.Step.allCases, id: \.self) { step in
                Text(title(step))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(step == current ? Color.black : Color.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    // VERIFY on a Mac: the lit capsule slides between steps.
                    .background { if step == current { Capsule().fill(Brand.hiVis).matchedGeometryEffect(id: "lit", in: lit) } }
            }
        }
        .padding(3)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
        .animation(reduceMotion ? nil : Motion.spring(false), value: current)
        .allowsHitTesting(false)                                   // drags pass through to the window
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current.rawValue + 1) of \(AppModel.Step.allCases.count): \(title(current))")
    }

    private func title(_ step: AppModel.Step) -> String {
        switch step {
        case .welcome: "Start"
        case .checks: "Checks"
        case .tests: "Tests"
        case .report: "Report"
        }
    }
}

// MARK: - Buttons

/// The one prominent button per screen (Continue, Save PNG…): hi-vis fill, black label, a lit top edge and a
/// machined lower edge. Replaces .borderedProminent there; .keyboardShortcut(.defaultAction) still works.
struct HiVisButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Plate(configuration: configuration) }

    // Not `Body`: that's ButtonStyle's associated type.
    private struct Plate: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var enabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
            let down = configuration.isPressed && !reduceMotion
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 18)
                .frame(minHeight: 30)
                .background(shape.fill(Brand.hiVis).overlay(shape.fill(LinearGradient(colors: [.clear, Color.black.opacity(0.12)], startPoint: .top, endPoint: .bottom))))
                .overlay(shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.55), Color.black.opacity(0.25)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
                .contentShape(shape)
                .compositingGroup()
                .shadow(color: Brand.hiVis.opacity(0.3), radius: 10, y: 3)   // static glow; only the plate moves
                .opacity(enabled ? 1 : 0.4)
                .offset(y: down ? 1 : 0)
                .scaleEffect(down ? 0.97 : 1)
                .animation(Motion.pop, value: configuration.isPressed)
        }
    }
}

/// Welcome choices and Tests tiles: a key-cap. Raised fill, lit top edge, hairline; sinks 1pt when pressed and
/// turns toward the pointer. Replaces MOTION §5.1's TileButtonStyle with the same tilt, press and bounce.
struct KeyCapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Cap(configuration: configuration) }

    private struct Cap: View {
        let configuration: ButtonStyleConfiguration
        @State private var hovers = 0
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.colorScheme) private var scheme
        @Environment(\.colorSchemeContrast) private var contrast

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
            let down = configuration.isPressed && !reduceMotion
            let dark = scheme == .dark
            configuration.label
                .frame(maxWidth: .infinity)
                .padding(Space.m)
                .background {
                    if contrast == .increased {
                        shape.fill(.quaternary)
                    } else {
                        shape.fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(shape.fill(LinearGradient(colors: [Color.white.opacity(dark ? 0.08 : 0), Color.black.opacity(dark ? 0 : 0.035)], startPoint: .top, endPoint: .bottom)))
                            .overlay(shape.strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5))
                            .shadow(color: .black.opacity(dark ? 0.6 : 0.12), radius: 0, y: down ? 0 : 2)   // the key's side
                            .shadow(color: .black.opacity(dark ? 0.4 : 0.08), radius: 8, y: 4)
                    }
                }
                .contentShape(shape)
                .offset(y: down ? 1 : 0)
                .scaleEffect(down ? 0.985 : 1)
                .animation(Motion.pop, value: configuration.isPressed)
                .bounce(on: hovers)                                   // Compat: symbol bounce on macOS 14+
                .modifier(HoverTilt(max: 7))
                .onHover { if $0 && !reduceMotion { hovers += 1 } }
        }
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

// MARK: - Motion (docs/MOTION.md §1.8, §5.1)

/// Turns a surface to face the pointer (the edge under it recedes), at most `max` degrees, with an optional glare
/// masked to the content's own shape. Flat under Reduce Motion or with `max: 0`. The pointer is read in the layout
/// frame, so the tilt never moves hit areas.
struct HoverTilt: ViewModifier {
    var max = 7.0
    var glare = false
    @State private var size = CGSize.zero
    @State private var p = CGPoint.zero          // -1...1 from the center
    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if glare && hovering {
                    RadialGradient(colors: [Color.white.opacity(0.28), .clear], center: .center,
                                   startRadius: 0, endRadius: size.width * 0.6)
                        .offset(x: p.x * size.width / 2, y: p.y * size.height / 2)
                        .mask { content }            // VERIFY: content drawn twice; fine for an icon and one card
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            // VERIFY on a Mac: the edge under the pointer should recede; negate both angles if it rises instead.
            .rotation3DEffect(.degrees(-p.y * max), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(p.x * max), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .background {
                GeometryReader { g in
                    Color.clear.onAppear { size = g.size }.onChange(of: g.size) { size = $0 }
                }
            }
            .onContinuousHover { phase in
                guard !reduceMotion, max > 0, size.width > 0, size.height > 0 else { return }
                switch phase {
                case .active(let at):
                    withAnimation(Motion.follow) {
                        hovering = true
                        p = CGPoint(x: at.x / size.width * 2 - 1, y: at.y / size.height * 2 - 1)
                    }
                case .ended:
                    withAnimation(Motion.spring(false)) {
                        hovering = false
                        p = .zero
                    }
                }
            }
    }
}

extension AnyTransition {
    /// Check rows and the verdict: turns down into place from the top edge like a split-flap card, and leaves by
    /// fading, so old and new never overlap mid-turn. Opacity only under Reduce Motion.
    static func flip(_ reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .modifier(active: FlipDown(angle: 70, opacity: 0), identity: FlipDown(angle: 0, opacity: 1)),
            removal: .opacity)
    }
}

private struct FlipDown: ViewModifier {
    let angle: Double
    let opacity: Double

    func body(content: Content) -> some View {
        content   // VERIFY sign on a Mac: the bottom edge should start toward the viewer
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.6)
            .opacity(opacity)
    }
}

/// Shows the content until the turn passes 90°, then `back`: a card turning over. `angle` animates.
struct FlipFaces<Back: View>: ViewModifier, Animatable {
    var angle: Double
    let back: Back
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        content
            .opacity(angle < 90 ? 1 : 0)
            .overlay {
                back.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(angle < 90 ? 0 : 1)
                    .accessibilityHidden(true)
            }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}
