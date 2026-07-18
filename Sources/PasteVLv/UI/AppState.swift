import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class AppState: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var pinboards: [Pinboard] = []
    @Published var selectedPinboardID: UUID?
    @Published var searchText = "" {
        didSet { refreshItems(resetSelection: true) }
    }
    @Published var selectedItemID: UUID?
    @Published var newPinboardName = ""
    @Published var lastSourceAppName: String?
    @Published private(set) var panelPresentationID = UUID()

    @Published var launchAtLoginEnabled: Bool {
        didSet { settings.launchAtLoginEnabled = launchAtLoginEnabled }
    }

    @Published var directPasteEnabled: Bool {
        didSet { settings.directPasteEnabled = directPasteEnabled }
    }

    @Published var pastePlainTextByDefault: Bool {
        didSet { settings.pastePlainTextByDefault = pastePlainTextByDefault }
    }

    @Published var soundEffectsEnabled: Bool {
        didSet { settings.soundEffectsEnabled = soundEffectsEnabled }
    }

    @Published var showMenuBarIcon: Bool {
        didSet { settings.showMenuBarIcon = showMenuBarIcon }
    }

    @Published var isCapturePaused: Bool {
        didSet { settings.isCapturePaused = isCapturePaused }
    }

    @Published var retentionPolicy: RetentionPolicy {
        didSet {
            settings.retentionPolicy = retentionPolicy
            cleanupExpiredItems()
        }
    }

    @Published var openShortcut: HotKeyShortcut {
        didSet { settings.openShortcut = openShortcut }
    }

    private let repository: ClipboardRepository
    let settings: AppSettings

    init(repository: ClipboardRepository, settings: AppSettings) {
        self.repository = repository
        self.settings = settings
        self.launchAtLoginEnabled = settings.launchAtLoginEnabled
        self.directPasteEnabled = settings.directPasteEnabled
        self.pastePlainTextByDefault = settings.pastePlainTextByDefault
        self.soundEffectsEnabled = settings.soundEffectsEnabled
        self.showMenuBarIcon = settings.showMenuBarIcon
        self.isCapturePaused = settings.isCapturePaused
        self.retentionPolicy = settings.retentionPolicy
        self.openShortcut = settings.openShortcut
    }

    func bootstrap() {
        repository.bootstrapPinboardsIfNeeded()
        refreshAll(resetSelection: true)
        cleanupExpiredItems()
    }

    func refreshAll(resetSelection: Bool = false) {
        pinboards = repository.fetchPinboards()
        refreshItems(resetSelection: resetSelection)
    }

    func refreshItems(resetSelection: Bool = false) {
        let previousSelection = selectedItemID
        items = repository.fetchItems(search: searchText, pinboardID: selectedPinboardID)
        lastSourceAppName = items.first?.sourceAppName

        if resetSelection {
            selectedItemID = items.first?.id
            return
        }

        if let previousSelection,
           items.contains(where: { $0.id == previousSelection }) {
            selectedItemID = previousSelection
        } else {
            selectedItemID = items.first?.id
        }
    }

    func select(pinboardID: UUID?) {
        selectedPinboardID = pinboardID
        refreshItems(resetSelection: true)
    }

    func selectItem(id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        selectedItemID = id
    }

    func moveSelection(offset: Int) {
        guard !items.isEmpty else {
            selectedItemID = nil
            return
        }

        let currentIndex = items.firstIndex(where: { $0.id == selectedItemID }) ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), items.count - 1)
        selectedItemID = items[nextIndex].id
    }

    func prepareForPanelPresentation() {
        refreshAll(resetSelection: true)
    }

    func notifyPanelPresented() {
        panelPresentationID = UUID()
    }

    func createPinboard() {
        repository.createPinboard(name: newPinboardName)
        newPinboardName = ""
        refreshAll()
    }

    func createPinboard(name: String, colorHex: String) {
        repository.createPinboard(name: name, colorHex: colorHex)
        refreshAll()
    }

    func update(pinboardID: UUID, name: String, colorHex: String) {
        repository.updatePinboard(id: pinboardID, name: name, colorHex: colorHex)
        refreshAll()
    }

    func delete(pinboardID: UUID) {
        repository.deletePinboard(id: pinboardID)
        if selectedPinboardID == pinboardID {
            selectedPinboardID = nil
        }
        refreshAll()
    }

    func assign(itemID: UUID, to pinboardID: UUID?) {
        repository.assign(itemID: itemID, to: pinboardID)
        refreshItems()
    }

    func toggleFavorite(itemID: UUID) {
        repository.toggleFavorite(itemID: itemID)
        refreshItems()
    }

    func togglePinned(itemID: UUID) {
        repository.togglePinned(itemID: itemID)
        refreshItems()
    }

    func delete(itemID: UUID) {
        repository.delete(itemID: itemID)
        refreshItems()
    }

    func toggleCurrentAppExclusion() {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }
        settings.toggleExcluded(bundleID: bundleID)
    }

    func cleanupExpiredItems() {
        repository.cleanupItems(olderThan: retentionPolicy.cutoffDate)
        refreshItems()
    }

    func clearHistory() {
        repository.deleteAllItems()
        refreshItems()
    }

    func exportHistoryInteractively() {
        let panel = NSSavePanel()
        panel.title = "Exportar historial"
        panel.message = "Guardar historial y grupos en un respaldo JSON."
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = defaultExportFilename()

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try repository.exportHistory(to: url)
            presentAlert(
                title: "Exportación completada",
                message: "Respaldo guardado en:\n\(url.path)"
            )
        } catch {
            presentAlert(
                title: "No se pudo exportar",
                message: error.localizedDescription,
                style: .warning
            )
        }
    }

    func importHistoryInteractively() {
        let panel = NSOpenPanel()
        panel.title = "Importar historial"
        panel.message = "Selecciona un respaldo JSON exportado desde Paste-vlv."
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let summary = try repository.importHistory(from: url)
            refreshAll(resetSelection: true)
            presentAlert(
                title: "Importación completada",
                message: summary.message
            )
        } catch {
            presentAlert(
                title: "No se pudo importar",
                message: error.localizedDescription,
                style: .warning
            )
        }
    }

    func colorHex(for item: ClipboardItem) -> String {
        guard let pinboardID = item.pinboardID,
              let pinboard = pinboards.first(where: { $0.id == pinboardID }) else {
            return "#6EA7F7"
        }
        return pinboard.colorHex
    }

    func pinboardName(for item: ClipboardItem) -> String? {
        guard let pinboardID = item.pinboardID else { return nil }
        return pinboards.first(where: { $0.id == pinboardID })?.name
    }

    var selectedItem: ClipboardItem? {
        guard let selectedItemID else { return items.first }
        return items.first(where: { $0.id == selectedItemID }) ?? items.first
    }

    private func defaultExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return "paste-vlv-history-\(formatter.string(from: Date())).json"
    }

    private func presentAlert(title: String, message: String, style: NSAlert.Style = .informational) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
