// Summary: Core domain enums for save intent, cost significance, priority, and item status.

import Foundation

/// Why the user is saving this item.
enum SaveIntent: String, Codable, CaseIterable, Identifiable, Sendable {
    case want
    case need
    case dream
    case gift

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .want: return "Want"
        case .need: return "Need"
        case .dream: return "Dream"
        case .gift: return "Gift"
        }
    }
}

/// Subjective cost weight — not tied to dollar ranges.
enum CostSignificance: String, Codable, CaseIterable, Identifiable, Sendable {
    case small
    case considered
    case major
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "$  Small"
        case .considered: return "$$  Considered"
        case .major: return "$$$  Major"
        case .unknown: return "Not sure"
        }
    }

    var shortLabel: String {
        switch self {
        case .small: return "$"
        case .considered: return "$$"
        case .major: return "$$$"
        case .unknown: return "?"
        }
    }

    /// Default cooling-off duration for this significance level.
    var defaultCoolingOff: TimeInterval {
        switch self {
        case .small: return 24 * 60 * 60
        case .considered: return 3 * 24 * 60 * 60
        case .major: return 7 * 24 * 60 * 60
        case .unknown: return 3 * 24 * 60 * 60
        }
    }
}

enum ItemPriority: String, Codable, CaseIterable, Identifiable, Sendable {
    case mustHave
    case niceToHave
    case undecided

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mustHave: return "Must-have"
        case .niceToHave: return "Nice-to-have"
        case .undecided: return "Undecided"
        }
    }
}

enum ItemStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case considering
    case readyForReview
    case purchased
    case letGo
    case archived

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .considering: return "Considering"
        case .readyForReview: return "Ready to revisit"
        case .purchased: return "Purchased"
        case .letGo: return "Let go"
        case .archived: return "Archived"
        }
    }
}

/// Decision taken during review.
enum DecisionType: String, Codable, CaseIterable, Sendable {
    case buy
    case keepConsidering
    case letGo
    case undo
}

// MARK: - Goals

enum GoalType: String, Codable, CaseIterable, Identifiable, Sendable {
    case purchase
    case experience
    case travel
    case project
    case recurring
    case lowCost

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .purchase: return "Purchase"
        case .experience: return "Experience"
        case .travel: return "Travel"
        case .project: return "Project"
        case .recurring: return "Recurring"
        case .lowCost: return "Low / no cost"
        }
    }
}

/// Commitment level across goals — not the same as item must-have.
enum GoalPriorityLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case primary
    case active
    case flexible
    case someday

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .primary: return "Primary"
        case .active: return "Active"
        case .flexible: return "Flexible"
        case .someday: return "Someday"
        }
    }
}

enum GoalTrackStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case ahead
    case onTrack
    case aLittleBehind
    case needsAdjustment
    case paused
    case completed
    case abandoned

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ahead: return "Ahead"
        case .onTrack: return "On track"
        case .aLittleBehind: return "A little behind"
        case .needsAdjustment: return "Needs adjustment"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        }
    }
}

enum ContributionFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case weekly
    case monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

enum ContributionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case financial
    case planning
    case behavioral

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .financial: return "Financial"
        case .planning: return "Planning"
        case .behavioral: return "Behavioral"
        }
    }
}

enum GoalMotivation: String, Codable, CaseIterable, Identifiable, Sendable {
    case dailyLife
    case largerPriority
    case withSomeone
    case personalGrowth
    case joy
    case practicalNeed
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dailyLife: return "It would improve my daily life"
        case .largerPriority: return "It supports a larger priority"
        case .withSomeone: return "I want to experience it with someone"
        case .personalGrowth: return "It represents personal growth"
        case .joy: return "It would bring me joy"
        case .practicalNeed: return "It solves a practical need"
        case .custom: return "My own reason"
        }
    }
}

enum AspirationLinkRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case essential
    case optional
    case inspiration
    case alternative
    case booked
    case decidedAgainst

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .essential: return "Essential"
        case .optional: return "Optional"
        case .inspiration: return "Inspiration"
        case .alternative: return "Alternative"
        case .booked: return "Booked or purchased"
        case .decidedAgainst: return "Decided against"
        }
    }
}
