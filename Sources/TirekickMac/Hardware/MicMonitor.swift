import AVFoundation

/// Level meter for the microphone test. Nothing is recorded or saved.
// ponytail: uses the default input device (the built-in mic unless a headset is connected); pick the built-in
// device through Core Audio if testers get confused by AirPods.
@MainActor public final class MicMonitor {
    private let engine = AVAudioEngine()
    private var running = false

    public init() {}

    public static func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    /// Calls `onLevel` on the main actor with 0...1 (-60...0 dBFS), about 10 times a second: installTap's documented
    /// minimum buffer is 100 ms, so 20 a second isn't available. Throws NoDeviceError when there's no audio input.
    public func start(onLevel: @escaping @MainActor (Double) -> Void) throws {
        stop()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.sampleRate > 0 else { throw NoDeviceError() }
        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(format.sampleRate / 10), format: format,
                         block: Self.levelTap(onLevel))
        do { try engine.start() } catch { input.removeTap(onBus: 0); throw error }
        running = true
    }

    public func stop() {
        guard running else { return }   // touching inputNode before start() could ask for the microphone
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        running = false
    }

    /// Built outside the main actor because the tap runs on an audio thread.
    private nonisolated static func levelTap(_ onLevel: @escaping @MainActor (Double) -> Void) -> AVAudioNodeTapBlock {
        { buffer, _ in
            guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return }
            let count = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<count { sum += samples[i] * samples[i] }
            let decibels = 20 * log10(max(sqrt(sum / Float(count)), 1e-6))
            let level = Double(min(max((decibels + 60) / 60, 0), 1))
            Task { @MainActor in onLevel(level) }
        }
    }
}
