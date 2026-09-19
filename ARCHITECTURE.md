# Architecture

Prism uses **MVVM + repository protocols + SwiftData** for a local-first MVP.

```
Prism/
  App/           # PrismApp, environment, router, DI
  Core/          # Design system, analytics, security, utilities
  Domain/        # Models, repository protocols, use-case services
  Features/      # SwiftUI feature modules
  Infrastructure/# SwiftData, notifications, Supabase stubs
PrismShareExtension/
PrismTests/
PrismUITests/
```

## Data flow

UI → ViewModels / views → Domain services → Repository protocols → `LocalStore` (SwiftData).

Mocks and in-memory containers support previews and tests. Supabase can replace repository implementations without rewriting Features.

## Conflict policy (future sync)

Documented in `SyncConflictPolicy` and [SUPABASE_SETUP.md](SUPABASE_SETUP.md): latest scalar edit wins; tags/feelings merge by id; decisions append-only.

## Design system

Tokens live in `Core/DesignSystem/PrismTokens.swift` (colors, gradients, type, spacing, radii, motion, haptics). Components in `PrismComponents.swift`. Visual language follows the Figma concept (violet/prism/glass); behavior follows product rules.
