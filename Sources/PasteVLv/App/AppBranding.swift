import AppKit

enum AppBranding {
    static let displayName = "Paste-vlv"

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
