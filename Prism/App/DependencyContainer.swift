// Summary: Dependency injection container holding repositories, services, and SwiftData container.

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class DependencyContainer: ObservableObject {
    let modelContainer: ModelContainer
    let store: LocalStore
    let decisionService: DecisionService
    let moneyStoryService: MoneyStoryService
    let spendingPocketService: SpendingPocketService
    let notificationScheduler: NotificationScheduling
    let analytics: AnalyticsClient
    let auth: AuthRepository
    let crashReporter: CrashReporting

    var profileRepository: UserProfileRepository { store }
    var collectionRepository: CollectionRepository { store }
    var savedItemRepository: SavedItemRepository { store }
    var mediaRepository: MediaRepository { store }
    var tagRepository: TagRepository { store }
    var feelingRepository: FeelingRepository { store }
    var decisionRepository: DecisionRepository { store }
    var reviewEventRepository: ReviewEventRepository { store }
    var settingsRepository: SettingsRepository { store }

    init(
        modelContainer: ModelContainer,
        notificationScheduler: NotificationScheduling = LocalNotificationScheduler(),
        analytics: AnalyticsClient = PrivacySafeAnalytics(),
        auth: AuthRepository = StubAuthRepository(),
        crashReporter: CrashReporting = RedactingCrashReporter()
    ) {
        self.modelContainer = modelContainer
        self.store = LocalStore(container: modelContainer)
        self.decisionService = DecisionService()
        self.moneyStoryService = MoneyStoryService()
        self.spendingPocketService = SpendingPocketService()
        self.notificationScheduler = notificationScheduler
        self.analytics = analytics
        self.auth = auth
        self.crashReporter = crashReporter
    }

    static func live() -> DependencyContainer {
        do {
            let container = try PrismModelContainerFactory.make(inMemory: false)
            return DependencyContainer(modelContainer: container)
        } catch {
            // Fall back to in-memory so the app still launches.
            let container = try! PrismModelContainerFactory.make(inMemory: true)
            return DependencyContainer(modelContainer: container)
        }
    }

    static func preview() -> DependencyContainer {
        let container = try! PrismModelContainerFactory.make(inMemory: true)
        return DependencyContainer(modelContainer: container)
    }
}
