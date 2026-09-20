// Summary: Onboarding — brand hero + 3 content pages, shared hero bg, fixed CTA slot.

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @EnvironmentObject private var router: AppRouter
    @State private var page = 0
    @State private var isWorking = false
    @State private var errorText: String?

    /// Content pages after the brand hero (page 0).
    private let pages: [(title: String, body: String)] = [
        (
            "Save what inspires you",
            "Bring products, trips, restaurants, events, and experiences from any social platform into one place."
        ),
        (
            "Turn inspiration into goals",
            "Prism helps you understand what matters, estimate the cost, and create a realistic plan for making it happen."
        ),
        (
            "Spend with intention",
            "See how today’s choices affect your bigger goals—then buy, wait, find an alternative, or put that money toward what matters more."
        )
    ]

    private var isBrandPage: Bool { page == 0 }
    private var isLastContentPage: Bool { page == pages.count }
    private var contentPageIndex: Int { page - 1 }

    private var ctaTitle: String {
        if isBrandPage { return "Get started" }
        if isLastContentPage { return "Save my first inspiration" }
        return "Next"
    }

    var body: some View {
        ZStack {
            heroBackground

            VStack(spacing: 0) {
                Group {
                    if isBrandPage {
                        brandContent
                    } else {
                        contentPage
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                ctaFooter
            }
            .padding(.horizontal, PrismSpacing.xxl)
            .padding(.top, PrismSpacing.lg)
            .padding(.bottom, PrismSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeInOut(duration: PrismMotion.standard), value: page)
    }

    private var brandContent: some View {
        VStack(spacing: PrismSpacing.md) {
            Spacer(minLength: 0)
            PrismLogoMark(width: 180, height: 128)
            Text("Prism")
                .font(PrismTypography.display(1))
                .foregroundStyle(.clear)
                .accessibilityIdentifier("onboarding.brand")
                .accessibilityLabel("Prism")
                .accessibilityAddTraits(.isHeader)
            Text("Catch the impulse")
                .font(PrismTypography.body(16, weight: .light))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, PrismSpacing.md)
            Spacer(minLength: 0)
        }
    }

    private var contentPage: some View {
        VStack(spacing: PrismSpacing.lg) {
            Spacer(minLength: 0)
            PrismLogoMark()
                .frame(height: 72)
            Text("Prism")
                .font(PrismTypography.display(36))
                .accessibilityIdentifier("onboarding.brand")

            VStack(spacing: PrismSpacing.sm) {
                Text(pages[contentPageIndex].title)
                    .font(PrismTypography.title(26))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(pages[contentPageIndex].body)
                    .font(PrismTypography.body())
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PrismSpacing.md)

            pageDots
            Spacer(minLength: 0)
        }
    }

    private var ctaFooter: some View {
        VStack(spacing: PrismSpacing.sm) {
            if let errorText {
                Text(errorText)
                    .font(PrismTypography.caption())
                    .foregroundStyle(PrismColors.danger)
                    .multilineTextAlignment(.center)
            }

            PrismPrimaryButton(title: ctaTitle) {
                handleCTA()
            }
            .disabled(isWorking)
            .opacity(isWorking ? 0.7 : 1)
            .accessibilityIdentifier(isLastContentPage ? "onboarding.demo" : "onboarding.continue")
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 56)
    }

    private var heroBackground: some View {
        GeometryReader { geo in
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
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .opacity(PrismBackdrop.materialOpacity)
                Color.black.opacity(PrismBackdrop.scrimOpacity + 0.08)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var pageDots: some View {
        HStack(spacing: PrismSpacing.xs) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == contentPageIndex ? Color.white : Color.white.opacity(0.28))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
        .padding(.top, PrismSpacing.xs)
    }

    private func handleCTA() {
        if isLastContentPage {
            Task { await startDemoAndCapture() }
        } else {
            withAnimation(.easeInOut(duration: PrismMotion.standard)) { page += 1 }
        }
    }

    private func startDemoAndCapture() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await environment.ensureDemoProfileIfNeeded()
            guard var profile = environment.profile else { return }
            profile.onboardingCompleted = true
            profile.isDemoMode = true
            try await container.profileRepository.save(profile)
            environment.profile = profile
            await DemoDataSeeder.seedIfNeeded(userID: profile.id, container: container)
            container.analytics.track(.onboardingCompleted)
            router.presentCapture()
        } catch {
            errorText = "Could not start. Please try again."
            container.crashReporter.record(error: error, context: "onboarding.demo")
        }
    }
}
