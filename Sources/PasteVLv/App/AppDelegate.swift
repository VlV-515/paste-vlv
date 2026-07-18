import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private let repository = ClipboardRepository(context: PersistenceController.shared.viewContext)
    private let hotKeyManager = HotKeyManager()
    private let pasteController = PasteController()

    private lazy var appState = AppState(repository: repository, settings: settings)
    private lazy var clipboardMonitor = ClipboardMonitor(repository: repository, settings: settings)

    private var statusItem: NSStatusItem?
    private var panel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        appState.bootstrap()
        configureStatusItem()
        configurePanel()
        configureClipboardMonitor()
        configureHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        hotKeyManager.unregister()
        PersistenceController.shared.saveIfNeeded()
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "PasteVLv")
        statusItem.button?.action = #selector(togglePanelFromStatusItem)
        statusItem.button?.target = self

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show PasteVLv", action: #selector(showPanelFromMenu), keyEquivalent: "v"))
        menu.addItem(NSMenuItem(title: "Pause Capture", action: #selector(toggleCapturePause), keyEquivalent: "p"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        self.statusItem = statusItem
    }

    private func configurePanel() {
        let view = ClipboardPanelView(
            appState: appState,
            onPaste: { [weak self] item, plainText in
                self?.hidePanel()
                self?.pasteController.paste(item, asPlainText: plainText)
            },
            onClose: { [weak self] in
                self?.hidePanel()
            }
        )

        let hostingController = NSHostingController(rootView: view)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "PasteVLv"
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = hostingController
        self.panel = panel
    }

    private func configureClipboardMonitor() {
        clipboardMonitor.onCapture = { [weak self] in
            Task { @MainActor in
                self?.appState.refreshAll()
            }
        }
        clipboardMonitor.start()
    }

    private func configureHotKey() {
        hotKeyManager.onHotKey = { [weak self] in
            self?.togglePanel()
        }
        hotKeyManager.registerDefaultShortcut()
    }

    private func togglePanel() {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        appState.refreshAll()
        positionPanel()
        NSApp.activate(ignoringOtherApps: true)
        panel?.makeKeyAndOrderFront(nil)
    }

    private func hidePanel() {
        panel?.orderOut(nil)
    }

    private func positionPanel() {
        guard let panel else { return }
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let width = min(screenFrame.width - 80, 1120)
        let height = min(screenFrame.height - 120, 540)
        let x = screenFrame.midX - width / 2
        let y = screenFrame.minY + 44
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    @objc private func togglePanelFromStatusItem() {
        togglePanel()
    }

    @objc private func showPanelFromMenu() {
        showPanel()
    }

    @objc private func toggleCapturePause() {
        appState.isCapturePaused.toggle()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
