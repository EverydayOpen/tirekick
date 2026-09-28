import SwiftUI
import TirekickCore

/// Four screens like Setup Assistant on the bay: StepBar in the hidden title bar's strip, a floating Back/Continue
/// bar; an open test takes the whole window.
struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let test = model.openTest {
                testView(test)
            } else {
                VStack(spacing: 0) {
                    // VERIFY on a Mac: the capsule's centre is level with the traffic lights; nudge the top padding.
                    StepBar(current: model.step)
                        .padding(.top, 6)
                        .padding(.bottom, Space.xs)
                    screen
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        // An inset, not a row: scrolling content passes under the material bar.
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            if model.step != .welcome { bottomBar }
                        }
                }
                .ignoresSafeArea(.container, edges: .top)
            }
        }
        .background { Bay() }
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

    /// Floats in a material capsule, like TestScaffold's bar.
    private var bottomBar: some View {
        HStack {
            Button("Back") { model.back() }
                .buttonStyle(.bordered)
                .controlSize(.large)
            Spacer()
            // The Report is the last screen; its one prominent button is Save PNG.
            if model.step != .report {
                Button("Continue") { model.next() }
                    .buttonStyle(HiVisButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.facts == nil)
            }
        }
        .padding(.vertical, Space.xs)
        .padding(.horizontal, Space.s)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
        .padding([.horizontal, .bottom], Space.l)
    }
}
