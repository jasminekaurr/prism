// Summary: Collections list with cover glimpses; create flow with presets.

import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer
    @State private var collections: [PrismCollection] = []
    @State private var itemCounts: [UUID: Int] = [:]
    @State private var previewItems: [UUID: [SavedItem]] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        PrismLogoMark()
                        Spacer()
                    }
                    .padding(.top, PrismSpacing.sm)

                    HStack(alignment: .center) {
                        Text("Collections")
                            .font(PrismTypography.title(32))
                        Spacer()
                        PrismHeaderAction(title: "New", accessibilityID: "collections.create") {
                            router.sheet = .createCollection
                        }
                    }
                    .padding(.horizontal, PrismSpacing.md)
                    .padding(.bottom, PrismSpacing.sm)

                    if collections.isEmpty {
                        EmptyStateView(
                            title: "Start a collection",
                            message: "Group the things you’re considering — fashion, gifts, a first apartment, or a dream.",
                            actionTitle: "Create",
                            action: { router.sheet = .createCollection }
                        )
                        .accessibilityIdentifier("collections.empty")
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: PrismSpacing.sm) {
                                ForEach(collections) { collection in
                                    Button {
                                        router.sheet = .review(collection.id)
                                    } label: {
                                        collectionCard(collection)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("collections.item.\(collection.id.uuidString)")
                                }
                            }
                            .padding(.horizontal, PrismSpacing.md)
                            .padding(.bottom, 110)
                        }
                        .prismTransparentBackground()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await reload() }
        .onChange(of: router.sheet) { _, new in
            if new == nil { Task { await reload() } }
        }
    }

    private func collectionCard(_ collection: PrismCollection) -> some View {
        let count = itemCounts[collection.id, default: 0]
        let previews = previewItems[collection.id] ?? []
        return GlassCard {
            HStack(alignment: .top, spacing: 12) {
                collectionGlimpse(previews)
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.name)
                        .font(PrismTypography.headline())
                        .foregroundStyle(.white)
                    Text("\(count) item\(count == 1 ? "" : "s")")
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textSecondary)
                    if let description = collection.description {
                        Text(description)
                            .font(PrismTypography.body(14))
                            .foregroundStyle(PrismColors.textSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .padding(.top, 4)
            }
        }
    }

    private func collectionGlimpse(_ items: [SavedItem]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: 72, height: 72)

            if items.isEmpty {
                Image(systemName: "square.stack")
                    .foregroundStyle(Color.white.opacity(0.35))
            } else {
                ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { index, item in
                    AspirationMediaView(item: item, height: 56, cornerRadius: 12)
                        .frame(width: 56, height: 56)
                        .clipped()
                        .rotationEffect(.degrees(Double(index - 1) * 6))
                        .offset(x: CGFloat(index) * 6 - 6, y: CGFloat(index) * 2 - 2)
                        .zIndex(Double(index))
                }
            }
        }
        .frame(width: 72, height: 72)
        .clipped()
    }

    private func reload() async {
        guard let userID = environment.profile?.id else { return }
        collections = (try? await container.collectionRepository.fetchAll(userID: userID)) ?? []
        let items = (try? await container.savedItemRepository.fetchAll(userID: userID)) ?? []
        var counts: [UUID: Int] = [:]
        var previews: [UUID: [SavedItem]] = [:]
        for item in items {
            guard let cid = item.collectionID else { continue }
            counts[cid, default: 0] += 1
            var list = previews[cid] ?? []
            if list.count < 3 { list.append(item) }
            previews[cid] = list
        }
        itemCounts = counts
        previewItems = previews
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
