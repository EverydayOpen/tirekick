import SwiftUI
import TirekickCore

/// Four screens like Setup Assistant, with a Back/Continue bar; an open test takes the whole window.
struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let test = model.openTest {
                testView(test)
            } else {
                VStack(spacing: 0) {
                    screen.frame(maxWidth: .infinity, maxHeight: .infinity)
                    if model.step != .welcome { bottomBar }
                }
            }
        }
        .animation(Motion.standard(reduceMotion), value: model.step)
        .animation(Motion.standard(reduceMotion), value: model.openTest)
    }

    @ViewBuilder private var screen: some View {
        switch model.step {
        case .welcome: WelcomeView()
        case .checks: ChecksView()
        case .tests: TestsView()
        case .report: ReportView()
        }
    }

    @ViewBuilder private func testView(_ test: HardwareTest) -> some View {
        switch test {
        case .keyboard: KeyboardTestView()
        case .display: DisplayTestView()
        case .speakers: SpeakersTestView()
        case .microphone: MicrophoneTestView()
        case .camera: CameraTestView()
        case .trackpad: TrackpadTestView()
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button("Back") { model.back() }
                Spacer()
                // The Report is the last screen; its one prominent button is Save PNG.
                if model.step != .report {
                    Button("Continue") { model.next() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .disabled(model.facts == nil)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(Space.l)
        }
    }
}
