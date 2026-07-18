import AppKit
import Combine
import ServiceManagement
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
    private var preferencesWindow: NSWindow?
    private var pasteTargetApplication: NSRunningApplication?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        appState.bootstrap()
        configureStatusItem()
        configurePanel()
        configureClipboardMonitor()
        configureHotKey()
        configureSettingsObservers()
        applyLaunchAtLoginSetting()
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
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferencesFromMenu), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Pause Capture", action: #selector(toggleCapturePause), keyEquivalent: "p"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.isVisible = settings.showMenuBarIcon

        self.statusItem = statusItem
    }

    private func configurePanel() {
        let view = ClipboardPanelView(
            appState: appState,
            onPaste: { [weak self] item, plainText in
                self?.hidePanel()
                self?.handlePaste(item: item, plainText: plainText)
            },
            onClose: { [weak self] in
                self?.hidePanel()
            },
            onOpenPreferences: { [weak self] in
                self?.showPreferences()
            }
        )

        let hostingController = NSHostingController(rootView: view)
        let panel = ClipboardOverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 360),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "PasteVLv"
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
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
        hotKeyManager.register(settings.openShortcut)
    }

    private func configureSettingsObservers() {
        settings.$openShortcut
            .dropFirst()
            .sink { [weak self] shortcut in
                self?.hotKeyManager.register(shortcut)
            }
            .store(in: &cancellables)

        settings.$showMenuBarIcon
            .dropFirst()
            .sink { [weak self] isVisible in
                self?.statusItem?.isVisible = isVisible
            }
            .store(in: &cancellables)

        settings.$launchAtLoginEnabled
            .dropFirst()
            .sink { [weak self] _ in
                self?.applyLaunchAtLoginSetting()
            }
            .store(in: &cancellables)
    }

    private func togglePanel() {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        pasteTargetApplication = currentPasteTargetApplication()
        appState.refreshAll()
        positionPanel()
        panel?.orderFrontRegardless()
    }

    private func hidePanel() {
        panel?.orderOut(nil)
    }

    private func showPreferences() {
        if preferencesWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 330),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Preferencias"
            window.isReleasedWhenClosed = false
            window.center()
            window.contentViewController = NSHostingController(rootView: PreferencesView(appState: appState))
            preferencesWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow?.makeKeyAndOrderFront(nil)
    }

    private func handlePaste(item: ClipboardItem, plainText: Bool) {
        let pasteAsPlainText = plainText || settings.pastePlainTextByDefault
        if settings.directPasteEnabled {
            pasteController.paste(
                item,
                asPlainText: pasteAsPlainText,
                into: pasteTargetApplication
            )
        } else {
            pasteController.copy(item, asPlainText: pasteAsPlainText)
        }

        if settings.soundEffectsEnabled {
            NSSound.beep()
        }
    }

    private func currentPasteTargetApplication() -> NSRunningApplication? {
        guard let application = NSWorkspace.shared.frontmostApplication,
              application.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return nil
        }
        return application
    }

    private func applyLaunchAtLoginSetting() {
        do {
            if settings.launchAtLoginEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Unable to update launch at login: \(error.localizedDescription)")
        }
    }

    private func positionPanel() {
        guard let panel else { return }
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let height = min(screenFrame.height - 90, 380)
        panel.setFrame(
            NSRect(x: screenFrame.minX, y: screenFrame.minY, width: screenFrame.width, height: height),
            display: true
        )
    }

    @objc private func togglePanelFromStatusItem() {
        togglePanel()
    }

    @objc private func showPanelFromMenu() {
        showPanel()
    }

    @objc private func showPreferencesFromMenu() {
        showPreferences()
    }

    @objc private func toggleCapturePause() {
        appState.isCapturePaused.toggle()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private final class ClipboardOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
