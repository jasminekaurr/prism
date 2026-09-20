// Summary: Capture flow — collection, intent, cost, URL with automatic link preview image.

import SwiftUI
import PhotosUI

struct CaptureFlowView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var collections: [PrismCollection] = []
    @State private var selectedCollectionID: UUID?
    @State private var intent: SaveIntent = .want
    @State private var cost: CostSignificance = .unknown
    @State private var title = ""
    @State private var urlText = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var previewFromLink = false
    @State private var isLoadingPreview = false
    @State private var previewFailed = false
    @State private var errorText: String?
    @State private var isSaving = false
    @State private var previewTask: Task<Void, Never>?
    @State private var appliedShareDraft = false

    private var canSave: Bool {
        guard !isSaving, selectedCollectionID != nil else { return false }
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLink = URLHelpers.normalizedURL(from: urlText) != nil
        return hasTitle || hasLink
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.md) {
                        Text("Save something")
                            .font(PrismTypography.title())
                            .accessibilityIdentifier("capture.title")

                        linkPreviewSection

                        SectionMicroLabel(text: "Collection")
                        if collections.isEmpty {
                            Text("Create a collection first from the Collections tab.")
                                .foregroundStyle(PrismColors.textSecondary)
                            Button("Create a collection") {
                                dismiss()
                            }
                            .font(PrismTypography.caption())
                        } else {
                            Picker("Collection", selection: $selectedCollectionID) {
                                ForEach(collections) { c in
                                    Text(c.name).tag(Optional(c.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("capture.collection")
                        }

                        SectionMicroLabel(text: "What kind of desire is this?")
                        Picker("Intent", selection: $intent) {
                            ForEach(SaveIntent.allCases) { i in
                                Text(i.displayName).tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("capture.intent")

                        SectionMicroLabel(text: "How significant does the cost feel?")
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(CostSignificance.allCases) { level in
                                Button {
                                    cost = level
                                } label: {
                                    HStack {
                                        Text(level.displayName)
                                        Spacer()
                                        if cost == level {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                    }
                                    .padding(12)
                                    .background {
                                        RoundedRectangle(cornerRadius: PrismRadius.md)
                                            .stroke(cost == level ? PrismColors.lavender : PrismColors.glassStroke)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(minHeight: 44)
                            }
                        }

                        SectionMicroLabel(text: "Title")
                        TextField("What is it?", text: $title)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                            .accessibilityIdentifier("capture.itemTitle")

                        SectionMicroLabel(text: "Link (optional)")
                        TextField("https://…", text: $urlText)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                            .accessibilityIdentifier("capture.url")
                            .onChange(of: urlText) { _, newValue in
                                schedulePreviewFetch(for: newValue)
                            }
                            .onSubmit {
                                schedulePreviewFetch(for: urlText, immediate: true)
                            }

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(imageData == nil ? "Add from Photos" : "Replace photo", systemImage: "photo")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .accessibilityIdentifier("capture.photos")
                        .onChange(of: photoItem) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self) {
                                    imageData = data
                                    previewFromLink = false
                                    previewFailed = false
                                }
                            }
                        }

                        if let errorText {
                            Text(errorText).foregroundStyle(PrismColors.danger)
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            Text("Save")
                                .font(PrismTypography.headline())
                                .foregroundStyle(PrismColors.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .padding(.horizontal, PrismSpacing.lg)
                                .background {
                                    RoundedRectangle(cornerRadius: PrismRadius.md, style: .continuous)
                                        .fill(Color.black.opacity(canSave ? 0.85 : 0.35))
                                        .shadow(color: PrismColors.violet.opacity(canSave ? 0.55 : 0), radius: 12, y: 2)
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                        .accessibilityIdentifier("capture.save")

                        Text("Paste a link to load a preview automatically. A title is filled in for you when possible.")
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textTertiary)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task {
            await loadCollections()
            applyShareDraftIfNeeded()
        }
        .onDisappear {
            previewTask?.cancel()
            router.clearCaptureDraft()
        }
    }

    private func applyShareDraftIfNeeded() {
        guard !appliedShareDraft else { return }
        appliedShareDraft = true
        if let data = router.captureImageData {
            imageData = data
            previewFromLink = false
        }
        if !router.captureTitleHint.isEmpty, title.isEmpty {
            title = router.captureTitleHint
        }
        if !router.captureURLText.isEmpty {
            urlText = router.captureURLText
            if imageData == nil {
                previewFromLink = true
                schedulePreviewFetch(for: router.captureURLText, immediate: true)
            }
        }
    }

    @ViewBuilder
    private var linkPreviewSection: some View {
        if isLoadingPreview {
            GlassCard {
                HStack(spacing: PrismSpacing.sm) {
                    ProgressView()
                    Text("Loading link preview…")
                        .font(PrismTypography.body())
                        .foregroundStyle(PrismColors.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            }
            .accessibilityIdentifier("capture.preview.loading")
        } else if let imageData, let uiImage = UIImage(data: imageData) {
            GlassCard(padding: PrismSpacing.xs) {
                VStack(alignment: .leading, spacing: PrismSpacing.xs) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: PrismRadius.md, style: .continuous))
                        .accessibilityIdentifier("capture.preview.image")

                    if previewFromLink, let domain = URLHelpers.domain(from: URLHelpers.normalizedURL(from: urlText)) {
                        Text(domain)
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textTertiary)
                            .padding(.horizontal, PrismSpacing.xs)
                            .padding(.bottom, PrismSpacing.xs)
                    }
                }
            }
        } else if previewFailed, URLHelpers.normalizedURL(from: urlText) != nil {
            GlassCard {
                VStack(spacing: PrismSpacing.sm) {
                    Image(systemName: "link")
                        .font(.system(size: 28))
                        .foregroundStyle(PrismColors.lavender)
                    Text(URLHelpers.domain(from: URLHelpers.normalizedURL(from: urlText)) ?? "Link attached")
                        .font(PrismTypography.headline())
                    Text("No preview image was available. You can still save, or add a photo.")
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            }
            .accessibilityIdentifier("capture.preview.fallback")
        }
    }

    private func schedulePreviewFetch(for raw: String, immediate: Bool = false) {
        previewTask?.cancel()
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URLHelpers.normalizedURL(from: trimmed) else {
            if trimmed.isEmpty {
                if previewFromLink {
                    imageData = nil
                    previewFromLink = false
                }
                previewFailed = false
                isLoadingPreview = false
            }
            return
        }

        // Immediately give a usable title from the domain so Save is enabled while preview loads.
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let host = url.host {
            title = host.replacingOccurrences(of: "www.", with: "")
        }

        previewTask = Task {
            if !immediate {
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isLoadingPreview = true
                previewFailed = false
                errorText = nil
            }
            let result = await LinkPreviewFetcher.fetch(for: url)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isLoadingPreview = false
                let currentTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                let isPlaceholderTitle = currentTitle.isEmpty
                    || currentTitle == url.host?.replacingOccurrences(of: "www.", with: "")
                if isPlaceholderTitle, let previewTitle = result.title, !previewTitle.isEmpty {
                    title = previewTitle
                }
                if let data = result.imageData, UIImage(data: data) != nil {
                    if imageData == nil || previewFromLink {
                        imageData = data
                        previewFromLink = true
                        previewFailed = false
                    }
                } else {
                    if previewFromLink {
                        imageData = nil
                    }
                    previewFailed = imageData == nil
                }
            }
        }
    }

    private func loadCollections() async {
        guard let userID = environment.profile?.id else { return }
        collections = (try? await container.collectionRepository.fetchAll(userID: userID)) ?? []
        if selectedCollectionID == nil {
            selectedCollectionID = collections.first?.id
        }
        if collections.isEmpty {
            errorText = "Create a collection first, then come back to save."
        }
    }

    private func save() async {
        errorText = nil
        guard let profile = environment.profile else {
            errorText = "Session missing. Close and open Add again."
            return
        }
        guard let collectionID = selectedCollectionID else {
            errorText = "Create a collection first, then save."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URLHelpers.normalizedURL(from: trimmedURL)
        if !trimmedURL.isEmpty && url == nil {
            // Don’t block save — keep going without a link.
            errorText = nil
        }

        var resolvedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedTitle.isEmpty {
            resolvedTitle = url.flatMap { URLHelpers.domain(from: $0)?.replacingOccurrences(of: "www.", with: "") }
                ?? "Saved item"
        }

        var mediaID: UUID?
        if let imageData {
            let assetID = UUID()
            do {
                let asset = try await container.mediaRepository.saveImageData(imageData, userID: profile.id, assetID: assetID)
                mediaID = asset.id
            } catch {
                // Still save the item even if media write fails.
                container.crashReporter.record(error: error, context: "capture.media")
            }
        }

        let reviewAt = CoolingOffCalculator.reviewDate(
            significance: cost,
            settings: profile.defaultCoolingPeriods
        )

        let item = SavedItem(
            id: UUID(),
            userID: profile.id,
            collectionID: collectionID,
            title: resolvedTitle,
            notes: nil,
            reflection: nil,
            sourceURL: url,
            sourceDomain: URLHelpers.domain(from: url),
            merchantName: nil,
            intent: intent,
            costSignificance: cost,
            priority: .undecided,
            estimatedPrice: nil,
            estimatedCurrencyCode: nil,
            confirmedPurchasePrice: nil,
            confirmedPurchaseCurrencyCode: nil,
            status: .considering,
            primaryMediaID: mediaID,
            notificationsEnabled: profile.notificationPreferences.coolingOffRemindersEnabled,
            createdAt: .now,
            updatedAt: .now,
            reviewAt: reviewAt,
            decidedAt: nil,
            archivedAt: nil,
            deletedAt: nil
        )

        do {
            try await container.savedItemRepository.upsert(item)
            if let reviewAt, profile.notificationPreferences.coolingOffRemindersEnabled, item.notificationsEnabled {
                await container.notificationScheduler.scheduleReviewReminder(itemID: item.id, at: reviewAt)
            }
            if let reviewAt {
                try await container.reviewEventRepository.append(
                    ReviewEvent(
                        id: UUID(),
                        userID: profile.id,
                        savedItemID: item.id,
                        scheduledAt: reviewAt,
                        completedAt: nil,
                        createdAt: .now
                    )
                )
            }
            container.analytics.track(.itemSaved)
            PrismHaptics.save()
            dismiss()
        } catch {
            errorText = "Couldn’t save. Your draft is still here — try again."
            container.crashReporter.record(error: error, context: "capture.save")
        }
    }
}
