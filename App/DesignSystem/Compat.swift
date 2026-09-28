import SwiftUI

// The only file with `if #available` (BUILD_PLAN §10). Each helper does nothing on macOS 13, which is the full design.
extension View {
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
