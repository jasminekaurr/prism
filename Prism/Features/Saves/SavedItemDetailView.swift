// Summary: Saved item detail with optional reflection entry and spending-pocket soft preview.

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
    @State private var undoMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                if let item {
                    ScrollView {
                        VStack(alignment: .leading, spacing: PrismSpacing.md) {
                            HStack {
                                Spacer()
                                PrismBrandMark(size: 18)
                                Spacer()
                            }
                            Text(item.title)
                                .font(PrismTypography.title())
                                .accessibilityIdentifier("detail.title")

                            mediaBlock(item)

                            if let pocketPreview {
                                GlassCard {
                                    Text(pocketPreview)
                                        .font(PrismTypography.body())
                                        .foregroundStyle(PrismColors.textSecondary)
                                }
                            }

                            if let reflection = item.reflection, !reflection.isEmpty {
                                GlassCard {
                                    SectionMicroLabel(text: "Why do I want this?")
                                    Text(reflection)
                                        .font(PrismTypography.body())
                                }
                            }

                            if !feelings.isEmpty {
                                GlassCard {
                                    SectionMicroLabel(text: "Feelings")
                                    FlowTags(names: feelings.map(\.name))
                                }
                            }

                            HStack {
                                TagPill(text: item.intent.displayName, color: PrismColors.tagWant)
                                if let cost = item.costSignificance {
                                    TagPill(text: cost.displayName, color: PrismColors.tagPriority)
                                }
                                TagPill(text: item.status.displayName, color: PrismColors.lavender, filled: false)
                            }

                            if let estimate = item.estimatedPrice {
                                Text("Estimated \(CurrencyFormatting.string(from: estimate, currencyCode: item.estimatedCurrencyCode ?? "USD"))")
                                    .font(PrismTypography.caption())
                                    .foregroundStyle(PrismColors.textSecondary)
                            }

                            if let confirmed = item.confirmedPurchasePrice {
                                Text("Confirmed \(CurrencyFormatting.string(from: confirmed, currencyCode: item.confirmedPurchaseCurrencyCode ?? "USD"))")
                                    .font(PrismTypography.caption())
                                    .foregroundStyle(PrismColors.successSoft)
                            }

                            if let url = item.sourceURL {
                                Button("Open source") {
                                    openURL(url)
                                }
                                .frame(minHeight: 44)
                            }

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
                            }

                            if let undoMessage {
                                Text(undoMessage).font(PrismTypography.caption())
                            }
                        }
                        .padding()
                    }
                } else {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task { await load() }
    }

    @ViewBuilder
    private func mediaBlock(_ item: SavedItem) -> some View {
        RoundedRectangle(cornerRadius: PrismRadius.lg)
            .fill(PrismColors.violet.opacity(0.3))
            .frame(height: 280)
            .overlay {
                VStack {
                    if let domain = item.sourceDomain {
                        Text(domain).foregroundStyle(PrismColors.textSecondary)
                    } else {
                        Image(systemName: "photo").font(.largeTitle)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(PrismMaterials.scrimOpacity)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: PrismRadius.lg))
            }
    }

    private func load() async {
        item = try? await container.savedItemRepository.fetch(id: itemID)
        feelings = (try? await container.feelingRepository.feelings(for: itemID)) ?? []
        tags = (try? await container.tagRepository.tags(for: itemID)) ?? []
        if let item, let profile = environment.profile {
            let snap = container.spendingPocketService.snapshot(settings: profile.spendingPocket, items: [])
            // Use pocket settings only for preview text; remaining not needed here.
            let previewSnap = SpendingPocketSnapshot(
                isActive: profile.spendingPocket.isEnabled && profile.spendingPocket.monthlyAmount != nil,
                monthlyAmount: profile.spendingPocket.monthlyAmount,
                currencyCode: profile.spendingPocket.currencyCode,
                confirmedSpentThisMonth: 0,
                remaining: nil,
                isPaused: profile.spendingPocket.isPaused
            )
            pocketPreview = previewSnap.previewCopy(itemTitle: item.title, estimatedPrice: item.estimatedPrice)
            _ = snap
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
