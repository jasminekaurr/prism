// Summary: App-wide environment holding session profile state and bootstrap helpers.

import Foundation
import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    let container: DependencyContainer
    let router: AppRouter

    @Published var profile: UserProfile?
    @Published var isLocked: Bool = false
    @Published var lastUndo: UndoPayload?

    struct UndoPayload {
        var itemID: UUID
        var message: String
    }

    init(container: DependencyContainer, router: AppRouter) {
        self.container = container
        self.router = router
    }

    static func bootstrap() -> AppEnvironment {
        let env = AppEnvironment(container: .live(), router: AppRouter())
        return env
    }

    func refreshProfile() async {
        profile = try? await container.profileRepository.currentProfile()
        if let settings = try? await container.settingsRepository.load() {
            isLocked = settings.appLockEnabled
        }
    }

    func ensureDemoProfileIfNeeded() async throws {
        if let existing = try await container.profileRepository.currentProfile() {
            profile = existing
            return
        }
        let newProfile = UserProfile(
            id: UUID(),
            displayName: nil,
            createdAt: .now,
            onboardingCompleted: false,
            isDemoMode: true,
            notificationPreferences: .default,
            defaultCoolingPeriods: .default,
            spendingPocket: .default
        )
        try await container.profileRepository.save(newProfile)
        profile = newProfile
    }
}

/// Navigation destinations and sheet presentation.
@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable {
        case home, collections, review, moneyStory, settings
    }

    enum Sheet: Identifiable, Equatable {
        case capture
        case createCollection
        case itemDetail(UUID)
        case reflection(UUID)
        case buyConfirmation(UUID)
        case keepConsidering(UUID)
        case spendingPocketInfo
        case estimatedLetGoInfo
        case goalSetup(UUID?)
        case goalDetail(UUID)
        case addProgress(UUID)

        var id: String {
            switch self {
            case .capture: return "capture"
            case .createCollection: return "createCollection"
            case .itemDetail(let id): return "item-\(id)"
            case .reflection(let id): return "reflection-\(id)"
            case .buyConfirmation(let id): return "buy-\(id)"
            case .keepConsidering(let id): return "keep-\(id)"
            case .spendingPocketInfo: return "pocketInfo"
            case .estimatedLetGoInfo: return "estInfo"
            case .goalSetup(let id): return "goalSetup-\(id?.uuidString ?? "new")"
            case .goalDetail(let id): return "goalDetail-\(id)"
            case .addProgress(let id): return "progress-\(id)"
            }
        }
    }

    @Published var selectedTab: Tab = .home
    @Published var sheet: Sheet?
    @Published var showOnboarding: Bool = false
}
