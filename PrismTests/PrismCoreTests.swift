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

    func testBufferRaisesEffectiveTargetAndPace() {
        let calendar = Calendar(identifier: .gregorian)
        let created = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let target = calendar.date(from: DateComponents(year: 2027, month: 1, day: 1))!
        var goal = PrismGoal(
            id: UUID(),
            userID: UUID(),
            sourceAspirationID: nil,
            title: "Laptop",
            goalDescription: nil,
            type: .purchase,
            motivation: .practicalNeed,
            customMotivation: nil,
            targetAmount: 1_199,
            currencyCode: "USD",
            amountSaved: 150,
            targetDate: target,
            contributionFrequency: .monthly,
            priority: .active,
            includesBuffer: false,
            trackStatus: .onTrack,
            createdAt: created,
            updatedAt: created,
            completedAt: nil,
            pausedAt: nil
        )
        let service = GoalPlanningService()
        XCTAssertEqual(service.effectiveTarget(for: goal), 1_199)
        let without = service.pace(for: goal, now: created, calendar: calendar)

        goal.includesBuffer = true
        let effective = NSDecimalNumber(decimal: service.effectiveTarget(for: goal) ?? 0).doubleValue
        XCTAssertEqual(effective, 1294.92, accuracy: 0.01)
        let withBuffer = service.pace(for: goal, now: created, calendar: calendar)
        XCTAssertGreaterThan(
            NSDecimalNumber(decimal: withBuffer.requiredPerPeriod ?? 0).doubleValue,
            NSDecimalNumber(decimal: without.requiredPerPeriod ?? 0).doubleValue
        )
    }

    func testProjectedCostExcludesAlternativesAndInspiration() {
        let userID = UUID()
        let goalID = UUID()
        let now = Date()
        let components: [GoalComponent] = [
            GoalComponent(id: UUID(), userID: userID, goalID: goalID, name: "Air", estimatedCost: 1199, currencyCode: "USD", isOptional: false, role: .essential, sortOrder: 0, createdAt: now),
            GoalComponent(id: UUID(), userID: userID, goalID: goalID, name: "Refurb", estimatedCost: 1019, currencyCode: "USD", isOptional: false, role: .alternative, sortOrder: 1, createdAt: now),
            GoalComponent(id: UUID(), userID: userID, goalID: goalID, name: "Student", estimatedCost: nil, currencyCode: nil, isOptional: false, role: .inspiration, sortOrder: 2, createdAt: now),
            GoalComponent(id: UUID(), userID: userID, goalID: goalID, name: "Case", estimatedCost: 45, currencyCode: "USD", isOptional: true, role: .optional, sortOrder: 3, createdAt: now),
            GoalComponent(id: UUID(), userID: userID, goalID: goalID, name: "Care", estimatedCost: 95, currencyCode: "USD", isOptional: true, role: .optional, sortOrder: 4, createdAt: now)
        ]
        let projected = components
            .filter(\.countsTowardProjectedCost)
            .compactMap(\.estimatedCost)
            .reduce(Decimal(0), +)
        XCTAssertEqual(projected, 1339)
        XCTAssertEqual(projected - 1199, 140)
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

// MARK: - Reflection features (regret check-in, goal lifecycle, weekly recap)

private func makeTestItem(
    status: ItemStatus = .considering,
    createdAt: Date = .now,
    checkInAt: Date? = nil,
    answer: RegretAnswer? = nil
) -> SavedItem {
    SavedItem(
        id: UUID(), userID: UUID(), collectionID: nil, title: "Item", notes: nil, reflection: nil,
        sourceURL: nil, sourceDomain: nil, merchantName: nil, intent: .want, costSignificance: .small,
        priority: nil, estimatedPrice: nil, estimatedCurrencyCode: nil,
        confirmedPurchasePrice: nil, confirmedPurchaseCurrencyCode: nil,
        status: status, primaryMediaID: nil, notificationsEnabled: false,
        createdAt: createdAt, updatedAt: createdAt, reviewAt: nil, decidedAt: nil,
        archivedAt: nil, deletedAt: nil,
        regretCheckInAt: checkInAt, regretAnswer: answer, regretAnsweredAt: nil
    )
}

private func makeTestGoal(
    type: GoalType = .purchase,
    priority: GoalPriorityLevel = .active,
    status: GoalTrackStatus = .onTrack,
    target: Decimal? = 1000
) -> PrismGoal {
    PrismGoal(
        id: UUID(), userID: UUID(), sourceAspirationID: nil, title: "Goal", goalDescription: nil,
        type: type, motivation: .joy, customMotivation: nil, targetAmount: target,
        currencyCode: "USD", amountSaved: 0,
        targetDate: Calendar.current.date(byAdding: .month, value: 6, to: .now),
        contributionFrequency: .monthly, priority: priority, includesBuffer: false,
        trackStatus: status, createdAt: .now, updatedAt: .now, completedAt: nil, pausedAt: nil
    )
}

final class RegretCheckInTests: XCTestCase {
    func testBuySchedulesCheckIn() throws {
        let item = makeTestItem(status: .considering)
        let now = Date(timeIntervalSince1970: 2_000_000)
        let result = try DecisionService().applyBuy(
            item: item, userID: item.userID, purchaseConfirmed: true,
            confirmedPrice: 20, currencyCode: "USD", now: now,
            checkInInterval: RegretCheckIn.defaultInterval
        )
        XCTAssertEqual(result.item.regretCheckInAt, now.addingTimeInterval(30 * 24 * 3600))
        XCTAssertNil(result.item.regretAnswer)
    }

    func testBuyNotConfirmedDoesNotSchedule() throws {
        let item = makeTestItem(status: .considering)
        let result = try DecisionService().applyBuy(
            item: item, userID: item.userID, purchaseConfirmed: false,
            confirmedPrice: nil, currencyCode: nil
        )
        XCTAssertNil(result.item.regretCheckInAt)
    }

    func testUndoBuyClearsCheckIn() throws {
        let item = makeTestItem(status: .considering)
        let service = DecisionService()
        let bought = try service.applyBuy(
            item: item, userID: item.userID, purchaseConfirmed: true,
            confirmedPrice: 20, currencyCode: "USD"
        )
        let undone = try service.undo(item: bought.item, lastEvent: bought.event, userID: item.userID)
        XCTAssertNil(undone.item.regretCheckInAt)
        XCTAssertNil(undone.item.regretAnswer)
    }

    func testDueFilter() {
        let now = Date(timeIntervalSince1970: 3_000_000)
        let due = makeTestItem(status: .purchased, checkInAt: now.addingTimeInterval(-60))
        let future = makeTestItem(status: .purchased, checkInAt: now.addingTimeInterval(3600))
        let answered = makeTestItem(status: .purchased, checkInAt: now.addingTimeInterval(-60), answer: .glad)
        let notPurchased = makeTestItem(status: .letGo, checkInAt: now.addingTimeInterval(-60))
        let result = RegretCheckIn.due(items: [due, future, answered, notPurchased], now: now)
        XCTAssertEqual(result.map(\.id), [due.id])
    }

    func testMoneyStoryCountsAnswers() {
        let glad = makeTestItem(status: .purchased, answer: .glad)
        let regret = makeTestItem(status: .purchased, answer: .regret)
        let unanswered = makeTestItem(status: .purchased)
        let snap = MoneyStoryService().snapshot(items: [glad, regret, unanswered])
        XCTAssertEqual(snap.regretGlad, 1)
        XCTAssertEqual(snap.regretRegret, 1)
        XCTAssertEqual(snap.regretAnswered, 2)
    }

    func testMockSchedulerRecordsRegretCalls() async {
        let mock = MockNotificationScheduler()
        let id = UUID()
        await mock.scheduleRegretCheckIn(itemID: id, at: .now.addingTimeInterval(60))
        await mock.cancelRegretCheckIn(itemID: id)
        let scheduled = await mock.regretScheduled
        let cancelled = await mock.regretCancelled
        XCTAssertEqual(scheduled, [id])
        XCTAssertEqual(cancelled, [id])
    }
}

final class GoalLifecycleTests: XCTestCase {
    func testLowCostGoalCanBeMarkedComplete() {
        let goal = makeTestGoal(type: .lowCost, target: nil)
        let done = GoalPlanningService().markComplete(goal)
        XCTAssertEqual(done.trackStatus, .completed)
        XCTAssertNotNil(done.completedAt)
    }

    func testFocusGoalPrefersPrimaryAndSkipsPausedOrDone() {
        let primary = makeTestGoal(priority: .primary)
        let active = makeTestGoal(priority: .active)
        let pausedPrimary = makeTestGoal(priority: .primary, status: .paused)
        let service = GoalPlanningService()
        XCTAssertEqual(service.focusGoal(in: [active, primary])?.id, primary.id)
        XCTAssertEqual(service.focusGoal(in: [pausedPrimary, active])?.id, active.id)
        XCTAssertNil(service.focusGoal(in: [makeTestGoal(priority: .someday)]))
        XCTAssertNil(service.focusGoal(in: [makeTestGoal(status: .completed)]))
    }

    func testRecordOutcomeTrimsNote() {
        let goal = makeTestGoal()
        let service = GoalPlanningService()
        let withNote = service.recordOutcome(goal, rating: .worthIt, note: "  Loved it  ")
        XCTAssertEqual(withNote.outcomeRating, .worthIt)
        XCTAssertEqual(withNote.outcomeNote, "Loved it")
        let blank = service.recordOutcome(goal, rating: .mixed, note: "   ")
        XCTAssertNil(blank.outcomeNote)
    }

    func testPauseAndResume() {
        let service = GoalPlanningService()
        let paused = service.pause(makeTestGoal())
        XCTAssertEqual(paused.trackStatus, .paused)
        XCTAssertNotNil(paused.pausedAt)
        let resumed = service.resume(paused)
        XCTAssertNil(resumed.pausedAt)
        XCTAssertNotEqual(resumed.trackStatus, .paused)
    }
}

final class RecapPlannerTests: XCTestCase {
    func testNextRecapIsFutureSundayAtSixPM() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: 9))! // a Wednesday
        let date = RecapPlanner.nextRecapDate(after: now, calendar: calendar)!
        XCTAssertGreaterThan(date, now)
        XCTAssertEqual(calendar.component(.weekday, from: date), 1)
        XCTAssertEqual(calendar.component(.hour, from: date), 18)
    }

    func testPausedCountOnlyLastSevenDays() {
        let now = Date(timeIntervalSince1970: 5_000_000)
        let recent = makeTestItem(createdAt: now.addingTimeInterval(-2 * 24 * 3600))
        let old = makeTestItem(createdAt: now.addingTimeInterval(-10 * 24 * 3600))
        XCTAssertEqual(RecapPlanner.pausedCount(items: [recent, old], now: now), 1)
    }

    func testBodyNeverContainsItemDetails() {
        XCTAssertTrue(RecapPlanner.body(pausedCount: 3).contains("3 impulses"))
        XCTAssertTrue(RecapPlanner.body(pausedCount: 1).contains("1 impulse "))
        XCTAssertFalse(RecapPlanner.body(pausedCount: 0).isEmpty)
    }
}
