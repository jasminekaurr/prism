// Summary: Settings — pocket, cooling-off, notifications, privacy, export, wipe, app lock, legal copy.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer

    @State private var settings = UserSettings.default
    @State private var pocketAmount = ""
    @State private var pocketEnabled = false
    @State private var pocketPaused = false
    @State private var coolingEnabled = true
    @State private var notificationsEnabled = false
    @State private var exportURL: URL?
    @State private var showWipeConfirm = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                Form {
                    Section {
                        HStack {
                            Spacer()
                            PrismBrandMark(size: 22)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        if environment.profile?.isDemoMode == true {
                            Text("Local / demo mode — data is not synced to the cloud.")
                                .font(PrismTypography.caption())
                                .foregroundStyle(PrismColors.textSecondary)
                        }
                    }

                    Section("Spending pocket") {
                        Toggle("Use a spending pocket", isOn: $pocketEnabled)
                            .accessibilityIdentifier("settings.pocket.enabled")
                        Toggle("Pause pocket", isOn: $pocketPaused)
                            .disabled(!pocketEnabled)
                        TextField("Monthly comfort amount", text: $pocketAmount)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("settings.pocket.amount")
                        Text("Prism never calculates what you can afford. This is your guardrail.")
                            .font(.caption)
                        Button("Save pocket") { Task { await savePocket() } }
                            .accessibilityIdentifier("settings.pocket.save")
                    }

                    Section("Cooling-off") {
                        Toggle("Automatic review dates", isOn: $coolingEnabled)
                            .accessibilityIdentifier("settings.cooling")
                        Text("$ 24h · $$ 3d · $$$ 7d · Not sure 3d (defaults)")
                            .font(.caption)
                        Button("Save cooling-off") { Task { await saveCooling() } }
                    }

                    Section("Notifications") {
                        Toggle("Cooling-off reminders", isOn: $notificationsEnabled)
                            .accessibilityIdentifier("settings.notifications")
                        Button("Enable notifications") {
                            Task { await enableNotifications() }
                        }
                        Text("Reminders say an item is ready — not the item title.")
                            .font(.caption)
                    }

                    Section("Privacy & security") {
                        Toggle("App lock (Face ID / Touch ID)", isOn: $settings.appLockEnabled)
                            .accessibilityIdentifier("settings.appLock")
                        Toggle("Anonymous product analytics", isOn: $settings.analyticsEnabled)
                        Button("Save privacy settings") { Task { await saveSettings() } }
                    }

                    Section("Data") {
                        Button("Export my data (JSON)") {
                            Task { await exportData() }
                        }
                        .accessibilityIdentifier("settings.export")
                        if let exportURL {
                            ShareLink(item: exportURL) {
                                Label("Share export file", systemImage: "square.and.arrow.up")
                            }
                        }
                        Button("Delete local data", role: .destructive) {
                            showWipeConfirm = true
                        }
                        .accessibilityIdentifier("settings.deleteLocal")
                    }

                    Section("Account") {
                        Button("Sign in with Apple") {}
                            .disabled(true)
                        Text("Cloud accounts and Sign in with Apple arrive in a later build.")
                            .font(.caption)
                    }

                    Section("Legal") {
                        Text(PrismCopy.financialBoundary)
                            .font(.caption)
                        Text(PrismCopy.privacySummary)
                            .font(.caption)
                    }

                    if let statusMessage {
                        Section {
                            Text(statusMessage)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Delete all local Prism data?", isPresented: $showWipeConfirm, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    Task { await wipe() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .task { await load() }
    }

    private func load() async {
        settings = (try? await container.settingsRepository.load()) ?? .default
        if let profile = environment.profile {
            pocketEnabled = profile.spendingPocket.isEnabled
            pocketPaused = profile.spendingPocket.isPaused
            if let amount = profile.spendingPocket.monthlyAmount {
                pocketAmount = "\(amount)"
            }
            coolingEnabled = profile.defaultCoolingPeriods.enabled
            notificationsEnabled = profile.notificationPreferences.coolingOffRemindersEnabled
        }
    }

    private func savePocket() async {
        guard var profile = environment.profile else { return }
        profile.spendingPocket.isEnabled = pocketEnabled
        profile.spendingPocket.isPaused = pocketPaused
        profile.spendingPocket.monthlyAmount = DecimalParsing.parse(pocketAmount)
        try? await container.profileRepository.save(profile)
        environment.profile = profile
        statusMessage = "Spending pocket updated."
    }

    private func saveCooling() async {
        guard var profile = environment.profile else { return }
        profile.defaultCoolingPeriods.enabled = coolingEnabled
        try? await container.profileRepository.save(profile)
        environment.profile = profile
        statusMessage = "Cooling-off preference saved."
    }

    private func enableNotifications() async {
        let granted = await container.notificationScheduler.requestPermission()
        guard var profile = environment.profile else { return }
        profile.notificationPreferences.permissionAsked = true
        profile.notificationPreferences.coolingOffRemindersEnabled = granted && notificationsEnabled
        try? await container.profileRepository.save(profile)
        environment.profile = profile
        if granted {
            container.analytics.track(.notificationEnabled)
            statusMessage = "Notifications enabled."
        } else {
            statusMessage = "Notifications were not allowed. You can enable them in iOS Settings."
        }
    }

    private func saveSettings() async {
        try? await container.settingsRepository.save(settings)
        environment.isLocked = settings.appLockEnabled
        statusMessage = "Privacy settings saved."
    }

    private func exportData() async {
        guard let profile = environment.profile else { return }
        do {
            let url = try await DataExporter.exportJSON(
                profile: profile,
                collections: try await container.collectionRepository.fetchAll(userID: profile.id),
                items: try await container.savedItemRepository.fetchAll(userID: profile.id)
            )
            exportURL = url
            statusMessage = "Export ready."
        } catch {
            statusMessage = "Export failed."
        }
    }

    private func wipe() async {
        try? await container.profileRepository.deleteAllLocalData()
        environment.profile = nil
        statusMessage = "Local data deleted."
    }
}

enum PrismCopy {
    static let financialBoundary = """
    Prism does not connect to bank accounts, calculate disposable income, or tell you what you can afford. \
    Confirmed prices are only those you enter. Estimates stay labeled as estimates.
    """

    static let privacySummary = """
    Reflections, decisions, and media stay on device in this local build. \
    Analytics (if enabled) never include titles, reflections, prices, URLs, or media.
    """
}
