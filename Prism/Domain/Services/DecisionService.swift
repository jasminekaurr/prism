// Summary: Decision state machine with undo support via append-only decision events.

import Foundation

struct DecisionTransitionResult: Equatable, Sendable {
    var item: SavedItem
    var event: DecisionEvent
}

enum DecisionServiceError: Error, Equatable {
    case invalidTransition
    case nothingToUndo
}

struct DecisionService: Sendable {
    func applyBuy(
        item: SavedItem,
        userID: UUID,
        purchaseConfirmed: Bool,
        confirmedPrice: Decimal?,
        currencyCode: String?,
        now: Date = .now
    ) throws -> DecisionTransitionResult {
        guard item.status == .considering || item.status == .readyForReview || item.status == .letGo else {
            throw DecisionServiceError.invalidTransition
        }
        var updated = item
        let previous = item.status
        if purchaseConfirmed {
            updated.status = .purchased
            updated.confirmedPurchasePrice = confirmedPrice
            updated.confirmedPurchaseCurrencyCode = currencyCode
            updated.decidedAt = now
            updated.archivedAt = nil
        } else {
            // User chose Buy but said purchase did not happen — keep considering with a note via event.
            updated.status = .considering
            updated.decidedAt = nil
        }
        updated.updatedAt = now
        updated.reviewAt = purchaseConfirmed ? nil : updated.reviewAt

        let event = DecisionEvent(
            id: UUID(),
            userID: userID,
            savedItemID: item.id,
            decision: .buy,
            previousStatus: previous,
            newStatus: updated.status,
            confirmedPrice: purchaseConfirmed ? confirmedPrice : nil,
            currencyCode: purchaseConfirmed ? currencyCode : nil,
            note: purchaseConfirmed ? nil : "Buy selected but purchase not confirmed",
            createdAt: now,
            undoneByEventID: nil
        )
        return DecisionTransitionResult(item: updated, event: event)
    }

    func applyKeepConsidering(
        item: SavedItem,
        userID: UUID,
        newReviewAt: Date?,
        now: Date = .now
    ) throws -> DecisionTransitionResult {
        guard item.status == .considering || item.status == .readyForReview else {
            throw DecisionServiceError.invalidTransition
        }
        var updated = item
        let previous = item.status
        updated.status = .considering
        updated.reviewAt = newReviewAt
        updated.updatedAt = now
        let event = DecisionEvent(
            id: UUID(),
            userID: userID,
            savedItemID: item.id,
            decision: .keepConsidering,
            previousStatus: previous,
            newStatus: .considering,
            confirmedPrice: nil,
            currencyCode: nil,
            note: nil,
            createdAt: now,
            undoneByEventID: nil
        )
        return DecisionTransitionResult(item: updated, event: event)
    }

    func applyLetGo(
        item: SavedItem,
        userID: UUID,
        now: Date = .now
    ) throws -> DecisionTransitionResult {
        guard item.status == .considering || item.status == .readyForReview || item.status == .purchased else {
            throw DecisionServiceError.invalidTransition
        }
        var updated = item
        let previous = item.status
        updated.status = .letGo
        updated.decidedAt = now
        updated.archivedAt = now
        updated.reviewAt = nil
        updated.updatedAt = now
        // Keep estimated price as estimate only — never treat as savings.
        let event = DecisionEvent(
            id: UUID(),
            userID: userID,
            savedItemID: item.id,
            decision: .letGo,
            previousStatus: previous,
            newStatus: .letGo,
            confirmedPrice: nil,
            currencyCode: nil,
            note: nil,
            createdAt: now,
            undoneByEventID: nil
        )
        return DecisionTransitionResult(item: updated, event: event)
    }

    func undo(
        item: SavedItem,
        lastEvent: DecisionEvent,
        userID: UUID,
        now: Date = .now
    ) throws -> DecisionTransitionResult {
        guard lastEvent.undoneByEventID == nil else {
            throw DecisionServiceError.nothingToUndo
        }
        var updated = item
        updated.status = lastEvent.previousStatus
        updated.updatedAt = now
        if lastEvent.decision == .buy || lastEvent.decision == .letGo {
            updated.decidedAt = nil
            updated.archivedAt = nil
            if lastEvent.decision == .buy {
                updated.confirmedPurchasePrice = nil
                updated.confirmedPurchaseCurrencyCode = nil
            }
        }
        let undoID = UUID()
        let event = DecisionEvent(
            id: undoID,
            userID: userID,
            savedItemID: item.id,
            decision: .undo,
            previousStatus: lastEvent.newStatus,
            newStatus: lastEvent.previousStatus,
            confirmedPrice: nil,
            currencyCode: nil,
            note: "Undo of \(lastEvent.id)",
            createdAt: now,
            undoneByEventID: nil
        )
        // Caller should also mark lastEvent.undoneByEventID = undoID when persisting.
        return DecisionTransitionResult(item: updated, event: event)
    }
}
