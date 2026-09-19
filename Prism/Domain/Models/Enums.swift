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
