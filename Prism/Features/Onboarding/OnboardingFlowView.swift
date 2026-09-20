// Summary: Onboarding — brand hero first, then product intro pages, demo mode entry.

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @State private var page = 0
    @State private var isWorking = false
    @State private var errorText: String?

    /// Content pages after the brand hero (page 0).
    private let pages: [(title: String, body: String)] = [
        ("Save what inspires you.", "Collect products, experiences, and ideas from anywhere — without rushing to buy."),
        ("Give the impulse space.", "Reflect lightly, pause with a cooling-off period you control, then revisit."),
        ("Work toward what matters.", "When something is worth it, turn it into a goal — with a target, a date, and progress you define."),
        ("Your boundary, your choice.", "Prism never connects to your bank or decides what you can afford. Spending pockets and goals use only numbers you enter.")
    ]

    private var isBrandPage: Bool { page == 0 }
    private var isLastContentPage: Bool { page == pages.count }
    private var contentPageIndex: Int { page - 1 }

    var body: some View {
        ZStack {
            if isBrandPage {
                brandHeroBackground
            }

            VStack(spacing: PrismSpacing.lg) {
                if isBrandPage {
                    Spacer(minLength: 0)
                    // Wordmark lives in BrandSplash art; keep an accessible label for UITests.
                    Text("Prism")
                        .font(PrismTypography.display(1))
                        .foregroundStyle(.clear)
                        .accessibilityIdentifier("onboarding.brand")
                        .accessibilityLabel("Prism")
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                } else {
                    Spacer()
                    PrismLogoMark()
                        .frame(height: 88)
                    Text("Prism")
                        .font(PrismTypography.display(44))
                        .accessibilityIdentifier("onboarding.brand")

                    VStack(spacing: PrismSpacing.sm) {
                        Text(pages[contentPageIndex].title)
                            .font(PrismTypography.title(26))
                            .multilineTextAlignment(.center)
                        Text(pages[contentPageIndex].body)
                            .font(PrismTypography.body())
                            .foregroundStyle(PrismColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, PrismSpacing.xl)
                    .frame(minHeight: 140)

                    pageDots
                }

                if !isLastContentPage {
                    PrismPrimaryButton(title: isBrandPage ? "Get started" : "Continue") {
                        withAnimation(.easeInOut(duration: PrismMotion.standard)) { page += 1 }
                    }
                    .accessibilityIdentifier("onboarding.continue")
                    .padding(.horizontal, isBrandPage ? PrismSpacing.xl : 0)
                } else {
                    VStack(spacing: PrismSpacing.sm) {
                        PrismPrimaryButton(title: "Explore locally") {
                            Task { await startDemo() }
                        }
                        .accessibilityIdentifier("onboarding.demo")

                        Button("Sign in with Apple (coming soon)") {}
                            .disabled(true)
                            .font(PrismTypography.body())
                            .foregroundStyle(PrismColors.textTertiary)
                            .accessibilityIdentifier("onboarding.apple")

                        Text("Local and demo data stays on this device until you create an account later.")
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }

                if let errorText {
                    Text(errorText).foregroundStyle(PrismColors.danger)
                }

                if !isBrandPage {
                    Spacer()
                } else {
                    Color.clear.frame(height: PrismSpacing.md)
                }
            }
            .padding()
        }
        .animation(.easeInOut(duration: PrismMotion.standard), value: page)
    }

    private var brandHeroBackground: some View {
        Image("BrandSplash")
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.45)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            }
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

    private func startDemo() async {
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
        } catch {
            errorText = "Could not start local mode. Please try again."
            container.crashReporter.record(error: error, context: "onboarding.demo")
        }
    }
}

struct PrismLogoMark: View {
    var body: some View {
        Image("PrismMark")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}
