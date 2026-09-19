// Summary: Optional reflection editor — feelings, priority, estimated price, merchant, tags.

import SwiftUI

struct ReflectionEditorView: View {
    let itemID: UUID
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var item: SavedItem?
    @State private var reflection = ""
    @State private var selectedFeelings: Set<UUID> = []
    @State private var priority: ItemPriority = .undecided
    @State private var estimatedText = ""
    @State private var merchant = ""
    @State private var customTag = ""
    @State private var tags: [Tag] = []

    private let allFeelings = Feeling.systemFeelings

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.md) {
                        Text("Reflection")
                            .font(PrismTypography.title())
                        Text("Optional — save takes seconds; this can wait.")
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textTertiary)

                        SectionMicroLabel(text: "Why do I want this?")
                        TextField("A few words…", text: $reflection, axis: .vertical)
                            .padding()
                            .frame(minHeight: 100)
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                            .accessibilityIdentifier("reflection.text")

                        SectionMicroLabel(text: "How does it make me feel?")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                            ForEach(allFeelings) { feeling in
                                let selected = selectedFeelings.contains(feeling.id)
                                Button {
                                    if selected { selectedFeelings.remove(feeling.id) }
                                    else { selectedFeelings.insert(feeling.id) }
                                } label: {
                                    TagPill(text: feeling.name, color: selected ? PrismColors.tagFashion : PrismColors.lavender, filled: selected)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("feeling.\(feeling.name.lowercased().replacingOccurrences(of: " ", with: "_"))")
                            }
                        }

                        SectionMicroLabel(text: "Must-have or nice-to-have?")
                        Picker("Priority", selection: $priority) {
                            ForEach(ItemPriority.allCases) { p in
                                Text(p.displayName).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)

                        SectionMicroLabel(text: "Estimated price (optional)")
                        TextField("0.00", text: $estimatedText)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                            .accessibilityIdentifier("reflection.estimate")

                        SectionMicroLabel(text: "Merchant or source (optional)")
                        TextField("Store or brand", text: $merchant)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))

                        SectionMicroLabel(text: "Custom tag")
                        HStack {
                            TextField("Tag", text: $customTag)
                            Button("Add") { addTag() }
                                .disabled(customTag.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        FlowTags(names: tags.map(\.name))

                        PrismPrimaryButton(title: "Save reflection") {
                            Task { await save() }
                        }
                        .accessibilityIdentifier("reflection.save")
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
        .task { await load() }
    }

    private func load() async {
        item = try? await container.savedItemRepository.fetch(id: itemID)
        guard let item else { return }
        reflection = item.reflection ?? ""
        priority = item.priority ?? .undecided
        if let estimate = item.estimatedPrice {
            estimatedText = "\(estimate)"
        }
        merchant = item.merchantName ?? ""
        let existing = (try? await container.feelingRepository.feelings(for: itemID)) ?? []
        selectedFeelings = Set(existing.map(\.id))
        tags = (try? await container.tagRepository.tags(for: itemID)) ?? []
    }

    private func addTag() {
        guard let profile = environment.profile else { return }
        let tag = Tag(id: UUID(), userID: profile.id, name: customTag.trimmingCharacters(in: .whitespaces), createdAt: .now)
        tags.append(tag)
        customTag = ""
    }

    private func save() async {
        guard var item, let profile = environment.profile else { return }
        item.reflection = reflection.isEmpty ? nil : reflection
        item.priority = priority
        item.estimatedPrice = DecimalParsing.parse(estimatedText)
        item.estimatedCurrencyCode = item.estimatedPrice == nil ? nil : profile.spendingPocket.currencyCode
        item.merchantName = merchant.isEmpty ? nil : merchant
        item.updatedAt = .now
        try? await container.savedItemRepository.upsert(item)
        let chosen = allFeelings.filter { selectedFeelings.contains($0.id) }
        try? await container.feelingRepository.setFeelings(chosen, for: item.id, userID: profile.id)
        try? await container.tagRepository.setTags(tags, for: item.id, userID: profile.id)
        dismiss()
    }
}
