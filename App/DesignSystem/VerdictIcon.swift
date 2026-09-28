import SwiftUI
import TirekickCore

/// The only view that draws a verdict. VoiceOver always hears the word; with Differentiate Without Color the word
/// is shown too, unless `showsWord` is off (check rows and tiles, where the symbols already differ in shape).
struct VerdictIcon: View {
    let verdict: Verdict
    var size: CGFloat = 16
    var showsWord = true
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate

    var body: some View {
        HStack(spacing: Space.xxs) {
            Image(systemName: verdict.symbol)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(verdict.color)
            if differentiate && showsWord {
                Text(verdict.word).font(.caption.weight(.semibold))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(verdict.word)
    }
}
