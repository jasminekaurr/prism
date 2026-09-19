// Summary: SwiftData-backed repository implementations for local-first Prism persistence.

import Foundation
import SwiftData
import UIKit

@MainActor
final class LocalStore {
    let modelContext: ModelContext
    let mediaDirectory: URL

    init(container: ModelContainer) {
        self.modelContext = container.mainContext
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.mediaDirectory = docs.appendingPathComponent("PrismMedia", isDirectory: true)
        try? FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
    }

    func saveContext() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}

extension LocalStore: UserProfileRepository {
    func currentProfile() async throws -> UserProfile? {
        let descriptor = FetchDescriptor<SDUserProfile>()
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func save(_ profile: UserProfile) async throws {
        let descriptor = FetchDescriptor<SDUserProfile>(predicate: #Predicate { $0.id == profile.id })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(profile)
        } else {
            modelContext.insert(SDUserProfile(from: profile))
        }
        try saveContext()
    }

    func deleteAllLocalData() async throws {
        try modelContext.delete(model: SDUserProfile.self)
        try modelContext.delete(model: SDCollection.self)
        try modelContext.delete(model: SDSavedItem.self)
        try modelContext.delete(model: SDMediaAsset.self)
        try modelContext.delete(model: SDTag.self)
        try modelContext.delete(model: SDSavedItemTag.self)
        try modelContext.delete(model: SDSavedItemFeeling.self)
        try modelContext.delete(model: SDDecisionEvent.self)
        try modelContext.delete(model: SDReviewEvent.self)
        try modelContext.delete(model: SDUserSettings.self)
        try modelContext.delete(model: SDGoal.self)
        try modelContext.delete(model: SDGoalMilestone.self)
        try modelContext.delete(model: SDGoalComponent.self)
        try modelContext.delete(model: SDGoalContribution.self)
        try modelContext.delete(model: SDGoalAspirationLink.self)
        try saveContext()
        try? FileManager.default.removeItem(at: mediaDirectory)
        try? FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
    }
}

extension LocalStore: CollectionRepository {
    func fetchAll(userID: UUID) async throws -> [PrismCollection] {
        let descriptor = FetchDescriptor<SDCollection>(
            predicate: #Predicate { $0.userID == userID && $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(id: UUID) async throws -> PrismCollection? {
        let descriptor = FetchDescriptor<SDCollection>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func upsert(_ collection: PrismCollection) async throws {
        let id = collection.id
        let descriptor = FetchDescriptor<SDCollection>(predicate: #Predicate { $0.id == id })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(collection)
        } else {
            modelContext.insert(SDCollection(from: collection))
        }
        try saveContext()
    }

    func archiveCollection(id: UUID) async throws {
        let descriptor = FetchDescriptor<SDCollection>(predicate: #Predicate { $0.id == id })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.archivedAt = .now
            existing.updatedAt = .now
            try saveContext()
        }
    }
}

extension LocalStore: SavedItemRepository {
    func fetchAll(userID: UUID) async throws -> [SavedItem] {
        let descriptor = FetchDescriptor<SDSavedItem>(
            predicate: #Predicate { $0.userID == userID && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(id: UUID) async throws -> SavedItem? {
        let descriptor = FetchDescriptor<SDSavedItem>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func fetchReadyForReview(userID: UUID, asOf date: Date) async throws -> [SavedItem] {
        let descriptor = FetchDescriptor<SDSavedItem>(
            predicate: #Predicate { $0.userID == userID && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor).map { $0.toDomain() }
        return all.filter { item in
            guard item.status == ItemStatus.considering || item.status == ItemStatus.readyForReview else { return false }
            guard let reviewAt = item.reviewAt else { return false }
            return reviewAt <= date
        }
        .map { item in
            var copy = item
            if copy.status == ItemStatus.considering { copy.status = ItemStatus.readyForReview }
            return copy
        }
    }

    func upsert(_ item: SavedItem) async throws {
        let id = item.id
        let descriptor = FetchDescriptor<SDSavedItem>(predicate: #Predicate { $0.id == id })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(item)
        } else {
            modelContext.insert(SDSavedItem(from: item))
        }
        try saveContext()
    }

    func softDeleteItem(id: UUID) async throws {
        let descriptor = FetchDescriptor<SDSavedItem>(predicate: #Predicate { $0.id == id })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.deletedAt = .now
            existing.updatedAt = .now
            try saveContext()
        }
    }
}

extension LocalStore: MediaRepository {
    func fetch(id: UUID) async throws -> MediaAsset? {
        let descriptor = FetchDescriptor<SDMediaAsset>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func upsert(_ asset: MediaAsset) async throws {
        let id = asset.id
        let descriptor = FetchDescriptor<SDMediaAsset>(predicate: #Predicate { $0.id == id })
        if try modelContext.fetch(descriptor).first == nil {
            modelContext.insert(SDMediaAsset(from: asset))
            try saveContext()
        }
    }

    func localFileURL(for asset: MediaAsset) async -> URL? {
        guard let relative = asset.localRelativePath else { return nil }
        return mediaDirectory.appendingPathComponent(relative)
    }

    func saveImageData(_ data: Data, userID: UUID, assetID: UUID) async throws -> MediaAsset {
        // Strip EXIF by re-encoding via UIImage when possible.
        let processed: Data
        if let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.82) {
            processed = jpeg
        } else {
            processed = data
        }
        let relative = "\(userID.uuidString)/\(assetID.uuidString).jpg"
        let folder = mediaDirectory.appendingPathComponent(userID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = mediaDirectory.appendingPathComponent(relative)
        try processed.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])

        // Thumbnail
        var thumbRelative: String?
        if let image = UIImage(data: processed) {
            let thumb = image.preparingThumbnail(of: CGSize(width: 400, height: 400))
            if let thumbData = thumb?.jpegData(compressionQuality: 0.7) {
                thumbRelative = "\(userID.uuidString)/\(assetID.uuidString)_thumb.jpg"
                try thumbData.write(
                    to: mediaDirectory.appendingPathComponent(thumbRelative!),
                    options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
                )
            }
        }

        let asset = MediaAsset(
            id: assetID,
            userID: userID,
            localRelativePath: relative,
            remotePath: nil,
            thumbnailRelativePath: thumbRelative,
            mimeType: "image/jpeg",
            byteSize: processed.count,
            width: nil,
            height: nil,
            createdAt: .now
        )
        try await upsert(asset)
        return asset
    }
}

extension LocalStore: TagRepository {
    func fetchAll(userID: UUID) async throws -> [Tag] {
        let descriptor = FetchDescriptor<SDTag>(predicate: #Predicate { $0.userID == userID })
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func upsert(_ tag: Tag) async throws {
        let id = tag.id
        let descriptor = FetchDescriptor<SDTag>(predicate: #Predicate { $0.id == id })
        if try modelContext.fetch(descriptor).first == nil {
            modelContext.insert(SDTag(from: tag))
            try saveContext()
        }
    }

    func tags(for itemID: UUID) async throws -> [Tag] {
        let links = FetchDescriptor<SDSavedItemTag>(predicate: #Predicate { $0.savedItemID == itemID })
        let tagIDs = Set(try modelContext.fetch(links).map(\.tagID))
        let descriptor = FetchDescriptor<SDTag>()
        return try modelContext.fetch(descriptor)
            .filter { tagIDs.contains($0.id) }
            .map { $0.toDomain() }
    }

    func setTags(_ tags: [Tag], for itemID: UUID, userID: UUID) async throws {
        let existing = FetchDescriptor<SDSavedItemTag>(predicate: #Predicate { $0.savedItemID == itemID })
        for link in try modelContext.fetch(existing) {
            modelContext.delete(link)
        }
        for tag in tags {
            try await upsert(tag)
            modelContext.insert(SDSavedItemTag(from: SavedItemTag(id: UUID(), userID: userID, savedItemID: itemID, tagID: tag.id)))
        }
        try saveContext()
    }
}

extension LocalStore: FeelingRepository {
    func allFeelings() async throws -> [Feeling] {
        Feeling.systemFeelings
    }

    func feelings(for itemID: UUID) async throws -> [Feeling] {
        let descriptor = FetchDescriptor<SDSavedItemFeeling>(predicate: #Predicate { $0.savedItemID == itemID })
        return try modelContext.fetch(descriptor).map {
            Feeling(id: $0.feelingID, name: $0.feelingName, isSystem: true)
        }
    }

    func setFeelings(_ feelings: [Feeling], for itemID: UUID, userID: UUID) async throws {
        let existing = FetchDescriptor<SDSavedItemFeeling>(predicate: #Predicate { $0.savedItemID == itemID })
        for link in try modelContext.fetch(existing) {
            modelContext.delete(link)
        }
        for feeling in feelings {
            modelContext.insert(SDSavedItemFeeling(
                id: UUID(),
                userID: userID,
                savedItemID: itemID,
                feelingID: feeling.id,
                feelingName: feeling.name
            ))
        }
        try saveContext()
    }
}

extension LocalStore: DecisionRepository {
    func events(for itemID: UUID) async throws -> [DecisionEvent] {
        let descriptor = FetchDescriptor<SDDecisionEvent>(
            predicate: #Predicate { $0.savedItemID == itemID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func append(_ event: DecisionEvent) async throws {
        modelContext.insert(SDDecisionEvent(from: event))
        try saveContext()
    }

    func latestActive(for itemID: UUID) async throws -> DecisionEvent? {
        let descriptor = FetchDescriptor<SDDecisionEvent>(
            predicate: #Predicate { $0.savedItemID == itemID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let events = try modelContext.fetch(descriptor).map { $0.toDomain() }
        return events.first { $0.decision != DecisionType.undo && $0.undoneByEventID == nil }
    }
}

extension LocalStore: ReviewEventRepository {
    func append(_ event: ReviewEvent) async throws {
        modelContext.insert(SDReviewEvent(from: event))
        try saveContext()
    }

    func events(for itemID: UUID) async throws -> [ReviewEvent] {
        let descriptor = FetchDescriptor<SDReviewEvent>(
            predicate: #Predicate { $0.savedItemID == itemID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }
}

extension LocalStore: SettingsRepository {
    func load() async throws -> UserSettings {
        let descriptor = FetchDescriptor<SDUserSettings>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing.toDomain()
        }
        return .default
    }

    func save(_ settings: UserSettings) async throws {
        let descriptor = FetchDescriptor<SDUserSettings>()
        if let existing = try modelContext.fetch(descriptor).first {
            existing.appLockEnabled = settings.appLockEnabled
            existing.analyticsEnabled = settings.analyticsEnabled
        } else {
            modelContext.insert(SDUserSettings(from: settings))
        }
        try saveContext()
    }
}

extension LocalStore: GoalRepository {
    func fetchAll(userID: UUID) async throws -> [PrismGoal] {
        let descriptor = FetchDescriptor<SDGoal>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func fetch(id: UUID) async throws -> PrismGoal? {
        let descriptor = FetchDescriptor<SDGoal>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func upsert(_ goal: PrismGoal) async throws {
        if goal.priority == .primary {
            let uid = goal.userID
            let all = FetchDescriptor<SDGoal>(predicate: #Predicate { $0.userID == uid })
            for existing in try modelContext.fetch(all) where existing.id != goal.id {
                if existing.priorityRaw == GoalPriorityLevel.primary.rawValue {
                    existing.priorityRaw = GoalPriorityLevel.active.rawValue
                    existing.updatedAt = .now
                }
            }
        }
        let id = goal.id
        let descriptor = FetchDescriptor<SDGoal>(predicate: #Predicate { $0.id == id })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(goal)
        } else {
            modelContext.insert(SDGoal(from: goal))
        }
        try saveContext()
    }

    func fetchMilestones(goalID: UUID) async throws -> [GoalMilestone] {
        let descriptor = FetchDescriptor<SDGoalMilestone>(
            predicate: #Predicate { $0.goalID == goalID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func upsertMilestone(_ milestone: GoalMilestone) async throws {
        let id = milestone.id
        let descriptor = FetchDescriptor<SDGoalMilestone>(predicate: #Predicate { $0.id == id })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.title = milestone.title
            existing.targetAmount = milestone.targetAmount
            existing.isCompleted = milestone.isCompleted
            existing.completedAt = milestone.completedAt
            existing.sortOrder = milestone.sortOrder
        } else {
            modelContext.insert(SDGoalMilestone(from: milestone))
        }
        try saveContext()
    }

    func fetchComponents(goalID: UUID) async throws -> [GoalComponent] {
        let descriptor = FetchDescriptor<SDGoalComponent>(
            predicate: #Predicate { $0.goalID == goalID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func upsertComponent(_ component: GoalComponent) async throws {
        let id = component.id
        let descriptor = FetchDescriptor<SDGoalComponent>(predicate: #Predicate { $0.id == id })
        if try modelContext.fetch(descriptor).first == nil {
            modelContext.insert(SDGoalComponent(from: component))
            try saveContext()
        }
    }

    func fetchContributions(goalID: UUID) async throws -> [GoalContribution] {
        let descriptor = FetchDescriptor<SDGoalContribution>(
            predicate: #Predicate { $0.goalID == goalID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func appendContribution(_ contribution: GoalContribution) async throws {
        modelContext.insert(SDGoalContribution(from: contribution))
        try saveContext()
    }

    func fetchLinks(goalID: UUID) async throws -> [GoalAspirationLink] {
        let descriptor = FetchDescriptor<SDGoalAspirationLink>(
            predicate: #Predicate { $0.goalID == goalID }
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func linkAspiration(_ link: GoalAspirationLink) async throws {
        modelContext.insert(SDGoalAspirationLink(from: link))
        try saveContext()
    }
}
