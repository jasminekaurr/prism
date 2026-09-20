// Summary: Reusable glass surfaces, Figma backdrop, chrome, item cards, and primary buttons.

import SwiftUI

// MARK: - Backdrop (Figma: large offset art + light frost)

struct PrismAtmosphericBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            ZStack {
                PrismColors.backgroundDeep
                // Refraction-only art (never BrandSplash — that includes logo/tagline).
                // Figma rotates this plate 180° so blooms sit behind the feed.
                Image("PrismBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w * 2.05, height: h * 1.35)
                    .rotationEffect(.degrees(180))
                    .position(x: w * 0.38, y: h * 0.52)
                Color.black.opacity(PrismBackdrop.scrimOpacity)
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .background(PrismClearHostingBackground())
    }
}

/// Forces UIKit hosting / tab child controllers to a clear background so SwiftUI layers show through.
private struct PrismClearHostingBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            var current: UIView? = view
            while let c = current {
                c.backgroundColor = .clear
                current = c.superview
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.backgroundColor = .clear
    }
}

/// Clears system chrome so the root atmospheric background shows through.
struct PrismClearChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
            .background(Color.clear)
    }
}

extension View {
    func prismClearChrome() -> some View {
        modifier(PrismClearChrome())
    }

    /// Transparent hosting for NavigationStack / Tab content on iOS 17+.
    func prismTransparentBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}

// MARK: - Glass

struct GlassCard<Content: View>: View {
    var padding: CGFloat = PrismSpacing.md
    var cornerRadius: CGFloat = PrismRadius.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.25))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(PrismColors.glassStroke, lineWidth: 1)
                    }
            }
    }
}

struct TagPill: View {
    let text: String
    var color: Color = PrismColors.tagWant
    var filled: Bool = true

    var body: some View {
        Text(text)
            .font(PrismTypography.caption())
            .foregroundStyle(filled ? Color.white : PrismColors.textPrimary)
            .padding(.horizontal, PrismSpacing.sm)
            .padding(.vertical, PrismSpacing.xxs + 2)
            .background {
                Capsule()
                    .fill(filled ? color : Color.clear)
                    .overlay {
                        Capsule().stroke(filled ? Color.clear : PrismColors.glassStroke, lineWidth: 1)
                    }
            }
            .accessibilityLabel(text)
    }
}

struct PrismPrimaryButton: View {
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PrismTypography.headline())
                .foregroundStyle(PrismColors.textPrimary)
                .frame(minHeight: 44)
                .padding(.horizontal, PrismSpacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: PrismRadius.md, style: .continuous)
                        .fill(Color.black.opacity(0.85))
                        .shadow(color: isDestructive ? PrismColors.danger.opacity(0.35) : PrismColors.violet.opacity(0.55), radius: 12, y: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("button.\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }
}

struct PrismBrandMark: View {
    var size: CGFloat = 22

    var body: some View {
        Text("Prism")
            .font(PrismTypography.display(size))
            .foregroundStyle(PrismColors.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Figma-style top band: frosted strip + centered wordmark.
struct PrismTopBar: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 69 / 255, green: 29 / 255, blue: 114 / 255).opacity(0.05))
                .background(.ultraThinMaterial.opacity(0.35))
            PrismBrandMark(size: 17)
                .padding(.top, 22)
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
    }
}

/// Figma home search pill + profile button.
struct PrismSearchChrome: View {
    @Binding var search: String
    var onProfile: () -> Void
    var searchIdentifier: String = "home.search"

    var body: some View {
        HStack(spacing: PrismSpacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(Color(white: 0.2))
                TextField("Search", text: $search)
                    .font(PrismTypography.body(18))
                    .foregroundStyle(Color(white: 0.2))
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier(searchIdentifier)
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(Color(white: 0.2))
            }
            .padding(.horizontal, PrismSpacing.md)
            .padding(.vertical, PrismSpacing.sm)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            Button(action: onProfile) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(white: 0.25))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(white: 0.95).opacity(0.5)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
            .accessibilityIdentifier("home.profile")
        }
        .padding(.horizontal, PrismSpacing.md)
    }
}

struct SectionMicroLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(PrismTypography.micro())
            .tracking(1.2)
            .foregroundStyle(PrismColors.textTertiary)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: PrismSpacing.md) {
            Text(title)
                .font(PrismTypography.title(24))
                .multilineTextAlignment(.center)
            Text(message)
                .font(PrismTypography.body())
                .foregroundStyle(PrismColors.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrismPrimaryButton(title: actionTitle, action: action)
            }
        }
        .padding(PrismSpacing.xl)
    }
}

// MARK: - Figma Item Card

struct AspirationItemCard: View {
    let item: SavedItem
    var collectionName: String?
    var maxTags: Int = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack {
                AspirationMediaView(item: item, height: 162, cornerRadius: 16)
                // Source / play affordances
                VStack {
                    HStack {
                        if item.sourceDomain != nil {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                                .padding(6)
                        }
                        Spacer()
                    }
                    Spacer()
                    if looksLikeVideo {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.95))
                            .shadow(radius: 4)
                    }
                }
                .padding(8)
            }
            .frame(height: 162)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            tagRow
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(PrismColors.glassStroke, lineWidth: 1)
                }
        }
    }

    private var looksLikeVideo: Bool {
        guard let url = item.sourceURL?.absoluteString.lowercased() else { return false }
        return url.contains("tiktok") || url.contains("reel") || url.contains("youtube") || url.contains("vimeo")
    }

    private var tagRow: some View {
        let tags = displayTags
        let visible = Array(tags.prefix(maxTags))
        let overflow = tags.count - visible.count
        return HStack(alignment: .center, spacing: 8) {
            FlexibleTagWrap(tags: visible)
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(PrismTypography.body(14))
                    .foregroundStyle(.white)
            }
        }
    }

    private var displayTags: [(String, Color)] {
        var result: [(String, Color)] = []
        result.append((item.intent.displayName, intentColor(item.intent)))
        if let name = collectionName, !name.isEmpty {
            result.append((name, PrismColors.tagFashion))
        }
        if let cost = item.costSignificance {
            result.append((priorityLabel(cost), priorityColor(cost)))
        }
        if let priority = item.priority, priority != .undecided {
            result.append((priority.displayName, PrismColors.lavender))
        }
        return result
    }

    private func intentColor(_ intent: SaveIntent) -> Color {
        switch intent {
        case .want: return PrismColors.tagWant
        case .need: return PrismColors.tagNeed
        case .dream: return PrismColors.tagDream
        case .gift: return PrismColors.tagGift
        }
    }

    private func priorityLabel(_ cost: CostSignificance) -> String {
        switch cost {
        case .small: return "Low Priority"
        case .considered: return "Medium Priority"
        case .major: return "High Priority"
        case .unknown: return "Priority?"
        }
    }

    private func priorityColor(_ cost: CostSignificance) -> Color {
        switch cost {
        case .small: return PrismColors.tagPriority
        case .considered: return Color.orange
        case .major: return PrismColors.danger
        case .unknown: return PrismColors.textTertiary
        }
    }
}

/// Simple wrapping HStack for a few tags (avoids complex layout dependency).
private struct FlexibleTagWrap: View {
    let tags: [(String, Color)]
    var body: some View {
        WrappingHStack(spacing: 8) {
            ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                TagPill(text: tag.0, color: tag.1)
            }
        }
    }
}

/// Back-compat alias used by older call sites.
typealias SavedItemCard = AspirationItemCard
