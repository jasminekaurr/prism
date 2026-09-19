# MVP Scope — Must / Nice / Skipped / Implemented

Last updated: 2026-09-19

## Must-haves (local TestFlight MVP)

| Item | Status |
|---|---|
| Onboarding + financial boundary + demo mode | Implemented |
| Tab shell: Home, Collections, Review, Money Story, Settings | Implemented |
| Collections create + presets | Implemented |
| Capture: title, collection, intent, cost, Photos, URL paste | Implemented |
| Home masonry + search + status filters | Implemented |
| Item detail + optional reflection/feelings/tags/estimate | Implemented |
| Cooling-off defaults + local notification scheduler | Implemented |
| Review Buy / Keep considering / Let go + Undo payload | Implemented |
| Money Story counts + confirmed spend + estimated let-go disclaimer | Implemented |
| Spending pocket (soft preview; confirmed reduces remaining) | Implemented |
| Settings: pocket, cooling, notifications, app lock, export, wipe | Implemented |
| Design tokens + glass UI | Implemented |
| Unit tests (cooling, money, pocket, decisions, URL, notifications mock) | Implemented |
| UITest smoke (onboarding, collection, capture open) | Implemented |
| Privacy manifest + usage strings | Implemented |
| Docs (README, architecture, security, privacy, scope, TestFlight) | Implemented |

## Nice-to-haves / later

| Item | Status |
|---|---|
| Supabase + RLS + private media | Deferred (stubs + setup doc) |
| Sign in with Apple + Keychain session | Stub UI only |
| Live offline sync queue | Designed, not live |
| Share Extension fully provisioned | Scaffolded; needs App Group |
| Demo → account merge | Deferred (needs auth) |
| AI Description (user-provided text only) | Explicitly later |
| Video saves | Skipped |
| Email magic-link | Skipped |
| StoreKit / premium | Skipped |
| Real crash vendor | Protocol + no-op |
| Soft-reserve pocket (option B) | Rejected for MVP |
| Rolling 30-day pocket | Calendar month only |
| Fraunces bundled font | New York fallback |
| Full 10 UITest journeys | Partial smoke; expand later |
| 500-item performance profiling | Seed helper + sanity unit test implemented |

## Forbidden (never)

- Bank links / affordability engine
- Scraping social or retailer pages
- Calling let-go estimates “money saved”
- Credit score / fintech dashboard widgets from early Figma drafts
- Service-role keys in the client

## Implemented checklist notes

Update this table whenever a feature ships or is deferred. Do not represent stubs as complete.
