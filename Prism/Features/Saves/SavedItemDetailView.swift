// Summary: Saved item detail styled to Figma — media hero, tags, why / feelings glass panels.

import SwiftUI

struct SavedItemDetailView: View {
    let itemID: UUID
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var item: SavedItem?
    @State private var feelings: [Feeling] = []
    @State private var tags: [Tag] = []
    @State private var pocketPreview: String?
    @State private var goalTradeoff: String?
    @State private var collectionName: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                if let item {
                    ScrollView {
                        VStack(alignment: .leading, spacing: PrismSpacing.md) {
                            PrismTopBar()

                            HStack {
                                Spacer()
                                Button("Edit") {
                                    router.sheet = .reflection(item.id)
                                }
                                .font(PrismTypography.caption())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.black.opacity(0.45)))
                                .accessibilityIdentifier("detail.edit")
                            }
                            .padding(.horizontal, PrismSpacing.md)

                            Text(item.title)
                                .font(PrismTypography.title(24))
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .accessibilityIdentifier("detail.title")

                            ZStack(alignment: .topLeading) {
                                AspirationMediaView(item: item, height: 360, cornerRadius: 20)
                                    .padding(.horizontal, 40)
                                if item.sourceDomain != nil {
                                    Image(systemName: "camera.fill")
                                        .foregroundStyle(.white)
                                        .padding(10)
                                        .padding(.leading, 52)
                                        .padding(.top, 12)
                                }
                                if looksLikeVideo(item) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 56))
                                        .foregroundStyle(.white.opacity(0.95))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            .accessibilityIdentifier("detail.media")

                            if let notes = item.notes, !notes.isEmpty {
                                GlassCard {
                                    SectionMicroLabel(text: "Notes")
                                    Text(notes)
                                        .font(PrismTypography.body())
                                }
                                .padding(.horizontal, PrismSpacing.md)
                            }

                            VStack(alignment: .leading, spacing: PrismSpacing.sm) {
                                SectionMicroLabel(text: "Tags")
                                WrappingHStack(spacing: 8) {
                                    TagPill(text: item.intent.displayName, color: PrismColors.tagWant)
                                    if let cost = item.costSignificance {
                                        TagPill(text: cost.displayName, color: PrismColors.tagPriority)
                                    }
                                    TagPill(text: item.status.displayName, color: PrismColors.lavender, filled: false)
                                    ForEach(tags) { tag in
                                        TagPill(text: tag.name, color: PrismColors.tagFashion)
                                    }
                                }
                            }
                            .padding(.horizontal, PrismSpacing.md)

                            HStack(alignment: .top, spacing: PrismSpacing.sm) {
                                GlassCard {
                                    SectionMicroLabel(text: "Why do I want this?")
                                    Text(item.reflection?.isEmpty == false ? (item.reflection ?? "") : "Add a short reflection anytime.")
                                        .font(PrismTypography.body())
                                        .foregroundStyle(item.reflection?.isEmpty == false ? PrismColors.textPrimary : PrismColors.textTertiary)
                                        .frame(minHeight: 100, alignment: .topLeading)
                                }
                                GlassCard {
                                    SectionMicroLabel(text: "Feeling attached")
                                    if feelings.isEmpty {
                                        Text("—")
                                            .foregroundStyle(PrismColors.textTertiary)
                                    } else {
                                        VStack(spacing: 4) {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 28))
                                                .foregroundStyle(PrismColors.magenta)
                                            ForEach(feelings.prefix(3)) { feeling in
                                                Text(feeling.name)
                                                    .font(PrismTypography.caption())
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(width: 120)
                            }
                            .padding(.horizontal, PrismSpacing.md)

                            if let pocketPreview {
                                GlassCard {
                                    Text(pocketPreview)
                                        .font(PrismTypography.body())
                                        .foregroundStyle(PrismColors.textSecondary)
                                }
                                .padding(.horizontal, PrismSpacing.md)
                            }

                            if let goalTradeoff {
                                GlassCard {
                                    SectionMicroLabel(text: "Goal trade-off")
                                    Text(goalTradeoff)
                                        .font(PrismTypography.body())
                                        .foregroundStyle(PrismColors.textSecondary)
                                }
                                .padding(.horizontal, PrismSpacing.md)
                            }

                            if let estimate = item.estimatedPrice {
                                Text("Estimated \(CurrencyFormatting.string(from: estimate, currencyCode: item.estimatedCurrencyCode ?? "USD"))")
                                    .font(PrismTypography.caption())
                                    .foregroundStyle(PrismColors.textSecondary)
                                    .padding(.horizontal, PrismSpacing.md)
                            }

                            if let url = item.sourceURL {
                                Button("Open source") { openURL(url) }
                                    .frame(minHeight: 44)
                                    .padding(.horizontal, PrismSpacing.md)
                            }

                            HStack {
                                PrismPrimaryButton(title: "Make this a goal") {
                                    router.sheet = .goalSetup(item.id)
                                }
                                .accessibilityIdentifier("detail.makeGoal")
                            }
                            .padding(.horizontal, PrismSpacing.md)

                            HStack {
                                PrismPrimaryButton(title: "Reflect") {
                                    router.sheet = .reflection(item.id)
                                }
                                if item.status == .considering || item.status == .readyForReview {
                                    PrismPrimaryButton(title: "Review") {
                                        dismiss()
                                        router.selectedTab = .review
                                    }
                                }
                                Button("Done") { dismiss() }
                                    .font(PrismTypography.headline())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.black.opacity(0.55)))
                                    .accessibilityIdentifier("detail.done")
                            }
                            .padding(.horizontal, PrismSpacing.md)
                            .padding(.bottom, PrismSpacing.xl)
                        }
                    }
                    .prismTransparentBackground()
                } else {
                    ProgressView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await load() }
    }

    private func looksLikeVideo(_ item: SavedItem) -> Bool {
        guard let url = item.sourceURL?.absoluteString.lowercased() else { return false }
        return url.contains("tiktok") || url.contains("reel") || url.contains("youtube") || url.contains("vimeo")
    }

    private func load() async {
        item = try? await container.savedItemRepository.fetch(id: itemID)
        feelings = (try? await container.feelingRepository.feelings(for: itemID)) ?? []
        tags = (try? await container.tagRepository.tags(for: itemID)) ?? []
        if let item, let profile = environment.profile {
            if let cid = item.collectionID {
                let cols = (try? await container.collectionRepository.fetchAll(userID: profile.id)) ?? []
                collectionName = cols.first { $0.id == cid }?.name
            }
            let previewSnap = SpendingPocketSnapshot(
                isActive: profile.spendingPocket.isEnabled && profile.spendingPocket.monthlyAmount != nil,
                monthlyAmount: profile.spendingPocket.monthlyAmount,
                currencyCode: profile.spendingPocket.currencyCode,
                confirmedSpentThisMonth: 0,
                remaining: nil,
                isPaused: profile.spendingPocket.isPaused
            )
            pocketPreview = previewSnap.previewCopy(itemTitle: item.title, estimatedPrice: item.estimatedPrice)

            let goals = (try? await container.goalRepository.fetchAll(userID: profile.id)) ?? []
            if let primary = goals.first(where: { $0.priority == .primary && $0.trackStatus != .completed })
                ?? goals.first(where: { $0.priority == .active && $0.trackStatus != .completed }) {
                let pace = container.goalPlanningService.pace(for: primary)
                goalTradeoff = container.goalPlanningService.tradeoffCopy(
                    itemTitle: item.title,
                    estimatedPrice: item.estimatedPrice,
                    against: primary,
                    pace: pace
                )
            }
        }
    }
}

struct FlowTags: View {
    let names: [String]
    var body: some View {
        FlexibleView(data: names, spacing: 8) { name in
            TagPill(text: name, color: PrismColors.tagFashion)
        }
    }
}
