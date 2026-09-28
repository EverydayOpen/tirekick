import AppKit
import SwiftUI
import TirekickCore

/// The studio stage: the card on a lit panel, dealt face down and turned over once per visit, then following the
/// pointer (MOTION §5.6). Every effect sits around ReportCardView, never inside it, so Save PNG stays flat.
struct ReportView: View {
    @EnvironmentObject private var model: AppModel
    @State private var dealt = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    // Mask serial, Copy and the Save buttons are in RootView's bottom bar.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.l) {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text("Report card").font(.system(size: 26, weight: .bold))
                    Text(model.mode == .buying
                         ? "Save the picture for your records or to show the seller. The PDF adds every command's output."
                         : "Share the picture with a listing. The PDF adds every command's output.")
                        .foregroundStyle(.secondary)
                }

                if let card = model.card { stage(card) }

                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("What Tirekick can't tell you").font(.headline)
                    ForEach(ReportText.cantTell, id: \.self) { item in
                        Label {
                            Text(item).fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "questionmark.circle").foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.callout)
            }
            .padding(Space.xxl)
        }
        .background { keyLight }
    }

    private func stage(_ card: ReportCard) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        let panel = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let dark = scheme == .dark
        return ReportCardView(card: card)   // the PNG itself (Export renders it): effects go around it, never inside
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.black.opacity(0.1), lineWidth: 0.5))   // the card is always white
            .modifier(HoverTilt(max: 4, glare: true))
            .modifier(FlipFaces(angle: dealt || reduceMotion ? 0 : 180, back: CardBack().clipShape(shape)))
            .scrollLean(reduceMotion)       // Compat: macOS 14+
            .lifted()
            .background(alignment: .bottom) {
                // Where the card meets the panel. Static: it doesn't tilt or turn with the card.
                Ellipse().fill(Color.black.opacity(0.5)).frame(width: 520, height: 24).blur(radius: 10).offset(y: 10)
            }
            .onAppear { withAnimation(Motion.spring(reduceMotion).delay(0.1)) { dealt = true } }
            .frame(maxWidth: .infinity)
            .padding(.top, Space.xxl)
            .padding(.bottom, Space.xxl)
            // Light: darker than the bay, so the white card is the brightest thing on screen.
            .background(panel.fill(LinearGradient(colors: dark ? [Color(white: 0.17), Color(white: 0.10)]
                                                               : [Color(white: 0.90), Color(white: 0.84)],
                                                  startPoint: .top, endPoint: .bottom)))
            .overlay(panel.strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5))
    }

    /// Bay with a brighter key light over the stage. Increase Contrast keeps Bay's plain window background.
    private var keyLight: some View {
        Bay().overlay {
            if contrast != .increased {
                RadialGradient(colors: [Color.white.opacity(scheme == .dark ? 0.06 : 0.4), .clear],
                               center: .top, startRadius: 0, endRadius: 360)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// The card's back, seen only while it turns over: white, with the app icon. No text, so nothing to read or miss.
private struct CardBack: View {
    var body: some View {
        Color.white.overlay { Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 72, height: 72) }
    }
}
