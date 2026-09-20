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

### Prompt 5 — 2026-09-19
I don't see the bg image in the background. maybe the blur is too high, experiment with it. this is what i want to see:
[attached screenshot + PrismAtmosphericBackground selection]

**TL;DR:** Lowered backdrop blur from 80→12 and dropped opaque blur so PrismBackground light streaks read instead of a flat purple wash.

**Files changed:**
- `Prism/Core/DesignSystem/PrismTokens.swift` — blurRadius 12, scrim 0.22
- `Prism/Core/DesignSystem/PrismComponents.swift` — soft blur without opaque; slight overscan before blur

**Key decisions:** Reference still wants atmosphere (not sharp art); 12 keeps streaks visible under glass cards. Tune further if needed (try 6–20).

**Errors encountered:** None

### Prompt 6 — 2026-09-19
Figma UI match (all 6 frames) — implement the plan

**TL;DR:** Matched app UI to original Figma frames: Figma backdrop recipe (visible art + frost), Home aspiration feed, Goals tab, restyled detail/review/Money Story; Collections under Home segment.

**Files changed:**
- `Prism/Core/DesignSystem/PrismComponents.swift` — Figma backdrop, chrome, AspirationItemCard
- `Prism/Core/DesignSystem/PrismTokens.swift` — backdrop scrim
- `Prism/Resources/Assets.xcassets/PrismBackground.imageset/` — Figma refraction art
- `Prism/App/AppRouter.swift`, `AppEnvironment.swift` — Home/Goals/Review/Story/Settings tabs
- `Prism/Features/Home/HomeView.swift` — Figma feed
- `Prism/Features/Goals/GoalsHubView.swift` — [NEW] goals hub
- `Prism/Features/Review/ReviewViews.swift`, `SavedItemDetailView.swift`, `MoneyStoryView.swift`, `AspirationMediaView.swift`, `SettingsView.swift`
- `PrismUITests` — Collections via Home segment
- `scratchpad/figma-ui-match-v1.md`

**Key decisions:** Product metrics on Money Story (no credit/category spend); Goals tab for goals-first IA; frost overlay not heavy image blur so bg shows.

**Errors encountered:** WrappingHStack redeclaration (removed duplicate); GoalsHubView missing until xcodegen; sips cwd trap in /tmp (used absolute paths).

### Prompt 7 — 2026-09-19
No image named PrismBackground found in asset catalog…

**TL;DR:** Root cause was Assets.xcassets never in the app Resources build phase (no Assets.car). Fixed via XcodeGen `buildPhase: resources` sources + user PrismBackground image; verified Assets.car contains PrismBackground.

**Files changed:**
- `project.yml` — resources via sources buildPhase; team ID
- `Prism.xcodeproj/project.pbxproj` — regenerated with Resources phase
- `PrismBackground.imageset` — user-provided background JPEG
- `scripts/ensure-resources.py` — [NEW] safety patch if xcodegen drops resources

**Key decisions:** Prefer XcodeGen sources+buildPhase over broken top-level resources; keep ensure-resources as fallback.

**Errors encountered:** Manual pbxproj patch briefly corrupted project (regenerated).

### Prompt 8 — 2026-09-19
BrandSplash/PrismBackground missing in app; splash works but not inside app

**TL;DR:** In-app tabs used Color.clear over an opaque TabView host and heavy frost hid the art. Local PrismAtmosphericBackground on each tab, lighter scrim, BrandSplash fallback, same JPEG for PrismBackground.

**Files changed:** PrismComponents, PrismTokens, Home/Goals/Review/MoneyStory/Settings, PrismBackground imageset

**Key decisions:** Do not rely on root bg through TabView; no need to resend Figma (all 6 frames already used).

**Errors encountered:** None

### Prompt 9 — 2026-09-19
1. brother what have you done. the vision is there, but this needs to be fixed.
2. When i open share a link from insta in the app, the app should open and automatically open the save something option.
3. make a dummy database with some examples - you can use the same images I have in figma for this purpose and then anything we add on top can add value

**TL;DR:** Fixed inverted in-app branding by using refraction-only PrismBackground (never BrandSplash) for atmospheric UI; Instagram/share now stores payload + opens prism://share which presents Capture prefilled; seeded demo collections/items from Figma Demo* images on demo start / empty Home.

**Files changed:**
- `Prism/Core/DesignSystem/PrismComponents.swift` — atmospheric bg uses PrismBackground only + 180° Figma plate
- `Prism/App/AppEnvironment.swift` — presentCapture draft fields on AppRouter
- `Prism/App/AppRouter.swift` — consume App Group share + onOpenURL → Capture
- `Prism/Features/Capture/CaptureFlowView.swift` — apply share draft URL/title/image
- `PrismShareExtension/ShareViewController.swift` — store payload, open prism://share
- `Prism/Infrastructure/Notifications/ShareInbox.swift` — extract URL from shared text
- `Prism/Domain/Services/DemoDataSeeder.swift` — [NEW] Figma sample aspirations + media
- `Prism/Features/Onboarding/OnboardingFlowView.swift` — seed after Explore locally
- `Prism/Features/Home/HomeView.swift` — seed if demo empty; + opens presentCapture
- `Prism/Prism.entitlements` / `PrismShareExtension/...entitlements` — App Group
- `project.yml` + `Prism/Info.plist` — entitlements + prism URL scheme

**Key decisions:** BrandSplash stays splash/onboarding only (logo baked in); Share Extension uses responder-chain openURL because extensionContext.open is unavailable for share extensions; first demo item is readyForReview so Review isn’t empty.

**Errors encountered:** xcodebuild OS=latest failed to resolve iPhone 16; rebuilt with OS=18.4 successfully.
