// Summary: Authentication feature shell — Sign in with Apple UI stub for future backend wiring.

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    var body: some View {
        VStack(spacing: PrismSpacing.md) {
            Text("Sign in")
                .font(PrismTypography.title())
            Text("Cloud sync and Sign in with Apple will unlock once Supabase is configured. For now, continue in local mode from onboarding.")
                .font(PrismTypography.body())
                .foregroundStyle(PrismColors.textSecondary)
                .multilineTextAlignment(.center)
            SignInWithAppleButton(.signIn) { _ in } onCompletion: { _ in }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 44)
                .disabled(true)
                .opacity(0.4)
        }
        .padding()
    }
}
