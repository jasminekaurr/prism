// Summary: Home — saves grid with search + filters; profile → Settings (recreation screen 02).

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer

    @State private var items: [SavedItem] = []
    @State private var collections: [PrismCollection] = []
    @State private var search = ""
    @State private var filter: HomeFilter = .all

    private enum HomeFilter: String, CaseIterable {
        case all = "All"
        case highPriority = "High priority"
        case undecided = "Undecided"
        case videos = "Videos"
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.md) {
                        PrismTopBar()
                            .padding(.horizontal, PrismSpacing.md)

                        PrismSearchChrome(search: $search) {
                            router.sheet = .settings
                        }

                        filterRow

                        if filteredItems.isEmpty {
                            Text("Save something that caught your eye. Reflect later — or make it a goal when you’re ready.")
                                .font(PrismTypography.body())
                                .foregroundStyle(PrismColors.textSecondary)
                                .padding(.horizontal, PrismSpacing.md)
                                .padding(.top, PrismSpacing.lg)
                                .accessibilityIdentifier("home.empty")
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredItems) { item in
                                    Button {
                                        router.sheet = .itemDetail(item.id)
                                    } label: {
                                        homeCard(for: item)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .accessibilityIdentifier("home.item.\(item.id.uuidString)")
                                }
                            }
                            .padding(.horizontal, PrismSpacing.md)
                            .accessibilityIdentifier("home.grid")
                        }
                    }
                    .padding(.bottom, 110)
                }
                .prismTransparentBackground()

                Button {
                    router.presentCapture()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(PrismColors.buttonDark))
                }
                .padding(.trailing, PrismSpacing.lg)
                .padding(.bottom, 88)
                .accessibilityIdentifier("home.add")
                .accessibilityLabel("Paste anything")
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await reload() }
        .onChange(of: router.sheet) { _, new in
            if new == nil { Task { await reload() } }
        }
    }

    private var filterRow: some View {
        PrismSegmentedControl(options: HomeFilter.allCases, selection: $filter) { $0.rawValue }
            .padding(.horizontal, PrismSpacing.md)
    }

    @ViewBuilder
    private func homeCard(for item: SavedItem) -> some View {
        SavedItemCard(item: item, collectionName: nil, showPlay: looksLikeVideo(item), tags: cardTags(for: item))
    }

    private func cardTags(for item: SavedItem) -> [(String, PrismTone)] {
        var result: [(String, PrismTone)] = [(item.intent.displayName, .intent)]
        if let priority = item.priority, priority != .undecided {
            result.append((priority.displayName, .priority))
        }
        if let cost = item.costSignificance {
            result.append((cost.shortLabel, .topic))
        }
        return result
    }

    private func looksLikeVideo(_ item: SavedItem) -> Bool {
        let url = item.sourceURL?.absoluteString.lowercased() ?? ""
        return url.contains("reel") || url.contains("tiktok") || url.contains("/video")
    }

    private var filteredItems: [SavedItem] {
        items.filter { item in
            switch filter {
            case .all: break
            case .highPriority:
                if item.priority != .mustHave { return false }
            case .undecided:
                if item.priority != .undecided && item.priority != nil { return false }
            case .videos:
                if !looksLikeVideo(item) { return false }
            }
            if search.isEmpty { return true }
            return item.title.localizedCaseInsensitiveContains(search)
                || (item.notes?.localizedCaseInsensitiveContains(search) ?? false)
        }
        .sorted { $0.createdAt > $1.createdAt }
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

struct SavedItemCard: View {
    let item: SavedItem
    var collectionName: String?
    var showPlay: Bool = false
    var tags: [(String, PrismTone)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                AspirationMediaView(item: item, height: 162)
                    .frame(maxWidth: .infinity)
                    .frame(height: 162)
                    .clipped()
                    .overlay(PrismGradients.cardFade)
                    .clipShape(RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous))
                if showPlay {
                    PlayBadge(size: 36)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 162)
            .clipped()

            HStack(spacing: 6) {
                ForEach(Array(resolvedTags.prefix(2).enumerated()), id: \.offset) { _, pair in
                    TagPill(text: pair.0, tone: pair.1)
                }
                Spacer(minLength: 0)
            }
            .frame(height: 28, alignment: .leading)
            .clipped()
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous)
                .fill(PrismColors.glassFill)
                .overlay {
                    RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous)
                        .stroke(PrismColors.glassStroke, lineWidth: 1)
                }
        }
    }

    private var resolvedTags: [(String, PrismTone)] {
        if !tags.isEmpty { return tags }
        var result: [(String, PrismTone)] = [(item.intent.displayName, .intent)]
        if let cost = item.costSignificance {
            result.append((cost.shortLabel, .priority))
        }
        return result
    }
}

/// Shared goal card used on Goals hub (and elsewhere).
struct GoalCardView: View {
    let goal: PrismGoal
    let pace: GoalPaceSnapshot
    var isPrimary: Bool

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PrismSpacing.sm) {
                HStack {
                    Text(isPrimary ? "PRIMARY GOAL" : goal.priority.displayName.uppercased())
                        .font(PrismTypography.mono)
                        .foregroundStyle(Color.white.opacity(0.7))
                    Spacer()
                    statusChip
                }
                Text(goal.title)
                    .font(PrismTypography.title(27))
                if let target = GoalPlanningService().effectiveTarget(for: goal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(CurrencyFormatting.string(from: goal.amountSaved, currencyCode: goal.currencyCode))
                            .font(PrismTypography.number(26))
                        Text("of \(CurrencyFormatting.string(from: target, currencyCode: goal.currencyCode))")
                            .font(PrismTypography.body(14))
                            .foregroundStyle(PrismColors.textSecondary)
                        Spacer()
                        if let pct = pace.percentFunded {
                            Text("\(Int(pct))%")
                                .font(PrismTypography.number(14))
                                .foregroundStyle(PrismColors.textSecondary)
                        }
                    }
                    ProgressView(value: (pace.percentFunded ?? 0) / 100)
                        .tint(barColor)
                }
                if let required = pace.requiredPerPeriod, goal.trackStatus != .paused {
                    Text("\(CurrencyFormatting.string(from: required, currencyCode: goal.currencyCode)) / \(pace.periodLabel)")
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textSecondary)
                }
            }
        }
    }

    private var statusChip: some View {
        Text(pace.trackStatus.displayName)
            .font(PrismTypography.caption())
            .foregroundStyle(statusForeground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(statusBackground))
    }

    private var statusBackground: Color {
        switch pace.trackStatus {
        case .ahead, .onTrack: return PrismColors.statusGreen
        case .aLittleBehind, .needsAdjustment: return PrismColors.statusAmber
        default: return Color.white.opacity(0.18)
        }
    }

    private var statusForeground: Color {
        switch pace.trackStatus {
        case .aLittleBehind, .needsAdjustment: return PrismColors.textOnLight
        default: return .white
        }
    }

    private var barColor: Color {
        switch pace.trackStatus {
        case .ahead, .onTrack: return PrismColors.statusGreen
        case .aLittleBehind, .needsAdjustment: return PrismColors.statusAmber
        default: return Color.white.opacity(0.45)
        }
    }
}
