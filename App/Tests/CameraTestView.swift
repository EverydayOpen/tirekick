import AppKit
import AVFoundation
import SwiftUI
import TirekickCore
import TirekickMac

struct CameraTestView: View {
    @EnvironmentObject private var model: AppModel
    @State private var camera: CameraSession?
    @State private var problem: String?
    @State private var denied = false

    var body: some View {
        TestScaffold(
            test: .camera,
            instruction: "Check the picture is sharp and the green light next to the camera is on. Nothing is recorded or saved."
        ) {
            if let camera {
                // The one lifted object: the picture in a dark bezel. The shadow is on the SwiftUI bezel, not on
                // the AppKit preview, so it renders.
                CameraPreview(session: camera.session)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .accessibilityLabel("Camera preview")
                    .padding(Space.xs)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(white: 0.08)).lifted())
            } else if let problem {
                PermissionProblem(text: problem, pane: denied ? "Privacy_Camera" : nil)
            } else {
                ProgressView()
            }
        }
        // Opening the test is what asks for access (BUILD_PLAN §3.7).
        .task { await start() }
        .onDisappear { camera?.stop() }
    }

    private func start() async {
        guard await CameraSession.requestAccess() else {
            denied = true
            problem = "Tirekick can't use the camera. Allow it in System Settings › Privacy & Security › Camera, or skip this test."
            return
        }
        guard !Task.isCancelled else { return }   // left the test while macOS asked
        let camera = CameraSession()
        do {
            try camera.start()
            self.camera = camera
        } catch is NoDeviceError {
            // On a MacBook or iMac a missing camera is the fault this test is for (a closed lid hides it too).
            problem = model.isAllInOne == true
                ? "Tirekick can't find the built-in camera. This Mac should have one: if the lid is open, choose Problem."
                : "This Mac has no built-in camera. Choose Skip."
        } catch {
            problem = "Couldn't start the camera. Another app may be using it. Quit that app and open the test again, or choose Skip."
        }
    }
}

private struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer = preview   // layer-hosting: set the layer before wantsLayer
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
