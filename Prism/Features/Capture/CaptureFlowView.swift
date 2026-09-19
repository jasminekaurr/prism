// Summary: Capture flow — collection, intent, cost significance, optional photo/URL/manual title.

import SwiftUI
import PhotosUI

struct CaptureFlowView: View {
    @EnvironmentObject private var environment: AppEnvironment
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
    @State private var errorText: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.md) {
                        Text("Save something")
                            .font(PrismTypography.title())
                            .accessibilityIdentifier("capture.title")

                        SectionMicroLabel(text: "Collection")
                        if collections.isEmpty {
                            Text("Create a collection first from the Collections tab.")
                                .foregroundStyle(PrismColors.textSecondary)
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
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                            .accessibilityIdentifier("capture.url")

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Add from Photos", systemImage: "photo")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .accessibilityIdentifier("capture.photos")
                        .onChange(of: photoItem) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self) {
                                    imageData = data
                                }
                            }
                        }

                        if imageData != nil {
                            Text("Photo attached")
                                .font(PrismTypography.caption())
                                .foregroundStyle(PrismColors.successSoft)
                        }

                        if let errorText {
                            Text(errorText).foregroundStyle(PrismColors.danger)
                        }

                        PrismPrimaryButton(title: "Save") {
                            Task { await save() }
                        }
                        .disabled(isSaving || selectedCollectionID == nil || title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("capture.save")

                        Text("Everything else can wait. Reflection is optional.")
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
        .task { await loadCollections() }
    }

    private func loadCollections() async {
        guard let userID = environment.profile?.id else { return }
        collections = (try? await container.collectionRepository.fetchAll(userID: userID)) ?? []
        if selectedCollectionID == nil {
            selectedCollectionID = collections.first?.id
        }
    }

    private func save() async {
        guard let profile = environment.profile,
              let collectionID = selectedCollectionID else { return }
        isSaving = true
        defer { isSaving = false }

        let url = URLHelpers.validatedHTTPSURL(from: urlText)
            ?? (urlText.isEmpty ? nil : URL(string: urlText))
        if !urlText.isEmpty && url == nil {
            errorText = "That link doesn’t look valid. You can still save without it."
            return
        }

        var mediaID: UUID?
        if let imageData {
            let assetID = UUID()
            if let asset = try? await container.mediaRepository.saveImageData(imageData, userID: profile.id, assetID: assetID) {
                mediaID = asset.id
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
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
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
