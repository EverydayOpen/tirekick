import SwiftUI
import TirekickCore

struct TestsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text("Test the hardware")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.5)
                    .accessibilityAddTraits(.isHeader)
                Text("Each test takes under a minute and ends with Pass, Problem or Skip. They're all optional.")
                    .foregroundStyle(.secondary)
            }
            // 3×2 in the fixed 720pt window: six HoverTilts, within MOTION §1.6's cap of 8.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: Space.l)], spacing: Space.l) {
                ForEach(HardwareTest.allCases, id: \.self) { test in
                    Button { model.openTest = test } label: { tile(test) }
                        .buttonStyle(KeyCapStyle())
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(Space.xxl)
    }

    /// A key-cap, legend top-left: the symbol in a well, the name, then the result as a tag with its mono note, or
    /// "Not tested". The LED lights once the test has run (lime means tested; the verdict stays in the tag, and a
    /// skip isn't a run). Every tile has the same three rows, so the grid stays even.
    private func tile(_ test: HardwareTest) -> some View {
        let result = model.testResults[test]
        return VStack(alignment: .leading, spacing: Space.s) {
            Image(systemName: test.symbol)
                .font(.system(size: 18, weight: .medium))
                .well(.secondary, size: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(test.title).font(.system(size: 15, weight: .semibold))
                HStack(spacing: 6) {
                    if let result {
                        // Problem is orange like every other "Check these" (TestOutcome.verdict); red means Walk away.
                        Tag(text: result.outcome.word, tint: result.outcome.verdict.color)
                        if let note = result.note {
                            Text(note)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    } else {
                        Text("Not tested").foregroundStyle(.secondary)
                    }
                }
                .font(.system(.caption, design: .monospaced))
                .frame(height: 20)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)   // fills the bay down to the bar
        .overlay(alignment: .topTrailing) { KeyLED(lit: result.map { $0.outcome != .skipped } ?? false) }
    }
}
