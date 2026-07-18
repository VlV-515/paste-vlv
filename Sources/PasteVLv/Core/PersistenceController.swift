import CoreData
import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentCloudKitContainer(name: "PasteVLv", managedObjectModel: model)

        let description = NSPersistentStoreDescription(url: Self.storeURL)
        description.type = NSSQLiteStoreType
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.cloudKitContainerOptions = nil

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions = [description]
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unable to load PasteVLv store: \(error)")
            }
        }
    }

    func saveIfNeeded() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            NSLog("Unable to save PasteVLv context: \(error.localizedDescription)")
        }
    }

    static var applicationSupportURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = base.appendingPathComponent("PasteVLv", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var attachmentsURL: URL {
        let url = applicationSupportURL.appendingPathComponent("Attachments", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static var storeURL: URL {
        applicationSupportURL.appendingPathComponent("PasteVLv.sqlite")
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [makeClipboardItemEntity(), makePinboardEntity()]
        return model
    }

    private static func makeClipboardItemEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ClipboardItemEntity"
        entity.managedObjectClassName = NSStringFromClass(ClipboardItemEntity.self)

        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("kind", .stringAttributeType),
            attribute("preview", .stringAttributeType),
            attribute("searchableText", .stringAttributeType),
            attribute("text", .stringAttributeType, optional: true),
            attribute("urlString", .stringAttributeType, optional: true),
            attribute("filePath", .stringAttributeType, optional: true),
            attribute("attachmentPath", .stringAttributeType, optional: true),
            attribute("sourceAppName", .stringAttributeType, optional: true),
            attribute("sourceAppBundleID", .stringAttributeType, optional: true),
            attribute("createdAt", .dateAttributeType),
            attribute("contentHash", .stringAttributeType),
            attribute("isFavorite", .booleanAttributeType, defaultValue: false),
            attribute("isPinned", .booleanAttributeType, defaultValue: false),
            attribute("pinboardID", .UUIDAttributeType, optional: true)
        ]

        return entity
    }

    private static func makePinboardEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PinboardEntity"
        entity.managedObjectClassName = NSStringFromClass(PinboardEntity.self)

        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("colorHex", .stringAttributeType),
            attribute("sortOrder", .integer16AttributeType),
            attribute("createdAt", .dateAttributeType)
        ]

        return entity
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }
}
