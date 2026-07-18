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

final class AppSettings: ObservableObject {
    @Published var isCapturePaused: Bool {
        didSet { defaults.set(isCapturePaused, forKey: Keys.isCapturePaused) }
    }

    @Published var retentionPolicy: RetentionPolicy {
        didSet { defaults.set(retentionPolicy.rawValue, forKey: Keys.retentionPolicy) }
    }

    @Published var excludedBundleIDs: Set<String> {
        didSet { defaults.set(Array(excludedBundleIDs), forKey: Keys.excludedBundleIDs) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isCapturePaused = defaults.bool(forKey: Keys.isCapturePaused)
        let retentionRaw = defaults.string(forKey: Keys.retentionPolicy) ?? RetentionPolicy.oneMonth.rawValue
        self.retentionPolicy = RetentionPolicy(rawValue: retentionRaw) ?? .oneMonth
        let excluded = defaults.stringArray(forKey: Keys.excludedBundleIDs) ?? []
        self.excludedBundleIDs = Set(excluded)
    }

    func toggleExcluded(bundleID: String) {
        if excludedBundleIDs.contains(bundleID) {
            excludedBundleIDs.remove(bundleID)
        } else {
            excludedBundleIDs.insert(bundleID)
        }
    }

    private enum Keys {
        static let isCapturePaused = "isCapturePaused"
        static let retentionPolicy = "retentionPolicy"
        static let excludedBundleIDs = "excludedBundleIDs"
    }
}
