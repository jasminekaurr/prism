// Summary: Figma Home — aspiration masonry with All / Collections; profile opens Settings.

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer

    @State private var items: [SavedItem] = []
    @State private var collections: [PrismCollection] = []
    @State private var search = ""
    @State private var segment: HomeSegment = .all
    @State private var showStatusFilter = false
    @State private var statusFilter: ItemStatus?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private enum HomeSegment: String, CaseIterable {
        case all = "All"
        case collections = "Collections"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.md) {
                        PrismTopBar()
                        PrismSearchChrome(search: $search) {
                            router.selectedTab = .settings
                        }
                        segmentRow
                        if segment == .all {
                            allFeed
                        } else {
                            CollectionsEmbeddedView(collections: collections, itemCounts: itemCounts)
                        }
                    }
                    .padding(.bottom, 88)
                }
                .prismTransparentBackground()

                Button {
                    router.presentCapture()
                } label: {
                    Image(systemName: "plus")
                        .font(PrismTypography.title(22))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.black.opacity(0.85)).shadow(color: PrismColors.violet.opacity(0.5), radius: 12))
                }
                .padding(PrismSpacing.lg)
                .accessibilityIdentifier("home.add")
                .accessibilityLabel("Add aspiration")
            }
            .prismClearChrome()
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Filter by status", isPresented: $showStatusFilter, titleVisibility: .visible) {
                Button("All statuses") { statusFilter = nil }
                ForEach([ItemStatus.considering, .readyForReview, .purchased, .letGo], id: \.self) { status in
                    Button(status.displayName) { statusFilter = status }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .task { await reload() }
        .onChange(of: router.sheet) { _, new in
            if new == nil { Task { await reload() } }
        }
    }

    private var segmentRow: some View {
        HStack(spacing: PrismSpacing.sm) {
            ForEach(HomeSegment.allCases, id: \.self) { seg in
                Button {
                    withAnimation(.easeInOut(duration: PrismMotion.quick)) { segment = seg }
                } label: {
                    VStack(spacing: 4) {
                        Text(seg.rawValue)
                            .font(PrismTypography.body(16, weight: segment == seg ? .semibold : .regular))
                            .foregroundStyle(.white)
                        Rectangle()
                            .fill(segment == seg ? Color.white : Color.clear)
                            .frame(height: 1)
                            .frame(width: seg == .all ? 30 : 90)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(seg == .all ? "home.segment.all" : "home.segment.collections")
            }
            Spacer()
            Button {
                showStatusFilter = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
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
        .padding(.horizontal, PrismSpacing.md)
    }

    private var allFeed: some View {
        Group {
            if filteredItems.isEmpty {
                Text("Save something that caught your eye. Reflect later — or make it a goal when you’re ready.")
                    .font(PrismTypography.body())
                    .foregroundStyle(PrismColors.textSecondary)
                    .padding(.horizontal, PrismSpacing.md)
                    .accessibilityIdentifier("home.empty")
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredItems) { item in
                        Button {
                            router.sheet = .itemDetail(item.id)
                        } label: {
                            AspirationItemCard(item: item, collectionName: collectionName(for: item))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.item.\(item.id.uuidString)")
                    }
                }
                .padding(.horizontal, 10)
                .accessibilityIdentifier("home.grid")
            }
        }
    }

    private var itemCounts: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for item in items {
            if let cid = item.collectionID {
                counts[cid, default: 0] += 1
            }
        }
        return counts
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

    private func collectionName(for item: SavedItem) -> String? {
        collections.first { $0.id == item.collectionID }?.name
    }

    private func reload() async {
        guard let profile = environment.profile else { return }
        if profile.isDemoMode {
            await DemoDataSeeder.seedIfNeeded(userID: profile.id, container: container)
        }
        items = (try? await container.savedItemRepository.fetchAll(userID: profile.id)) ?? []
        collections = (try? await container.collectionRepository.fetchAll(userID: profile.id)) ?? []
    }
}

/// Collections list embedded under Home’s Collections segment.
struct CollectionsEmbeddedView: View {
    @EnvironmentObject private var router: AppRouter
    let collections: [PrismCollection]
    let itemCounts: [UUID: Int]

    var body: some View {
        VStack(spacing: PrismSpacing.sm) {
            if collections.isEmpty {
                EmptyStateView(
                    title: "Start a collection",
                    message: "Group the things you’re considering — fashion, gifts, a first apartment, or a dream.",
                    actionTitle: "Create",
                    action: { router.sheet = .createCollection }
                )
                .accessibilityIdentifier("collections.empty")
            } else {
                ForEach(collections) { collection in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(collection.name)
                                    .font(PrismTypography.headline())
                                Text("\(itemCounts[collection.id, default: 0]) items")
                                    .font(PrismTypography.caption())
                                    .foregroundStyle(PrismColors.textSecondary)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, PrismSpacing.md)
                    .accessibilityIdentifier("collections.item.\(collection.id.uuidString)")
                }
            }
            PrismPrimaryButton(title: "New collection") {
                router.sheet = .createCollection
            }
            .accessibilityIdentifier("collections.create")
            .padding(.horizontal, PrismSpacing.md)
        }
    }
}
