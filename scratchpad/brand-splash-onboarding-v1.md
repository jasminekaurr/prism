# Brand splash + onboarding page 1 — plan v1

Date: 2026-09-19

## Goal
Use the provided Prism brand hero as:
1. System launch / splash screen
2. Onboarding first page
3. App icon (iOS “favicon” equivalent) from the translucent pyramid mark

## Approach
1. Copy brand JPEG into `Assets.xcassets` as `BrandSplash`.
2. Extract / compose a pyramid mark → `PrismMark` imageset + `AppIcon` 1024².
3. Add `LaunchScreen.storyboard` full-bleed `BrandSplash`; point Info.plist / XcodeGen at it.
4. Rewrite onboarding so page 0 is the brand hero; keep existing copy pages after.
5. Point `PrismLogoMark` at `PrismMark` asset.
6. Preserve UITest ids: `onboarding.brand`, `onboarding.continue`, `onboarding.demo`.

## Out of scope
- Web favicon (no web target in this repo)
- Regenerating Xcode project unless `xcodegen` is available and needed for LaunchScreen resource

## Verify
- Asset catalog contains BrandSplash, PrismMark, AppIcon
- Onboarding page 0 shows hero; Continue advances
- Launch storyboard references BrandSplash
