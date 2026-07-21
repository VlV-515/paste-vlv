import CoreData
import Foundation

@objc(ClipboardItemEntity)
final class ClipboardItemEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var kind: String
    @NSManaged var customTitle: String?
    @NSManaged var preview: String
    @NSManaged var searchableText: String
    @NSManaged var text: String?
    @NSManaged var urlString: String?
    @NSManaged var filePath: String?
    @NSManaged var attachmentPath: String?
    @NSManaged var sourceAppName: String?
    @NSManaged var sourceAppBundleID: String?
    @NSManaged var createdAt: Date
    @NSManaged var contentHash: String
    @NSManaged var isFavorite: Bool
    @NSManaged var isPinned: Bool
    @NSManaged var pinboardID: UUID?
}

@objc(PinboardEntity)
final class PinboardEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var colorHex: String
    @NSManaged var sortOrder: Int16
    @NSManaged var createdAt: Date
}

extension ClipboardItemEntity {
    func asDomain() -> ClipboardItem {
        ClipboardItem(
            id: id,
            kind: ClipboardKind(rawValue: kind) ?? .text,
            customTitle: customTitle,
            preview: preview,
            searchableText: searchableText,
            text: text,
            urlString: urlString,
            filePath: filePath,
            attachmentPath: attachmentPath,
            sourceAppName: sourceAppName,
            sourceAppBundleID: sourceAppBundleID,
            createdAt: createdAt,
            contentHash: contentHash,
            isFavorite: isFavorite,
            isPinned: isPinned,
            pinboardID: pinboardID
        )
    }
}

extension PinboardEntity {
    func asDomain() -> Pinboard {
        Pinboard(
            id: id,
            name: name,
            colorHex: colorHex,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }
}
