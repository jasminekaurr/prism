// Summary: Seeds local demo collections, sample aspirations, and MacBook-style goals matching recreation screens.

import Foundation
import UIKit

enum DemoDataSeeder {
    private static let seededKey = "prism.demo.recreationSeeded.v1"
    private static let goalsSeededKey = "prism.demo.goalsSeeded.v1"

    @MainActor
    static func seedIfNeeded(
        userID: UUID,
        container: DependencyContainer,
        force: Bool = false
    ) async {
        if force || !UserDefaults.standard.bool(forKey: seededKey) {
            let existing = (try? await container.savedItemRepository.fetchAll(userID: userID)) ?? []
            if force || existing.isEmpty {
                await seedCollectionsAndSaves(userID: userID, container: container)
            }
            UserDefaults.standard.set(true, forKey: seededKey)
        }

        if force || !UserDefaults.standard.bool(forKey: goalsSeededKey) {
            let existingGoals = (try? await container.goalRepository.fetchAll(userID: userID)) ?? []
            if force || existingGoals.isEmpty {
                await seedGoals(userID: userID, container: container)
            }
            UserDefaults.standard.set(true, forKey: goalsSeededKey)
        }
    }

    @MainActor
    private static func seedCollectionsAndSaves(userID: UUID, container: DependencyContainer) async {
        let fashionID = UUID()
        let homeID = UUID()
        let concertID = UUID()
        let techID = UUID()
        let now = Date()

        let collections: [PrismCollection] = [
            .init(id: fashionID, userID: userID, name: "Summer Fashion", description: "Warm-weather wants", coverMediaID: nil, colorTheme: nil, createdAt: now, updatedAt: now, archivedAt: nil),
            .init(id: homeID, userID: userID, name: "Home", description: "Apartment & cleaning", coverMediaID: nil, colorTheme: nil, createdAt: now, updatedAt: now, archivedAt: nil),
            .init(id: concertID, userID: userID, name: "Concerts", description: "Live experiences", coverMediaID: nil, colorTheme: nil, createdAt: now, updatedAt: now, archivedAt: nil),
            .init(id: techID, userID: userID, name: "Tech", description: "Devices & gear", coverMediaID: nil, colorTheme: nil, createdAt: now, updatedAt: now, archivedAt: nil)
        ]
        for collection in collections {
            try? await container.collectionRepository.upsert(collection)
        }

        struct Sample {
            let title: String
            let collectionID: UUID
            let intent: SaveIntent
            let cost: CostSignificance
            let assetName: String?
            let url: String
            let domain: String
            let price: Decimal?
            let merchant: String?
            let reflection: String?
        }

        let samples: [Sample] = [
            .init(title: "Convertible flats-to-heels sandal", collectionID: fashionID, intent: .want, cost: .small, assetName: "DemoHeels", url: "https://www.instagram.com/reel/demo-heels/", domain: "instagram.com", price: nil, merchant: "viceversa", reflection: "I think it would be a versatile shoe for the summer. I don't have to worry about my feet hurting."),
            .init(title: "Active washing machine cleaner", collectionID: homeID, intent: .need, cost: .major, assetName: "DemoCleaner", url: "https://www.instagram.com/p/demo-cleaner/", domain: "instagram.com", price: nil, merchant: nil, reflection: nil),
            .init(title: "Orange suede clog sandal", collectionID: fashionID, intent: .want, cost: .considered, assetName: "DemoClogs", url: "https://www.instagram.com/p/demo-clogs/", domain: "instagram.com", price: nil, merchant: nil, reflection: nil),
            .init(title: "Strappy summer sandal", collectionID: fashionID, intent: .want, cost: .small, assetName: "DemoSandals", url: "https://www.instagram.com/reel/demo-sandals/", domain: "instagram.com", price: nil, merchant: nil, reflection: nil),
            .init(title: "Coldplay Live in Las Vegas", collectionID: concertID, intent: .dream, cost: .major, assetName: "DemoConcert", url: "https://www.instagram.com/p/demo-coldplay/", domain: "instagram.com", price: 240, merchant: nil, reflection: nil),
            .init(
                title: "MacBook Air 13” M4",
                collectionID: techID,
                intent: .need,
                cost: .major,
                assetName: nil,
                url: "https://www.apple.com/macbook-air/",
                domain: "apple.com",
                price: 1_199,
                merchant: "Apple",
                reflection: "My 2019 Air can't handle the video edits for class. A 40-minute export would take five."
            )
        ]

        for (index, sample) in samples.enumerated() {
            var mediaID: UUID?
            if let assetName = sample.assetName,
               let image = UIImage(named: assetName),
               let data = image.jpegData(compressionQuality: 0.85) {
                let id = UUID()
                _ = try? await container.mediaRepository.saveImageData(data, userID: userID, assetID: id)
                mediaID = id
            }
            let reviewAt = index == 0
                ? Calendar.current.date(byAdding: .hour, value: -1, to: now)
                : Calendar.current.date(byAdding: .day, value: 2, to: now)
            let item = SavedItem(
                id: UUID(),
                userID: userID,
                collectionID: sample.collectionID,
                title: sample.title,
                notes: nil,
                reflection: sample.reflection,
                sourceURL: URL(string: sample.url),
                sourceDomain: sample.domain,
                merchantName: sample.merchant,
                intent: sample.intent,
                costSignificance: sample.cost,
                priority: index == 0 ? .mustHave : .undecided,
                estimatedPrice: sample.price,
                estimatedCurrencyCode: sample.price == nil ? nil : "USD",
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
    }

    @MainActor
    private static func seedGoals(userID: UUID, container: DependencyContainer) async {
        let now = Date()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt

        let japanDate = cal.date(from: DateComponents(year: 2027, month: 4, day: 1)) ?? now
        let laptopDate = cal.date(from: DateComponents(year: 2027, month: 3, day: 1)) ?? now
        let concertDate = cal.date(from: DateComponents(year: 2026, month: 12, day: 15)) ?? now

        let japanID = UUID()
        let laptopID = UUID()
        let concertID = UUID()
        let sofaID = UUID()
        let kyotoID = UUID()

        let goals: [PrismGoal] = [
            PrismGoal(
                id: japanID,
                userID: userID,
                sourceAspirationID: nil,
                title: "Japan",
                goalDescription: "April 2027 trip",
                type: .travel,
                motivation: .withSomeone,
                customMotivation: nil,
                targetAmount: 4_500,
                currencyCode: "USD",
                amountSaved: 1_575,
                targetDate: japanDate,
                contributionFrequency: .monthly,
                priority: .primary,
                includesBuffer: true,
                trackStatus: .onTrack,
                createdAt: now,
                updatedAt: now,
                completedAt: nil,
                pausedAt: nil
            ),
            PrismGoal(
                id: laptopID,
                userID: userID,
                sourceAspirationID: nil,
                title: "New laptop",
                goalDescription: "Before spring term",
                type: .purchase,
                motivation: .personalGrowth,
                customMotivation: nil,
                targetAmount: 1_199,
                currencyCode: "USD",
                amountSaved: 150,
                targetDate: laptopDate,
                contributionFrequency: .monthly,
                priority: .active,
                includesBuffer: true,
                trackStatus: .onTrack,
                createdAt: now,
                updatedAt: now,
                completedAt: nil,
                pausedAt: nil
            ),
            PrismGoal(
                id: concertID,
                userID: userID,
                sourceAspirationID: nil,
                title: "Concert tickets",
                goalDescription: nil,
                type: .experience,
                motivation: .joy,
                customMotivation: nil,
                targetAmount: 240,
                currencyCode: "USD",
                amountSaved: 200,
                targetDate: concertDate,
                contributionFrequency: .monthly,
                priority: .active,
                includesBuffer: false,
                trackStatus: .ahead,
                createdAt: now,
                updatedAt: now,
                completedAt: nil,
                pausedAt: nil
            ),
            PrismGoal(
                id: sofaID,
                userID: userID,
                sourceAspirationID: nil,
                title: "New sofa",
                goalDescription: nil,
                type: .purchase,
                motivation: .dailyLife,
                customMotivation: nil,
                targetAmount: 1_200,
                currencyCode: "USD",
                amountSaved: 0,
                targetDate: nil,
                contributionFrequency: .monthly,
                priority: .flexible,
                includesBuffer: false,
                trackStatus: .paused,
                createdAt: now,
                updatedAt: now,
                completedAt: nil,
                pausedAt: now
            ),
            PrismGoal(
                id: kyotoID,
                userID: userID,
                sourceAspirationID: nil,
                title: "Kyoto cooking class",
                goalDescription: nil,
                type: .experience,
                motivation: .joy,
                customMotivation: nil,
                targetAmount: 180,
                currencyCode: "USD",
                amountSaved: 0,
                targetDate: nil,
                contributionFrequency: .monthly,
                priority: .someday,
                includesBuffer: false,
                trackStatus: .paused,
                createdAt: now,
                updatedAt: now,
                completedAt: nil,
                pausedAt: now
            )
        ]

        for goal in goals {
            try? await container.goalRepository.upsert(goal)
        }

        // New laptop plan lines — projected cost = essential + optionals = $1,339 ($140 over $1,199).
        let laptopComponents: [(String, Decimal?, AspirationLinkRole)] = [
            ("M4 MacBook Air 13\"", 1_199, .essential),
            ("Refurbished M4 Air, same specs", 1_019, .alternative),
            ("Student pricing, explained", nil, .inspiration),
            ("Hard case + two dongles", 45, .optional),
            ("AppleCare — worth it?", 95, .optional)
        ]
        for (index, row) in laptopComponents.enumerated() {
            try? await container.goalRepository.upsertComponent(
                GoalComponent(
                    id: UUID(),
                    userID: userID,
                    goalID: laptopID,
                    name: row.0,
                    estimatedCost: row.1,
                    currencyCode: row.1 == nil ? nil : "USD",
                    isOptional: row.2 == .optional,
                    role: row.2,
                    sortOrder: index,
                    createdAt: now
                )
            )
        }

        try? await container.goalRepository.upsertMilestone(
            GoalMilestone(
                id: UUID(),
                userID: userID,
                goalID: laptopID,
                title: "Compare options",
                targetAmount: 474,
                isCompleted: false,
                completedAt: nil,
                sortOrder: 0,
                createdAt: now
            )
        )
        try? await container.goalRepository.upsertMilestone(
            GoalMilestone(
                id: UUID(),
                userID: userID,
                goalID: laptopID,
                title: "Reach 50% funded",
                targetAmount: 797,
                isCompleted: false,
                completedAt: nil,
                sortOrder: 1,
                createdAt: now
            )
        )
        try? await container.goalRepository.upsertMilestone(
            GoalMilestone(
                id: UUID(),
                userID: userID,
                goalID: laptopID,
                title: "Ready to buy",
                targetAmount: 1_120,
                isCompleted: false,
                completedAt: nil,
                sortOrder: 2,
                createdAt: now
            )
        )

        try? await container.goalRepository.appendContribution(
            GoalContribution(
                id: UUID(),
                userID: userID,
                goalID: laptopID,
                kind: .financial,
                amount: 150,
                currencyCode: "USD",
                note: "Starting stash",
                createdAt: now
            )
        )
    }
}
