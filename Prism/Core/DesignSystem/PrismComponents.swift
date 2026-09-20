// Summary: Reusable chrome from App Screens recreation — backdrop, glass, chips, save cards, tab bar, buttons.

import SwiftUI

// MARK: - Backdrop (flipped bg.jpg + soft blur + glass-friendly scrim)

struct PrismAtmosphericBackground: View {
    var body: some View {
        GeometryReader { geo in
            // Use screen size as a floor so the keyboard shrinking the
            // GeometryReader cannot re-scale the art (feels like a page zoom).
            let screen = UIScreen.main.bounds
            let w = max(geo.size.width, screen.width, 1)
            let h = max(geo.size.height, screen.height, 1)
            ZStack {
                PrismColors.backgroundMid
                Image("PrismBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w * 1.35, height: h * 1.2)
                    .scaleEffect(x: -1, y: -1)
                    .blur(radius: PrismBackdrop.imageBlurRadius)
                    .position(x: w * 0.45, y: h * 0.48)
                // Soft frosted veil so glass cards read against the art.
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .opacity(PrismBackdrop.materialOpacity)
                Color.black.opacity(PrismBackdrop.scrimOpacity)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .background(PrismClearHostingBackground())
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

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

// MARK: - Glass

struct GlassCard<Content: View>: View {
    var padding: CGFloat = PrismSpacing.md
    var cornerRadius: CGFloat = PrismRadius.lg
    var stroke: Color = PrismColors.glassStroke
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(PrismColors.glassFill)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(stroke, lineWidth: 1)
                    }
            }
    }
}

// MARK: - Chips / tags

struct TagPill: View {
    let text: String
    var tone: PrismTone = .intent
    var color: Color? = nil
    var filled: Bool = true
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(PrismTypography.caption())
            if let onRemove {
                Button(action: onRemove) {
                    Text("✕").font(.system(size: 11)).opacity(0.75)
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(filled ? (color != nil ? Color.white : tone.foreground) : PrismColors.textPrimary)
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background {
            Capsule()
                .fill(filled ? (color ?? tone.background) : Color.clear)
                .overlay {
                    Capsule().stroke(filled ? (color ?? tone.border) : PrismColors.glassStroke, lineWidth: 1)
                }
        }
        .accessibilityLabel(text)
    }
}

struct FilterChip: View {
    let title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PrismTypography.body(12.5))
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .frame(height: 32)
                .background {
                    Capsule()
                        .fill(selected ? Color.white.opacity(0.22) : Color.white.opacity(0.06))
                        .overlay {
                            Capsule().stroke(selected ? Color.white : Color.white.opacity(0.3), lineWidth: 1)
                        }
                }
        }
        .buttonStyle(.plain)
    }
}

/// Sliding context switcher — distinct from TagPill chips.
struct PrismSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    var title: (Option) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    PrismHaptics.soft()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = option
                    }
                } label: {
                    Text(title(option))
                        .font(PrismTypography.body(12.5, weight: .medium))
                        .foregroundStyle(selection == option ? .white : Color.white.opacity(0.55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background {
            GeometryReader { geo in
                let count = max(options.count, 1)
                let slot = geo.size.width / CGFloat(count)
                let index = CGFloat(options.firstIndex(of: selection) ?? 0)
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .overlay {
                        Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1)
                    }
                    .frame(width: max(slot - 2, 0), height: max(geo.size.height - 6, 0))
                    .offset(x: index * slot + 1, y: 3)
                    .animation(.spring(response: 0.32, dampingFraction: 0.82), value: selection)
            }
        }
        .background {
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
        }
    }
}

// MARK: - Buttons

struct PrismPrimaryButton: View {
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PrismTypography.body(16, weight: .medium))
                .foregroundStyle(PrismColors.buttonInk)
                .frame(minHeight: 40)
                .padding(.horizontal, PrismSpacing.md)
                .background {
                    RoundedRectangle(cornerRadius: PrismRadius.sm, style: .continuous)
                        .fill(PrismColors.buttonDark)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("button.\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }
}

// MARK: - Brand

struct PrismLogoMark: View {
    var width: CGFloat = 34
    var height: CGFloat = 24

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            var left = Path()
            left.move(to: CGPoint(x: w * 0.49, y: 0))
            left.addLine(to: CGPoint(x: 0, y: h * 0.75))
            left.addLine(to: CGPoint(x: w * 0.32, y: h))
            left.closeSubpath()
            ctx.fill(left, with: .color(Color.white.opacity(0.55)))
            var right = Path()
            right.move(to: CGPoint(x: w, y: h * 0.89))
            right.addLine(to: CGPoint(x: w * 0.49, y: 0))
            right.addLine(to: CGPoint(x: w * 0.31, y: h))
            right.closeSubpath()
            ctx.fill(right, with: .color(Color.white.opacity(0.35)))
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
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

// MARK: - Search + top chrome

struct PrismSearchChrome: View {
    @Binding var search: String
    var placeholder: String = "Search your saves"
    var onProfile: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(PrismColors.textOnLight)
                TextField(placeholder, text: $search)
                    .font(PrismTypography.body(17))
                    .foregroundStyle(PrismColors.textOnLight)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Capsule().fill(Color.white.opacity(0.5)))

            Button(action: onProfile) {
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(red: 0.05, green: 0.12, blue: 0.17))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.5)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("home.profile")
        }
        .padding(.horizontal, PrismSpacing.md)
    }
}

struct PrismTopBar: View {
    var body: some View {
        HStack {
            Spacer()
            PrismLogoMark()
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

/// Consistent top-trailing text action (New, See all, etc.).
struct PrismHeaderAction: View {
    let title: String
    var accessibilityID: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PrismTypography.caption())
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay {
                            Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1)
                        }
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID ?? "header.action.\(title)")
    }
}

// MARK: - Save card (178×251)

struct PrismSaveCard: View {
    let image: Image?
    let uiImage: UIImage?
    var tags: [(String, PrismTone)]
    var showPlay: Bool = false
    var moreLabel: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .center) {
                Group {
                    if let uiImage {
                        Color.clear.overlay {
                            Image(uiImage: uiImage).resizable().scaledToFill()
                        }
                    } else if let image {
                        Color.clear.overlay {
                            image.resizable().scaledToFill()
                        }
                    } else {
                        Color.white.opacity(0.08)
                    }
                }
                .frame(width: 162, height: 162)
                .clipped()
                .overlay(PrismGradients.cardFade)

                if showPlay {
                    PlayBadge(size: 36)
                }
            }
            .frame(width: 162, height: 162)
            .clipShape(RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous))

            FlowTagRow(tags: tags, moreLabel: moreLabel)
                .frame(width: 162, alignment: .leading)
        }
        .padding(8)
        .frame(width: 178, height: 251, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous)
                .fill(PrismColors.glassFill)
        }
    }
}

struct PlayBadge: View {
    var size: CGFloat = 36
    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.5)).frame(width: size, height: size)
            Circle().stroke(Color.white, lineWidth: 1.5).frame(width: size * 0.83, height: size * 0.83)
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.28))
                .foregroundStyle(.white)
                .offset(x: 1)
        }
    }
}

struct FlowTagRow: View {
    var tags: [(String, PrismTone)]
    var moreLabel: String? = nil

    var body: some View {
        // Simple wrapping via LazyVGrid-like HStack wrap approximation
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ForEach(Array(tags.prefix(3).enumerated()), id: \.offset) { _, pair in
                    TagPill(text: pair.0, tone: pair.1)
                        .scaleEffect(0.85, anchor: .leading)
                }
                if let moreLabel {
                    Text(moreLabel).font(PrismTypography.body(14)).foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Custom tab bar

struct PrismTabBar: View {
    @Binding var selection: AppRouter.Tab

    private let items: [(AppRouter.Tab, String, String)] = [
        (.home, "house", "Home"),
        (.collections, "square.stack.3d.up", "Collections"),
        (.goals, "scope", "Goals"),
        (.moneyStory, "chart.pie", "Money Story")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { tab, icon, label in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .regular))
                        Text(label)
                            .font(PrismTypography.chrome(9.5))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .opacity(selection == tab ? 1 : 0.5)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(tab)")
            }
        }
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(PrismColors.tabBarFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                }
                .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(.horizontal, PrismSpacing.md)
        .padding(.bottom, 8)
    }
}

// MARK: - Helpers

extension View {
    func prismTransparentBackground() -> some View {
        self.scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func prismClearChrome() -> some View {
        self.toolbarBackground(.hidden, for: .navigationBar)
    }
}
