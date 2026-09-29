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
        .background { Bay(step: model.step) }
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

    /// One floating bar per screen, like TestScaffold's. The Report's controls live here too, so its one prominent
    /// button, Save PNG, sits where Continue does and a full card never pushes it out of reach.
    private var bottomBar: some View {
        HStack {
            Button("Back") { model.back() }
            if model.step == .report {
                Group {
                    Toggle("Mask serial", isOn: $model.maskSerial).padding(.leading, Space.xs)
                    Spacer()
                    CopyButton { model.copyReport() }
                    Button("Save PDF…") {
                        if let report = model.report { Export.pdf(ReportText.full(report, maskSerial: model.maskSerial)) }
                    }
                    Button("Save PNG…") { if let card = model.card { Export.png(card) } }
                        .buttonStyle(HiVisButtonStyle())
                        .keyboardShortcut(.defaultAction)
                }
                .disabled(model.report == nil)
            } else {
                Spacer()
                Button("Continue") { model.next() }
                    .buttonStyle(HiVisButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.facts == nil)
            }
        }
        .buttonStyle(.bordered)                                    // the hi-vis buttons set their own
        .controlSize(.large)
        .floatingBar()
    }
}
