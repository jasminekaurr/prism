// Summary: Goal domain models — goals, milestones, components, contributions, aspiration links.

import Foundation

struct PrismGoal: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var sourceAspirationID: UUID?
    var title: String
    var goalDescription: String?
    var type: GoalType
    var motivation: GoalMotivation?
    var customMotivation: String?
    var targetAmount: Decimal?
    var currencyCode: String
    var amountSaved: Decimal
    var targetDate: Date?
    var contributionFrequency: ContributionFrequency
    var priority: GoalPriorityLevel
    var includesBuffer: Bool
    var trackStatus: GoalTrackStatus
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var pausedAt: Date?
    var outcomeRating: GoalOutcomeRating? = nil
    var outcomeNote: String? = nil
}

struct GoalMilestone: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var goalID: UUID
    var title: String
    var targetAmount: Decimal?
    var isCompleted: Bool
    var completedAt: Date?
    var sortOrder: Int
    var createdAt: Date
}

struct GoalComponent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var goalID: UUID
    var name: String
    var estimatedCost: Decimal?
    var currencyCode: String?
    var isOptional: Bool
    /// How this line sits in the plan (essential / optional / alternative / inspiration).
    var role: AspirationLinkRole
    var sortOrder: Int
    var createdAt: Date

    /// Costs that count toward “projected cost of this plan” (excludes alternatives & inspiration).
    var countsTowardProjectedCost: Bool {
        switch role {
        case .essential, .optional, .booked: return true
        case .alternative, .inspiration, .decidedAgainst: return false
        }
    }

    init(
        id: UUID,
        userID: UUID,
        goalID: UUID,
        name: String,
        estimatedCost: Decimal?,
        currencyCode: String?,
        isOptional: Bool,
        role: AspirationLinkRole? = nil,
        sortOrder: Int,
        createdAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.goalID = goalID
        self.name = name
        self.estimatedCost = estimatedCost
        self.currencyCode = currencyCode
        self.isOptional = isOptional
        self.role = role ?? (isOptional ? .optional : .essential)
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}

struct GoalContribution: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var goalID: UUID
    var kind: ContributionKind
    var amount: Decimal?
    var currencyCode: String?
    var note: String?
    var createdAt: Date
}

struct GoalAspirationLink: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    var goalID: UUID
    var savedItemID: UUID
    var role: AspirationLinkRole
    var createdAt: Date
}
