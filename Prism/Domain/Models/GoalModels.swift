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
    var sortOrder: Int
    var createdAt: Date
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
