// Summary: Home masonry grid with search, filters, and quick-add entry.

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer

    @State private var items: [SavedItem] = []
    @State private var collections: [PrismCollection] = []
    @State private var search = ""
    @State private var statusFilter: ItemStatus?
    @State private var intentFilter: SaveIntent?
    @StateObject private var viewModel = HomeViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: PrismSpacing.sm),
        GridItem(.flexible(), spacing: PrismSpacing.sm)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                PrismAtmosphericBackground()
                VStack(spacing: PrismSpacing.sm) {
                    header
                    filterRow
                    if filteredItems.isEmpty {
                        EmptyStateView(
                            title: "Your archive is open",
                            message: "Save something that caught your eye. You can reflect later.",
                            actionTitle: "Add",
                            action: { router.sheet = .capture }
                        )
                        .accessibilityIdentifier("home.empty")
                    } else {
                        ScrollView {
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
                            .padding(.bottom, 80)
                        }
                        .accessibilityIdentifier("home.grid")
                    }
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
                .accessibilityLabel("Add item")
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
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $search)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("home.search")
            }
            .padding(PrismSpacing.sm)
            .background(GlassCard(padding: 0) { Color.clear.frame(height: 1) }.opacity(0))
            .background {
                RoundedRectangle(cornerRadius: PrismRadius.md)
                    .fill(PrismColors.glassFill)
                    .overlay { RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke) }
            }
            .padding(.horizontal, PrismSpacing.md)
        }
        .padding(.top, PrismSpacing.sm)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                filterChip("All", selected: statusFilter == nil && intentFilter == nil) {
                    statusFilter = nil
                    intentFilter = nil
                }
                ForEach(ItemStatus.allCases) { status in
                    filterChip(status.displayName, selected: statusFilter == status) {
                        statusFilter = status
                    }
                }
            }
            .padding(.horizontal, PrismSpacing.md)
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

    private var filteredItems: [SavedItem] {
        items.filter { item in
            if let statusFilter, item.status != statusFilter { return false }
            if let intentFilter, item.intent != intentFilter { return false }
            if search.isEmpty { return true }
            return item.title.localizedCaseInsensitiveContains(search)
                || (item.notes?.localizedCaseInsensitiveContains(search) ?? false)
        }
    }

    private func collectionName(for item: SavedItem) -> String? {
        collections.first { $0.id == item.collectionID }?.name
    }

    private func reload() async {
        guard let userID = environment.profile?.id else { return }
        items = (try? await container.savedItemRepository.fetchAll(userID: userID)) ?? []
        collections = (try? await container.collectionRepository.fetchAll(userID: userID)) ?? []
        // Promote due items to readyForReview status in UI list
        let ready = (try? await container.savedItemRepository.fetchReadyForReview(userID: userID, asOf: .now)) ?? []
        for item in ready where item.status == .readyForReview {
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx].status = .readyForReview
            }
        }
    }
}

@MainActor
final class HomeViewModel: ObservableObject {}

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
