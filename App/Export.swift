import AppKit
import SwiftUI
import TirekickCore
import UniformTypeIdentifiers

/// The only code that writes a file, and only where the user picks in the save panel (BUILD_PLAN §3).
@MainActor enum Export {
    /// The share card at 2x, drawn by the same view as the on-screen preview.
    static func png(_ card: ReportCard) {
        let renderer = ImageRenderer(content: ReportCardView(card: card))
        renderer.scale = 2
        guard let image = renderer.cgImage,
              let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            NSSound.beep()
            return
        }
        save(data, as: .png, name: "Tirekick report.png")
    }

    /// The full report (ReportText.full, raw evidence included) as a paginated text PDF.
    static func pdf(_ text: String) {
        let info = NSPrintInfo()
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.isVerticallyCentered = false
        let width = info.paperSize.width - info.leftMargin - info.rightMargin
        // TextKit 1, whose print pagination is long established (VERIFY: multi-page output on 13 and 26).
        let view = NSTextView(usingTextLayoutManager: false)
        view.frame = NSRect(x: 0, y: 0, width: width, height: 0)
        view.appearance = NSAppearance(named: .aqua)   // black text on white paper, even in Dark Mode
        view.isVerticallyResizable = true
        view.maxSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        view.string = text
        view.font = .monospacedSystemFont(ofSize: 9, weight: .regular)
        view.textColor = .black
        view.sizeToFit()
        let data = NSMutableData()
        let operation = NSPrintOperation.pdfOperation(with: view, inside: view.bounds, to: data, printInfo: info)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false
        guard operation.run() else {
            NSSound.beep()
            return
        }
        save(data as Data, as: .pdf, name: "Tirekick report.pdf")
    }

    private static func save(_ data: Data, as type: UTType, name: String) {
        guard let window = NSApp.keyWindow else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = name
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
}
