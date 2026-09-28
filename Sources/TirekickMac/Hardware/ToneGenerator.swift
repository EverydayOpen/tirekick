import AVFoundation

/// Thrown when this Mac has no such device: no built-in camera (Mac mini, Mac Studio, Mac Pro), no audio input or output.
public struct NoDeviceError: Error {}

/// Sine tones for the speaker test on the default output device: left, right or both channels.
@MainActor public final class ToneGenerator {
    public enum Channel: Sendable { case left, right, both }

    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?

    public init() {}

    public func play(_ channel: Channel, frequency: Double = 440) throws {
        stop()
        let sampleRate = engine.outputNode.inputFormat(forBus: 0).sampleRate
        guard sampleRate > 0, let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            throw NoDeviceError()
        }
        let node = Self.sine(cyclesPerFrame: frequency / sampleRate, left: channel != .right, right: channel != .left, format: format)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        source = node
        try engine.start()
    }

    public func stop() {
        engine.stop()
        if let source { engine.detach(source) }
        source = nil
    }

    /// Built outside the main actor because the render block runs on the audio thread.
    /// The standard format is deinterleaved, so buffer 0 is the left channel and buffer 1 the right.
    private nonisolated static func sine(cyclesPerFrame: Double, left: Bool, right: Bool, format: AVAudioFormat) -> AVAudioSourceNode {
        let phase = Phase()
        return AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let value = Float(sin(2 * Double.pi * phase.value)) * 0.3
                phase.value = (phase.value + cyclesPerFrame).truncatingRemainder(dividingBy: 1)
                for (index, buffer) in buffers.enumerated() {
                    let on = index == 0 ? left : right
                    UnsafeMutableBufferPointer<Float>(buffer)[frame] = on ? value : 0
                }
            }
            return noErr
        }
    }
}

/// Only the render thread touches it.
private final class Phase: @unchecked Sendable {
    var value = 0.0
}
