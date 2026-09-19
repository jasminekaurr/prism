// Summary: Reusable glass surfaces, tag pills, atmospheric backgrounds, and primary buttons.

import SwiftUI

/// App-wide background: the Prism light-refraction art with a uniform blur.
struct PrismAtmosphericBackground: View {
    var body: some View {
        GeometryReader { geo in
            Image("PrismBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .blur(radius: PrismBackdrop.blurRadius, opaque: true)
                .overlay(Color.black.opacity(PrismBackdrop.scrimOpacity))
                .clipped()
        }
        .background(PrismColors.backgroundDeep)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = PrismSpacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous)
                    .fill(PrismColors.glassFill)
                    .background {
                        RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.35))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: PrismRadius.lg, style: .continuous)
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
