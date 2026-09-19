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
