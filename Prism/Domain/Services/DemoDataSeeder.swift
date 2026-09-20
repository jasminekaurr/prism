// Summary: Seeds local demo collections + Figma sample aspirations with bundled media.

import Foundation
import UIKit

enum DemoDataSeeder {
    private static let seededKey = "prism.demo.figmaSeeded.v1"

    /// Idempotent: only seeds once per install unless forced.
    @MainActor
    static func seedIfNeeded(
        userID: UUID,
        container: DependencyContainer,
        force: Bool = false
    ) async {
        if !force, UserDefaults.standard.bool(forKey: seededKey) { return }
        let existing = (try? await container.savedItemRepository.fetchAll(userID: userID)) ?? []
        if !force, !existing.isEmpty {
            UserDefaults.standard.set(true, forKey: seededKey)
            return
        }

        let fashionID = UUID()
        let homeID = UUID()
        let concertID = UUID()
        let now = Date()

        let collections: [PrismCollection] = [
            .init(id: fashionID, userID: userID, name: "Summer Fashion", description: "Warm-weather wants", coverMediaID: nil, colorTheme: nil, createdAt: now, updatedAt: now, archivedAt: nil),
            .init(id: homeID, userID: userID, name: "Home", description: "Apartment & cleaning", coverMediaID: nil, colorTheme: nil, createdAt: now, updatedAt: now, archivedAt: nil),
            .init(id: concertID, userID: userID, name: "Concerts", description: "Live experiences", coverMediaID: nil, colorTheme: nil, createdAt: now, updatedAt: now, archivedAt: nil)
        ]
        for collection in collections {
            try? await container.collectionRepository.upsert(collection)
        }

        struct Sample {
            let title: String
            let collectionID: UUID
            let intent: SaveIntent
            let cost: CostSignificance
            let assetName: String
            let url: String
            let domain: String
        }

        let samples: [Sample] = [
            .init(title: "Convertible flats-to-heels sandal", collectionID: fashionID, intent: .want, cost: .small, assetName: "DemoHeels", url: "https://www.instagram.com/reel/demo-heels/", domain: "instagram.com"),
            .init(title: "Active washing machine cleaner", collectionID: homeID, intent: .need, cost: .major, assetName: "DemoCleaner", url: "https://www.instagram.com/p/demo-cleaner/", domain: "instagram.com"),
            .init(title: "Orange suede clog sandal", collectionID: fashionID, intent: .want, cost: .considered, assetName: "DemoClogs", url: "https://www.instagram.com/p/demo-clogs/", domain: "instagram.com"),
            .init(title: "Strappy summer sandal", collectionID: fashionID, intent: .want, cost: .small, assetName: "DemoSandals", url: "https://www.instagram.com/reel/demo-sandals/", domain: "instagram.com"),
            .init(title: "Coldplay Live in Las Vegas", collectionID: concertID, intent: .dream, cost: .major, assetName: "DemoConcert", url: "https://www.instagram.com/p/demo-coldplay/", domain: "instagram.com")
        ]

        for (index, sample) in samples.enumerated() {
            guard let image = UIImage(named: sample.assetName),
                  let data = image.jpegData(compressionQuality: 0.85) else { continue }
            let mediaID = UUID()
            let itemID = UUID()
            _ = try? await container.mediaRepository.saveImageData(data, userID: userID, assetID: mediaID)
            // First item is already due for Review so that tab isn't empty.
            let reviewAt = index == 0
                ? Calendar.current.date(byAdding: .hour, value: -1, to: now)
                : Calendar.current.date(byAdding: .day, value: 2, to: now)
            let item = SavedItem(
                id: itemID,
                userID: userID,
                collectionID: sample.collectionID,
                title: sample.title,
                notes: nil,
                reflection: nil,
                sourceURL: URL(string: sample.url),
                sourceDomain: sample.domain,
                merchantName: nil,
                intent: sample.intent,
                costSignificance: sample.cost,
                priority: .undecided,
                estimatedPrice: nil,
                estimatedCurrencyCode: nil,
                confirmedPurchasePrice: nil,
                confirmedPurchaseCurrencyCode: nil,
                status: index == 0 ? .readyForReview : .considering,
                primaryMediaID: mediaID,
                notificationsEnabled: true,
                createdAt: now,
                updatedAt: now,
                reviewAt: reviewAt,
                decidedAt: nil,
                archivedAt: nil,
                deletedAt: nil
            )
            try? await container.savedItemRepository.upsert(item)
        }

        UserDefaults.standard.set(true, forKey: seededKey)
    }
}
