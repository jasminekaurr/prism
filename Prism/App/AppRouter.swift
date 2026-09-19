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
        }
        .sheet(item: $router.sheet) { sheet in
            sheetContent(sheet)
        }
        .tint(PrismColors.lavender)
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
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "square.grid.2x2") }
                .tag(AppRouter.Tab.home)
                .accessibilityIdentifier("tab.home")

            CollectionsView()
                .tabItem { Label("Collections", systemImage: "rectangle.stack") }
                .tag(AppRouter.Tab.collections)
                .accessibilityIdentifier("tab.collections")

            ReviewHubView()
                .tabItem { Label("Review", systemImage: "sparkles") }
                .tag(AppRouter.Tab.review)
                .accessibilityIdentifier("tab.review")

            MoneyStoryView()
                .tabItem { Label("Story", systemImage: "chart.bar") }
                .tag(AppRouter.Tab.moneyStory)
                .accessibilityIdentifier("tab.moneyStory")

            SettingsView()
                .tabItem { Label("Settings", systemImage: "person.crop.circle") }
                .tag(AppRouter.Tab.settings)
                .accessibilityIdentifier("tab.settings")
        }
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
