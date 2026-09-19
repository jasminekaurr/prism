// Summary: Collections list and creation flow with preset suggestions.

import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer
    @State private var collections: [PrismCollection] = []
    @State private var itemCounts: [UUID: Int] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                VStack {
                    PrismBrandMark().padding(.top, PrismSpacing.sm)
                    Text("Collections")
                        .font(PrismTypography.title())
                    if collections.isEmpty {
                        EmptyStateView(
                            title: "Start a collection",
                            message: "Group the things you’re considering — fashion, gifts, a first apartment, or a dream.",
                            actionTitle: "Create",
                            action: { router.sheet = .createCollection }
                        )
                        .accessibilityIdentifier("collections.empty")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: PrismSpacing.sm) {
                                ForEach(collections) { collection in
                                    GlassCard {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(collection.name)
                                                    .font(PrismTypography.headline())
                                                Text("\(itemCounts[collection.id, default: 0]) items")
                                                    .font(PrismTypography.caption())
                                                    .foregroundStyle(PrismColors.textSecondary)
                                                if let description = collection.description {
                                                    Text(description)
                                                        .font(PrismTypography.body())
                                                        .foregroundStyle(PrismColors.textSecondary)
                                                        .lineLimit(2)
                                                }
                                            }
                                            Spacer()
                                            if itemCounts[collection.id, default: 0] > 0 {
                                                Button("Make a goal") {
                                                    router.sheet = .goalFromCollection(collection.id)
                                                }
                                                .font(PrismTypography.caption())
                                                .buttonStyle(.bordered)
                                                .accessibilityIdentifier("collections.makeGoal.\(collection.id.uuidString)")
                                            }
                                        }
                                    }
                                    .accessibilityIdentifier("collections.item.\(collection.id.uuidString)")
                                }
                            }
                            .padding()
                        }
                    }
                    PrismPrimaryButton(title: "New collection") {
                        router.sheet = .createCollection
                    }
                    .padding(.bottom)
                    .accessibilityIdentifier("collections.create")
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await reload() }
        .onChange(of: router.sheet) { _, new in
            if new == nil { Task { await reload() } }
        }
    }

    private func reload() async {
        guard let userID = environment.profile?.id else { return }
        collections = (try? await container.collectionRepository.fetchAll(userID: userID)) ?? []
        let items = (try? await container.savedItemRepository.fetchAll(userID: userID)) ?? []
        var counts: [UUID: Int] = [:]
        for item in items {
            if let cid = item.collectionID {
                counts[cid, default: 0] += 1
            }
        }
        itemCounts = counts
    }
}

struct CreateCollectionView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""

    private let presets = ["Summer Fashion", "First Apartment", "Gifts", "Concerts", "Dream"]

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.md) {
                        Text("Create a collection")
                            .font(PrismTypography.title())
                        TextField("Name", text: $name)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                            .accessibilityIdentifier("collection.name")
                        TextField("Description (optional)", text: $description, axis: .vertical)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                        Text("Suggestions")
                            .font(PrismTypography.headline())
                        FlowLayout(items: presets) { preset in
                            Button(preset) { name = preset }
                                .buttonStyle(.bordered)
                        }
                        PrismPrimaryButton(title: "Save") {
                            Task { await save() }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("collection.save")
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
    }

    private func save() async {
        guard let userID = environment.profile?.id else { return }
        let collection = PrismCollection(
            id: UUID(),
            userID: userID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description,
            coverMediaID: nil,
            colorTheme: nil,
            createdAt: .now,
            updatedAt: .now,
            archivedAt: nil
        )
        try? await container.collectionRepository.upsert(collection)
        dismiss()
    }
}

/// Simple wrapping layout for preset chips.
struct FlowLayout<Content: View>: View {
    let items: [String]
    @ViewBuilder var content: (String) -> Content

    var body: some View {
        FlexibleView(data: items, spacing: 8) { item in
            content(item)
        }
    }
}

/// Wrapping layout that reports its true size to the parent, so following
/// content is pushed down instead of overlapping.
struct WrappingHStack: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxWidth = max(maxWidth, x - spacing)
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    var body: some View {
        WrappingHStack(spacing: spacing) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
