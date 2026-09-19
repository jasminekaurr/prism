// Summary: Local notification scheduling for cooling-off reminders with privacy-safe lock-screen copy.

import Foundation
import UserNotifications

protocol NotificationScheduling: Sendable {
    func requestPermission() async -> Bool
    func scheduleReviewReminder(itemID: UUID, at date: Date) async
    func cancelReviewReminder(itemID: UUID) async
    func reconcilePending() async
    func scheduleRegretCheckIn(itemID: UUID, at date: Date) async
    func cancelRegretCheckIn(itemID: UUID) async
    func scheduleWeeklyRecap(body: String, at date: Date) async
    func cancelWeeklyRecap() async
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

    func scheduleRegretCheckIn(itemID: UUID, at date: Date) async {
        let id = Self.regretIdentifier(for: itemID)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        // Intentionally omit item title for lock-screen privacy.
        await add(id: id, body: "Time for a quick check-in on a past purchase.", at: date, itemID: itemID)
    }

    func cancelRegretCheckIn(itemID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.regretIdentifier(for: itemID)])
    }

    func scheduleWeeklyRecap(body: String, at date: Date) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.recapIdentifier])
        await add(id: Self.recapIdentifier, body: body, at: date, itemID: nil)
    }

    func cancelWeeklyRecap() async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.recapIdentifier])
    }

    private func add(id: String, body: String, at date: Date, itemID: UUID?) async {
        guard date > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = "Prism"
        content.body = body
        content.sound = .default
        if let itemID {
            content.userInfo = ["itemID": itemID.uuidString]
        }
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private static let recapIdentifier = "recap.weekly"

    private static func regretIdentifier(for itemID: UUID) -> String {
        "regret.\(itemID.uuidString)"
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

    private(set) var regretScheduled: [UUID] = []
    private(set) var regretCancelled: [UUID] = []
    private(set) var recapBodies: [String] = []
    private(set) var recapCancelCount = 0

    func scheduleRegretCheckIn(itemID: UUID, at date: Date) async { regretScheduled.append(itemID) }
    func cancelRegretCheckIn(itemID: UUID) async { regretCancelled.append(itemID) }
    func scheduleWeeklyRecap(body: String, at date: Date) async { recapBodies.append(body) }
    func cancelWeeklyRecap() async { recapCancelCount += 1 }

    func scheduledIDs() -> [UUID] { scheduled.map(\.0) }
    func cancelledIDs() -> [UUID] { cancelled }
}
