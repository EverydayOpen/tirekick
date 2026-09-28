import SwiftUI
import TirekickCore

struct TestsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text("Test the hardware").font(.title2.weight(.semibold))
                Text("Each test takes under a minute and ends with Pass, Problem or Skip. They're all optional.")
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: Space.m)], spacing: Space.m) {
                ForEach(HardwareTest.allCases, id: \.self) { test in
                    Button { model.openTest = test } label: { tile(test) }
                        .buttonStyle(TileButtonStyle())
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Space.xxl)
    }

    private func tile(_ test: HardwareTest) -> some View {
        let result = model.testResults[test]
        return VStack(spacing: Space.xs) {
            Image(systemName: test.symbol)
                .font(.system(size: 28))
                .foregroundStyle(.tint)
                .frame(height: 34)
                .accessibilityHidden(true)
            Text(test.title).font(.headline)
            HStack(spacing: Space.xxs) {
                if let result {
                    // The outcome word follows, so VoiceOver shouldn't also hear the verdict word ("Couldn't check").
                    VerdictIcon(verdict: result.outcome.verdict, size: 12, showsWord: false)
                        .accessibilityHidden(true)
                    Text([result.outcome.word, result.note].compactMap { $0 }.joined(separator: " · "))
                } else {
                    Text("Not tested")
                }
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .frame(minHeight: 96)
    }
}
