import SwiftUI
import TirekickCore

/// The only view that draws a verdict. VoiceOver always hears the word; with Differentiate Without Color the word
/// is shown too, unless `showsWord` is off (check rows and tiles, where the symbols already differ in shape).
/// `tile`: a System Settings tile, the white symbol on the verdict colour's gradient in a `size` squircle (the Checks
/// header). Plain fills, no shadow: severity never glows.
struct VerdictIcon: View {
    let verdict: Verdict
    var size: CGFloat = 16
    var showsWord = true
    var tile = false
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate

    var body: some View {
        HStack(spacing: Space.xxs) {
            if tile {
                let shape = RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                Image(systemName: verdict.symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: size, height: size)
                    .background(verdict.color.gradient, in: shape)
                    .overlay(shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center), lineWidth: 0.5))   // lit top edge
            } else {
                Image(systemName: verdict.symbol)
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(verdict.color)
            }
            if differentiate && showsWord {
                Text(verdict.word).font(.caption.weight(.semibold))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(verdict.word)
    }
}
