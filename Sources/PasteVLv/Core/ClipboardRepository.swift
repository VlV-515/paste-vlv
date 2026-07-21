import CoreData
import CryptoKit
import Foundation

final class ClipboardRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func bootstrapPinboardsIfNeeded(language: AppLanguage) {
        backfillLastUsedDates()

        let request = NSFetchRequest<PinboardEntity>(entityName: "PinboardEntity")
        request.fetchLimit = 1

        do {
            if try context.count(for: request) > 0 {
                return
            }

            let initialPinboards = language == .english
                ? [("General", "#2563EB"), ("Links", "#059669"), ("Images", "#D97706")]
                : [("General", "#2563EB"), ("Enlaces", "#059669"), ("Imágenes", "#D97706")]

            initialPinboards.enumerated().forEach { index, data in
                let pinboard = PinboardEntity(context: context)
                pinboard.id = UUID()
                pinboard.name = data.0
                pinboard.colorHex = data.1
                pinboard.sortOrder = Int16(index)
                pinboard.createdAt = Date()
            }

            save()
        } catch {
            NSLog("Unable to bootstrap pinboards: \(error.localizedDescription)")
        }
    }

    func fetchPinboards() -> [Pinboard] {
        let request = NSFetchRequest<PinboardEntity>(entityName: "PinboardEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]

        do {
            return try context.fetch(request).map { $0.asDomain() }
        } catch {
            NSLog("Unable to fetch pinboards: \(error.localizedDescription)")
            return []
        }
    }

    func fetchItems(
        search: String,
        pinboardID: UUID?,
        hiddenHistoryItemIDs: Set<UUID> = [],
        limit: Int = 200
    ) -> [ClipboardItem] {
        let request = NSFetchRequest<ClipboardItemEntity>(entityName: "ClipboardItemEntity")
        request.fetchLimit = limit
        request.sortDescriptors = pinboardID == nil
            ? [
                NSSortDescriptor(key: "lastUsedAt", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            : [
                NSSortDescriptor(key: "isPinned", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]

        var predicates: [NSPredicate] = []
        if let pinboardID {
            predicates.append(NSPredicate(format: "pinboardID == %@", pinboardID as CVarArg))
        } else if !hiddenHistoryItemIDs.isEmpty {
            predicates.append(NSPredicate(format: "NOT (id IN %@)", Array(hiddenHistoryItemIDs)))
        }

        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            predicates.append(
                NSPredicate(
                    format: "customTitle CONTAINS[cd] %@ OR searchableText CONTAINS[cd] %@ OR preview CONTAINS[cd] %@ OR sourceAppName CONTAINS[cd] %@",
                    trimmed,
                    trimmed,
                    trimmed,
                    trimmed
                )
            )
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        do {
            return try context.fetch(request).map { $0.asDomain() }
        } catch {
            NSLog("Unable to fetch clipboard items: \(error.localizedDescription)")
            return []
        }
    }

    @discardableResult
    func addCapturedContent(_ content: CapturedClipboardContent) -> ClipboardItem? {
        let hash = Self.hash(content.rawHashInput)

        if let existing = existingItem(hash: hash) {
            let now = Date()
            existing.createdAt = now
            existing.lastUsedAt = now
            existing.sourceAppName = content.sourceAppName
            existing.sourceAppBundleID = content.sourceAppBundleID
            save()
            return existing.asDomain()
        }

        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.kind = content.kind.rawValue
        item.customTitle = nil
        item.preview = content.preview
        item.searchableText = content.searchableText
        item.text = content.text
        item.urlString = content.urlString
        item.filePath = content.filePath
        item.attachmentPath = content.attachmentPath
        item.sourceAppName = content.sourceAppName
        item.sourceAppBundleID = content.sourceAppBundleID
        item.createdAt = Date()
        item.lastUsedAt = item.createdAt
        item.contentHash = hash
        item.isFavorite = false
        item.isPinned = false
        item.pinboardID = nil
        save()
        return item.asDomain()
    }

    func assign(itemID: UUID, to pinboardID: UUID?) {
        guard let item = findItem(id: itemID) else { return }
        item.pinboardID = pinboardID
        save()
    }

    func toggleFavorite(itemID: UUID) {
        guard let item = findItem(id: itemID) else { return }
        item.isFavorite.toggle()
        save()
    }

    func togglePinned(itemID: UUID) {
        guard let item = findItem(id: itemID) else { return }
        item.isPinned.toggle()
        save()
    }

    func delete(itemID: UUID) {
        guard let item = findItem(id: itemID) else { return }
        context.delete(item)
        save()
    }

    func delete(itemIDs: Set<UUID>) {
        guard !itemIDs.isEmpty else { return }

        let request = NSFetchRequest<ClipboardItemEntity>(entityName: "ClipboardItemEntity")
        request.predicate = NSPredicate(format: "id IN %@", Array(itemIDs))

        do {
            try context.fetch(request).forEach(context.delete)
            save()
        } catch {
            NSLog("Unable to delete selected clipboard items: \(error.localizedDescription)")
        }
    }

    func updateTitle(itemID: UUID, title: String?) {
        guard let item = findItem(id: itemID) else { return }
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        item.customTitle = trimmed?.isEmpty == false ? trimmed : nil
        save()
    }

    func createPinboard(name: String) {
        createPinboard(name: name, colorHex: ["#F85B5B", "#F59E0B", "#FACC15", "#63D957", "#38BDF8", "#C084FC", "#94A3B8"].randomElement()!)
    }

    func createPinboard(name: String, colorHex: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let pinboard = PinboardEntity(context: context)
        pinboard.id = UUID()
        pinboard.name = trimmed
        pinboard.colorHex = colorHex
        pinboard.sortOrder = Int16(fetchPinboards().count)
        pinboard.createdAt = Date()
        save()
    }

    func updatePinboard(id: UUID, name: String, colorHex: String) {
        guard let pinboard = findPinboard(id: id) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pinboard.name = trimmed
        pinboard.colorHex = colorHex
        save()
    }

    func recordUse(itemID: UUID) {
        guard let item = findItem(id: itemID) else { return }
        item.lastUsedAt = Date()
        save()
    }

    func reorderPinboard(id: UUID, to destinationIndex: Int) {
        var pinboards = fetchPinboards()
        guard let sourceIndex = pinboards.firstIndex(where: { $0.id == id }) else {
            return
        }

        let moved = pinboards.remove(at: sourceIndex)
        let adjustedDestination = destinationIndex > sourceIndex
            ? destinationIndex - 1
            : destinationIndex
        let insertionIndex = min(max(adjustedDestination, 0), pinboards.count)
        pinboards.insert(moved, at: insertionIndex)

        for (index, pinboard) in pinboards.enumerated() {
            findPinboard(id: pinboard.id)?.sortOrder = Int16(index)
        }
        save()
    }

    func deletePinboard(id: UUID) {
        let request = NSFetchRequest<ClipboardItemEntity>(entityName: "ClipboardItemEntity")
        request.predicate = NSPredicate(format: "pinboardID == %@", id as CVarArg)

        do {
            try context.fetch(request).forEach { $0.pinboardID = nil }
        } catch {
            NSLog("Unable to unassign deleted pinboard items: \(error.localizedDescription)")
        }

        guard let pinboard = findPinboard(id: id) else {
            save()
            return
        }

        context.delete(pinboard)
        save()
    }

    func deleteAllItems() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ClipboardItemEntity")
        let delete = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(delete)
            save()
        } catch {
            NSLog("Unable to clear clipboard history: \(error.localizedDescription)")
        }
    }

    func cleanupItems(olderThan date: Date?) {
        guard let date else { return }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ClipboardItemEntity")
        request.predicate = NSPredicate(
            format: "createdAt < %@ AND pinboardID == nil AND isPinned == NO AND isFavorite == NO",
            date as NSDate
        )
        let delete = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(delete)
            save()
        } catch {
            NSLog("Unable to clean clipboard history: \(error.localizedDescription)")
        }
    }

    func exportHistory(to url: URL) throws -> ClipboardHistoryExportSummary {
        let exportPayload = try makeHistoryArchive(exportedAt: Date())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(exportPayload.archive)
        try data.write(to: url, options: .atomic)
        return exportPayload.summary
    }

    func importHistory(from url: URL) throws -> ClipboardHistoryImportSummary {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let archive = try decoder.decode(ClipboardHistoryArchive.self, from: data).validated()

        var createdPinboards = 0
        var updatedPinboards = 0
        var createdItems = 0
        var updatedItems = 0

        for snapshot in archive.pinboards.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let entity: PinboardEntity
            if let existing = findPinboard(id: snapshot.id) {
                entity = existing
                updatedPinboards += 1
            } else {
                entity = PinboardEntity(context: context)
                createdPinboards += 1
            }

            entity.id = snapshot.id
            entity.name = snapshot.name
            entity.colorHex = snapshot.colorHex
            entity.sortOrder = snapshot.sortOrder
            entity.createdAt = snapshot.createdAt
        }

        for snapshot in archive.items.sorted(by: { $0.createdAt < $1.createdAt }) {
            let entity: ClipboardItemEntity
            if let existing = findItem(id: snapshot.id) {
                entity = existing
                updatedItems += 1
            } else {
                entity = ClipboardItemEntity(context: context)
                createdItems += 1
            }

            entity.id = snapshot.id
            entity.kind = snapshot.kind.rawValue
            entity.customTitle = snapshot.customTitle
            entity.preview = snapshot.preview
            entity.searchableText = snapshot.searchableText
            entity.text = snapshot.text
            entity.urlString = nil
            entity.filePath = nil
            entity.attachmentPath = nil
            entity.sourceAppName = snapshot.sourceAppName
            entity.sourceAppBundleID = snapshot.sourceAppBundleID
            entity.createdAt = snapshot.createdAt
            entity.lastUsedAt = snapshot.createdAt
            entity.contentHash = snapshot.contentHash
            entity.isFavorite = snapshot.isFavorite
            entity.isPinned = snapshot.isPinned
            entity.pinboardID = snapshot.pinboardID
        }

        save()

        return ClipboardHistoryImportSummary(
            createdPinboards: createdPinboards,
            updatedPinboards: updatedPinboards,
            createdItems: createdItems,
            updatedItems: updatedItems
        )
    }

    private func existingItem(hash: String) -> ClipboardItemEntity? {
        let request = NSFetchRequest<ClipboardItemEntity>(entityName: "ClipboardItemEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "contentHash == %@", hash)
        return try? context.fetch(request).first
    }

    private func findItem(id: UUID) -> ClipboardItemEntity? {
        let request = NSFetchRequest<ClipboardItemEntity>(entityName: "ClipboardItemEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }

    private func findPinboard(id: UUID) -> PinboardEntity? {
        let request = NSFetchRequest<PinboardEntity>(entityName: "PinboardEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }

    private func backfillLastUsedDates() {
        let request = NSFetchRequest<ClipboardItemEntity>(entityName: "ClipboardItemEntity")
        request.predicate = NSPredicate(format: "lastUsedAt == nil")

        do {
            try context.fetch(request).forEach { $0.lastUsedAt = $0.createdAt }
            save()
        } catch {
            NSLog("Unable to migrate clipboard usage dates: \(error.localizedDescription)")
        }
    }

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            NSLog("Unable to save clipboard data: \(error.localizedDescription)")
        }
    }

    private func makeHistoryArchive(exportedAt: Date) throws -> (archive: ClipboardHistoryArchive, summary: ClipboardHistoryExportSummary) {
        let pinboards = try fetchAllPinboardEntities().map {
                ClipboardHistoryPinboard(
                    id: $0.id,
                    name: $0.name,
                    colorHex: $0.colorHex,
                    sortOrder: $0.sortOrder,
                    createdAt: $0.createdAt
                )
            }
        let allItems = try fetchAllItemEntities()
        let exportedItems = allItems.compactMap { entity -> ClipboardHistoryItem? in
            guard entity.pinboardID != nil else { return nil }
            guard entity.kind == ClipboardKind.text.rawValue else { return nil }

            return ClipboardHistoryItem(
                    id: entity.id,
                    kind: ClipboardKind(rawValue: entity.kind) ?? .text,
                    customTitle: entity.customTitle,
                    preview: entity.preview,
                    searchableText: entity.searchableText,
                    text: entity.text,
                    sourceAppName: entity.sourceAppName,
                    sourceAppBundleID: entity.sourceAppBundleID,
                    createdAt: entity.createdAt,
                    contentHash: entity.contentHash,
                    isFavorite: entity.isFavorite,
                    isPinned: entity.isPinned,
                    pinboardID: entity.pinboardID
                )
            }
        let summary = ClipboardHistoryExportSummary(
            exportedPinboards: pinboards.count,
            exportedItems: exportedItems.count,
            omittedUngroupedItems: allItems.filter { $0.pinboardID == nil }.count,
            omittedNonTextGroupedItems: allItems.filter { $0.pinboardID != nil && $0.kind != ClipboardKind.text.rawValue }.count
        )
        let archive = ClipboardHistoryArchive(
            schemaVersion: ClipboardHistoryArchive.currentSchemaVersion,
            exportedAt: exportedAt,
            exportedBy: ClipboardHistoryExporter(
                appName: "Paste-vlv",
                bundleIdentifier: Bundle.main.bundleIdentifier ?? "dev.vlv.pastevlv",
                platform: "macOS"
            ),
            pinboards: pinboards,
            items: exportedItems
        )
        return (archive, summary)
    }

    private func fetchAllItemEntities() throws -> [ClipboardItemEntity] {
        let request = NSFetchRequest<ClipboardItemEntity>(entityName: "ClipboardItemEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        return try context.fetch(request)
    }

    private func fetchAllPinboardEntities() throws -> [PinboardEntity] {
        let request = NSFetchRequest<PinboardEntity>(entityName: "PinboardEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        return try context.fetch(request)
    }

    private static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
