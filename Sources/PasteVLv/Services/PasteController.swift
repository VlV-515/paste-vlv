import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation

final class PasteController {
    func copy(_ item: ClipboardItem, asPlainText: Bool = false) {
        placeOnPasteboard(item, asPlainText: asPlainText)
    }

    func paste(_ item: ClipboardItem, asPlainText: Bool = false) {
        placeOnPasteboard(item, asPlainText: asPlainText)
        requestAccessibilityIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.sendCommandV()
        }
    }

    private func placeOnPasteboard(_ item: ClipboardItem, asPlainText: Bool) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if asPlainText {
            pasteboard.setString(item.text ?? item.preview, forType: .string)
            return
        }

        switch item.kind {
        case .text, .link:
            pasteboard.setString(item.text ?? item.urlString ?? item.preview, forType: .string)
        case .file:
            let urls = (item.filePath ?? "")
                .split(separator: "\n")
                .map { URL(fileURLWithPath: String($0)) }
            if !urls.isEmpty {
                pasteboard.writeObjects(urls as [NSURL])
            } else {
                pasteboard.setString(item.preview, forType: .string)
            }
        case .image:
            if let attachmentPath = item.attachmentPath,
               let data = try? Data(contentsOf: URL(fileURLWithPath: attachmentPath)) {
                pasteboard.setData(data, forType: .tiff)
            } else {
                pasteboard.setString(item.preview, forType: .string)
            }
        }
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    private func sendCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
