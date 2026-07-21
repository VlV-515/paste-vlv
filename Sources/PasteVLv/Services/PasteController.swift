import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation

final class PasteController {
    private var didRequestAccessibilityPrompt = false
    var onPasteboardWrite: (() -> Void)?

    func copy(_ item: ClipboardItem, asPlainText: Bool = false) {
        placeOnPasteboard(item, asPlainText: asPlainText)
    }

    func paste(
        _ item: ClipboardItem,
        asPlainText: Bool = false,
        into targetApplication: NSRunningApplication? = nil
    ) {
        placeOnPasteboard(item, asPlainText: asPlainText)

        requestAccessibilityPromptIfNeeded()

        targetApplication?.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            self.sendCommandV(to: targetApplication)
        }
    }

    private func placeOnPasteboard(_ item: ClipboardItem, asPlainText: Bool) {
        let pasteboard = NSPasteboard.general
        defer { onPasteboardWrite?() }
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

    private func requestAccessibilityPromptIfNeeded() {
        guard !AXIsProcessTrusted(), !didRequestAccessibilityPrompt else { return }

        didRequestAccessibilityPrompt = true
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    private func sendCommandV(to targetApplication: NSRunningApplication?) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        if let processIdentifier = targetApplication?.processIdentifier {
            keyDown?.postToPid(processIdentifier)
            keyUp?.postToPid(processIdentifier)
        } else {
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}
