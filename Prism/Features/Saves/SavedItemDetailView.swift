// Summary: Item detail — Bought?, AI description, editable tags + collection, feeling mood, goal CTA.

import SwiftUI

struct SavedItemDetailView: View {
    let itemID: UUID
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var item: SavedItem?
    @State private var feelings: [Feeling] = []
    @State private var tags: [Tag] = []
    @State private var collections: [PrismCollection] = []
    @State private var selectedCollectionID: UUID?
    @State private var newTagText = ""
    @State private var moodValence: MoodValence?
    @State private var showMoodPicker = false
    @State private var whyText: String = ""
    @State private var goalTradeoff: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                if let item {
                    ScrollView {
                        VStack(alignment: .leading, spacing: PrismSpacing.lg) {
                            topChrome(item)
                            Text(item.title)
                                .font(PrismTypography.display(24, weight: .regular))
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .accessibilityIdentifier("detail.title")

                            mediaBlock(item)

                            sectionBlock(label: "AI DESCRIPTION") {
                                Text(MockAIDescription.text(for: item))
                                    .font(PrismTypography.body(14))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            sectionBlock(label: "COLLECTION") {
                                collectionEditor
                            }

                            sectionBlock(label: "TAGS") {
                                tagEditor(intentLabel: item.intent.displayName)
                            }

                            HStack(alignment: .top, spacing: PrismSpacing.md) {
                                sectionBlock(label: "WHY DO I WANT THIS?") {
                                    TextField("Add a reflection…", text: $whyText, axis: .vertical)
                                        .font(PrismTypography.body(14))
                                        .foregroundStyle(.white)
                                        .frame(minHeight: 120, alignment: .topLeading)
                                }
                                .frame(maxWidth: .infinity)

                                sectionBlock(label: "FEELING ATTACHED") {
                                    FeelingMoodCardPreview(
                                        valence: moodValence,
                                        feelings: feelings
                                    ) {
                                        showMoodPicker = true
                                    }
                                }
                                .frame(width: 132)
                            }

                            if let goalTradeoff {
                                GlassCard {
                                    SectionMicroLabel(text: "Goal trade-off")
                                    Text(goalTradeoff)
                                        .font(PrismTypography.body())
                                        .foregroundStyle(PrismColors.textSecondary)
                                }
                            }

                            worthSavingBlock(item)

                            HStack {
                                Spacer()
                                PrismPrimaryButton(title: "Delete") {
                                    Task { await softDelete() }
                                }
                                PrismPrimaryButton(title: "Save") {
                                    Task { await saveEdits() }
                                }
                            }
                        }
                        .padding(.horizontal, PrismSpacing.lg)
                        .padding(.bottom, 40)
                    }
                    .prismTransparentBackground()
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
        .sheet(isPresented: $showMoodPicker) {
            FeelingMoodPickerView(
                itemID: itemID,
                initialValence: moodValence ?? .neutral,
                initialFeelings: feelings
            ) { valence, chosen in
                moodValence = valence
                feelings = chosen
                Task { await persistFeelings(chosen) }
            }
        }
    }

    private var collectionEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            if collections.isEmpty {
                Text("No collections yet. Create one from the Collections tab.")
                    .font(PrismTypography.caption())
                    .foregroundStyle(PrismColors.textSecondary)
            } else {
                Picker("Collection", selection: $selectedCollectionID) {
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(collections) { c in
                        Text(c.name).tag(Optional(c.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)
                .accessibilityIdentifier("detail.collection")
            }
            if selectedCollectionID != nil {
                Button("Remove from collection") {
                    selectedCollectionID = nil
                    PrismHaptics.soft()
                }
                .font(PrismTypography.caption())
                .foregroundStyle(PrismColors.lavender)
                .accessibilityIdentifier("detail.collection.remove")
            }
        }
    }

    private func tagEditor(intentLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            FlexibleView(data: tags.map(\.name), spacing: 8) { name in
                TagPill(text: name, tone: .topic, onRemove: {
                    tags.removeAll { $0.name.caseInsensitiveCompare(name) == .orderedSame }
                    PrismHaptics.soft()
                })
            }
            TagPill(text: intentLabel, tone: .intent)

            HStack(spacing: 8) {
                TextField("Add a tag", text: $newTagText)
                    .textInputAutocapitalization(.words)
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: PrismRadius.md)
                            .stroke(PrismColors.glassStroke)
                    }
                    .accessibilityIdentifier("detail.tagField")
                Button("Add") { addTag() }
                    .font(PrismTypography.caption())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background {
                        Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1)
                    }
                    .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("detail.tagAdd")
            }
        }
    }

    private func addTag() {
        let name = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard let userID = environment.profile?.id else { return }
        if tags.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            newTagText = ""
            return
        }
        tags.append(Tag(id: UUID(), userID: userID, name: name, createdAt: .now))
        newTagText = ""
        PrismHaptics.soft()
    }

    private func topChrome(_ item: SavedItem) -> some View {
        HStack {
            PrismLogoMark()
            Spacer()
            Button {
                Task { await toggleBought() }
            } label: {
                Text(item.status == .purchased ? "Bought" : "Bought?")
                    .font(PrismTypography.body(12))
                    .foregroundStyle(PrismColors.textOnLight)
                    .frame(width: 63, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.95, green: 0.93, blue: 0.98).opacity(item.status == .purchased ? 1 : 0.5))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func mediaBlock(_ item: SavedItem) -> some View {
        ZStack {
            AspirationMediaView(item: item, height: 466)
                .frame(maxWidth: 274)
                .frame(height: 466)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            if looksLikeVideo(item) {
                PlayBadge(size: 73)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("detail.media")
    }

    private func sectionBlock<Content: View>(label: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(PrismTypography.micro())
                .foregroundStyle(.white)
            GlassCard(padding: 14, cornerRadius: PrismRadius.lg, content: content)
        }
    }

    private func worthSavingBlock(_ item: SavedItem) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 11) {
                Text("Worth saving for?")
                    .font(PrismTypography.title(24))
                Text("Carry this save into a goal — name, cover, type, and estimate come with you.")
                    .font(PrismTypography.body(14))
                    .foregroundStyle(PrismColors.textSecondary)
                PrismPrimaryButton(title: "Start a goal") {
                    router.sheet = .goalSetup(item.id)
                }
                .accessibilityIdentifier("detail.makeGoal")
            }
        }
    }

    private func looksLikeVideo(_ item: SavedItem) -> Bool {
        let url = item.sourceURL?.absoluteString.lowercased() ?? ""
        return url.contains("reel") || url.contains("tiktok") || url.contains("/video")
    }

    private func load() async {
        item = try? await container.savedItemRepository.fetch(id: itemID)
        feelings = (try? await container.feelingRepository.feelings(for: itemID)) ?? []
        tags = (try? await container.tagRepository.tags(for: itemID)) ?? []
        whyText = item?.reflection ?? ""
        moodValence = MoodValenceStore.load(itemID: itemID)
        selectedCollectionID = item?.collectionID
        if let profile = environment.profile {
            collections = (try? await container.collectionRepository.fetchAll(userID: profile.id)) ?? []
            let goals = (try? await container.goalRepository.fetchAll(userID: profile.id)) ?? []
            if let item,
               let primary = goals.first(where: { $0.priority == .primary && $0.trackStatus != .completed })
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

    private func persistFeelings(_ chosen: [Feeling]) async {
        guard let profile = environment.profile else { return }
        try? await container.feelingRepository.setFeelings(chosen, for: itemID, userID: profile.id)
        feelings = chosen
    }

    private func toggleBought() async {
        guard var item else { return }
        if item.status == .purchased {
            item.status = .considering
            item.decidedAt = nil
        } else {
            item.status = .purchased
            item.decidedAt = .now
        }
        item.updatedAt = .now
        try? await container.savedItemRepository.upsert(item)
        self.item = item
        PrismHaptics.decision()
    }

    private func saveEdits() async {
        guard var item else { return }
        isSaving = true
        defer { isSaving = false }
        item.reflection = whyText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        item.collectionID = selectedCollectionID
        item.updatedAt = .now
        try? await container.savedItemRepository.upsert(item)
        if let profile = environment.profile {
            try? await container.feelingRepository.setFeelings(feelings, for: itemID, userID: profile.id)
            try? await container.tagRepository.setTags(tags, for: itemID, userID: profile.id)
        }
        PrismHaptics.save()
        dismiss()
    }

    private func softDelete() async {
        try? await container.savedItemRepository.softDeleteItem(id: itemID)
        PrismHaptics.decision()
        dismiss()
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

struct FlowTags: View {
    let names: [String]
    var body: some View {
        FlexibleView(data: names, spacing: 8) { name in
            TagPill(text: name, tone: .topic)
        }
    }
}
