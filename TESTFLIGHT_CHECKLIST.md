# TestFlight Checklist

## Local-first path (current MVP)

1. [ ] `xcodegen generate` && open `Prism.xcodeproj`
2. [ ] Set your Development Team on Prism + PrismShareExtension
3. [ ] Update bundle IDs if needed (`com.prism.app` / `com.prism.app.share`)
4. [ ] Run on a physical device or Simulator; complete onboarding in demo mode
5. [ ] Verify save → reflect → review → Money Story / spending pocket
6. [ ] Verify Settings export + delete local data
7. [ ] Archive (Release) and validate; upload when ready

## Before cloud / production TestFlight

1. [ ] Apple Developer App IDs for app + Share Extension
2. [ ] App Group `group.com.prism.app` on both targets
3. [ ] Sign in with Apple capability
4. [ ] Push / notification capability if using remote later (local notifications work without)
5. [ ] Supabase project + redirect URLs ([SUPABASE_SETUP.md](SUPABASE_SETUP.md))
6. [ ] Privacy usage descriptions (already in project settings)
7. [ ] Hosted Privacy Policy URL
8. [ ] Account deletion verification (cloud)
9. [ ] App Store privacy answers checklist
10. [ ] Export compliance notes (encryption: standard HTTPS only)

## Internal tester notes

- Start in **Explore locally**
- Create a collection before saving
- Spending pocket is optional
- Share Extension may no-op until App Group is provisioned

## Known limitations

See README and [docs/MVP_SCOPE.md](docs/MVP_SCOPE.md).
