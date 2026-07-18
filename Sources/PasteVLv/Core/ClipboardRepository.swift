import CoreData
import CryptoKit
import Foundation

final class ClipboardRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func bootstrapPinboardsIfNeeded() {
        let request = NSFetchRequest<PinboardEntity>(entityName: "PinboardEntity")
        request.fetchLimit = 1

        do {
            if try context.count(for: request) > 0 {
                return
            }

            [
                ("General", "#2563EB"),
                ("Links", "#059669"),
                ("Images", "#D97706")
            ].enumerated().forEach { index, data in
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

    func fetchItems(search: String, pinboardID: UUID?, limit: Int = 200) -> [ClipboardItem] {
        let request = NSFetchRequest<ClipboardItemEntity>(entityName: "ClipboardItemEntity")
        request.fetchLimit = limit
        request.sortDescriptors = [
            NSSortDescriptor(key: "isPinned", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        var predicates: [NSPredicate] = []
        if let pinboardID {
            predicates.append(NSPredicate(format: "pinboardID == %@", pinboardID as CVarArg))
        }

        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            predicates.append(
                NSPredicate(
                    format: "searchableText CONTAINS[cd] %@ OR preview CONTAINS[cd] %@ OR sourceAppName CONTAINS[cd] %@",
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
            existing.createdAt = Date()
            existing.sourceAppName = content.sourceAppName
            existing.sourceAppBundleID = content.sourceAppBundleID
            save()
            return existing.asDomain()
        }

        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.kind = content.kind.rawValue
        item.preview = content.preview
        item.searchableText = content.searchableText
        item.text = content.text
        item.urlString = content.urlString
        item.filePath = content.filePath
        item.attachmentPath = content.attachmentPath
        item.sourceAppName = content.sourceAppName
        item.sourceAppBundleID = content.sourceAppBundleID
        item.createdAt = Date()
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
        request.predicate = NSPredicate(format: "createdAt < %@ AND isPinned == NO AND isFavorite == NO", date as NSDate)
        let delete = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(delete)
            save()
        } catch {
            NSLog("Unable to clean clipboard history: \(error.localizedDescription)")
        }
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

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            NSLog("Unable to save clipboard data: \(error.localizedDescription)")
        }
    }

    private static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
