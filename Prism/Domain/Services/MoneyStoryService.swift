// Summary: Money Story aggregation and spending-pocket calculations with confirmed vs estimated separation.

import Foundation

struct FeelingCount: Equatable, Sendable {
    var name: String
    var count: Int
}

struct IntentCount: Equatable, Sendable {
    var intent: SaveIntent
    var count: Int
}

struct MoneyStorySnapshot: Equatable, Sendable {
    var purchasesConfirmed: Int
    var confirmedAmountSpent: Decimal
    var confirmedSpendSampleSize: Int
    var purchasesMissingPrice: Int
    var itemsLetGo: Int
    var itemsStillConsidering: Int
    var impulsesPaused: Int
    var averageHoursToDecision: Double?
    var estimatedValueOfItemsLetGo: Decimal?
    var estimatedLetGoSampleSize: Int
    var commonFeelings: [FeelingCount]
    var commonIntents: [IntentCount]

    static let empty = MoneyStorySnapshot(
        purchasesConfirmed: 0,
        confirmedAmountSpent: 0,
        confirmedSpendSampleSize: 0,
        purchasesMissingPrice: 0,
        itemsLetGo: 0,
        itemsStillConsidering: 0,
        impulsesPaused: 0,
        averageHoursToDecision: nil,
        estimatedValueOfItemsLetGo: nil,
        estimatedLetGoSampleSize: 0,
        commonFeelings: [],
        commonIntents: []
    )
}

struct SpendingPocketSnapshot: Equatable, Sendable {
    var isActive: Bool
    var monthlyAmount: Decimal?
    var currencyCode: String
    var confirmedSpentThisMonth: Decimal
    var remaining: Decimal?
    var isPaused: Bool

    /// Soft preview only — does not reduce remaining.
    func previewCopy(itemTitle: String, estimatedPrice: Decimal?) -> String? {
        guard isActive, !isPaused, let monthly = monthlyAmount, let estimate = estimatedPrice else {
            return nil
        }
        let estimateText = CurrencyFormatting.string(from: estimate, currencyCode: currencyCode)
        let monthlyText = CurrencyFormatting.string(from: monthly, currencyCode: currencyCode)
        return "\(itemTitle) would use \(estimateText) of your \(monthlyText) spending pocket."
    }
}

enum MoneyStoryTimeFilter: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case allTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .allTime: return "All time"
        }
    }
}

struct MoneyStoryService: Sendable {
    func snapshot(
        items: [SavedItem],
        feelingsByItem: [UUID: [Feeling]] = [:],
        filter: MoneyStoryTimeFilter = .allTime,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> MoneyStorySnapshot {
        let filtered = items.filter { item in
            guard item.deletedAt == nil else { return false }
            return isInFilter(item.createdAt, filter: filter, now: now, calendar: calendar)
                || (item.decidedAt.map { isInFilter($0, filter: filter, now: now, calendar: calendar) } ?? false)
        }

        let purchased = filtered.filter { $0.status == .purchased }
        let withPrice = purchased.compactMap(\.confirmedPurchasePrice)
        let letGo = filtered.filter { $0.status == .letGo }
        let considering = filtered.filter { $0.status == .considering || $0.status == .readyForReview }
        let impulsesPaused = filtered.filter { $0.status != .purchased || $0.decidedAt != nil }.count
        // Impulses paused = saved and not immediately recorded as purchased at save time.
        // Approximate: all items that entered considering flow (everything except instant — we don't support instant buy).
        let pausedCount = filtered.count

        let decisionDurations: [TimeInterval] = filtered.compactMap { item in
            guard let decided = item.decidedAt else { return nil }
            return decided.timeIntervalSince(item.createdAt)
        }
        let avgHours: Double? = decisionDurations.isEmpty
            ? nil
            : (decisionDurations.reduce(0, +) / Double(decisionDurations.count)) / 3600

        let estimatedLetGoPrices = letGo.compactMap(\.estimatedPrice)

        var feelingCounts: [String: Int] = [:]
        for item in filtered {
            for feeling in feelingsByItem[item.id] ?? [] {
                feelingCounts[feeling.name, default: 0] += 1
            }
        }
        let topFeelings = feelingCounts
            .map { FeelingCount(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }

        var intentCounts: [SaveIntent: Int] = [:]
        for item in filtered {
            intentCounts[item.intent, default: 0] += 1
        }
        let topIntents = intentCounts
            .map { IntentCount(intent: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        return MoneyStorySnapshot(
            purchasesConfirmed: purchased.count,
            confirmedAmountSpent: withPrice.reduce(Decimal(0), +),
            confirmedSpendSampleSize: withPrice.count,
            purchasesMissingPrice: purchased.count - withPrice.count,
            itemsLetGo: letGo.count,
            itemsStillConsidering: considering.count,
            impulsesPaused: pausedCount,
            averageHoursToDecision: avgHours,
            estimatedValueOfItemsLetGo: estimatedLetGoPrices.isEmpty ? nil : estimatedLetGoPrices.reduce(0, +),
            estimatedLetGoSampleSize: estimatedLetGoPrices.count,
            commonFeelings: Array(topFeelings),
            commonIntents: topIntents
        )
    }

    private func isInFilter(_ date: Date, filter: MoneyStoryTimeFilter, now: Date, calendar: Calendar) -> Bool {
        switch filter {
        case .allTime:
            return true
        case .week:
            guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
            return date >= start
        case .month:
            guard let start = calendar.date(byAdding: .month, value: -1, to: now) else { return true }
            return date >= start
        }
    }
}

struct SpendingPocketService: Sendable {
    func snapshot(
        settings: SpendingPocketSettings,
        items: [SavedItem],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> SpendingPocketSnapshot {
        let spent = confirmedSpendThisMonth(items: items, now: now, calendar: calendar)
        let remaining: Decimal?
        if let monthly = settings.monthlyAmount, settings.isEnabled {
            remaining = monthly - spent
        } else {
            remaining = nil
        }
        return SpendingPocketSnapshot(
            isActive: settings.isEnabled && settings.monthlyAmount != nil,
            monthlyAmount: settings.monthlyAmount,
            currencyCode: settings.currencyCode,
            confirmedSpentThisMonth: spent,
            remaining: remaining,
            isPaused: settings.isPaused
        )
    }

    func confirmedSpendThisMonth(
        items: [SavedItem],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Decimal {
        let comps = calendar.dateComponents([.year, .month], from: now)
        return items.reduce(Decimal(0)) { partial, item in
            guard item.status == .purchased,
                  let price = item.confirmedPurchasePrice,
                  let decided = item.decidedAt else {
                return partial
            }
            let d = calendar.dateComponents([.year, .month], from: decided)
            guard d.year == comps.year, d.month == comps.month else { return partial }
            return partial + price
        }
    }
}
