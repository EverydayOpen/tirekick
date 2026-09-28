import AppKit
import SwiftUI
import TirekickCore

/// The shareable card: the Report screen's preview and, through ImageRenderer, the PNG. Always light, so every
/// shared PNG looks the same; pure SwiftUI only (ImageRenderer draws no AppKit-backed controls).
struct ReportCardView: View {
    let card: ReportCard

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            HStack(spacing: Space.s) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)
                Text(card.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                VerdictIcon(verdict: card.verdict, size: 30, showsWord: false)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(card.headline).font(.system(size: 30, weight: .bold))
                    if let summary = card.summary {
                        Text(summary)
                            .font(.title3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: Space.xs) {
                ForEach(Array(card.rows.enumerated()), id: \.offset) { _, row in
                    HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                        // Strangers read this PNG, so each row carries the word as well as the symbol.
                        HStack(spacing: Space.xxs) {
                            Image(systemName: row.verdict.symbol).foregroundStyle(row.verdict.color)
                            Text(row.verdict.word)
                                .font(.caption.weight(.bold))
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 124, alignment: .leading)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(row.verdict.word)
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
}
