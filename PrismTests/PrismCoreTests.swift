// Summary: Unit tests for cooling-off, money story, spending pocket, decisions, currency, and URLs.

import XCTest
@testable import Prism

final class CoolingOffTests: XCTestCase {
    func testDefaultDurations() {
        let settings = CoolingPeriodSettings.default
        let created = Date(timeIntervalSince1970: 1_000_000)
        let small = CoolingOffCalculator.reviewDate(from: created, significance: .small, settings: settings)!
        XCTAssertEqual(small.timeIntervalSince(created), 24 * 3600, accuracy: 1)

        let major = CoolingOffCalculator.reviewDate(from: created, significance: .major, settings: settings)!
        XCTAssertEqual(major.timeIntervalSince(created), 7 * 24 * 3600, accuracy: 1)
    }

    func testDisabledReturnsNil() {
        var settings = CoolingPeriodSettings.default
        settings.enabled = false
        XCTAssertNil(CoolingOffCalculator.reviewDate(significance: .small, settings: settings))
    }
}

final class MoneyStoryTests: XCTestCase {
    func testConfirmedSpendExcludesEstimatesAndMissing() {
        let user = UUID()
        let purchasedWithPrice = makeItem(user: user, status: .purchased, confirmed: 40, estimated: 999, decided: .now)
        let purchasedMissing = makeItem(user: user, status: .purchased, confirmed: nil, estimated: 50, decided: .now)
        let letGo = makeItem(user: user, status: .letGo, confirmed: nil, estimated: 80, decided: .now)
        let considering = makeItem(user: user, status: .considering, confirmed: nil, estimated: 20, decided: nil)

        let snap = MoneyStoryService().snapshot(items: [purchasedWithPrice, purchasedMissing, letGo, considering])
        XCTAssertEqual(snap.purchasesConfirmed, 2)
        XCTAssertEqual(snap.confirmedAmountSpent, 40)
        XCTAssertEqual(snap.confirmedSpendSampleSize, 1)
        XCTAssertEqual(snap.purchasesMissingPrice, 1)
        XCTAssertEqual(snap.itemsLetGo, 1)
        XCTAssertEqual(snap.estimatedValueOfItemsLetGo, 80)
        XCTAssertEqual(snap.itemsStillConsidering, 1)
    }

    func testNeverTreatsMissingAsZeroInSample() {
        let user = UUID()
        let items = [
            makeItem(user: user, status: .purchased, confirmed: 10, estimated: nil, decided: .now),
            makeItem(user: user, status: .purchased, confirmed: nil, estimated: nil, decided: .now)
        ]
        let snap = MoneyStoryService().snapshot(items: items)
        XCTAssertEqual(snap.confirmedAmountSpent, 10)
        XCTAssertEqual(snap.confirmedSpendSampleSize, 1)
        XCTAssertEqual(snap.purchasesMissingPrice, 1)
    }

    private func makeItem(
        user: UUID,
        status: ItemStatus,
        confirmed: Decimal?,
        estimated: Decimal?,
        decided: Date?
    ) -> SavedItem {
        SavedItem(
            id: UUID(),
            userID: user,
            collectionID: nil,
            title: "Item",
            notes: nil,
            reflection: nil,
            sourceURL: nil,
            sourceDomain: nil,
            merchantName: nil,
            intent: .want,
            costSignificance: .considered,
            priority: .undecided,
            estimatedPrice: estimated,
            estimatedCurrencyCode: estimated == nil ? nil : "USD",
            confirmedPurchasePrice: confirmed,
            confirmedPurchaseCurrencyCode: confirmed == nil ? nil : "USD",
            status: status,
            primaryMediaID: nil,
            notificationsEnabled: false,
            createdAt: .now.addingTimeInterval(-3600),
            updatedAt: .now,
            reviewAt: nil,
            decidedAt: decided,
            archivedAt: status == .letGo ? decided : nil,
            deletedAt: nil
        )
    }
}

final class SpendingPocketTests: XCTestCase {
    func testPreviewDoesNotReduceRemaining() {
        var settings = SpendingPocketSettings.default
        settings.isEnabled = true
        settings.monthlyAmount = 200
        settings.currencyCode = "USD"

        let user = UUID()
        let purchased = SavedItem(
            id: UUID(), userID: user, collectionID: nil, title: "Bag", notes: nil, reflection: nil,
            sourceURL: nil, sourceDomain: nil, merchantName: nil, intent: .want, costSignificance: .small,
            priority: nil, estimatedPrice: 85, estimatedCurrencyCode: "USD",
            confirmedPurchasePrice: 50, confirmedPurchaseCurrencyCode: "USD",
            status: .purchased, primaryMediaID: nil, notificationsEnabled: false,
            createdAt: .now, updatedAt: .now, reviewAt: nil, decidedAt: .now, archivedAt: nil, deletedAt: nil
        )

        let service = SpendingPocketService()
        let snap = service.snapshot(settings: settings, items: [purchased])
        XCTAssertEqual(snap.remaining, 150)
        let preview = snap.previewCopy(itemTitle: "These heels", estimatedPrice: 85)
        XCTAssertNotNil(preview)
        XCTAssertTrue(preview!.contains("These heels would use"))
        XCTAssertTrue(preview!.contains("spending pocket"))
        // Preview must not change remaining
        XCTAssertEqual(snap.remaining, 150)
    }

    func testPausedPocketNotActiveGuidance() {
        var settings = SpendingPocketSettings.default
        settings.isEnabled = true
        settings.isPaused = true
        settings.monthlyAmount = 200
        let snap = SpendingPocketService().snapshot(settings: settings, items: [])
        XCTAssertTrue(snap.isPaused)
        XCTAssertNil(snap.previewCopy(itemTitle: "X", estimatedPrice: 10))
    }
}

final class DecisionServiceTests: XCTestCase {
    func testLetGoAndUndo() throws {
        let user = UUID()
        var item = SavedItem(
            id: UUID(), userID: user, collectionID: nil, title: "Shoes", notes: nil, reflection: nil,
            sourceURL: nil, sourceDomain: nil, merchantName: nil, intent: .want, costSignificance: .major,
            priority: .niceToHave, estimatedPrice: 120, estimatedCurrencyCode: "USD",
            confirmedPurchasePrice: nil, confirmedPurchaseCurrencyCode: nil,
            status: .readyForReview, primaryMediaID: nil, notificationsEnabled: true,
            createdAt: .now, updatedAt: .now, reviewAt: .now, decidedAt: nil, archivedAt: nil, deletedAt: nil
        )
        let service = DecisionService()
        let letGo = try service.applyLetGo(item: item, userID: user)
        XCTAssertEqual(letGo.item.status, .letGo)
        XCTAssertEqual(letGo.item.estimatedPrice, 120)

        let undone = try service.undo(item: letGo.item, lastEvent: letGo.event, userID: user)
        XCTAssertEqual(undone.item.status, .readyForReview)
        XCTAssertNil(undone.item.decidedAt)
    }

    func testBuyWithConfirmedPrice() throws {
        let user = UUID()
        let item = SavedItem(
            id: UUID(), userID: user, collectionID: nil, title: "Bag", notes: nil, reflection: nil,
            sourceURL: nil, sourceDomain: nil, merchantName: nil, intent: .gift, costSignificance: .small,
            priority: nil, estimatedPrice: 30, estimatedCurrencyCode: "USD",
            confirmedPurchasePrice: nil, confirmedPurchaseCurrencyCode: nil,
            status: .considering, primaryMediaID: nil, notificationsEnabled: false,
            createdAt: .now, updatedAt: .now, reviewAt: nil, decidedAt: nil, archivedAt: nil, deletedAt: nil
        )
        let result = try DecisionService().applyBuy(
            item: item,
            userID: user,
            purchaseConfirmed: true,
            confirmedPrice: 28,
            currencyCode: "USD"
        )
        XCTAssertEqual(result.item.status, .purchased)
        XCTAssertEqual(result.item.confirmedPurchasePrice, 28)
    }
}

final class UtilityTests: XCTestCase {
    func testCurrencyFormatting() {
        let text = CurrencyFormatting.string(from: 12.5, currencyCode: "USD", locale: Locale(identifier: "en_US"))
        XCTAssertTrue(text.contains("12.50"))
    }

    func testInvalidURLRejected() {
        XCTAssertNil(URLHelpers.validatedHTTPSURL(from: "javascript:alert(1)"))
        XCTAssertNil(URLHelpers.validatedHTTPSURL(from: "not a url"))
        XCTAssertNotNil(URLHelpers.validatedHTTPSURL(from: "https://example.com/item"))
    }

    func testDecimalParsing() {
        XCTAssertEqual(DecimalParsing.parse("85.50"), Decimal(string: "85.50"))
        XCTAssertNil(DecimalParsing.parse(""))
    }
}

final class NotificationSchedulerTests: XCTestCase {
    func testScheduleAndCancelRecorded() async {
        let mock = MockNotificationScheduler()
        let id = UUID()
        await mock.scheduleReviewReminder(itemID: id, at: .now.addingTimeInterval(3600))
        await mock.cancelReviewReminder(itemID: id)
        let scheduled = await mock.scheduledIDs()
        let cancelled = await mock.cancelledIDs()
        XCTAssertEqual(scheduled, [id])
        XCTAssertEqual(cancelled, [id])
    }
}

final class PerformanceSanityTests: XCTestCase {
    func testMoneyStoryHandles500Items() {
        let items = PerformanceSeed.items(count: 500)
        let events = PerformanceSeed.decisionEvents(count: 1000)
        XCTAssertEqual(events.count, 1000)
        measure {
            let snap = MoneyStoryService().snapshot(items: items)
            XCTAssertGreaterThan(snap.impulsesPaused, 0)
        }
    }
}

final class GoalPlanningTests: XCTestCase {
    func testRequiredMonthlyContribution() {
        let calendar = Calendar(identifier: .gregorian)
        let created = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let target = calendar.date(from: DateComponents(year: 2027, month: 1, day: 1))!
        let now = created
        let goal = PrismGoal(
            id: UUID(),
            userID: UUID(),
            sourceAspirationID: nil,
            title: "Japan trip",
            goalDescription: nil,
            type: .travel,
            motivation: .joy,
            customMotivation: nil,
            targetAmount: 4500,
            currencyCode: "USD",
            amountSaved: 600,
            targetDate: target,
            contributionFrequency: .monthly,
            priority: .primary,
            includesBuffer: false,
            trackStatus: .onTrack,
            createdAt: created,
            updatedAt: created,
            completedAt: nil,
            pausedAt: nil
        )
        let pace = GoalPlanningService().pace(for: goal, now: now, calendar: calendar)
        XCTAssertEqual(pace.remaining, 3900)
        XCTAssertEqual(pace.monthsRemaining, 12)
        let required = NSDecimalNumber(decimal: pace.requiredPerPeriod!).doubleValue
        XCTAssertEqual(required, 325, accuracy: 1)
    }

    func testTradeoffCopy() {
        let goal = PrismGoal(
            id: UUID(), userID: UUID(), sourceAspirationID: nil, title: "Japan",
            goalDescription: nil, type: .travel, motivation: .joy, customMotivation: nil,
            targetAmount: 4500, currencyCode: "USD", amountSaved: 600,
            targetDate: Calendar.current.date(byAdding: .month, value: 12, to: .now),
            contributionFrequency: .monthly, priority: .primary, includesBuffer: false,
            trackStatus: .onTrack, createdAt: .now, updatedAt: .now, completedAt: nil, pausedAt: nil
        )
        let service = GoalPlanningService()
        let pace = service.pace(for: goal)
        let copy = service.tradeoffCopy(itemTitle: "These shoes", estimatedPrice: 140, against: goal, pace: pace)
        XCTAssertNotNil(copy)
        XCTAssertTrue(copy!.contains("These shoes"))
        XCTAssertTrue(copy!.contains("Japan"))
    }
}
