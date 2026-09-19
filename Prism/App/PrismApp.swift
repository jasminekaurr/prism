// Summary: App entry point. Boots Prism with the shared dependency container and root router.
// Prism — Turn impulse into inspiration.

import SwiftUI
import SwiftData

@main
struct PrismApp: App {
    @StateObject private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .environmentObject(environment.router)
                .environmentObject(environment.container)
                .preferredColorScheme(.dark)
        }
        .modelContainer(environment.container.modelContainer)
    }
}
