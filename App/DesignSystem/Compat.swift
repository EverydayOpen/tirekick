import SwiftUI

// The only file with `if #available` (BUILD_PLAN §10). On macOS 13 each helper does nothing or draws the pre-26
// look, which is the full design.
extension View {
    /// Liquid Glass on macOS 26; a material with a hairline before. Floating bars and the StepBar only, never content.
    /// Materials and glass handle Reduce Transparency themselves.
    @ViewBuilder func barSurface() -> some View {
        if #available(macOS 26, *) {
            glassEffect(.regular, in: Capsule())   // VERIFY by eye on the CI capture (signature checked in Apple's docs)
        } else {
            // The shadow hangs off the capsule, not the labels, so glyphs cast none (MOTION §1.4).
            background { Capsule().fill(.regularMaterial).shadow(color: .black.opacity(0.14), radius: 18, y: 8) }
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5).allowsHitTesting(false))
        }
    }

    /// A capsule `.bordered` button (DESIGN.md §5.3 "Check Again"). `ButtonBorderShape.capsule` is macOS 14; macOS 13
    /// keeps the system's rounded rectangle.
    @ViewBuilder func capsuleBorder() -> some View {
        if #available(macOS 14, *) {
            buttonBorderShape(.capsule)
        } else {
            self
        }
    }

    /// Bounces the SF Symbols inside once each time `value` changes (macOS 14 symbol effects).
    @ViewBuilder func bounce(on value: some Equatable) -> some View {
        if #available(macOS 14, *) {
            symbolEffect(.bounce, value: value)
        } else {
            self
        }
    }

    /// Leans a surface back, at most 8°, as it scrolls up and away (macOS 14 `visualEffect`).
    @ViewBuilder func scrollLean(_ reduceMotion: Bool) -> some View {
        if #available(macOS 14, *) {
            visualEffect { content, proxy in
                // VERIFY: the .scrollView coordinate space and rotation3DEffect on VisualEffect, macOS 14.
                let past = reduceMotion ? 0 : min(max(-proxy.frame(in: .scrollView).minY / 40, 0), 8)
                return content.rotation3DEffect(.degrees(past), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.4)
            }
        } else {
            self
        }
    }
}
