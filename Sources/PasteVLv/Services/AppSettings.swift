import Carbon.HIToolbox
import Foundation

enum RetentionPolicy: String, CaseIterable, Identifiable {
    case oneDay
    case oneWeek
    case oneMonth
    case oneYear
    case forever

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneDay: return "1 day"
        case .oneWeek: return "1 week"
        case .oneMonth: return "1 month"
        case .oneYear: return "1 year"
        case .forever: return "Forever"
        }
    }

    var cutoffDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .oneDay:
            return calendar.date(byAdding: .day, value: -1, to: Date())
        case .oneWeek:
            return calendar.date(byAdding: .day, value: -7, to: Date())
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: Date())
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: Date())
        case .forever:
            return nil
        }
    }
}

struct HotKeyShortcut: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    let displayName: String

    static let defaultOpen = HotKeyShortcut(
        keyCode: UInt32(kVK_ANSI_Semicolon),
        modifiers: UInt32(cmdKey | shiftKey),
        displayName: "⇧⌘Ñ"
    )
}

final class AppSettings: ObservableObject {
    @Published var launchAtLoginEnabled: Bool {
        didSet { defaults.set(launchAtLoginEnabled, forKey: Keys.launchAtLoginEnabled) }
    }

    @Published var directPasteEnabled: Bool {
        didSet { defaults.set(directPasteEnabled, forKey: Keys.directPasteEnabled) }
    }

    @Published var pastePlainTextByDefault: Bool {
        didSet { defaults.set(pastePlainTextByDefault, forKey: Keys.pastePlainTextByDefault) }
    }

    @Published var soundEffectsEnabled: Bool {
        didSet { defaults.set(soundEffectsEnabled, forKey: Keys.soundEffectsEnabled) }
    }

    @Published var showMenuBarIcon: Bool {
        didSet { defaults.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon) }
    }

    @Published var isCapturePaused: Bool {
        didSet { defaults.set(isCapturePaused, forKey: Keys.isCapturePaused) }
    }

    @Published var retentionPolicy: RetentionPolicy {
        didSet { defaults.set(retentionPolicy.rawValue, forKey: Keys.retentionPolicy) }
    }

    @Published var excludedBundleIDs: Set<String> {
        didSet { defaults.set(Array(excludedBundleIDs), forKey: Keys.excludedBundleIDs) }
    }

    @Published var openShortcut: HotKeyShortcut {
        didSet { saveShortcut(openShortcut, key: Keys.openShortcut) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.launchAtLoginEnabled = defaults.bool(forKey: Keys.launchAtLoginEnabled)
        self.directPasteEnabled = defaults.object(forKey: Keys.directPasteEnabled) as? Bool ?? true
        self.pastePlainTextByDefault = defaults.bool(forKey: Keys.pastePlainTextByDefault)
        self.soundEffectsEnabled = defaults.bool(forKey: Keys.soundEffectsEnabled)
        self.showMenuBarIcon = defaults.object(forKey: Keys.showMenuBarIcon) as? Bool ?? true
        self.isCapturePaused = defaults.bool(forKey: Keys.isCapturePaused)
        let retentionRaw = defaults.string(forKey: Keys.retentionPolicy) ?? RetentionPolicy.oneMonth.rawValue
        self.retentionPolicy = RetentionPolicy(rawValue: retentionRaw) ?? .oneMonth
        let excluded = defaults.stringArray(forKey: Keys.excludedBundleIDs) ?? []
        self.excludedBundleIDs = Set(excluded)
        self.openShortcut = Self.loadShortcut(defaults: defaults, key: Keys.openShortcut) ?? .defaultOpen
    }

    func toggleExcluded(bundleID: String) {
        if excludedBundleIDs.contains(bundleID) {
            excludedBundleIDs.remove(bundleID)
        } else {
            excludedBundleIDs.insert(bundleID)
        }
    }

    private func saveShortcut(_ shortcut: HotKeyShortcut, key: String) {
        guard let data = try? JSONEncoder().encode(shortcut) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadShortcut(defaults: UserDefaults, key: String) -> HotKeyShortcut? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(HotKeyShortcut.self, from: data)
    }

    private enum Keys {
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let directPasteEnabled = "directPasteEnabled"
        static let pastePlainTextByDefault = "pastePlainTextByDefault"
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let isCapturePaused = "isCapturePaused"
        static let retentionPolicy = "retentionPolicy"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let openShortcut = "openShortcut"
    }
}
