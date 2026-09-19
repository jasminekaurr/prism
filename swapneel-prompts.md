# Prism prompt history
# Append-only log of prompts and change summaries for this project.

### Prompt 1 — 2026-09-19
Implement the Prism iOS MVP Plan as specified. Do NOT edit the plan file. Mark todos in_progress as you work. Don't stop until all todos are complete.

**TL;DR:** Shipped local-first Prism iOS MVP: SwiftUI + SwiftData, spending pocket, full save→review→Money Story loop, Share Extension scaffold, docs, and 13 unit tests (all passing).

**Files changed:**
- `project.yml` — [NEW] XcodeGen definition (app, share extension, tests)
- `Prism/` — [NEW] App, Domain, Features, Infrastructure, DesignSystem
- `PrismShareExtension/` — [NEW] Share sheet scaffold + App Group inbox
- `PrismTests/` — [NEW] Unit tests (cooling, money, pocket, decisions, utils, perf)
- `PrismUITests/` — [NEW] UI smoke tests
- `docs/MVP_SCOPE.md` — [NEW] Must / nice / skipped / implemented tracker
- `README.md`, `ARCHITECTURE.md`, `SECURITY.md`, `PRIVACY.md`, `SUPABASE_SETUP.md`, `TESTFLIGHT_CHECKLIST.md`, `.env.example` — [NEW] docs
- `supabase/migrations/20260919000000_init_draft.sql` — [NEW] draft RLS schema
- `scratchpad/implementation-plan-v1.md` — [NEW] execution notes
- `swapneel-prompts.md` — [NEW] prompt log

**Key decisions:** Local-first only for first ship; spending pocket soft-preview (A); New York serif; Figma visuals with product-rule Money Story; Share Extension scaffolded but needs App Group provisioning.

**Errors encountered:** Share Extension empty MainStoryboard blocked install (fixed PrincipalClass); softDelete name clash; MoneyStorySnapshot Equatable tuples; AppRouter.Sheet Equatable for onChange; PerformanceSeed type-check timeout (rewrote loops).

### Prompt 2 — 2026-09-19
I am looking to build this app in expo and use sqlite, depading on the current progress, rate the efforts and tell n=me how much efforts wil it take for same plan and give me exact efforts plan

**TL;DR:** Assessed current SwiftUI/SwiftData MVP (~4.5k LOC, must-haves implemented) and produced an Expo + SQLite rewrite effort estimate and phased plan for the same local-first MVP scope. No code changes.

**Files changed:**
- None (estimation only)

**Key decisions:** Treat domain/services as portable; UI + persistence + native modules as full rewrite; Share Extension as optional stretch (high Expo cost).

**Errors encountered:** None

### Prompt 2 — 2026-09-19
Update Prism vision to goals (aspiration → goal → plan → contribution → outcome). Show updated planning file and update app flow/UI.

**TL;DR:** Added PRODUCT_VISION + goals domain/UI: Make this a goal flow, home goal dashboard, progress contributions, goal-aware review copy, Money Story priority insights.

**Files changed:**
- `docs/PRODUCT_VISION.md` — [NEW] goals-era product vision
- `scratchpad/prism-goals-vision-v1.md` — [NEW] implementation plan
- `Prism/Domain/Models/GoalModels.swift`, Enums, GoalPlanningService, SwiftData, LocalStore — goal persistence + pace math
- `Prism/Features/Goals/*`, Home, Detail, Review, MoneyStory, Onboarding — UI flow
- `docs/MVP_SCOPE.md`, `README.md` — scope + positioning
- `PrismTests` — GoalPlanningTests

**Key decisions:** Home leads with goals; aspirations remain the save feed; pace from user-entered targets only; soft active-goal limit of 3.

**Errors encountered:** SavedItemCard dropped on Home rewrite (restored); monthly pace test flaky on calendar month count (fixed with pinned dates).

### Prompt 3 — 2026-09-19
make this the onboarding 1st page + splash screen + use the logo as the favicon also

**TL;DR:** Wired the brand hero as Launch Screen + onboarding page 0, and set AppIcon from the pyramid mark (iOS favicon equivalent).

**Files changed:**
- `Prism/Resources/Assets.xcassets/BrandSplash.imageset/` — [NEW] full brand hero for splash/onboarding
- `Prism/Resources/Assets.xcassets/PrismMark.imageset/` — [NEW] pyramid mark for in-app logo
- `Prism/Resources/Assets.xcassets/AppIcon.appiconset/` — AppIcon from brand pyramid crop
- `Prism/Resources/LaunchScreen.storyboard` — [NEW] full-bleed BrandSplash launch screen
- `Prism/Features/Onboarding/OnboardingFlowView.swift` — page 0 brand hero; PrismLogoMark uses PrismMark
- `project.yml` + `Prism.xcodeproj` — UILaunchStoryboardName + LaunchScreen resource
- `scratchpad/brand-splash-onboarding-v1.md` — [NEW] plan

**Key decisions:** iOS AppIcon stands in for favicon (no web target); first onboarding page uses the composite hero image so typography matches the design; UITest ids preserved.

**Errors encountered:** None (xcodebuild succeeded).
