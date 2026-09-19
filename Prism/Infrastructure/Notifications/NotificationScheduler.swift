// Summary: Local notification scheduling for cooling-off reminders with privacy-safe lock-screen copy.

import Foundation
import UserNotifications

protocol NotificationScheduling: Sendable {
    func requestPermission() async -> Bool
    func scheduleReviewReminder(itemID: UUID, at date: Date) async
    func cancelReviewReminder(itemID: UUID) async
    func reconcilePending() async
}

struct LocalNotificationScheduler: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReviewReminder(itemID: UUID, at date: Date) async {
        await cancelReviewReminder(itemID: itemID)
        guard date > .now else { return }

        let content = UNMutableNotificationContent()
        // Intentionally omit item title for lock-screen privacy.
        content.title = "Prism"
        content.body = "An item is ready to revisit in Prism."
        content.sound = .default
        content.userInfo = ["itemID": itemID.uuidString]

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.identifier(for: itemID),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancelReviewReminder(itemID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(for: itemID)])
    }

    func reconcilePending() async {
        // MVP: no-op beyond trusting per-item schedule calls at save/decision time.
        // Future: re-fetch ready items and reschedule missing notifications.
    }

    private static func identifier(for itemID: UUID) -> String {
        "review.\(itemID.uuidString)"
    }
}

/// Test double that records schedule/cancel calls.
actor MockNotificationScheduler: NotificationScheduling {
    private(set) var scheduled: [(UUID, Date)] = []
    private(set) var cancelled: [UUID] = []

    func requestPermission() async -> Bool { true }

    func scheduleReviewReminder(itemID: UUID, at date: Date) async {
        scheduled.append((itemID, date))
    }

    func cancelReviewReminder(itemID: UUID) async {
        cancelled.append(itemID)
    }

    func reconcilePending() async {}

    func scheduledIDs() -> [UUID] { scheduled.map(\.0) }
    func cancelledIDs() -> [UUID] { cancelled }
}
