# Prism

**Save what inspires you. Work toward what matters.**

Prism is an intentional-spending assistant that turns social-media inspiration into clear priorities, achievable goals, and better spending decisions.

Save products, experiences, and aspirational content; reflect; revisit after a cooling-off period; then buy, keep considering, or let go — or **make it a goal** and track financial, planning, and behavioral progress.

## Positioning

> From “I want this” to “I’m making it happen.”

Core loop: **Save → Reflect → Prioritize → Set a goal → Make progress → Decide intentionally → Learn**

See [docs/PRODUCT_VISION.md](docs/PRODUCT_VISION.md) for the full goals-era vision.

## What Prism deliberately does not do

- Connect bank accounts or request balances
- Calculate disposable income or affordability
- Provide financial advice
- Scrape Instagram, TikTok, Pinterest, or retailer pages
- Treat estimated prices of let-go items as “money saved”
- Move or manage money
- Decide what you can afford

All money figures are **user-entered** and labeled **confirmed** or **estimated**.

## Spending pocket

Optionally set how much you are comfortable spending on wants this month. Prism can preview how an estimate fits that guardrail. Confirmed purchases reduce remaining for the calendar month. You can change, pause, or ignore the pocket anytime.

## Local setup (MVP)

Requirements: macOS with Xcode 16+, iOS 17 Simulator.

```bash
# Generate the Xcode project
xcodegen generate

# Open
open Prism.xcodeproj

# Or build from CLI
xcodebuild -scheme Prism -destination 'platform=iOS Simulator,name=iPhone 16' build

# Unit tests
xcodebuild -scheme Prism -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:PrismTests
```

This first ship runs **entirely on-device** with SwiftData. Sign in with Apple and Supabase are stubbed for a later phase.

## Project layout

See [ARCHITECTURE.md](ARCHITECTURE.md). Scope tracking: [docs/MVP_SCOPE.md](docs/MVP_SCOPE.md).

## Configuration

Copy [`.env.example`](.env.example) when cloud is enabled. Never commit service-role keys.

## Share Extension

Target `PrismShareExtension` is scaffolded. Bundle ID is `com.jasminekaur.prism` (share: `com.jasminekaur.prism.share`). Configure App Group `group.com.jasminekaur.prism` in the Apple Developer portal before TestFlight. See [TESTFLIGHT_CHECKLIST.md](TESTFLIGHT_CHECKLIST.md).

## Documentation

| Doc | Purpose |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layers, sync policy |
| [SECURITY.md](SECURITY.md) | Security practices |
| [PRIVACY.md](PRIVACY.md) | Privacy & retention |
| [SUPABASE_SETUP.md](SUPABASE_SETUP.md) | Deferred backend |
| [TESTFLIGHT_CHECKLIST.md](TESTFLIGHT_CHECKLIST.md) | Shipping checklist |
| [docs/MVP_SCOPE.md](docs/MVP_SCOPE.md) | Must / nice / skipped / implemented |

## Known limitations (local MVP)

- No cloud sync or Sign in with Apple (UI stub only)
- Share Extension requires App Group provisioning to work on device
- Images only (no video)
- No AI descriptions
- App icon is a placeholder
- Fraunces font not bundled — uses New York system serif
