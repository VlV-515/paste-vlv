import Foundation

struct ClipboardHistoryArchive: Codable {
    static let currentSchemaVersion = 2

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

            guard let pinboardID = item.pinboardID else {
                throw ClipboardTransferError.missingPinboardAssignment(item.id)
            }

            if !validPinboardIDs.contains(pinboardID) {
                throw ClipboardTransferError.missingPinboard(pinboardID)
            }

            if item.kind != .text {
                throw ClipboardTransferError.unsupportedItemKind(item.kind)
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
    let sourceAppName: String?
    let sourceAppBundleID: String?
    let createdAt: Date
    let contentHash: String
    let isFavorite: Bool
    let isPinned: Bool
    let pinboardID: UUID?
}

struct ClipboardHistoryExportSummary {
    let exportedPinboards: Int
    let exportedItems: Int
    let omittedUngroupedItems: Int
    let omittedNonTextGroupedItems: Int

    var message: String {
        [
            "Respaldo guardado.",
            "Grupos exportados: \(exportedPinboards)",
            "Textos exportados: \(exportedItems)",
            "",
            "Aviso:",
            "Historial general sin grupo omitido: \(omittedUngroupedItems)",
            "Items no-texto dentro de grupos omitidos: \(omittedNonTextGroupedItems)",
            "Razón: exportar todo, sobre todo imágenes, expande mucho JSON."
        ].joined(separator: "\n")
    }
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
            "Textos nuevos: \(createdItems)",
            "Textos actualizados: \(updatedItems)"
        ].joined(separator: "\n")
    }
}

enum ClipboardTransferError: LocalizedError {
    case unsupportedSchemaVersion(Int)
    case duplicatePinboardID(UUID)
    case duplicateItemID(UUID)
    case missingPinboardAssignment(UUID)
    case missingPinboard(UUID)
    case unsupportedItemKind(ClipboardKind)
    case invalidArchive

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Versión de respaldo no soportada: \(version)."
        case .duplicatePinboardID(let id):
            return "El JSON tiene grupos duplicados con id \(id.uuidString)."
        case .duplicateItemID(let id):
            return "El JSON tiene items duplicados con id \(id.uuidString)."
        case .missingPinboardAssignment(let id):
            return "El JSON tiene texto sin grupo asignado: \(id.uuidString)."
        case .missingPinboard(let id):
            return "El JSON referencia un grupo inexistente: \(id.uuidString)."
        case .unsupportedItemKind(let kind):
            return "El JSON solo admite textos agrupados. Item no soportado: \(kind.rawValue)."
        case .invalidArchive:
            return "El archivo no cumple estructura válida de respaldo Paste-vlv."
        }
    }
}
