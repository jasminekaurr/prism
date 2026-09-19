// Summary: Privacy-preserving analytics protocol and no-op-friendly implementation.

import Foundation

protocol AnalyticsClient: Sendable {
    func track(_ event: AnalyticsEvent)
}

enum AnalyticsEvent: String, Sendable {
    case onboardingCompleted = "onboarding_completed"
    case itemSaved = "item_saved"
    case reviewCompleted = "review_completed"
    case itemPurchasedConfirmed = "item_purchased_confirmed"
    case itemLetGo = "item_let_go"
    case notificationEnabled = "notification_enabled"
    case goalCreated = "goal_created"
    case goalContributionAdded = "goal_contribution_added"
    case goalCompleted = "goal_completed"
    case goalOutcomeRecorded = "goal_outcome_recorded"
    case regretCheckInAnswered = "regret_check_in_answered"
    case weeklyRecapEnabled = "weekly_recap_enabled"
    case redirectNudgeAccepted = "redirect_nudge_accepted"
    case goalFromCollectionCreated = "goal_from_collection_created"
}

/// Never attaches titles, reflections, prices, URLs, or media.
struct PrivacySafeAnalytics: AnalyticsClient {
    func track(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[analytics] \(event.rawValue)")
        #endif
    }
}

struct DisabledAnalytics: AnalyticsClient {
    func track(_ event: AnalyticsEvent) {}
}
