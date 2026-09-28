import SwiftUI
import TirekickCore
import TirekickMac

struct SpeakersTestView: View {
    @EnvironmentObject private var model: AppModel
    /// Made on the first Play, so opening the test touches no audio hardware.
    @State private var tone: ToneGenerator?
    @State private var playing: ToneGenerator.Channel?
    @State private var failure: String?

    var body: some View {
        // A monitor, AirPods or headphones would take the tone instead. VERIFY the device name ("MacBook Pro Speakers").
        let device: String = model.facts?.specs?.modelName.map { " (\"\($0) Speakers\")" } ?? ""
        TestScaffold(
            test: .speakers,
            instruction: "Unplug headphones and check that System Settings › Sound › Output is set to this Mac's own speakers\(device). Turn the volume up, then play each side. The tone should be clear, with no crackle or buzz, and come only from that side."
                + (model.isAllInOne == false ? " Mac mini, Mac Studio and Mac Pro have one built-in speaker; just listen for crackle or buzz." : "")
        ) {
            VStack(spacing: Space.l) {
                HStack(spacing: Space.s) {
                    button("Play Left", .left)
                    button("Play Both", .both)
                    button("Play Right", .right)
                }
                .padding(Space.s)
                .recessedPanel()
                if let failure {
                    Text(failure).foregroundStyle(.secondary)
                }
            }
        }
        .onDisappear { tone?.stop() }
    }

    private func button(_ title: String, _ channel: ToneGenerator.Channel) -> some View {
        let isPlaying = playing == channel
        return Button { toggle(channel) } label: {
            Label {
                Text(isPlaying ? "Stop" : title)
            } icon: {
                // Left's speaker faces left.
                Image(systemName: isPlaying ? "stop.fill" : "speaker.wave.2")
                    .scaleEffect(x: channel == .left && !isPlaying ? -1 : 1, y: 1)
            }
            .frame(minWidth: 110)
        }
        .controlSize(.large)
    }

    private func toggle(_ channel: ToneGenerator.Channel) {
        let tone = self.tone ?? ToneGenerator()
        self.tone = tone
        tone.stop()
        guard playing != channel else {
            playing = nil
            return
        }
        do {
            try tone.play(channel)
            playing = channel
            failure = nil
        } catch is NoDeviceError {
            playing = nil
            failure = "No speakers or headphones found. Every Mac has a built-in speaker, so choose Problem."
        } catch {
            playing = nil
            failure = "Couldn't play a sound. Check the output in System Settings › Sound and try again, or choose Skip."
        }
    }
}
