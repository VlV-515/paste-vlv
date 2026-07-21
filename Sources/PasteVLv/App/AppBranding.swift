import AppKit

enum AppBranding {
    static let displayName = "Paste-vlv"
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.2.0"
    static let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    static let developerURL = URL(string: "https://github.com/VlV-515")!
    static let projectURL = URL(string: "https://github.com/VlV-515/paste-vlv")!
    static let licenseURL = URL(string: "https://github.com/VlV-515/paste-vlv/blob/main/LICENSE")!

    static func makeAboutIcon() -> NSImage {
        if let bundleIconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: bundleIconURL) {
            return image
        }

        let projectIconURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Assets/AppIcon.icns")
        if let image = NSImage(contentsOf: projectIconURL) {
            return image
        }

        return NSApp.applicationIconImage
    }

    static func makeMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.black.setFill()
        NSBezierPath(roundedRect: NSRect(x: 2.4, y: 5.0, width: 9.6, height: 8.8), xRadius: 2.6, yRadius: 2.6).fill()
        NSBezierPath(roundedRect: NSRect(x: 4.8, y: 3.0, width: 10.8, height: 10.4), xRadius: 3.0, yRadius: 3.0).fill()

        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        context?.setBlendMode(.clear)
        context?.setFillColor(NSColor.clear.cgColor)
        context?.fill(CGRect(x: 7.0, y: 9.1, width: 5.9, height: 1.1))
        context?.fill(CGRect(x: 7.0, y: 6.6, width: 4.6, height: 1.1))
        context?.fill(CGRect(x: 7.0, y: 4.2, width: 3.3, height: 1.1))
        context?.restoreGState()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
