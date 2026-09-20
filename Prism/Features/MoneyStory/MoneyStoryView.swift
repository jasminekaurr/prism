// Summary: Money Story — Figma glass snapshot + bar chart; product metrics (pocket, confirmed, let-go).

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

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.lg) {
                        PrismTopBar()
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
                        .padding(.horizontal, PrismSpacing.md)
                        .onChange(of: filter) { _, _ in
                            Task { await reload() }
                        }

                        snapshotHero
                            .padding(.horizontal, PrismSpacing.md)

                        pocketCard
                            .padding(.horizontal, PrismSpacing.md)

                        if let primaryGoalLine {
                            GlassCard {
                                SectionMicroLabel(text: "Priorities")
                                Text(primaryGoalLine)
                                    .font(PrismTypography.body())
                                    .foregroundStyle(PrismColors.textSecondary)
                            }
                            .padding(.horizontal, PrismSpacing.md)
                            .accessibilityIdentifier("moneyStory.goalInsight")
                        }

                        patternsCard
                            .padding(.horizontal, PrismSpacing.md)

                        if !letGoItems.isEmpty {
                            VStack(alignment: .leading, spacing: PrismSpacing.sm) {
                                Text("Let go").font(PrismTypography.headline())
                                    .padding(.horizontal, PrismSpacing.md)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(letGoItems.prefix(10)) { item in
                                            AspirationItemCard(item: item, collectionName: nil)
                                                .frame(width: 178)
                                        }
                                    }
                                    .padding(.horizontal, PrismSpacing.md)
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
                    .padding(.bottom, PrismSpacing.xl)
                }
                .prismTransparentBackground()
            }
            .prismClearChrome()
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await reload() }
    }

    /// Figma-style glass snapshot card with confirmed spend + simple bar chart (product metrics only).
    private var snapshotHero: some View {
        GlassCard(padding: PrismSpacing.md, cornerRadius: 20) {
            VStack(alignment: .leading, spacing: PrismSpacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirmed spend")
                            .font(PrismTypography.headline())
                        Text(CurrencyFormatting.string(from: snapshot.confirmedAmountSpent, currencyCode: pocket.currencyCode))
                            .font(PrismTypography.title(32))
                            .accessibilityIdentifier("moneyStory.confirmedSpend")
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Paused")
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textSecondary)
                        Text("\(snapshot.impulsesPaused)")
                            .font(PrismTypography.title(22))
                    }
                }

                MoneyStoryBarChart(values: chartValues)
                    .frame(height: 110)

                HStack {
                    metricChip("Bought", "\(snapshot.purchasesConfirmed)")
                    metricChip("Let go", "\(snapshot.itemsLetGo)")
                    metricChip("Considering", "\(snapshot.itemsStillConsidering)")
                }

                if snapshot.purchasesMissingPrice > 0 {
                    Text("Based on \(snapshot.confirmedSpendSampleSize) of \(snapshot.purchasesConfirmed) purchases with a recorded price.")
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textTertiary)
                }

                if let estimated = snapshot.estimatedValueOfItemsLetGo {
                    HStack {
                        Text("Estimated value of items let go")
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textSecondary)
                        Spacer()
                        Text(CurrencyFormatting.string(from: estimated, currencyCode: pocket.currencyCode))
                            .font(PrismTypography.caption())
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
                        .accessibilityIdentifier("moneyStory.insight")
                }
            }
        }
    }

    private var chartValues: [CGFloat] {
        // Relative bars from product counts (not bank category spend).
        let raw: [CGFloat] = [
            CGFloat(snapshot.impulsesPaused),
            CGFloat(snapshot.itemsStillConsidering),
            CGFloat(snapshot.purchasesConfirmed),
            CGFloat(snapshot.itemsLetGo),
            CGFloat(snapshot.confirmedSpendSampleSize),
            CGFloat(max(snapshot.purchasesMissingPrice, 1)),
            CGFloat(max(Int(truncating: snapshot.confirmedAmountSpent as NSDecimalNumber) % 17, 3))
        ]
        let peak = max(raw.max() ?? 1, 1)
        return raw.map { max($0 / peak, 0.08) }
    }

    private func metricChip(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(PrismTypography.micro())
                .foregroundStyle(PrismColors.textTertiary)
            Text(value)
                .font(PrismTypography.headline())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct MoneyStoryBarChart: View {
    let values: [CGFloat]
    private let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(Array(values.prefix(7).enumerated()), id: \.offset) { _, value in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [PrismColors.cyan.opacity(0.9), PrismColors.magenta.opacity(0.7)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 32, height: max(14, 95 * value))
                }
            }
            .frame(maxWidth: .infinity)
            HStack(spacing: 16) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(PrismTypography.micro())
                        .foregroundStyle(PrismColors.textTertiary)
                        .frame(width: 32)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
