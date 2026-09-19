// Summary: Money Story dashboard — spending pocket, confirmed spend, patterns; never “money saved.”

import SwiftUI

struct MoneyStoryView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer

    @State private var filter: MoneyStoryTimeFilter = .month
    @State private var snapshot = MoneyStorySnapshot.empty
    @State private var pocket = SpendingPocketSnapshot(
        isActive: false,
        monthlyAmount: nil,
        currencyCode: "USD",
        confirmedSpentThisMonth: 0,
        remaining: nil,
        isPaused: false
    )
    @State private var letGoItems: [SavedItem] = []
    @State private var insight: String = ""
    @State private var primaryGoalLine: String?
    @State private var goalsCompleted = 0
    @State private var goalsRated = 0
    @State private var goalsWorthIt = 0
    @State private var shareImage: Image?

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.lg) {
                        HStack {
                            Spacer()
                            PrismBrandMark(size: 18)
                            Spacer()
                        }
                        Text("Your Money Story")
                            .font(PrismTypography.title())
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("moneyStory.title")

                        Picker("Time", selection: $filter) {
                            ForEach(MoneyStoryTimeFilter.allCases) { f in
                                Text(f.displayName).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: filter) { _, _ in
                            Task { await reload() }
                        }

                        if let shareImage {
                            ShareLink(
                                item: shareImage,
                                preview: SharePreview("My Prism story", image: shareImage)
                            ) {
                                Label("Share my story", systemImage: "square.and.arrow.up")
                                    .font(PrismTypography.caption())
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("moneyStory.share")
                        }

                        pocketCard
                        if let primaryGoalLine {
                            GlassCard {
                                SectionMicroLabel(text: "Priorities")
                                Text(primaryGoalLine)
                                    .font(PrismTypography.body())
                                    .foregroundStyle(PrismColors.textSecondary)
                            }
                            .accessibilityIdentifier("moneyStory.goalInsight")
                        }
                        snapshotCard
                        patternsCard

                        if !letGoItems.isEmpty {
                            VStack(alignment: .leading, spacing: PrismSpacing.sm) {
                                Text("Let go").font(PrismTypography.headline())
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(letGoItems.prefix(10)) { item in
                                            SavedItemCard(item: item, collectionName: nil)
                                                .frame(width: 178)
                                        }
                                    }
                                }
                            }
                        }

                        if snapshot.purchasesConfirmed == 0 && snapshot.itemsLetGo == 0 && snapshot.itemsStillConsidering == 0 {
                            EmptyStateView(
                                title: "Your story begins with a choice",
                                message: "Save items, revisit them, and Prism will reflect the patterns — without judging what you can afford."
                            )
                            .accessibilityIdentifier("moneyStory.empty")
                        }
                    }
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await reload() }
    }

    private var pocketCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Spending pocket")
                            .font(PrismTypography.headline())
                        Button {
                            router.sheet = .spendingPocketInfo
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel("About spending pocket")
                    }
                    if !pocket.isActive || pocket.isPaused {
                        Text(pocket.isPaused ? "Paused — not used as a guide right now." : "Not set. Add a comfort amount in Settings anytime.")
                            .font(PrismTypography.body())
                            .foregroundStyle(PrismColors.textSecondary)
                    } else if let monthly = pocket.monthlyAmount, let remaining = pocket.remaining {
                        Text("Remaining \(CurrencyFormatting.string(from: remaining, currencyCode: pocket.currencyCode)) of \(CurrencyFormatting.string(from: monthly, currencyCode: pocket.currencyCode))")
                            .font(PrismTypography.title(22))
                            .accessibilityIdentifier("moneyStory.pocketRemaining")
                        Text("Confirmed this month: \(CurrencyFormatting.string(from: pocket.confirmedSpentThisMonth, currencyCode: pocket.currencyCode))")
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var snapshotCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PrismSpacing.sm) {
                Text("Snapshot").font(PrismTypography.headline())
                metric("Purchases confirmed", "\(snapshot.purchasesConfirmed)")
                metric(
                    "Confirmed amount spent",
                    CurrencyFormatting.string(from: snapshot.confirmedAmountSpent, currencyCode: pocket.currencyCode)
                )
                if snapshot.purchasesMissingPrice > 0 {
                    Text("Based on \(snapshot.confirmedSpendSampleSize) of \(snapshot.purchasesConfirmed) purchases with a recorded price.")
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textTertiary)
                }
                metric("Items let go", "\(snapshot.itemsLetGo)")
                metric("Still considering", "\(snapshot.itemsStillConsidering)")
                metric("Impulses paused", "\(snapshot.impulsesPaused)")
                if snapshot.regretAnswered > 0 {
                    metric("Glad you bought", "\(snapshot.regretGlad) of \(snapshot.regretAnswered)")
                        .accessibilityIdentifier("moneyStory.regret")
                }
                if goalsCompleted > 0 {
                    metric("Goals completed", "\(goalsCompleted)")
                    if goalsRated > 0 {
                        metric("Goals that felt worth it", "\(goalsWorthIt) of \(goalsRated)")
                    }
                }
                if let avg = snapshot.averageHoursToDecision {
                    metric("Avg. hours to decide", String(format: "%.0f", avg))
                }
                if let estimated = snapshot.estimatedValueOfItemsLetGo {
                    HStack {
                        metric(
                            "Estimated value of items let go",
                            CurrencyFormatting.string(from: estimated, currencyCode: pocket.currencyCode)
                        )
                        Button {
                            router.sheet = .estimatedLetGoInfo
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel("About estimated let go value")
                    }
                }
                if !insight.isEmpty {
                    Text(insight)
                        .font(PrismTypography.body())
                        .foregroundStyle(PrismColors.textSecondary)
                        .padding(.top, 4)
                        .accessibilityIdentifier("moneyStory.insight")
                }
            }
        }
    }

    private var patternsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Patterns").font(PrismTypography.headline())
                if snapshot.commonFeelings.isEmpty && snapshot.commonIntents.isEmpty {
                    Text("Feelings and categories will appear as you reflect.")
                        .foregroundStyle(PrismColors.textSecondary)
                }
                ForEach(snapshot.commonFeelings, id: \.name) { row in
                    Text("\(row.name) · \(row.count)")
                        .font(PrismTypography.caption())
                }
                ForEach(snapshot.commonIntents, id: \.intent) { row in
                    Text("\(row.intent.displayName) · \(row.count)")
                        .font(PrismTypography.caption())
                }
            }
        }
    }

    @MainActor
    private func renderShareImage(_ data: ShareCardData) -> Image? {
        let renderer = ImageRenderer(content: MoneyStoryShareCard(data: data))
        renderer.scale = 3
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(PrismColors.textSecondary)
            Spacer()
            Text(value).font(PrismTypography.headline())
        }
        .font(PrismTypography.body())
    }

    private func reload() async {
        guard let profile = environment.profile else { return }
        let items = (try? await container.savedItemRepository.fetchAll(userID: profile.id)) ?? []
        var feelingsByItem: [UUID: [Feeling]] = [:]
        for item in items {
            feelingsByItem[item.id] = (try? await container.feelingRepository.feelings(for: item.id)) ?? []
        }
        snapshot = container.moneyStoryService.snapshot(items: items, feelingsByItem: feelingsByItem, filter: filter)
        pocket = container.spendingPocketService.snapshot(settings: profile.spendingPocket, items: items)
        letGoItems = items.filter { $0.status == .letGo }

        let goals = (try? await container.goalRepository.fetchAll(userID: profile.id)) ?? []
        let completedGoals = goals.filter { $0.trackStatus == .completed }
        let ratings = completedGoals.compactMap(\.outcomeRating)
        goalsCompleted = completedGoals.count
        goalsRated = ratings.count
        goalsWorthIt = ratings.filter { $0 == .worthIt }.count
        if let primary = goals.first(where: { $0.priority == .primary }) {
            let pace = container.goalPlanningService.pace(for: primary)
            let contribs = (try? await container.goalRepository.fetchContributions(goalID: primary.id)) ?? []
            let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
            let monthFinancial = contribs
                .filter { $0.kind == .financial && $0.createdAt >= monthStart }
                .compactMap(\.amount)
                .reduce(Decimal(0), +)
            let planningCount = contribs.filter { $0.kind == .planning && $0.createdAt >= monthStart }.count
            var parts: [String] = ["\(primary.title) is your primary goal."]
            if monthFinancial > 0 {
                parts.append("You contributed \(CurrencyFormatting.string(from: monthFinancial, currencyCode: primary.currencyCode)) this month.")
            }
            parts.append("Status: \(pace.trackStatus.displayName.lowercased()).")
            if planningCount > 0 {
                parts.append("You also completed \(planningCount) planning milestone\(planningCount == 1 ? "" : "s").")
            }
            if snapshot.itemsLetGo > 0 {
                parts.append("You let go of \(snapshot.itemsLetGo) aspiration\(snapshot.itemsLetGo == 1 ? "" : "s") while keeping this priority in view.")
            }
            primaryGoalLine = parts.joined(separator: " ")
        } else {
            primaryGoalLine = nil
        }

        let primaryForCard = goals.first { $0.priority == .primary && $0.trackStatus != .abandoned }
        let percent = primaryForCard.flatMap { container.goalPlanningService.percentFunded(for: $0) }
        shareImage = await renderShareImage(
            ShareCardData(
                period: filter.displayName,
                paused: snapshot.impulsesPaused,
                letGo: snapshot.itemsLetGo,
                purchased: snapshot.purchasesConfirmed,
                goalsCompleted: goalsCompleted,
                primaryGoalPercent: percent.map { Int($0.rounded()) }
            )
        )

        if let topIntent = snapshot.commonIntents.first,
           let topFeeling = snapshot.commonFeelings.first {
            insight = "You saved \(items.count) items in this period. Most were tagged “\(topFeeling.name),” and you chose to buy \(snapshot.purchasesConfirmed) after reviewing them. Top intent: \(topIntent.intent.displayName)."
        } else if !items.isEmpty {
            insight = "You’ve paused \(snapshot.impulsesPaused) impulses in this view. Patterns deepen as you add reflections and fund goals."
        } else {
            insight = ""
        }
    }
}

/// Counts only: no item titles, no goal titles, no prices.
struct ShareCardData: Equatable {
    var period: String
    var paused: Int
    var letGo: Int
    var purchased: Int
    var goalsCompleted: Int
    var primaryGoalPercent: Int?
}

/// Rendered to an image for sharing. Uses plain shapes only; materials do not render reliably off-screen.
struct MoneyStoryShareCard: View {
    let data: ShareCardData

    var body: some View {
        VStack(spacing: 20) {
            Text("Prism")
                .font(PrismTypography.display(30))
            Text("My Money Story \u{00B7} \(data.period)")
                .font(PrismTypography.caption())
                .foregroundStyle(PrismColors.textSecondary)
            VStack(spacing: 4) {
                Text("\(data.paused)")
                    .font(PrismTypography.display(72))
                Text(data.paused == 1 ? "impulse paused" : "impulses paused")
                    .font(PrismTypography.body())
                    .foregroundStyle(PrismColors.textSecondary)
            }
            HStack(spacing: 28) {
                stat(value: data.letGo, label: "let go")
                stat(value: data.purchased, label: "chosen on purpose")
                if data.goalsCompleted > 0 {
                    stat(value: data.goalsCompleted, label: data.goalsCompleted == 1 ? "goal done" : "goals done")
                }
            }
            if let percent = data.primaryGoalPercent {
                VStack(spacing: 6) {
                    Text("Primary goal \(percent)% funded")
                        .font(PrismTypography.caption())
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.18))
                        Capsule()
                            .fill(PrismColors.cyan)
                            .frame(width: 220 * CGFloat(min(max(percent, 0), 100)) / 100)
                    }
                    .frame(width: 220, height: 8)
                }
            }
            Spacer(minLength: 0)
            Text("Turn impulse into inspiration.")
                .font(PrismTypography.caption())
                .foregroundStyle(PrismColors.textTertiary)
        }
        .foregroundStyle(PrismColors.textPrimary)
        .padding(28)
        .frame(width: 360, height: 450)
        .background(PrismGradients.atmospheric)
    }

    private func stat(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(PrismTypography.title(28))
            Text(label)
                .font(PrismTypography.caption())
                .foregroundStyle(PrismColors.textSecondary)
        }
    }
}
