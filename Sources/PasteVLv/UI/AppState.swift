import AppKit
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var pinboards: [Pinboard] = []
    @Published var selectedPinboardID: UUID?
    @Published var searchText = "" {
        didSet { refreshItems() }
    }
    @Published var newPinboardName = ""
    @Published var lastSourceAppName: String?

    @Published var isCapturePaused: Bool {
        didSet { settings.isCapturePaused = isCapturePaused }
    }

    @Published var retentionPolicy: RetentionPolicy {
        didSet {
            settings.retentionPolicy = retentionPolicy
            cleanupExpiredItems()
        }
    }

    private let repository: ClipboardRepository
    let settings: AppSettings

    init(repository: ClipboardRepository, settings: AppSettings) {
        self.repository = repository
        self.settings = settings
        self.isCapturePaused = settings.isCapturePaused
        self.retentionPolicy = settings.retentionPolicy
    }

    func bootstrap() {
        repository.bootstrapPinboardsIfNeeded()
        refreshAll()
        cleanupExpiredItems()
    }

    func refreshAll() {
        pinboards = repository.fetchPinboards()
        refreshItems()
    }

    func refreshItems() {
        items = repository.fetchItems(search: searchText, pinboardID: selectedPinboardID)
        lastSourceAppName = items.first?.sourceAppName
    }

    func select(pinboardID: UUID?) {
        selectedPinboardID = pinboardID
        refreshItems()
    }

    func createPinboard() {
        repository.createPinboard(name: newPinboardName)
        newPinboardName = ""
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
}
