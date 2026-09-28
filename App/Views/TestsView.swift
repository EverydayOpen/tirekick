import SwiftUI
import TirekickCore

struct TestsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text("Test the hardware")
                    .font(.system(size: 26, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Text("Each test takes under a minute and ends with Pass, Problem or Skip. They're all optional.")
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: Space.m)], spacing: Space.m) {
                ForEach(HardwareTest.allCases, id: \.self) { test in
                    Button { model.openTest = test } label: { tile(test) }
                        .buttonStyle(KeyCapStyle())
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Space.xxl)
    }

    /// A key-cap, legend top-left: the symbol in a well, the name, then the result as a tag (plus the keyboard's
    /// count) or "Not tested". Every tile has the same three rows, so the grid stays even.
    private func tile(_ test: HardwareTest) -> some View {
        let result = model.testResults[test]
        return VStack(alignment: .leading, spacing: Space.s) {
            Image(systemName: test.symbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Brand.hiVisInk)
                .well(.secondary, size: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(test.title).font(.headline)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
