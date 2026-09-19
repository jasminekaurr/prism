// Summary: Home leads with primary/active goals, then aspiration feed for saves still considering.

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer

    @State private var items: [SavedItem] = []
    @State private var collections: [PrismCollection] = []
    @State private var goals: [PrismGoal] = []
    @State private var search = ""
    @State private var statusFilter: ItemStatus?

    private let columns = [
        GridItem(.flexible(), spacing: PrismSpacing.sm),
        GridItem(.flexible(), spacing: PrismSpacing.sm)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.lg) {
                        header
                        goalsSection
                        aspirationsSection
                    }
                    .padding(.bottom, 88)
                }

                Button {
                    router.sheet = .capture
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.black.opacity(0.85)).shadow(color: PrismColors.violet.opacity(0.5), radius: 12))
                }
                .padding(PrismSpacing.lg)
                .accessibilityIdentifier("home.add")
                .accessibilityLabel("Add aspiration")
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await reload() }
        .onChange(of: router.sheet) { _, new in
            if new == nil { Task { await reload() } }
        }
    }

    private var header: some View {
        VStack(spacing: PrismSpacing.sm) {
            PrismBrandMark()
            Text("Save what inspires you. Work toward what matters.")
                .font(PrismTypography.caption())
                .foregroundStyle(PrismColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search aspirations", text: $search)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("home.search")
            }
            .padding(PrismSpacing.sm)
            .background {
                RoundedRectangle(cornerRadius: PrismRadius.md)
                    .fill(PrismColors.glassFill)
                    .overlay { RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke) }
            }
            .padding(.horizontal, PrismSpacing.md)
        }
        .padding(.top, PrismSpacing.sm)
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            HStack {
                Text("Working toward")
                    .font(PrismTypography.title(22))
                Spacer()
                Button("New goal") {
                    router.sheet = .goalSetup(nil)
                }
                .font(PrismTypography.caption())
                .accessibilityIdentifier("home.newGoal")
            }
            .padding(.horizontal, PrismSpacing.md)

            if primaryGoal == nil && activeGoals.isEmpty {
                GlassCard {
                    EmptyStateView(
                        title: "Turn inspiration into a goal",
                        message: "When something matters enough, make it a goal — with a target, a date, and progress you control.",
                        actionTitle: "Make a goal",
                        action: { router.sheet = .goalSetup(nil) }
                    )
                }
                .padding(.horizontal, PrismSpacing.md)
                .accessibilityIdentifier("home.goalsEmpty")
            } else {
                if let primary = primaryGoal {
                    Button {
                        router.sheet = .goalDetail(primary.id)
                    } label: {
                        GoalCardView(goal: primary, pace: container.goalPlanningService.pace(for: primary), isPrimary: true)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, PrismSpacing.md)
                    .accessibilityIdentifier("home.primaryGoal")
                }
                ForEach(activeGoals.filter { $0.id != primaryGoal?.id }) { goal in
                    Button {
                        router.sheet = .goalDetail(goal.id)
                    } label: {
                        GoalCardView(goal: goal, pace: container.goalPlanningService.pace(for: goal), isPrimary: false)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, PrismSpacing.md)
                }
            }

            if !pausedOrFinishedGoals.isEmpty {
                Text("Paused & finished")
                    .font(PrismTypography.headline())
                    .foregroundStyle(PrismColors.textSecondary)
                    .padding(.horizontal, PrismSpacing.md)
                    .padding(.top, PrismSpacing.xs)
                ForEach(pausedOrFinishedGoals) { goal in
                    Button {
                        router.sheet = .goalDetail(goal.id)
                    } label: {
                        GoalCardView(goal: goal, pace: container.goalPlanningService.pace(for: goal), isPrimary: false)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, PrismSpacing.md)
                    .accessibilityIdentifier("home.finishedGoal.\(goal.id.uuidString)")
                }
            }
        }
    }

    private var aspirationsSection: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            Text("Aspirations")
                .font(PrismTypography.title(22))
                .padding(.horizontal, PrismSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    filterChip("All", selected: statusFilter == nil) { statusFilter = nil }
                    ForEach([ItemStatus.considering, .readyForReview, .purchased, .letGo], id: \.self) { status in
                        filterChip(status.displayName, selected: statusFilter == status) {
                            statusFilter = status
                        }
                    }
                }
                .padding(.horizontal, PrismSpacing.md)
            }

            if filteredItems.isEmpty {
                Text("Save something that caught your eye. Reflect later — or make it a goal when you’re ready.")
                    .font(PrismTypography.body())
                    .foregroundStyle(PrismColors.textSecondary)
                    .padding(.horizontal, PrismSpacing.md)
                    .accessibilityIdentifier("home.empty")
            } else {
                LazyVGrid(columns: columns, spacing: PrismSpacing.sm) {
                    ForEach(filteredItems) { item in
                        Button {
                            router.sheet = .itemDetail(item.id)
                        } label: {
                            SavedItemCard(item: item, collectionName: collectionName(for: item))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.item.\(item.id.uuidString)")
                    }
                }
                .padding(.horizontal, PrismSpacing.md)
                .accessibilityIdentifier("home.grid")
            }
        }
    }

    private var primaryGoal: PrismGoal? {
        goals.first { $0.priority == .primary && $0.trackStatus != .completed && $0.trackStatus != .abandoned }
    }

    private var activeGoals: [PrismGoal] {
        goals.filter {
            ($0.priority == .active || $0.priority == .primary)
                && $0.trackStatus != .completed
                && $0.trackStatus != .abandoned
                && $0.trackStatus != .paused
        }
    }

    private var pausedOrFinishedGoals: [PrismGoal] {
        goals.filter { $0.trackStatus == .paused || $0.trackStatus == .completed }
    }

    private var filteredItems: [SavedItem] {
        items.filter { item in
            if let statusFilter, item.status != statusFilter { return false }
            if search.isEmpty { return true }
            return item.title.localizedCaseInsensitiveContains(search)
                || (item.notes?.localizedCaseInsensitiveContains(search) ?? false)
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(PrismTypography.caption())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule().fill(selected ? PrismColors.violet.opacity(0.7) : PrismColors.glassFill)
                }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 40)
    }

    private func collectionName(for item: SavedItem) -> String? {
        collections.first { $0.id == item.collectionID }?.name
    }

    private func reload() async {
        guard let userID = environment.profile?.id else { return }
        items = (try? await container.savedItemRepository.fetchAll(userID: userID)) ?? []
        collections = (try? await container.collectionRepository.fetchAll(userID: userID)) ?? []
        goals = (try? await container.goalRepository.fetchAll(userID: userID)) ?? []
    }
}

struct GoalCardView: View {
    let goal: PrismGoal
    let pace: GoalPaceSnapshot
    var isPrimary: Bool

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PrismSpacing.sm) {
                HStack {
                    if isPrimary {
                        TagPill(text: "Primary", color: PrismColors.tagFashion)
                    }
                    TagPill(text: pace.trackStatus.displayName, color: PrismColors.lavender, filled: false)
                    Spacer()
                }
                Text(goal.title)
                    .font(PrismTypography.title(22))
                    .foregroundStyle(PrismColors.textPrimary)
                if let target = goal.targetAmount {
                    Text("\(CurrencyFormatting.string(from: goal.amountSaved, currencyCode: goal.currencyCode)) of \(CurrencyFormatting.string(from: target, currencyCode: goal.currencyCode))")
                        .font(PrismTypography.headline())
                    ProgressView(value: (pace.percentFunded ?? 0) / 100)
                        .tint(PrismColors.cyan)
                }
                if let required = pace.requiredPerPeriod {
                    Text("\(CurrencyFormatting.string(from: required, currencyCode: goal.currencyCode)) needed this \(pace.periodLabel)")
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textSecondary)
                }
                if let date = goal.targetDate {
                    Text(date, style: .date)
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textTertiary)
                }
            }
        }
    }
}

struct SavedItemCard: View {
    let item: SavedItem
    var collectionName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.xs) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: PrismRadius.md, style: .continuous)
                    .fill(PrismColors.violet.opacity(0.35))
                    .frame(height: 140)
                    .overlay {
                        if let domain = item.sourceDomain {
                            Text(domain)
                                .font(PrismTypography.caption())
                                .foregroundStyle(PrismColors.textSecondary)
                        } else {
                            Image(systemName: "photo")
                                .foregroundStyle(PrismColors.textTertiary)
                        }
                    }
                if item.sourceDomain != nil {
                    Image(systemName: "link")
                        .font(.caption2)
                        .padding(6)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                        .padding(8)
                }
            }
            Text(item.title)
                .font(PrismTypography.headline())
                .lineLimit(2)
                .foregroundStyle(PrismColors.textPrimary)
            HStack {
                TagPill(text: item.intent.displayName, color: intentColor(item.intent))
                if let cost = item.costSignificance {
                    TagPill(text: cost.shortLabel, color: PrismColors.tagPriority, filled: true)
                }
            }
        }
        .padding(PrismSpacing.xs)
        .background {
            RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous)
                .fill(PrismColors.glassFill)
                .overlay {
                    RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous)
                        .stroke(PrismColors.glassStroke, lineWidth: 1)
                }
        }
    }

    private func intentColor(_ intent: SaveIntent) -> Color {
        switch intent {
        case .want: return PrismColors.tagWant
        case .need: return PrismColors.tagNeed
        case .dream: return PrismColors.tagDream
        case .gift: return PrismColors.tagGift
        }
    }
}
