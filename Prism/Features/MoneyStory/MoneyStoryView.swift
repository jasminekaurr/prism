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

                        pocketCard
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

        if let topIntent = snapshot.commonIntents.first,
           let topFeeling = snapshot.commonFeelings.first {
            insight = "You saved \(items.count) items in this period. Most were tagged “\(topFeeling.name),” and you chose to buy \(snapshot.purchasesConfirmed) after reviewing them. Top intent: \(topIntent.intent.displayName)."
        } else if !items.isEmpty {
            insight = "You’ve paused \(snapshot.impulsesPaused) impulses in this view. Patterns deepen as you add reflections."
        } else {
            insight = ""
        }
    }
}
