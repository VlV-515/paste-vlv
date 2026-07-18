import Foundation

struct ClipboardHistoryArchive: Codable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let exportedAt: Date
    let exportedBy: ClipboardHistoryExporter
    let pinboards: [ClipboardHistoryPinboard]
    let items: [ClipboardHistoryItem]

    func validated() throws -> ClipboardHistoryArchive {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw ClipboardTransferError.unsupportedSchemaVersion(schemaVersion)
        }

        var seenPinboards = Set<UUID>()
        for pinboard in pinboards {
            guard seenPinboards.insert(pinboard.id).inserted else {
                throw ClipboardTransferError.duplicatePinboardID(pinboard.id)
            }
        }

        var seenItems = Set<UUID>()
        let validPinboardIDs = Set(pinboards.map(\.id))
        for item in items {
            guard seenItems.insert(item.id).inserted else {
                throw ClipboardTransferError.duplicateItemID(item.id)
            }

            if let pinboardID = item.pinboardID,
               !validPinboardIDs.contains(pinboardID) {
                throw ClipboardTransferError.missingPinboard(pinboardID)
            }

            if item.kind == .image, item.attachmentData == nil {
                throw ClipboardTransferError.missingImageData(item.id)
            }
        }

        return self
    }
}

struct ClipboardHistoryExporter: Codable {
    let appName: String
    let bundleIdentifier: String
    let platform: String
}

struct ClipboardHistoryPinboard: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let sortOrder: Int16
    let createdAt: Date
}

struct ClipboardHistoryItem: Codable {
    let id: UUID
    let kind: ClipboardKind
    let preview: String
    let searchableText: String
    let text: String?
    let urlString: String?
    let filePaths: [String]?
    let attachmentFileName: String?
    let attachmentData: Data?
    let sourceAppName: String?
    let sourceAppBundleID: String?
    let createdAt: Date
    let contentHash: String
    let isFavorite: Bool
    let isPinned: Bool
    let pinboardID: UUID?
}

struct ClipboardHistoryImportSummary {
    let createdPinboards: Int
    let updatedPinboards: Int
    let createdItems: Int
    let updatedItems: Int

    var message: String {
        [
            "Grupos nuevos: \(createdPinboards)",
            "Grupos actualizados: \(updatedPinboards)",
            "Items nuevos: \(createdItems)",
            "Items actualizados: \(updatedItems)"
        ].joined(separator: "\n")
    }
}

enum ClipboardTransferError: LocalizedError {
    case unsupportedSchemaVersion(Int)
    case duplicatePinboardID(UUID)
    case duplicateItemID(UUID)
    case missingPinboard(UUID)
    case missingImageData(UUID)
    case missingImageAttachment(URL)
    case invalidArchive

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Versión de respaldo no soportada: \(version)."
        case .duplicatePinboardID(let id):
            return "El JSON tiene grupos duplicados con id \(id.uuidString)."
        case .duplicateItemID(let id):
            return "El JSON tiene items duplicados con id \(id.uuidString)."
        case .missingPinboard(let id):
            return "El JSON referencia un grupo inexistente: \(id.uuidString)."
        case .missingImageData(let id):
            return "Falta payload binario para imagen \(id.uuidString)."
        case .missingImageAttachment(let url):
            return "No se encontró imagen adjunta para exportar: \(url.lastPathComponent)."
        case .invalidArchive:
            return "El archivo no cumple estructura válida de respaldo Paste-vlv."
        }
    }
}
