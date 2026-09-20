# MVP Scope — Must / Nice / Skipped / Implemented

Last updated: 2026-09-19 (Recreation IA — App Screens folder)

Canonical vision: [PRODUCT_VISION.md](PRODUCT_VISION.md)  
UI source of truth: `Prism App Screens Recreation/`

## Must-haves (local TestFlight MVP)

| Item | Status |
|---|---|
| Onboarding + financial boundary + demo mode | Implemented |
| Tab shell: **Home, Collections, Goals, Money Story** (4 tabs) | Implemented |
| Settings via Home profile (not a tab) | Implemented |
| Review as collection-scoped flow (not a tab) | Implemented |
| Home: saves masonry + filters (All / High priority / Undecided / Videos) | Implemented |
| Collections create + swipe sort deck (keep / delete) | Implemented |
| Capture “Paste anything” stages + Share Extension → Capture | Implemented |
| Item detail: Bought?, mock AI description, tags, why, feeling stars | Implemented |
| Goal setup 5 steps matching recreation chrome | Implemented |
| Goals dashboard tab (primary lead + other goals) | Implemented |
| Saves in goal: projected cost, classify, swipe remove | Implemented |
| Save → “Worth saving for?” → goal setup | Implemented |
| Money Story Weekly / Monthly / Over time MVP layout | Implemented (demo narrative UI; see [MONEY_STORY_REAL_DATA.md](MONEY_STORY_REAL_DATA.md)) |
| Goal pace (remaining + required contribution) | Implemented |
| Add progress (financial / planning / behavioral) | Implemented |
| Cooling-off defaults + local notification scheduler | Implemented |
| Spending pocket (soft preview) | Implemented |
| Design tokens + glass UI (Fraunces / Figtree / Encode Sans / Inter) | Implemented |
| Demo seed with sample images | Implemented |
| Unit tests + UITest smoke | Partial |
| Privacy manifest + usage strings | Implemented |
| Docs (vision, scope, handoff) | Implemented |

## Recreation screen checklist

| # | Screen | Status |
|---|---|---|
| 01 | Launch | Implemented |
| 02 | Home | Implemented |
| 03 | Item detail | Implemented |
| 04 | Save into collection (swipe) | Implemented |
| 05 | Review — buy or let go | Implemented |
| 07–11 | New goal steps 1–5 | Implemented |
| 12 | Saves attached to goal | Implemented |
| 13 | Share a link / Paste anything | Implemented |
| 14 | Saved item → start a goal | Implemented |
| 15 | Goals dashboard | Implemented |
| 16 | My Money Story MVP | Implemented (demo data; real aggregates → MONEY_STORY_REAL_DATA.md) |

## Nice-to-haves / later

| Item | Status |
|---|---|
| **Real AI description generation** (MVP uses local mock) | Future |
| Multi-goal monthly allocation editor | Deferred |
| Auto plan cost from linked aspiration roles | Partial (projected cost UI) |
| Full component booking deadlines | Deferred |
| Supabase + RLS + private media | Deferred |
| Sign in with Apple + Keychain session | Stub UI only |
| StoreKit / premium | Skipped |

## Forbidden (never)

- Bank links / affordability engine
- Scraping social or retailer pages for purchase
- Calling let-go estimates “money saved”
- Service-role keys in the client

## Implemented checklist notes

Update this table whenever a feature ships or is deferred. Do not represent stubs as complete.
