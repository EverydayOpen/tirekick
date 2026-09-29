import AppKit
import SwiftUI
import TirekickCore

/// The report card on the bay: the top sheet of a small paper stack, standing on the lime laser (DESIGN.md §5.3).
/// Dealt face down and turned over once per visit, then it follows the pointer (MOTION §5.6). Every effect sits
/// around ReportCardView, never inside it, so Save PNG stays flat. RootView paints the bay and its key light.
struct ReportView: View {
    @EnvironmentObject private var model: AppModel
    @State private var dealt = false
    @State private var cardHeight: CGFloat = 0
    private let previewScale: CGFloat = 0.78
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Mask serial, Copy and the Save buttons are in RootView's bottom bar.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xl) {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text("Report card").font(.system(size: 28, weight: .semibold)).tracking(-0.5)
                    Text(model.mode == .buying
                         ? "Save the picture for your records or to show the seller. The PDF adds every command's output."
                         : "Share the picture with a listing. The PDF adds every command's output.")
                        .foregroundStyle(.secondary)
                }

                if let card = model.card { stage(card) }

                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("What Tirekick can't tell you")
                        .font(.system(size: 12, weight: .semibold).smallCaps())
                        .tracking(0.5)
                        .foregroundStyle(.secondary)
                        .padding(.leading, Space.m)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(ReportText.cantTell.enumerated()), id: \.offset) { i, item in
                            if i > 0 { Divider().padding(.leading, 40) }
                            Label {
                                Text(item).fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: "questionmark.circle").foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, Space.m)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .font(.callout)
                    .surface(16)
                }
            }
            .padding(Space.xxl)
        }
    }

    private func stage(_ card: ReportCard) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return ReportCardView(card: card)   // the PNG itself (Export renders it): effects go around it, never inside
            .background { GeometryReader { g in Color.clear.onAppear { cardHeight = g.size.height }.onChange(of: g.size.height) { cardHeight = $0 } } }
            // Scaled to fit above the bottom bar, so the sheets and the laser show. VERIFY text crispness at 0.78.
            .scaleEffect(previewScale, anchor: .top)
            .frame(width: 560 * previewScale, height: cardHeight > 0 ? cardHeight * previewScale : nil, alignment: .top)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.black.opacity(0.1), lineWidth: 0.5))   // paper's edge: white in every scheme
            .background(alignment: .bottom) {
                // Two sheets under it: thickness. Paper in every scheme, like the card.
                ZStack {
                    shape.fill(Color(white: 0.86)).overlay(shape.strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5))
                        .padding(.horizontal, 10).offset(y: 6)
                    shape.fill(Color(white: 0.93)).overlay(shape.strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5))
                        .padding(.horizontal, 5).offset(y: 3)
                }
                .accessibilityHidden(true)
            }
            .modifier(HoverTilt(max: 4, glare: true))
            .modifier(FlipFaces(angle: dealt || reduceMotion ? 0 : 180, back: CardBack().clipShape(shape)))
            .scrollLean(reduceMotion)       // Compat: macOS 14+
            .lifted()
            .background(alignment: .bottom) {
                // The laser the stack stands on: Horizon's line (its vertical centre) 4pt under the bottom sheet.
                // Outside the tilt and the turn, so the light stays put. VERIFY by eye on a Mac.
                Horizon(tint: Brand.hiVis, width: 520, soft: false)
                    .alignmentGuide(.bottom) { $0.height / 2 }
                    .offset(y: 10)
            }
            .onAppear { withAnimation(Motion.spring(reduceMotion).delay(0.1)) { dealt = true } }
            .frame(maxWidth: .infinity)
            .padding(.top, Space.xs)
            .padding(.bottom, Space.xxl)
    }
}

/// The card's back, seen only while it turns over: white, with the app icon. No text, so nothing to read or miss.
private struct CardBack: View {
    var body: some View {
        Color.white.overlay { Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 72, height: 72) }
    }
}
