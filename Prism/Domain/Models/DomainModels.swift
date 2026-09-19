// Summary: Domain value types for profiles, collections, saves, media, tags, feelings, and events.

import Foundation

struct UserProfile: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var displayName: String?
    var createdAt: Date
    var onboardingCompleted: Bool
    var isDemoMode: Bool
    var notificationPreferences: NotificationPreferences
    var defaultCoolingPeriods: CoolingPeriodSettings
    var spendingPocket: SpendingPocketSettings
}

struct NotificationPreferences: Codable, Equatable, Sendable {
    var coolingOffRemindersEnabled: Bool
    var permissionAsked: Bool

    static let `default` = NotificationPreferences(
        coolingOffRemindersEnabled: false,
        permissionAsked: false
    )
}

struct CoolingPeriodSettings: Codable, Equatable, Sendable {
    /// When false, new saves do not get automatic review dates.
    var enabled: Bool
    var smallHours: Int
    var consideredHours: Int
    var majorHours: Int
    var unknownHours: Int

    static let `default` = CoolingPeriodSettings(
        enabled: true,
        smallHours: 24,
        consideredHours: 72,
        majorHours: 168,
        unknownHours: 72
    )

    func hours(for significance: CostSignificance?) -> Int {
        switch significance ?? .unknown {
        case .small: return smallHours
        case .considered: return consideredHours
        case .major: return majorHours
        case .unknown: return unknownHours
        }
    }
}

/// Self-declared monthly comfort amount for wants — never inferred from bank data.
struct SpendingPocketSettings: Codable, Equatable, Sendable {
    var isEnabled: Bool
    var monthlyAmount: Decimal?
    var currencyCode: String
    /// When true, pocket is paused and not shown as a constraint.
    var isPaused: Bool

    static let `default` = SpendingPocketSettings(
        isEnabled: false,
        monthlyAmount: nil,
        currencyCode: Locale.current.currency?.identifier ?? "USD",
        isPaused: false
    )
}

struct PrismCollection: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var name: String
    var description: String?
    var coverMediaID: UUID?
    var colorTheme: String?
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?
}

struct SavedItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var collectionID: UUID?
    var title: String
    var notes: String?
    var reflection: String?
    var sourceURL: URL?
    var sourceDomain: String?
    var merchantName: String?
    var intent: SaveIntent
    var costSignificance: CostSignificance?
    var priority: ItemPriority?
    var estimatedPrice: Decimal?
    var estimatedCurrencyCode: String?
    var confirmedPurchasePrice: Decimal?
    var confirmedPurchaseCurrencyCode: String?
    var status: ItemStatus
    var primaryMediaID: UUID?
    var notificationsEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    var reviewAt: Date?
    var decidedAt: Date?
    var archivedAt: Date?
    var deletedAt: Date?
}

struct MediaAsset: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var localRelativePath: String?
    var remotePath: String?
    var thumbnailRelativePath: String?
    var mimeType: String
    var byteSize: Int
    var width: Int?
    var height: Int?
    var createdAt: Date
}

struct Tag: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var name: String
    var createdAt: Date
}

struct SavedItemTag: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var savedItemID: UUID
    var tagID: UUID
}

struct Feeling: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var isSystem: Bool

    static let systemFeelings: [Feeling] = [
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Joy", isSystem: true),
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Excitement", isSystem: true),
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Comfort", isSystem: true),
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Confidence", isSystem: true),
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "Belonging", isSystem: true),
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, name: "Curiosity", isSystem: true),
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, name: "Convenience", isSystem: true),
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!, name: "Stress relief", isSystem: true),
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!, name: "Social pressure", isSystem: true),
        Feeling(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!, name: "Other", isSystem: true)
    ]
}

struct SavedItemFeeling: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var savedItemID: UUID
    var feelingID: UUID
}

struct ReviewEvent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var savedItemID: UUID
    var scheduledAt: Date
    var completedAt: Date?
    var createdAt: Date
}

struct DecisionEvent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var savedItemID: UUID
    var decision: DecisionType
    var previousStatus: ItemStatus
    var newStatus: ItemStatus
    var confirmedPrice: Decimal?
    var currencyCode: String?
    var note: String?
    var createdAt: Date
    /// When set, this decision was undone by a later event.
    var undoneByEventID: UUID?
}

struct SyncMetadata: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var entityType: String
    var entityID: UUID
    var lastLocalEditAt: Date
    var lastSyncedAt: Date?
    var pendingUpload: Bool
}

struct UserSettings: Codable, Equatable, Sendable {
    var appLockEnabled: Bool
    var analyticsEnabled: Bool

    static let `default` = UserSettings(appLockEnabled: false, analyticsEnabled: true)
}
