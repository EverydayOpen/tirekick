import SwiftUI
import TirekickCore
import TirekickMac

struct MicrophoneTestView: View {
    @EnvironmentObject private var model: AppModel
    @State private var mic: MicMonitor?
    /// MicMonitor's level: 0...1 for -60...0 dBFS.
    @State private var level = 0.0
    @State private var problem: String?
    @State private var denied = false

    var body: some View {
        TestScaffold(
            test: .microphone,
            // Uses the default input, so a headset's or display's mic would pass for the Mac's.
            instruction: "Speak or clap near the Mac. The bar should jump with each sound. Nothing is recorded or saved."
                + (model.isAllInOne == true ? " Unplug headsets; Input should be the Mac's built-in microphone." : "")
                + (model.isAllInOne == false ? " This Mac has no built-in microphone, so this tests whichever one is connected. Choose Skip unless it comes with the Mac." : "")
        ) {
            if let problem {
                PermissionProblem(text: problem, pane: denied ? "Privacy_Microphone" : nil)
            } else {
                LevelMeter(level: level)
            }
        }
        // Opening the test is what asks for access (BUILD_PLAN §3.7).
        .task { await start() }
        .onDisappear { mic?.stop() }
    }

    private func start() async {
        guard await MicMonitor.requestAccess() else {
            denied = true
            problem = "Tirekick can't use the microphone. Allow it in System Settings › Privacy & Security › Microphone, or skip this test."
            return
        }
        guard !Task.isCancelled else { return }   // left the test while macOS asked
        let mic = MicMonitor()
        self.mic = mic
        do {
            try mic.start { level = $0 }
        } catch is NoDeviceError {
            // On a MacBook or iMac a missing microphone is the fault this test is for (a closed lid hides it too).
            problem = model.isAllInOne == true
                ? "Tirekick can't find the built-in microphone. This Mac should have one: if the lid is open, choose Problem."
                : "This Mac has no built-in microphone. Choose Skip, or connect one and open the test again."
        } catch {
            problem = "Couldn't start the microphone. Another app may be using it. Quit that app and open the test again, or choose Skip."
        }
    }
}

/// A segmented meter set into the deck: segments light hi-vis as the microphone registers sound (lime means
/// "registered"). Never animated; it moves only with the sound.
private struct LevelMeter: View {
    let level: Double

    var body: some View {
        let segments = 24
        let lit = Int((level * Double(segments)).rounded())
        HStack(spacing: 3) {
            ForEach(0..<segments, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(i < lit ? Brand.hiVis : Color.primary.opacity(0.12))
            }
        }
        .frame(height: 28)
        .padding(Space.s)
        .recessedPanel(cornerRadius: 2 + Space.s)
        .frame(maxWidth: 440)
        .accessibilityElement()
        .accessibilityLabel("Input level")
        .accessibilityValue("\(Int((level * 100).rounded()))%")
    }
}
