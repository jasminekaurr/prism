// Summary: In-memory seed helpers for performance sanity checks (500 items / many decisions).

import Foundation

enum PerformanceSeed {
    static func items(count: Int, userID: UUID = UUID()) -> [SavedItem] {
        var result: [SavedItem] = []
        result.reserveCapacity(count)
        let intents = SaveIntent.allCases
        let costs = CostSignificance.allCases
        for index in 0..<count {
            let status: ItemStatus
            switch index % 5 {
            case 0: status = .purchased
            case 1: status = .letGo
            case 2: status = .readyForReview
            default: status = .considering
            }
            let item = SavedItem(
                id: UUID(),
                userID: userID,
                collectionID: nil,
                title: "Item \(index)",
                notes: nil,
                reflection: index % 3 == 0 ? "Reflection \(index)" : nil,
                sourceURL: nil,
                sourceDomain: nil,
                merchantName: nil,
                intent: intents[index % intents.count],
                costSignificance: costs[index % costs.count],
                priority: .undecided,
                estimatedPrice: index % 2 == 0 ? Decimal(index % 100) : nil,
                estimatedCurrencyCode: "USD",
                confirmedPurchasePrice: status == .purchased && index % 2 == 0 ? Decimal(index % 80) : nil,
                confirmedPurchaseCurrencyCode: "USD",
                status: status,
                primaryMediaID: nil,
                notificationsEnabled: false,
                createdAt: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                updatedAt: Date(),
                reviewAt: status == .readyForReview ? Date().addingTimeInterval(-60) : nil,
                decidedAt: (status == .purchased || status == .letGo) ? Date() : nil,
                archivedAt: status == .letGo ? Date() : nil,
                deletedAt: nil
            )
            result.append(item)
        }
        return result
    }

    static func decisionEvents(count: Int, userID: UUID = UUID()) -> [DecisionEvent] {
        var result: [DecisionEvent] = []
        result.reserveCapacity(count)
        for index in 0..<count {
            let isLetGo = index % 2 == 0
            let event = DecisionEvent(
                id: UUID(),
                userID: userID,
                savedItemID: UUID(),
                decision: isLetGo ? .letGo : .buy,
                previousStatus: .considering,
                newStatus: isLetGo ? .letGo : .purchased,
                confirmedPrice: isLetGo ? nil : Decimal(10),
                currencyCode: "USD",
                note: nil,
                createdAt: Date().addingTimeInterval(TimeInterval(-index)),
                undoneByEventID: nil
            )
            result.append(event)
        }
        return result
    }
}
