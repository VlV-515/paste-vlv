import Foundation

enum ClipboardKind: String, CaseIterable, Identifiable, Codable {
    case text
    case link
    case image
    case file

    var id: String { rawValue }

}

struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let kind: ClipboardKind
    let customTitle: String?
    let preview: String
    let searchableText: String
    let text: String?
    let urlString: String?
    let filePath: String?
    let attachmentPath: String?
    let sourceAppName: String?
    let sourceAppBundleID: String?
    let createdAt: Date
    let lastUsedAt: Date
    let contentHash: String
    let isFavorite: Bool
    let isPinned: Bool
    let pinboardID: UUID?
    let sortOrder: Int32
}

struct Pinboard: Identifiable, Equatable {
    let id: UUID
    let name: String
    let colorHex: String
    let sortOrder: Int16
    let createdAt: Date
}

struct CapturedClipboardContent {
    let kind: ClipboardKind
    let preview: String
    let searchableText: String
    let text: String?
    let urlString: String?
    let filePath: String?
    let attachmentPath: String?
    let rawHashInput: Data
    let sourceAppName: String?
    let sourceAppBundleID: String?
}
