# MVP Scope — Must / Nice / Skipped / Implemented

Last updated: 2026-09-19 (Goals vision update)

Canonical vision: [PRODUCT_VISION.md](PRODUCT_VISION.md)

## Must-haves (local TestFlight MVP)

| Item | Status |
|---|---|
| Onboarding + financial boundary + demo mode | Implemented |
| Tab shell: Home, Collections, Review, Money Story, Settings | Implemented |
| Collections create + presets | Implemented |
| Capture: title, collection, intent, cost, Photos, URL paste | Implemented |
| Home leads with primary/active goals + aspiration feed | Implemented |
| Make this a goal setup flow (define → motivate → target → priority → plan) | Implemented |
| Goal pace (remaining + required contribution) | Implemented |
| Add progress (financial / planning / behavioral) | Implemented |
| Goal-aware trade-off copy on detail + buy confirmation | Implemented |
| Money Story goal priority insight | Implemented |
| Item detail + optional reflection/feelings/tags/estimate | Implemented |
| Cooling-off defaults + local notification scheduler | Implemented |
| Review Buy / Keep considering / Let go + Undo payload | Implemented |
| Money Story counts + confirmed spend + estimated let-go disclaimer | Implemented |
| Spending pocket (soft preview; confirmed reduces remaining) | Implemented |
| Settings: pocket, cooling, notifications, app lock, export, wipe | Implemented |
| Design tokens + glass UI | Implemented |
| Unit tests (cooling, money, pocket, decisions, goals, URL, notifications) | Implemented |
| UITest smoke (onboarding, collection, capture open) | Implemented |
| Privacy manifest + usage strings | Implemented |
| Docs (README, vision, architecture, security, privacy, scope, TestFlight) | Implemented |

## Nice-to-haves / later

| Item | Status |
|---|---|
| Multi-goal monthly allocation editor | Deferred |
| Auto plan cost from linked aspiration roles | Deferred |
| Full component booking deadlines | Deferred |
| Goal outcome reflection after complete/abandon | Partial (status only) |
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
