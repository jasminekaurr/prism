// Summary: SwiftData persistent models mirroring domain entities for local-first storage.

import Foundation
import SwiftData

@Model
final class SDUserProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String?
    var createdAt: Date
    var onboardingCompleted: Bool
    var isDemoMode: Bool
    var notificationJSON: Data
    var coolingJSON: Data
    var pocketJSON: Data

    init(from profile: UserProfile) {
        self.id = profile.id
        self.displayName = profile.displayName
        self.createdAt = profile.createdAt
        self.onboardingCompleted = profile.onboardingCompleted
        self.isDemoMode = profile.isDemoMode
        self.notificationJSON = (try? JSONEncoder().encode(profile.notificationPreferences)) ?? Data()
        self.coolingJSON = (try? JSONEncoder().encode(profile.defaultCoolingPeriods)) ?? Data()
        self.pocketJSON = (try? JSONEncoder().encode(profile.spendingPocket)) ?? Data()
    }

    func toDomain() -> UserProfile {
        let notifications = (try? JSONDecoder().decode(NotificationPreferences.self, from: notificationJSON)) ?? .default
        let cooling = (try? JSONDecoder().decode(CoolingPeriodSettings.self, from: coolingJSON)) ?? .default
        let pocket = (try? JSONDecoder().decode(SpendingPocketSettings.self, from: pocketJSON)) ?? .default
        return UserProfile(
            id: id,
            displayName: displayName,
            createdAt: createdAt,
            onboardingCompleted: onboardingCompleted,
            isDemoMode: isDemoMode,
            notificationPreferences: notifications,
            defaultCoolingPeriods: cooling,
            spendingPocket: pocket
        )
    }

    func apply(_ profile: UserProfile) {
        displayName = profile.displayName
        onboardingCompleted = profile.onboardingCompleted
        isDemoMode = profile.isDemoMode
        notificationJSON = (try? JSONEncoder().encode(profile.notificationPreferences)) ?? notificationJSON
        coolingJSON = (try? JSONEncoder().encode(profile.defaultCoolingPeriods)) ?? coolingJSON
        pocketJSON = (try? JSONEncoder().encode(profile.spendingPocket)) ?? pocketJSON
    }
}

@Model
final class SDCollection {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var name: String
    var collectionDescription: String?
    var coverMediaID: UUID?
    var colorTheme: String?
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    init(from c: PrismCollection) {
        self.id = c.id
        self.userID = c.userID
        self.name = c.name
        self.collectionDescription = c.description
        self.coverMediaID = c.coverMediaID
        self.colorTheme = c.colorTheme
        self.createdAt = c.createdAt
        self.updatedAt = c.updatedAt
        self.archivedAt = c.archivedAt
    }

    func toDomain() -> PrismCollection {
        PrismCollection(
            id: id,
            userID: userID,
            name: name,
            description: collectionDescription,
            coverMediaID: coverMediaID,
            colorTheme: colorTheme,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt
        )
    }

    func apply(_ c: PrismCollection) {
        name = c.name
        collectionDescription = c.description
        coverMediaID = c.coverMediaID
        colorTheme = c.colorTheme
        updatedAt = c.updatedAt
        archivedAt = c.archivedAt
    }
}

@Model
final class SDSavedItem {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var collectionID: UUID?
    var title: String
    var notes: String?
    var reflection: String?
    var sourceURLString: String?
    var sourceDomain: String?
    var merchantName: String?
    var intentRaw: String
    var costSignificanceRaw: String?
    var priorityRaw: String?
    var estimatedPrice: Decimal?
    var estimatedCurrencyCode: String?
    var confirmedPurchasePrice: Decimal?
    var confirmedPurchaseCurrencyCode: String?
    var statusRaw: String
    var primaryMediaID: UUID?
    var notificationsEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    var reviewAt: Date?
    var decidedAt: Date?
    var archivedAt: Date?
    var deletedAt: Date?

    init(from item: SavedItem) {
        self.id = item.id
        self.userID = item.userID
        self.collectionID = item.collectionID
        self.title = item.title
        self.notes = item.notes
        self.reflection = item.reflection
        self.sourceURLString = item.sourceURL?.absoluteString
        self.sourceDomain = item.sourceDomain
        self.merchantName = item.merchantName
        self.intentRaw = item.intent.rawValue
        self.costSignificanceRaw = item.costSignificance?.rawValue
        self.priorityRaw = item.priority?.rawValue
        self.estimatedPrice = item.estimatedPrice
        self.estimatedCurrencyCode = item.estimatedCurrencyCode
        self.confirmedPurchasePrice = item.confirmedPurchasePrice
        self.confirmedPurchaseCurrencyCode = item.confirmedPurchaseCurrencyCode
        self.statusRaw = item.status.rawValue
        self.primaryMediaID = item.primaryMediaID
        self.notificationsEnabled = item.notificationsEnabled
        self.createdAt = item.createdAt
        self.updatedAt = item.updatedAt
        self.reviewAt = item.reviewAt
        self.decidedAt = item.decidedAt
        self.archivedAt = item.archivedAt
        self.deletedAt = item.deletedAt
    }

    func toDomain() -> SavedItem {
        SavedItem(
            id: id,
            userID: userID,
            collectionID: collectionID,
            title: title,
            notes: notes,
            reflection: reflection,
            sourceURL: sourceURLString.flatMap(URL.init(string:)),
            sourceDomain: sourceDomain,
            merchantName: merchantName,
            intent: SaveIntent(rawValue: intentRaw) ?? .want,
            costSignificance: costSignificanceRaw.flatMap(CostSignificance.init(rawValue:)),
            priority: priorityRaw.flatMap(ItemPriority.init(rawValue:)),
            estimatedPrice: estimatedPrice,
            estimatedCurrencyCode: estimatedCurrencyCode,
            confirmedPurchasePrice: confirmedPurchasePrice,
            confirmedPurchaseCurrencyCode: confirmedPurchaseCurrencyCode,
            status: ItemStatus(rawValue: statusRaw) ?? .considering,
            primaryMediaID: primaryMediaID,
            notificationsEnabled: notificationsEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
            reviewAt: reviewAt,
            decidedAt: decidedAt,
            archivedAt: archivedAt,
            deletedAt: deletedAt
        )
    }

    func apply(_ item: SavedItem) {
        collectionID = item.collectionID
        title = item.title
        notes = item.notes
        reflection = item.reflection
        sourceURLString = item.sourceURL?.absoluteString
        sourceDomain = item.sourceDomain
        merchantName = item.merchantName
        intentRaw = item.intent.rawValue
        costSignificanceRaw = item.costSignificance?.rawValue
        priorityRaw = item.priority?.rawValue
        estimatedPrice = item.estimatedPrice
        estimatedCurrencyCode = item.estimatedCurrencyCode
        confirmedPurchasePrice = item.confirmedPurchasePrice
        confirmedPurchaseCurrencyCode = item.confirmedPurchaseCurrencyCode
        statusRaw = item.status.rawValue
        primaryMediaID = item.primaryMediaID
        notificationsEnabled = item.notificationsEnabled
        updatedAt = item.updatedAt
        reviewAt = item.reviewAt
        decidedAt = item.decidedAt
        archivedAt = item.archivedAt
        deletedAt = item.deletedAt
    }
}

@Model
final class SDMediaAsset {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var localRelativePath: String?
    var remotePath: String?
    var thumbnailRelativePath: String?
    var mimeType: String
    var byteSize: Int
    var width: Int?
    var height: Int?
    var createdAt: Date

    init(from asset: MediaAsset) {
        self.id = asset.id
        self.userID = asset.userID
        self.localRelativePath = asset.localRelativePath
        self.remotePath = asset.remotePath
        self.thumbnailRelativePath = asset.thumbnailRelativePath
        self.mimeType = asset.mimeType
        self.byteSize = asset.byteSize
        self.width = asset.width
        self.height = asset.height
        self.createdAt = asset.createdAt
    }

    func toDomain() -> MediaAsset {
        MediaAsset(
            id: id,
            userID: userID,
            localRelativePath: localRelativePath,
            remotePath: remotePath,
            thumbnailRelativePath: thumbnailRelativePath,
            mimeType: mimeType,
            byteSize: byteSize,
            width: width,
            height: height,
            createdAt: createdAt
        )
    }
}

@Model
final class SDTag {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var name: String
    var createdAt: Date

    init(from tag: Tag) {
        self.id = tag.id
        self.userID = tag.userID
        self.name = tag.name
        self.createdAt = tag.createdAt
    }

    func toDomain() -> Tag {
        Tag(id: id, userID: userID, name: name, createdAt: createdAt)
    }
}

@Model
final class SDSavedItemTag {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var savedItemID: UUID
    var tagID: UUID

    init(from link: SavedItemTag) {
        self.id = link.id
        self.userID = link.userID
        self.savedItemID = link.savedItemID
        self.tagID = link.tagID
    }
}

@Model
final class SDSavedItemFeeling {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var savedItemID: UUID
    var feelingID: UUID
    var feelingName: String

    init(id: UUID, userID: UUID, savedItemID: UUID, feelingID: UUID, feelingName: String) {
        self.id = id
        self.userID = userID
        self.savedItemID = savedItemID
        self.feelingID = feelingID
        self.feelingName = feelingName
    }
}

@Model
final class SDDecisionEvent {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var savedItemID: UUID
    var decisionRaw: String
    var previousStatusRaw: String
    var newStatusRaw: String
    var confirmedPrice: Decimal?
    var currencyCode: String?
    var note: String?
    var createdAt: Date
    var undoneByEventID: UUID?

    init(from event: DecisionEvent) {
        self.id = event.id
        self.userID = event.userID
        self.savedItemID = event.savedItemID
        self.decisionRaw = event.decision.rawValue
        self.previousStatusRaw = event.previousStatus.rawValue
        self.newStatusRaw = event.newStatus.rawValue
        self.confirmedPrice = event.confirmedPrice
        self.currencyCode = event.currencyCode
        self.note = event.note
        self.createdAt = event.createdAt
        self.undoneByEventID = event.undoneByEventID
    }

    func toDomain() -> DecisionEvent {
        DecisionEvent(
            id: id,
            userID: userID,
            savedItemID: savedItemID,
            decision: DecisionType(rawValue: decisionRaw) ?? .keepConsidering,
            previousStatus: ItemStatus(rawValue: previousStatusRaw) ?? .considering,
            newStatus: ItemStatus(rawValue: newStatusRaw) ?? .considering,
            confirmedPrice: confirmedPrice,
            currencyCode: currencyCode,
            note: note,
            createdAt: createdAt,
            undoneByEventID: undoneByEventID
        )
    }
}

@Model
final class SDReviewEvent {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var savedItemID: UUID
    var scheduledAt: Date
    var completedAt: Date?
    var createdAt: Date

    init(from event: ReviewEvent) {
        self.id = event.id
        self.userID = event.userID
        self.savedItemID = event.savedItemID
        self.scheduledAt = event.scheduledAt
        self.completedAt = event.completedAt
        self.createdAt = event.createdAt
    }

    func toDomain() -> ReviewEvent {
        ReviewEvent(
            id: id,
            userID: userID,
            savedItemID: savedItemID,
            scheduledAt: scheduledAt,
            completedAt: completedAt,
            createdAt: createdAt
        )
    }
}

@Model
final class SDUserSettings {
    var id: UUID
    var appLockEnabled: Bool
    var analyticsEnabled: Bool

    init(from settings: UserSettings) {
        self.id = UUID()
        self.appLockEnabled = settings.appLockEnabled
        self.analyticsEnabled = settings.analyticsEnabled
    }

    func toDomain() -> UserSettings {
        UserSettings(appLockEnabled: appLockEnabled, analyticsEnabled: analyticsEnabled)
    }
}

enum PrismModelContainerFactory {
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            SDUserProfile.self,
            SDCollection.self,
            SDSavedItem.self,
            SDMediaAsset.self,
            SDTag.self,
            SDSavedItemTag.self,
            SDSavedItemFeeling.self,
            SDDecisionEvent.self,
            SDReviewEvent.self,
            SDUserSettings.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: config)
    }
}
