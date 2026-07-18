import Foundation

enum ClipboardKind: String, CaseIterable, Identifiable {
    case text
    case link
    case image
    case file

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: return "Text"
        case .link: return "Link"
        case .image: return "Image"
        case .file: return "File"
        }
    }
}

struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let kind: ClipboardKind
    let preview: String
    let searchableText: String
    let text: String?
    let urlString: String?
    let filePath: String?
    let attachmentPath: String?
    let sourceAppName: String?
    let sourceAppBundleID: String?
    let createdAt: Date
    let contentHash: String
    let isFavorite: Bool
    let isPinned: Bool
    let pinboardID: UUID?
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
