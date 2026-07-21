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
    @Published private(set) var selectedItemIDs: Set<UUID> = []
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

    @Published var appLanguage: AppLanguage {
        didSet { settings.appLanguage = appLanguage }
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
        self.appLanguage = settings.appLanguage
    }

    func bootstrap() {
        repository.bootstrapPinboardsIfNeeded(language: appLanguage)
        refreshAll(resetSelection: true)
        cleanupExpiredItems()
    }

    func refreshAll(resetSelection: Bool = false) {
        pinboards = repository.fetchPinboards()
        refreshItems(resetSelection: resetSelection)
    }

    func refreshItems(resetSelection: Bool = false) {
        let previousSelection = selectedItemID
        items = repository.fetchItems(
            search: searchText,
            pinboardID: selectedPinboardID,
            hiddenHistoryItemIDs: settings.hiddenHistoryItemIDs
        )
        lastSourceAppName = items.first?.sourceAppName

        if resetSelection {
            selectedItemID = items.first?.id
            selectedItemIDs = items.first.map { [$0.id] } ?? []
            return
        }

        if let previousSelection,
           items.contains(where: { $0.id == previousSelection }) {
            selectedItemID = previousSelection
        } else {
            selectedItemID = items.first?.id
        }

        selectedItemIDs.formIntersection(Set(items.map(\.id)))
        if selectedItemIDs.isEmpty, let selectedItemID {
            selectedItemIDs = [selectedItemID]
        }
    }

    func select(pinboardID: UUID?) {
        selectedPinboardID = pinboardID
        refreshItems(resetSelection: true)
    }

    func selectItem(id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        selectedItemID = id
        selectedItemIDs = [id]
    }

    func selectItems(_ itemIDs: Set<UUID>) {
        let visibleItemIDs = Set(items.map(\.id))
        let selection = itemIDs.intersection(visibleItemIDs)
        guard !selection.isEmpty else { return }
        selectedItemIDs = selection
        selectedItemID = items.first(where: { selection.contains($0.id) })?.id
    }

    func selectAllItems() {
        let allItems = repository.fetchItems(
            search: searchText,
            pinboardID: selectedPinboardID,
            hiddenHistoryItemIDs: settings.hiddenHistoryItemIDs,
            limit: .max
        )
        selectedItemIDs = Set(allItems.map(\.id))
        selectedItemID = items.first?.id
    }

    func moveSelection(offset: Int) {
        guard !items.isEmpty else {
            selectedItemID = nil
            return
        }

        let currentIndex = items.firstIndex(where: { $0.id == selectedItemID }) ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), items.count - 1)
        selectedItemID = items[nextIndex].id
        selectedItemIDs = [items[nextIndex].id]
    }

    func prepareForPanelPresentation() {
        selectedPinboardID = nil
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
        let itemIDs = Set(
            repository.fetchItems(search: "", pinboardID: pinboardID, limit: .max).map(\.id)
        )
        repository.deletePinboard(id: pinboardID)
        settings.restoreToHistory(itemIDs)
        if selectedPinboardID == pinboardID {
            selectedPinboardID = nil
        }
        refreshAll()
    }

    func recordUse(itemID: UUID) {
        settings.restoreToHistory([itemID])
        repository.recordUse(itemID: itemID)
    }

    func reorder(pinboardID: UUID, to destinationIndex: Int) {
        repository.reorderPinboard(id: pinboardID, to: destinationIndex)
        refreshAll()
    }

    func assign(itemID: UUID, to pinboardID: UUID?) {
        assign(itemIDs: [itemID], to: pinboardID)
    }

    func assign(itemIDs: Set<UUID>, to pinboardID: UUID?) {
        guard !itemIDs.isEmpty else { return }

        repository.assign(itemIDs: itemIDs, to: pinboardID)
        if pinboardID == nil {
            settings.restoreToHistory(itemIDs)
        }
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
        delete(itemIDs: [itemID])
    }

    func delete(itemIDs: Set<UUID>) {
        guard !itemIDs.isEmpty else { return }

        if selectedPinboardID == nil {
            let groupedItemIDs = Set(
                items.lazy
                    .filter { itemIDs.contains($0.id) && $0.pinboardID != nil }
                    .map(\.id)
            )
            settings.hideFromHistory(groupedItemIDs)
            repository.delete(itemIDs: itemIDs.subtracting(groupedItemIDs))
        } else {
            repository.delete(itemIDs: itemIDs)
            settings.restoreToHistory(itemIDs)
        }

        selectedItemID = nil
        selectedItemIDs.subtract(itemIDs)
        refreshItems(resetSelection: true)
    }

    func selectedItemIDsForDeletion() -> Set<UUID> {
        selectedItemIDs.isEmpty ? (selectedItem.map { [$0.id] } ?? []) : selectedItemIDs
    }

    func updateTitle(itemID: UUID, title: String?) {
        repository.updateTitle(itemID: itemID, title: title)
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
        let allItems = repository.fetchItems(search: "", pinboardID: nil, limit: .max)
        let groupedItemIDs = Set(allItems.filter { $0.pinboardID != nil }.map(\.id))
        settings.hideFromHistory(groupedItemIDs)
        repository.delete(itemIDs: Set(allItems.map(\.id)).subtracting(groupedItemIDs))
        refreshItems(resetSelection: true)
    }

    func handleCapturedItem(_ item: ClipboardItem?) {
        if let item {
            settings.restoreToHistory([item.id])
        }
        refreshAll()
    }

    func exportHistoryInteractively() {
        let panel = NSSavePanel()
        let copy = AppCopy(language: appLanguage)
        panel.title = copy.exportTitle
        panel.message = copy.exportMessage
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = defaultExportFilename()

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let summary = try repository.exportHistory(to: url)
            presentAlert(
                title: copy.exportComplete,
                message: "\(summary.message(language: appLanguage))\n\n\(copy.file):\n\(url.path)"
            )
        } catch {
            presentAlert(
                title: copy.exportFailed,
                message: localizedTransferError(error),
                style: .warning
            )
        }
    }

    func importHistoryInteractively() {
        let panel = NSOpenPanel()
        let copy = AppCopy(language: appLanguage)
        panel.title = copy.importTitle
        panel.message = copy.importMessage
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let summary = try repository.importHistory(from: url)
            refreshAll(resetSelection: true)
            presentAlert(
                title: copy.importComplete,
                message: summary.message(language: appLanguage)
            )
        } catch {
            presentAlert(
                title: copy.importFailed,
                message: localizedTransferError(error),
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
        return "paste-vlv-groups-\(formatter.string(from: Date())).json"
    }

    private func presentAlert(title: String, message: String, style: NSAlert.Style = .informational) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func localizedTransferError(_ error: Error) -> String {
        if let error = error as? ClipboardTransferError {
            return error.message(language: appLanguage)
        }
        return error.localizedDescription
    }
}
