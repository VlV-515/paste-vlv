import AppKit
import Foundation

final class ClipboardMonitor {
    private let repository: ClipboardRepository
    private let settings: AppSettings
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    var onCapture: (() -> Void)?

    init(repository: ClipboardRepository, settings: AppSettings) {
        self.repository = repository
        self.settings = settings
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { [weak self] _ in
            self?.scanPasteboardIfNeeded()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func scanPasteboardIfNeeded() {
        guard !settings.isCapturePaused else { return }

        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        let sourceApp = NSWorkspace.shared.frontmostApplication
        if let bundleID = sourceApp?.bundleIdentifier,
           settings.excludedBundleIDs.contains(bundleID) {
            return
        }

        guard let content = Self.capture(from: pasteboard, sourceApp: sourceApp) else { return }
        repository.addCapturedContent(content)
        onCapture?()
    }

    private static func capture(from pasteboard: NSPasteboard, sourceApp: NSRunningApplication?) -> CapturedClipboardContent? {
        if let fileContent = captureFile(from: pasteboard, sourceApp: sourceApp) {
            return fileContent
        }

        if let imageContent = captureImage(from: pasteboard, sourceApp: sourceApp) {
            return imageContent
        }

        if let linkContent = captureLink(from: pasteboard, sourceApp: sourceApp) {
            return linkContent
        }

        if let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            let preview = text.singleLinePreview(maxLength: 220)
            return CapturedClipboardContent(
                kind: .text,
                preview: preview,
                searchableText: text,
                text: text,
                urlString: nil,
                filePath: nil,
                attachmentPath: nil,
                rawHashInput: Data("text:\(text)".utf8),
                sourceAppName: sourceApp?.localizedName,
                sourceAppBundleID: sourceApp?.bundleIdentifier
            )
        }

        return nil
    }

    private static func captureFile(from pasteboard: NSPasteboard, sourceApp: NSRunningApplication?) -> CapturedClipboardContent? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return nil
        }

        let fileURLs = urls.filter { $0.isFileURL }
        guard !fileURLs.isEmpty else { return nil }

        let paths = fileURLs.map { $0.path }
        let preview = paths.map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
        let searchable = paths.joined(separator: "\n")

        return CapturedClipboardContent(
            kind: .file,
            preview: preview.singleLinePreview(maxLength: 220),
            searchableText: searchable,
            text: nil,
            urlString: nil,
            filePath: paths.joined(separator: "\n"),
            attachmentPath: nil,
            rawHashInput: Data("file:\(searchable)".utf8),
            sourceAppName: sourceApp?.localizedName,
            sourceAppBundleID: sourceApp?.bundleIdentifier
        )
    }

    private static func captureImage(from pasteboard: NSPasteboard, sourceApp: NSRunningApplication?) -> CapturedClipboardContent? {
        let data = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png)
        guard let data, NSImage(data: data) != nil else { return nil }

        let fileName = "\(UUID().uuidString).tiff"
        let url = PersistenceController.attachmentsURL.appendingPathComponent(fileName)

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Unable to persist clipboard image: \(error.localizedDescription)")
            return nil
        }

        return CapturedClipboardContent(
            kind: .image,
            preview: "Image copied at \(Date().formatted(date: .omitted, time: .shortened))",
            searchableText: "image \(sourceApp?.localizedName ?? "")",
            text: nil,
            urlString: nil,
            filePath: nil,
            attachmentPath: url.path,
            rawHashInput: Data("image:".utf8) + data,
            sourceAppName: sourceApp?.localizedName,
            sourceAppBundleID: sourceApp?.bundleIdentifier
        )
    }

    private static func captureLink(from pasteboard: NSPasteboard, sourceApp: NSRunningApplication?) -> CapturedClipboardContent? {
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first(where: { !$0.isFileURL }) {
            return makeLinkContent(urlString: url.absoluteString, sourceApp: sourceApp)
        }

        guard let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              ["http", "https", "mailto"].contains(scheme) else {
            return nil
        }

        return makeLinkContent(urlString: text, sourceApp: sourceApp)
    }

    private static func makeLinkContent(urlString: String, sourceApp: NSRunningApplication?) -> CapturedClipboardContent {
        CapturedClipboardContent(
            kind: .link,
            preview: urlString.singleLinePreview(maxLength: 220),
            searchableText: urlString,
            text: urlString,
            urlString: urlString,
            filePath: nil,
            attachmentPath: nil,
            rawHashInput: Data("link:\(urlString)".utf8),
            sourceAppName: sourceApp?.localizedName,
            sourceAppBundleID: sourceApp?.bundleIdentifier
        )
    }
}

private extension String {
    func singleLinePreview(maxLength: Int) -> String {
        let collapsed = components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard collapsed.count > maxLength else { return collapsed }
        let end = collapsed.index(collapsed.startIndex, offsetBy: maxLength)
        return String(collapsed[..<end]) + "..."
    }
}
