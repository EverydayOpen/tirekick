import AppKit
import SwiftUI
import TirekickCore

/// The shareable card: the Report screen's preview and, through ImageRenderer, the PNG. Paper in every scheme and
/// flat: pure fills only, no materials, blur, shadows or AppKit-backed controls, so every shared PNG looks the same.
/// Depth and motion go around it in ReportView, never in here (DESIGN.md §5.3).
struct ReportCardView: View {
    let card: ReportCard

    var body: some View {
        // Core joins both with " · ": "Tirekick report · <model line>" and "<date> · <serial> · <trust line>".
        let title = card.title.components(separatedBy: " · ")
        let footer = card.footer.components(separatedBy: " · ")
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Space.s) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title[0]).font(.system(size: 15, weight: .semibold)).tracking(-0.2)
                    if title.count > 1 {
                        Text(title.dropFirst().joined(separator: " · "))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Paper.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // The one brand mark on paper.
            Rectangle().fill(Brand.hiVis).frame(height: 2).padding(.top, Space.m).accessibilityHidden(true)

            // The verdict in ink, no coloured panel: colour stays in the symbol, so it reads first even as a thumbnail.
            HStack(spacing: Space.s) {
                VerdictIcon(verdict: card.verdict, size: 30, showsWord: false).accessibilityHidden(true)
                Text(card.headline)
                    .font(.system(size: 34, weight: .heavy).width(.expanded))
                    .tracking(-0.6)
                    .fixedSize(horizontal: false, vertical: true)   // "Couldn't check everything" takes two lines
            }
            .padding(.top, Space.xl)
            if let summary = card.summary {
                Text(summary)
                    .font(.system(size: 15))
                    .foregroundStyle(Paper.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.xs)
            }

            // The readout table: check · result, on paper hairlines.
            HStack {
                label("Check")
                Spacer()
                label("Result")
            }
            .padding(.top, Space.xl)
            .padding(.bottom, Space.xs)
            .accessibilityHidden(true)                                  // each row reads "check, result"
            ForEach(Array(card.rows.enumerated()), id: \.offset) { _, row in
                hairline
                HStack(spacing: Space.m) {
                    Text(row.text)
                        .font(.system(size: 13, weight: .medium))
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Tag(text: row.verdict.word, tint: row.verdict.color)   // the word too: strangers read this PNG
                }
                .padding(.vertical, Space.xs)
                .accessibilityElement(children: .combine)
            }
            hairline

            VStack(alignment: .leading, spacing: Space.xxs) {
                if footer.count > 1 {
                    Text(footer.dropLast().joined(separator: " · ")).foregroundStyle(Paper.ink2)
                }
                Text(footer[footer.count - 1])                              // "Only trust a check you run yourself: …"
            }
            .font(.system(size: 11, design: .monospaced))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Space.m)
        }
        .padding(28)
        .frame(width: 560, alignment: .leading)
        .background(Color.white)
        .foregroundStyle(Paper.ink)
        .environment(\.colorScheme, .light)
    }

    /// Column heads: small caps (BUILD_PLAN §8 allows them on the card), never ALL CAPS copy.
    private func label(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .semibold).smallCaps()).tracking(0.5).foregroundStyle(Paper.ink2)
    }

    private var hairline: some View { Rectangle().fill(Paper.line).frame(height: 1).accessibilityHidden(true) }
}

/// The site's paper tokens (DESIGN.md §4.1: --paper-ink, --paper-2, --paper-line), so the PNG and the site's card agree.
private enum Paper {
    static let ink = Color(red: 0.043, green: 0.043, blue: 0.039)       // #0B0B0A
    static let ink2 = Color(red: 0.333, green: 0.333, blue: 0.306)      // #55554E, 7.5:1 on white
    static let line = Color(red: 0.902, green: 0.902, blue: 0.878)      // #E6E6E0
}
