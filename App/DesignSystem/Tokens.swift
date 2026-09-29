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
/// beam, tested-key LEDs and registered keys.
enum Brand {
    /// Olive-black: the soft shadow under porcelain surfaces is tinted with it, not neutral grey (DESIGN.md §1.1 rule 3).
    static let ink = Color(red: 0.09, green: 0.10, blue: 0.04)
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

// MARK: - Surfaces (docs/DESIGN.md §3.1, §5.1, §5.2)

/// The bay behind every screen: warm graphite in dark, the plain window in light, plus one warm key light that sits
/// at a per-step point and moves only when the step changes (0.35 s, only `.position` animates). Static otherwise.
/// Increase Contrast gets the plain window background.
struct Bay: View {
    let step: AppModel.Step
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let dark = scheme == .dark
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            if contrast != .increased {
                if dark {
                    LinearGradient(colors: [Color(red: 0.075, green: 0.075, blue: 0.07), Bay.floor(true)], startPoint: .top, endPoint: .bottom)
                }
                GeometryReader { g in
                    RadialGradient(colors: [Color(red: 1, green: 0.94, blue: 0.82).opacity(dark ? 0.06 : 0.28), .clear],   // sodium white
                                   center: .center, startRadius: 0, endRadius: 360)
                        .frame(width: 720, height: 720)
                        .position(x: g.size.width * light.x, y: g.size.height * light.y)
                        .animation(reduceMotion ? nil : Animation.easeInOut(duration: 0.35), value: step)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var light: UnitPoint {
        switch step {
        case .welcome: UnitPoint(x: 0.5, y: 0.3)
        case .checks: UnitPoint(x: 0.2, y: 0.05)
        case .tests: UnitPoint(x: 0.5, y: 0)
        case .report: UnitPoint(x: 0.5, y: 0.55)
        }
    }

    /// The bottom of the bay; floatingBar fades to it. Light mode has no ramp (grey on grey), only the window.
    static func floor(_ dark: Bool) -> Color {
        dark ? Color(red: 0.04, green: 0.04, blue: 0.035) : Color(nsColor: .windowBackgroundColor)
    }
}

extension View {
    /// The floating bottom bar (RootView's and TestScaffold's): a `barSurface()` capsule on a fade to the bay's floor,
    /// so scrolled content never shows beneath or through it.
    func floatingBar() -> some View {
        modifier(FloatingBar())
    }

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

    /// Porcelain surface: white (a 5.5% white lift in dark), a hairline rim, a tight contact shadow plus a wide soft
    /// one tinted with the brand's ink. Concentric: pass the outer radius; content inside pads by radius - inner.
    /// Replaces grey grouped Form cells and `.quaternary` slabs. Never glass, never on a single row.
    func surface(_ radius: CGFloat = 16) -> some View { modifier(Surface(radius: radius)) }
}

private struct Surface: ViewModifier {
    let radius: CGFloat
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let dark = scheme == .dark, strong = contrast == .increased
        // The shadows hang off the fill, not the content: glyphs never cast their own (MOTION §1.4), and AppKit-backed
        // controls inside need no compositing group. White, not `.background`, which is the window's grey on macOS.
        // Dark's 5.5% fill casts almost nothing, so there the rim draws the edge (DESIGN.md §1.1 rule 3).
        return content
            .background {
                shape.fill(dark ? Color.white.opacity(0.055) : Color.white)
                    .shadow(color: .black.opacity(dark ? 0.35 : 0.05), radius: 1, y: 1)
                    .shadow(color: Brand.ink.opacity(dark ? 0.5 : 0.10), radius: 16, y: 8)
            }
            .overlay {
                shape.strokeBorder(strong ? Color.primary.opacity(0.5) : Color.primary.opacity(dark ? 0.10 : 0.07), lineWidth: strong ? 1 : 0.5)
                    .allowsHitTesting(false)
            }
    }
}

/// An object standing on a glossy floor: the view, its mirror fading out over 45% of its height, and a still
/// contact shadow at its base. Drawn once. Pass a stateless view: it is drawn twice. No mirror under Reduce
/// Transparency.
struct OnFloor<Content: View>: View {
    var height: CGFloat
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let mirror = reduceTransparency ? 0 : height * 0.45
        VStack(spacing: 2) {
            content
                .background(alignment: .bottom) {
                    Ellipse().fill(.black.opacity(0.16)).frame(width: height * 0.7, height: height * 0.08).blur(radius: 6)
                        .offset(y: height * 0.04)   // centred on the base line. VERIFY by eye under an app icon
                        .accessibilityHidden(true)
                }
            if !reduceTransparency {
                content
                    .scaleEffect(x: 1, y: -1)
                    .frame(height: mirror, alignment: .top).clipped()
                    .mask { LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom) }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        // Pinned: on CI the mirror collapsed to 0pt and the old negative padding pulled the next view over the laptop's base.
        .frame(height: height + 2 + mirror, alignment: .top)
    }
}

/// The key light under a lifted object: a pool of light and a thin bright line. Static; drawn once per size.
/// `soft`: Whydunit's dawn bloom. Tirekick passes false: a hard line with a tight spill. Decorative, hidden from
/// VoiceOver. The line runs through the middle of the view's height.
struct Horizon: View {
    var tint: Color
    var width: CGFloat = 420
    var soft = true
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            if contrast != .increased {
                // Elliptical, so the pool fades out inside its wide, short frame instead of being cut at the edges.
                EllipticalGradient(colors: [tint.opacity(soft ? 0.42 : 0.22), tint.opacity(soft ? 0.10 : 0), .clear],
                                   center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
            }
            LinearGradient(colors: [.clear, tint, .white.opacity(0.9), tint, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: width * 0.86, height: 1)
        }
        .frame(width: width, height: width * (soft ? 0.32 : 0.14))   // the same with or without the pool
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A small-caps label over a big number. One VoiceOver element. Whydunit passes .rounded, Tirekick .monospaced.
struct Metric: View {
    let label: String
    let value: String
    var unit: String? = nil
    var dot: Color? = nil
    var design: Font.Design = .rounded

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.weight(.semibold).smallCaps()).foregroundStyle(.secondary)   // VERIFY small caps with SF
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let dot { Circle().fill(dot).frame(width: 6, height: 6).accessibilityHidden(true) }
                Text(value).font(.system(size: 26, weight: .semibold, design: design)).monospacedDigit()
                if let unit { Text(unit).font(.callout.weight(.medium)).foregroundStyle(.secondary) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct FloatingBar: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        // Increase Contrast has no bay gradient, only the window background.
        let fadeTo = contrast == .increased ? Color(nsColor: .windowBackgroundColor) : Bay.floor(scheme == .dark)
        return content
            .padding(.vertical, Space.xs)
            .padding(.horizontal, Space.s)
            .barSurface()
            .padding([.horizontal, .bottom], Space.l)
            .background {
                // Starts a gap above the capsule and is opaque from its middle down, so nothing peeks out below it.
                LinearGradient(colors: [.clear, fadeTo, fadeTo], startPoint: .top, endPoint: .bottom)
                    .padding(.top, -Space.l)
                    .allowsHitTesting(false)
            }
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

/// Where you are, Mole-style: the four steps in one capsule on the controls layer, the current one an inverse
/// capsule (not lime: lime is the one prominent button). Not a control (Back and Continue move), so AppModel doesn't
/// change. VoiceOver: "Step 2 of 4: Checks".
struct StepBar: View {
    let current: AppModel.Step
    @Namespace private var lit
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        // Explicit, not Color.primary / windowBackgroundColor: semantic colours render vibrant over the glass track (1.5:1 on CI).
        let pill = dark ? Color(red: 0.957, green: 0.957, blue: 0.941) : Color(red: 0.106, green: 0.106, blue: 0.094)   // #F4F4F0 / #1B1B18
        let onPill = dark ? Color(red: 0.039, green: 0.039, blue: 0.035) : Color.white                                   // #0A0A09
        HStack(spacing: 2) {
            ForEach(AppModel.Step.allCases, id: \.self) { step in
                Text(title(step))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(step == current ? onPill : Color.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    // VERIFY on a Mac: the lit capsule slides between steps.
                    .background { if step == current { Capsule().fill(pill).matchedGeometryEffect(id: "lit", in: lit) } }
            }
        }
        .padding(3)
        // The glass is a sibling layer under the labels, so the inverse pill stays an opaque fill, not glass content.
        // VERIFY on the capture: pill near-white in dark, near-black in light.
        .background { Color.clear.barSurface() }
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
/// machined olive lip under it; a press sinks 1pt onto the lip. No glow: the light is hard. Replaces
/// .borderedProminent there; .keyboardShortcut(.defaultAction) still works.
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
                .background(shape.fill(Color(red: 0.36, green: 0.45, blue: 0.08)).offset(y: down ? 0.5 : 1.5))   // the lip; its bottom stays put
                .contentShape(shape)
                .opacity(enabled ? 1 : 0.4)
                .offset(y: down ? 1 : 0)
                .animation(Motion.pop, value: configuration.isPressed)
        }
    }
}

/// A real key-cap (Welcome choices, Tests tiles, the speaker keys, the ABM Copy key): a face lighter at the top with a
/// lit rim, on a side wall that shrinks from 3pt to 1pt as the face sinks 2pt. The rim turns lime under the pointer
/// and the cap turns toward it. Same tilt, press and bounce as MOTION §5.1's TileButtonStyle. TestScaffold's KeyLED
/// relies on the label being padded by `Space.m`.
struct KeyCapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Cap(configuration: configuration) }

    private struct Cap: View {
        let configuration: ButtonStyleConfiguration
        @State private var hovering = false
        @State private var hovers = 0
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.colorScheme) private var scheme
        @Environment(\.colorSchemeContrast) private var contrast

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
            let dark = scheme == .dark, down = configuration.isPressed && !reduceMotion
            let face = dark ? [Color(red: 0.149, green: 0.149, blue: 0.133), Color(red: 0.106, green: 0.106, blue: 0.094)]   // #262622 → #1B1B18
                            : [Color.white, Color(red: 0.945, green: 0.945, blue: 0.925)]                                        // #FFFFFF → #F1F1EC
            let wall = dark ? Color(red: 0.02, green: 0.02, blue: 0.016) : Color(red: 0.788, green: 0.788, blue: 0.753)          // #050504 / #C9C9C0
            configuration.label
                .frame(maxWidth: .infinity)
                .padding(Space.m)
                .background {
                    if contrast == .increased {
                        shape.fill(.quaternary).overlay(shape.strokeBorder(Color.primary, lineWidth: 1))
                    } else {
                        ZStack {
                            shape.fill(wall).offset(y: down ? 1 : 3)                                   // the side wall
                            shape.fill(LinearGradient(colors: face, startPoint: .top, endPoint: .bottom))
                                .overlay(shape.strokeBorder(Color.white.opacity(dark ? 0.14 : 0.9), lineWidth: 1)
                                    .mask { LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center) })   // the lit top rim
                                .overlay(shape.strokeBorder(hovering ? Brand.hiVis.opacity(0.6) : Color.primary.opacity(dark ? 0.08 : 0.12), lineWidth: hovering ? 1 : 0.5))
                                .shadow(color: .black.opacity(dark ? 0.5 : 0.10), radius: 8, y: 4)  // constant: never animated
                        }
                    }
                }
                .contentShape(shape)
                .offset(y: down ? 2 : 0)
                .animation(Motion.pop, value: configuration.isPressed)
                .bounce(on: hovers)                                   // Compat: symbol bounce on macOS 14+
                .modifier(HoverTilt(max: 7))
                .onHover {
                    hovering = $0                                     // a colour, not motion: shown under Reduce Motion too
                    if $0 && !reduceMotion { hovers += 1 }
                }
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
