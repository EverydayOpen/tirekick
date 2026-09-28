import AppKit
import SwiftUI
import TirekickCore

/// The shareable card: the Report screen's preview and, through ImageRenderer, the PNG. Always light and flat, so
/// every shared PNG looks the same; pure fills only (ImageRenderer draws no AppKit-backed controls). Depth and
/// motion go around it in ReportView, never in here.
struct ReportCardView: View {
    let card: ReportCard

    var body: some View {
        let plate = RoundedRectangle(cornerRadius: 14, style: .continuous)
        VStack(alignment: .leading, spacing: Space.l) {
            VStack(alignment: .leading, spacing: Space.s) {
                HStack(spacing: Space.s) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .accessibilityHidden(true)
                    Text(card.title)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Rectangle().fill(Brand.hiVis).frame(height: 2).accessibilityHidden(true)
            }

            // The verdict on a plate, so it reads first even as a thumbnail.
            HStack(spacing: Space.s) {
                VerdictIcon(verdict: card.verdict, size: 34, showsWord: false).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(card.headline).font(.system(size: 30, weight: .bold)).tracking(-0.4)
                    if let summary = card.summary {
                        Text(summary).font(.title3).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(card.verdict.color.opacity(0.10), in: plate)
            .overlay(plate.strokeBorder(card.verdict.color.opacity(0.28), lineWidth: 1))

            VStack(alignment: .leading, spacing: Space.xs) {
                ForEach(Array(card.rows.enumerated()), id: \.offset) { _, row in
                    HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                        // minWidth, not width: a longer word pushes its own row instead of overlapping the text.
                        badge(row.verdict).frame(minWidth: 124, alignment: .leading)
                        Text(row.text).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Divider()

            Text(card.footer)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Space.xxl)
        .frame(width: 600, alignment: .leading)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }

    /// Strangers read this PNG, so each row carries the word as well as the symbol: a small-caps capsule
    /// (BUILD_PLAN §8). Colour sits in the symbol and the fill; the word stays primary.
    private func badge(_ verdict: Verdict) -> some View {
        HStack(spacing: Space.xxs) {
            Image(systemName: verdict.symbol).foregroundStyle(verdict.color)
            Text(verdict.word).textCase(.uppercase)
        }
        .font(.caption.weight(.bold))
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(verdict.color.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(verdict.word)
    }
}
