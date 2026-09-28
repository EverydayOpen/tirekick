import AppKit
import SwiftUI

/// Welcome's laptop (MOTION.md §5.3, DESIGN.md §5.3), drawn with shapes and no assets: a graphite lid, an
/// aluminium deck and a lime-lit screen, standing on the bay's floor line. The lid opens once when it appears and
/// the laptop turns toward the pointer. With `scanning` the lid starts open and a lime beam sweeps the screen for as
/// long as the view exists (only while checks run). Still, and open, under Reduce Motion.
struct LaptopView: View {
    var scanning = false
    @State private var open: Bool
    @State private var sweep = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    init(scanning: Bool = false) {
        self.scanning = scanning
        _open = State(initialValue: scanning)
    }

    var body: some View {
        laptop
            .modifier(HoverTilt(max: scanning ? 0 : 8))
            .background(alignment: .bottom) { floor }
            .accessibilityHidden(true)
            .onAppear {
                if !open { withAnimation(reduceMotion ? nil : Motion.hero.delay(0.1)) { open = true } }
                sweep = scanning   // false → true after the first frame, so the scoped repeatForever below starts
            }
    }

    private var laptop: some View {
        let lid = RoundedRectangle(cornerRadius: 9, style: .continuous)
        return VStack(spacing: 0) {
            lid.fill(LinearGradient(colors: [Color(red: 0.165, green: 0.169, blue: 0.18), Color(red: 0.082, green: 0.086, blue: 0.094)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))     // graphite #2A2B2E → #151618
                .overlay(lid.strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))       // the bezel's lit edge
                .overlay(screen.padding(6))
                .frame(width: 150, height: 98)
                // VERIFY sign on a Mac: closed means the lid lies toward the viewer, edge-on.
                .rotation3DEffect(.degrees(open || reduceMotion ? 0 : -86), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.45)
            // The deck seen from the front: aluminium, a little wider than the lid, with the thumb notch.
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.85), Color(white: 0.56)], startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .top) { Capsule().fill(Color.black.opacity(0.2)).frame(width: 26, height: 2.5) }
                .frame(width: 178, height: 8)
        }
    }

    private var screen: some View {
        ZStack {
            RadialGradient(colors: [Color(red: 0.102, green: 0.141, blue: 0.063), .black], center: .center, startRadius: 0, endRadius: 80)   // #1A2410
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 46, height: 46)
                .shadow(color: Brand.hiVis.opacity(0.25), radius: 12)
                .opacity(open || reduceMotion ? 1 : 0)
                .animation(Motion.standard(reduceMotion).delay(0.45), value: open)
            if scanning && !reduceMotion {
                LinearGradient(colors: [.clear, Brand.hiVis.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 22)
                    .offset(y: sweep ? 50 : -50)
                    .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: sweep)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    /// The bay's floor, still while the laptop tilts: a lime spill, one lit horizon and a contact shadow, centred
    /// on the deck's lower edge.
    private var floor: some View {
        let dark = scheme == .dark
        return ZStack {
            Circle()
                .fill(RadialGradient(colors: [Brand.hiVis.opacity(dark ? 0.22 : 0.35), .clear], center: .center, startRadius: 0, endRadius: 170))
                .frame(width: 340, height: 340)
                .scaleEffect(x: 1, y: 0.16)
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Brand.hiVis.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 440, height: 1)
            Ellipse()
                .fill(Color.black.opacity(dark ? 0.6 : 0.3))
                .frame(width: 196, height: 7)
                .blur(radius: 4)
                .offset(y: 2)
        }
        .frame(height: 0)
        .allowsHitTesting(false)
    }
}
