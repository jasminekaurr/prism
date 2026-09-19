// Summary: Goal planning math — remaining, required pace, track status, trade-off copy.

import Foundation

struct GoalPaceSnapshot: Equatable, Sendable {
    var remaining: Decimal?
    var requiredPerPeriod: Decimal?
    var periodLabel: String
    var percentFunded: Double?
    var trackStatus: GoalTrackStatus
    var monthsRemaining: Int?
}

struct GoalPlanningService: Sendable {
    func pace(
        for goal: PrismGoal,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> GoalPaceSnapshot {
        if goal.trackStatus == .paused {
            return GoalPaceSnapshot(
                remaining: remaining(for: goal),
                requiredPerPeriod: nil,
                periodLabel: goal.contributionFrequency.displayName.lowercased(),
                percentFunded: percentFunded(for: goal),
                trackStatus: .paused,
                monthsRemaining: monthsUntil(goal.targetDate, from: now, calendar: calendar)
            )
        }
        if goal.trackStatus == .completed || goal.trackStatus == .abandoned {
            return GoalPaceSnapshot(
                remaining: remaining(for: goal),
                requiredPerPeriod: nil,
                periodLabel: goal.contributionFrequency.displayName.lowercased(),
                percentFunded: percentFunded(for: goal),
                trackStatus: goal.trackStatus,
                monthsRemaining: monthsUntil(goal.targetDate, from: now, calendar: calendar)
            )
        }

        let rem = remaining(for: goal)
        let months = max(monthsUntil(goal.targetDate, from: now, calendar: calendar) ?? 1, 1)
        var required: Decimal?
        if let rem, rem > 0 {
            switch goal.contributionFrequency {
            case .monthly:
                required = rem / Decimal(months)
            case .weekly:
                let weeks = max(months * 4, 1)
                required = rem / Decimal(weeks)
            }
        } else if rem != nil {
            required = 0
        }

        let status = inferredTrackStatus(goal: goal, remaining: rem, requiredMonthly: required.map {
            goal.contributionFrequency == .weekly ? $0 * 4 : $0
        }, now: now, calendar: calendar)

        return GoalPaceSnapshot(
            remaining: rem,
            requiredPerPeriod: required,
            periodLabel: goal.contributionFrequency == .weekly ? "week" : "month",
            percentFunded: percentFunded(for: goal),
            trackStatus: status,
            monthsRemaining: monthsUntil(goal.targetDate, from: now, calendar: calendar)
        )
    }

    func remaining(for goal: PrismGoal) -> Decimal? {
        guard let target = goal.targetAmount else { return nil }
        return target - goal.amountSaved
    }

    func percentFunded(for goal: PrismGoal) -> Double? {
        guard let target = goal.targetAmount, target > 0 else { return nil }
        let ratio = NSDecimalNumber(decimal: goal.amountSaved).doubleValue
            / NSDecimalNumber(decimal: target).doubleValue
        return min(max(ratio * 100, 0), 100)
    }

    /// Soft trade-off copy — never dictates the choice.
    func tradeoffCopy(
        itemTitle: String,
        estimatedPrice: Decimal?,
        against goal: PrismGoal,
        pace: GoalPaceSnapshot
    ) -> String? {
        guard let price = estimatedPrice,
              let required = pace.requiredPerPeriod,
              required > 0 else {
            if goal.motivation != nil {
                return "Remember why \(goal.title) matters before you decide."
            }
            return nil
        }
        let pct = (NSDecimalNumber(decimal: price).doubleValue
            / NSDecimalNumber(decimal: required).doubleValue) * 100
        let priceText = CurrencyFormatting.string(from: price, currencyCode: goal.currencyCode)
        let requiredText = CurrencyFormatting.string(from: required, currencyCode: goal.currencyCode)
        return "\(itemTitle) costs \(priceText). That is about \(Int(pct.rounded()))% of your \(goal.title) contribution (\(requiredText) per \(pace.periodLabel))."
    }

    func applyFinancialContribution(to goal: PrismGoal, amount: Decimal, now: Date = .now) -> PrismGoal {
        var updated = goal
        updated.amountSaved += amount
        updated.updatedAt = now
        if let target = updated.targetAmount, updated.amountSaved >= target {
            updated.trackStatus = .completed
            updated.completedAt = now
        }
        return updated
    }

    // MARK: - Lifecycle

    /// The goal Prism should reference in nudges: primary first, then the first active one.
    func focusGoal(in goals: [PrismGoal]) -> PrismGoal? {
        let open = goals.filter {
            $0.trackStatus != .completed && $0.trackStatus != .abandoned && $0.trackStatus != .paused
        }
        return open.first { $0.priority == .primary } ?? open.first { $0.priority == .active }
    }

    /// Works for every goal type, including low/no-cost goals that have no target amount.
    func markComplete(_ goal: PrismGoal, now: Date = .now) -> PrismGoal {
        var updated = goal
        updated.trackStatus = .completed
        updated.completedAt = now
        updated.pausedAt = nil
        updated.updatedAt = now
        return updated
    }

    func pause(_ goal: PrismGoal, now: Date = .now) -> PrismGoal {
        var updated = goal
        updated.trackStatus = .paused
        updated.pausedAt = now
        updated.updatedAt = now
        return updated
    }

    func resume(_ goal: PrismGoal, now: Date = .now) -> PrismGoal {
        var updated = goal
        updated.pausedAt = nil
        updated.trackStatus = .onTrack
        updated.updatedAt = now
        updated.trackStatus = pace(for: updated, now: now).trackStatus
        return updated
    }

    func abandon(_ goal: PrismGoal, now: Date = .now) -> PrismGoal {
        var updated = goal
        updated.trackStatus = .abandoned
        updated.pausedAt = nil
        updated.updatedAt = now
        return updated
    }

    func recordOutcome(_ goal: PrismGoal, rating: GoalOutcomeRating, note: String?, now: Date = .now) -> PrismGoal {
        var updated = goal
        updated.outcomeRating = rating
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        updated.outcomeNote = trimmed.isEmpty ? nil : trimmed
        updated.updatedAt = now
        return updated
    }

    // MARK: - Private

    private func monthsUntil(_ date: Date?, from now: Date, calendar: Calendar) -> Int? {
        guard let date else { return nil }
        let comps = calendar.dateComponents([.month], from: now, to: date)
        return max(comps.month ?? 0, 0)
    }

    private func inferredTrackStatus(
        goal: PrismGoal,
        remaining: Decimal?,
        requiredMonthly: Decimal?,
        now: Date,
        calendar: Calendar
    ) -> GoalTrackStatus {
        if goal.pausedAt != nil { return .paused }
        if goal.trackStatus == .completed { return .completed }
        guard let target = goal.targetAmount, let targetDate = goal.targetDate else {
            return .onTrack
        }
        if goal.amountSaved >= target { return .completed }

        let totalMonths = max(monthsUntil(targetDate, from: goal.createdAt, calendar: calendar) ?? 1, 1)
        let elapsed = max(totalMonths - (monthsUntil(targetDate, from: now, calendar: calendar) ?? 0), 0)
        let expectedSaved = target * Decimal(elapsed) / Decimal(totalMonths)
        let delta = goal.amountSaved - expectedSaved
        let tolerance = target * Decimal(string: "0.05")! // 5%

        if delta > tolerance { return .ahead }
        if delta >= -tolerance { return .onTrack }
        if delta >= -tolerance * 3 { return .aLittleBehind }
        return .needsAdjustment
    }
}
