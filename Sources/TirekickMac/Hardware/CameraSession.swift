// AVCaptureSession isn't Sendable, but Apple documents start/stopRunning as safe off the main thread.
@preconcurrency import AVFoundation

/// The built-in camera's live feed for the camera test. Nothing is recorded or saved.
@MainActor public final class CameraSession {
    public let session = AVCaptureSession()
    /// startRunning() blocks, so it and stopRunning() run here, in order.
    private let queue = DispatchQueue(label: "CameraSession")

    public init() {}

    public static func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    /// Throws NoDeviceError when there's no built-in camera, or AVFoundation's error when access was denied.
    /// Built-in only: a dead camera must not be hidden by an iPhone (Continuity Camera) or a USB webcam.
    // VERIFY: Intel Macs' FaceTime cameras report .builtInWideAngleCamera too.
    public func start() throws {
        if session.inputs.isEmpty {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
                throw NoDeviceError()
            }
            let input = try AVCaptureDeviceInput(device: camera)
            guard session.canAddInput(input) else { throw NoDeviceError() }
            session.addInput(input)
        }
        let session = self.session
        queue.async { session.startRunning() }
    }

    public func stop() {
        let session = self.session
        queue.async { session.stopRunning() }
    }
}
