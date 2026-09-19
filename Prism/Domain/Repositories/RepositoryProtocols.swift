// Summary: Repository protocol abstractions so UI stays independent of SwiftData or future Supabase.

import Foundation

protocol UserProfileRepository: Sendable {
    func currentProfile() async throws -> UserProfile?
    func save(_ profile: UserProfile) async throws
    func deleteAllLocalData() async throws
}

protocol CollectionRepository: Sendable {
    func fetchAll(userID: UUID) async throws -> [PrismCollection]
    func fetch(id: UUID) async throws -> PrismCollection?
    func upsert(_ collection: PrismCollection) async throws
    func archiveCollection(id: UUID) async throws
}

protocol SavedItemRepository: Sendable {
    func fetchAll(userID: UUID) async throws -> [SavedItem]
    func fetch(id: UUID) async throws -> SavedItem?
    func fetchReadyForReview(userID: UUID, asOf date: Date) async throws -> [SavedItem]
    func upsert(_ item: SavedItem) async throws
    func softDeleteItem(id: UUID) async throws
}

protocol MediaRepository: Sendable {
    func fetch(id: UUID) async throws -> MediaAsset?
    func upsert(_ asset: MediaAsset) async throws
    func localFileURL(for asset: MediaAsset) async -> URL?
    func saveImageData(_ data: Data, userID: UUID, assetID: UUID) async throws -> MediaAsset
}

protocol TagRepository: Sendable {
    func fetchAll(userID: UUID) async throws -> [Tag]
    func upsert(_ tag: Tag) async throws
    func tags(for itemID: UUID) async throws -> [Tag]
    func setTags(_ tags: [Tag], for itemID: UUID, userID: UUID) async throws
}

protocol FeelingRepository: Sendable {
    func allFeelings() async throws -> [Feeling]
    func feelings(for itemID: UUID) async throws -> [Feeling]
    func setFeelings(_ feelings: [Feeling], for itemID: UUID, userID: UUID) async throws
}

protocol DecisionRepository: Sendable {
    func events(for itemID: UUID) async throws -> [DecisionEvent]
    func append(_ event: DecisionEvent) async throws
    func latestActive(for itemID: UUID) async throws -> DecisionEvent?
}

protocol ReviewEventRepository: Sendable {
    func append(_ event: ReviewEvent) async throws
    func events(for itemID: UUID) async throws -> [ReviewEvent]
}

protocol SettingsRepository: Sendable {
    func load() async throws -> UserSettings
    func save(_ settings: UserSettings) async throws
}

/// Future cloud auth surface — unused for local MVP.
protocol AuthRepository: Sendable {
    var isSignedIn: Bool { get async }
    func signInWithApple(idToken: String, nonce: String) async throws -> UserProfile
    func signOut() async throws
    func deleteAccount() async throws
}
