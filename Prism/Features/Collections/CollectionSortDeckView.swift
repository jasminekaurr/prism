// Summary: Collection swipe deck — keep / delete stack (recreation screen 04).

import SwiftUI

struct CollectionSortDeckView: View {
    let collectionID: UUID
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var collection: PrismCollection?
    @State private var stack: [SavedItem] = []
    @State private var dragX: CGFloat = 0
    @State private var isDragging = false

    private let threshold: CGFloat = 110

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                VStack(spacing: PrismSpacing.md) {
                    PrismLogoMark().padding(.top, 8)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("COLLECTION")
                            .font(PrismTypography.micro())
                            .foregroundStyle(.white)
                        HStack {
                            Text(collection?.name ?? "Collection")
                                .font(PrismTypography.body(16))
                            Spacer()
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 13)
                        .frame(height: 40)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(PrismColors.glassFill)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(PrismColors.glassStroke, lineWidth: 1)
                                }
                        }
                    }
                    .padding(.horizontal, PrismSpacing.md)

                    ZStack {
                        if stack.isEmpty {
                            Text("Nothing left to sort")
                                .font(PrismTypography.title(24))
                                .foregroundStyle(Color.white.opacity(0.75))
                        } else {
                            ForEach(Array(stack.prefix(3).enumerated().reversed()), id: \.element.id) { index, item in
                                card(item, index: index)
                            }
                        }
                    }
                    .frame(height: 490)
                    .padding(.horizontal, PrismSpacing.md)

                    HStack {
                        Text("← swipe left to delete")
                        Spacer()
                        Text("swipe right to keep →")
                    }
                    .font(PrismTypography.mono)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(.horizontal, PrismSpacing.md)

                    HStack {
                        Spacer()
                        PrismPrimaryButton(title: "Review") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                router.sheet = .review(collectionID)
                            }
                        }
                    }
                    .padding(.horizontal, PrismSpacing.md)
                    .padding(.bottom, PrismSpacing.lg)
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

    private func card(_ item: SavedItem, index: Int) -> some View {
        let isTop = index == 0
        let offset = isTop ? dragX : CGFloat(index) * 8
        let keepOp = isTop ? max(0, min(1, dragX / threshold)) : 0
        let dropOp = isTop ? max(0, min(1, -dragX / threshold)) : 0

        return ZStack(alignment: .top) {
            AspirationMediaView(item: item, height: 474)
                .frame(width: 279, height: 474)
                .clipped()
            HStack {
                Text("KEEP")
                    .font(PrismTypography.body(13, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(PrismColors.statusGreenSoft)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay {
                        Capsule().stroke(PrismColors.statusGreen, lineWidth: 2)
                    }
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .opacity(keepOp)
                Spacer()
                Text("DELETE")
                    .font(PrismTypography.body(13, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(PrismColors.statusAmberSoft)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay {
                        Capsule().stroke(PrismColors.statusAmber, lineWidth: 2)
                    }
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .opacity(dropOp)
            }
            .padding(18)
            PlayBadge(size: 73)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
        .offset(x: isTop ? offset : 0, y: CGFloat(index) * 6)
        .rotationEffect(.degrees(isTop ? Double(dragX / 20) : 0))
        .opacity(isTop ? 1 : max(0.4, 1 - Double(index) * 0.25))
        .zIndex(Double(10 - index))
        .gesture(isTop ? dragGesture : nil)
        .animation(isDragging ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: dragX)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                dragX = value.translation.width
            }
            .onEnded { value in
                isDragging = false
                if value.translation.width > threshold {
                    PrismHaptics.save()
                    keepTop()
                } else if value.translation.width < -threshold {
                    PrismHaptics.decision()
                    deleteTop()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragX = 0
                    }
                }
            }
    }

    private func keepTop() {
        guard !stack.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            dragX = 400
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            _ = stack.removeFirst()
            dragX = 0
        }
    }

    private func deleteTop() {
        guard let top = stack.first else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            dragX = -400
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            Task {
                try? await container.savedItemRepository.softDeleteItem(id: top.id)
                stack.removeFirst()
                dragX = 0
            }
        }
    }

    private func load() async {
        collection = try? await container.collectionRepository.fetch(id: collectionID)
        guard let userID = environment.profile?.id else { return }
        let all = (try? await container.savedItemRepository.fetchAll(userID: userID)) ?? []
        stack = all.filter {
            $0.collectionID == collectionID
                && ($0.status == .considering || $0.status == .readyForReview)
        }
    }
}
