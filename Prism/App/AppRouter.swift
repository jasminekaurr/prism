// Summary: Root view — onboarding gate, optional app lock, and main tab shell.

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer

    var body: some View {
        ZStack {
            PrismAtmosphericBackground()
            Group {
                if environment.profile == nil || environment.profile?.onboardingCompleted == false {
                    OnboardingFlowView()
                } else if environment.isLocked {
                    AppLockView()
                } else {
                    MainTabView()
                }
            }
        }
        .task {
            await environment.refreshProfile()
            if environment.profile == nil {
                router.showOnboarding = true
            }
            await container.notificationScheduler.reconcilePending()
            await environment.refreshWeeklyRecap()
            await importPendingShareIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await importPendingShareIfNeeded() }
        }
        .onOpenURL { url in
            Task { await handleOpenURL(url) }
        }
        .sheet(item: $router.sheet) { sheet in
            sheetContent(sheet)
        }
        .tint(PrismColors.lavender)
        .font(PrismTypography.body())
    }

    private func importPendingShareIfNeeded() async {
        guard environment.profile?.onboardingCompleted == true else { return }
        guard let payload = MainAppShareInbox.consumePending() else { return }
        router.presentCapture(
            url: payload.urlString,
            title: payload.title ?? payload.text,
            imageData: payload.imageData
        )
    }

    private func handleOpenURL(_ url: URL) async {
        if url.host == "share" || url.path.contains("share") {
            await importPendingShareIfNeeded()
            return
        }
        if url.host == "capture" || url.path.contains("capture") {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let sharedURL = components?.queryItems?.first(where: { $0.name == "url" })?.value
            router.presentCapture(url: sharedURL)
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: AppRouter.Sheet) -> some View {
        switch sheet {
        case .capture:
            CaptureFlowView()
        case .createCollection:
            CreateCollectionView()
        case .itemDetail(let id):
            SavedItemDetailView(itemID: id)
        case .reflection(let id):
            ReflectionEditorView(itemID: id)
        case .buyConfirmation(let id):
            BuyConfirmationView(itemID: id)
        case .keepConsidering(let id):
            KeepConsideringView(itemID: id)
        case .spendingPocketInfo:
            InfoSheetView(
                title: "Spending pocket",
                message: "This is an amount you chose as a comfort boundary for wants this month. Prism never connects to your bank or decides what you can afford. You can change, pause, or ignore this anytime."
            )
        case .estimatedLetGoInfo:
            InfoSheetView(
                title: "Estimated value of items let go",
                message: "This number uses estimates you entered for items you chose not to buy. It does not mean this amount was added to your savings."
            )
        case .goalSetup(let itemID):
            GoalSetupSheetLoader(itemID: itemID)
        case .goalDetail(let id):
            GoalDetailView(goalID: id)
        case .addProgress(let id):
            AddProgressView(goalID: id)
        case .goalFromCollection(let id):
            GoalFromCollectionLoader(collectionID: id)
        case .settings:
            SettingsView()
        case .collectionSort(let id):
            CollectionSortDeckView(collectionID: id)
        case .review(let id):
            ReviewHubView(collectionID: id)
        }
    }
}

/// Loads a collection and its open aspirations before presenting goal setup.
struct GoalFromCollectionLoader: View {
    let collectionID: UUID
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @State private var collection: PrismCollection?
    @State private var items: [SavedItem] = []
    @State private var loaded = false

    var body: some View {
        Group {
            if !loaded {
                ProgressView()
                    .task { await load() }
            } else {
                GoalSetupFlowView(sourceItem: nil, sourceCollection: collection, collectionItems: items)
            }
        }
    }

    private func load() async {
        collection = try? await container.collectionRepository.fetch(id: collectionID)
        if let userID = environment.profile?.id {
            let all = (try? await container.savedItemRepository.fetchAll(userID: userID)) ?? []
            items = all.filter {
                $0.collectionID == collectionID
                    && ($0.status == .considering || $0.status == .readyForReview)
            }
        }
        loaded = true
    }
}

/// Loads optional source aspiration before presenting goal setup.
struct GoalSetupSheetLoader: View {
    let itemID: UUID?
    @EnvironmentObject private var container: DependencyContainer
    @State private var item: SavedItem?
    @State private var loaded = false

    var body: some View {
        Group {
            if itemID != nil && !loaded {
                ProgressView()
                    .task {
                        if let itemID {
                            item = try? await container.savedItemRepository.fetch(id: itemID)
                        }
                        loaded = true
                    }
            } else {
                GoalSetupFlowView(sourceItem: item)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedTab {
                case .home:
                    HomeView()
                case .collections:
                    CollectionsView()
                case .goals:
                    GoalsHubView()
                case .moneyStory:
                    MoneyStoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)

            PrismTabBar(selection: $router.selectedTab)
        }
        .background(Color.clear)
        .ignoresSafeArea(.keyboard)
    }
}

struct InfoSheetView: View {
    let title: String
    let message: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: PrismSpacing.md) {
                Text(title).font(PrismTypography.title())
                Text(message)
                    .font(PrismTypography.body())
                    .foregroundStyle(PrismColors.textSecondary)
                Spacer()
            }
            .padding()
            .background(PrismAtmosphericBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AppLockView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: PrismSpacing.lg) {
            PrismBrandMark(size: 36)
            Text("Prism is locked")
                .font(PrismTypography.title(22))
            Text("Use Face ID or Touch ID to open your archive.")
                .font(PrismTypography.body())
                .foregroundStyle(PrismColors.textSecondary)
                .multilineTextAlignment(.center)
            PrismPrimaryButton(title: "Unlock") {
                Task { await unlock() }
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(PrismColors.danger)
            }
        }
        .padding()
        .task { await unlock() }
    }

    private func unlock() async {
        let ok = await BiometricAuth.authenticate(reason: "Unlock Prism")
        if ok {
            environment.isLocked = false
        } else {
            errorMessage = "Could not unlock. Try again."
        }
    }
}
