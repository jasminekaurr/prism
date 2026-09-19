// Summary: Onboarding — visual intro, financial boundary, spending pocket intro, demo mode entry.

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @State private var page = 0
    @State private var isWorking = false
    @State private var errorText: String?

    private let pages: [(title: String, body: String)] = [
        ("Save what catches your eye.", "Collect products, experiences, and inspiration from anywhere — without rushing to buy."),
        ("Give the impulse space.", "Add a light reflection, tags, and a cooling-off pause that you control."),
        ("Return when you’re ready.", "Revisit with a clear mind. Buy, keep considering, or let go."),
        ("Your boundary, your choice.", "Prism never connects to your bank or decides what you can afford. You can set an optional spending pocket for wants — change, pause, or ignore it anytime.")
    ]

    var body: some View {
        VStack(spacing: PrismSpacing.lg) {
            Spacer()
            PrismLogoMark()
                .frame(height: 120)
            Text("Prism")
                .font(PrismTypography.display(56))
                .accessibilityIdentifier("onboarding.brand")

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: PrismSpacing.sm) {
                        Text(pages[index].title)
                            .font(PrismTypography.title(26))
                            .multilineTextAlignment(.center)
                        Text(pages[index].body)
                            .font(PrismTypography.body())
                            .foregroundStyle(PrismColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, PrismSpacing.xl)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 180)

            if page < pages.count - 1 {
                PrismPrimaryButton(title: "Continue") {
                    withAnimation { page += 1 }
                }
                .accessibilityIdentifier("onboarding.continue")
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
            Spacer()
        }
        .padding()
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
            container.analytics.track(.onboardingCompleted)
        } catch {
            errorText = "Could not start local mode. Please try again."
            container.crashReporter.record(error: error, context: "onboarding.demo")
        }
    }
}

struct PrismLogoMark: View {
    var body: some View {
        // Geometric prism stand-in using SF Symbol until brand asset is finalized.
        Image(systemName: "pyramid")
            .resizable()
            .scaledToFit()
            .foregroundStyle(
                LinearGradient(
                    colors: [PrismColors.cyan, PrismColors.lavender, PrismColors.magenta],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(0.9)
            .accessibilityHidden(true)
    }
}
