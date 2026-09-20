# Money Story — wiring real data

Status: **UI ships with recreation demo content** (`MoneyStoryDemoContent` in `MoneyStoryView.swift`). Aggregates below are not yet computed from the user’s saves/goals.

Reference layout: `Prism App Screens Recreation/Prism App Screens.dc.html` screen **16**.

## What the screen shows today

| Section | Demo source | Real-data work |
| --- | --- | --- |
| Weekly / Monthly / Over time chips | `MoneyStoryTimeFilter` | Keep; drive all sections with the same window |
| Headline + subtitle + basis | Hardcoded per filter | Narrative templates filled from counts (see below) |
| Metric tiles (ideas saved, decisions, redirected $, reconsidered, milestones) | Hardcoded | Count saves / decisions / goal contributions / reconsidered purchases / completed milestones in window |
| Goal progress bars | Japan / laptop demo | Active goals + `GoalPlanningService.percentFunded` + financial contributions this month |
| What caught your attention | Category bars | Group saves by intent/category; bar widths = share of period saves |
| What influenced you | TikTok / IG / Pinterest table | Group by source platform (`SavedItem` URL host or share metadata); “still live · 14d” = still considering after 14 days; goals = attached to a goal |
| Attention vs intention | 11 / 7 split | Heuristic: attention = fast save + Curious/Impulse + often removed; intention = revisited + goal-tied + High/Meaningful |
| How you decided | Flow 18 → 9 → outcomes | Period: saved → reviewed → became goals / deferred / removed |
| How saves felt | Feeling pills | `FeelingRepository` aggregates for items in window |
| Trade-offs you made | Three narrative cards | Pair deferred/bought decisions with goal pace deltas (contribution vs purchase) |
| One next step | CTA copy | Rank open High-priority / most-revisited saves; deep-link Review or item detail |
| Footer | Static disclaimer | Keep until bank linking exists |

## Existing services to extend

- `MoneyStoryService.snapshot(...)` — already returns purchases confirmed, let-go, still considering, feelings/intents, avg hours to decision. **Does not** yet produce attention bars, influence rows, attention-vs-intention, decision funnel, trade-offs, or next-step ranking.
- `SpendingPocketService` / pocket UI — intentionally omitted from the recreation MVP layout; reintroduce only if product wants it back under Story.
- `GoalPlanningService` + `goalRepository.fetchContributions` — for redirected $ and progress bars.
- Share card (`MoneyStoryShareCard`) — removed from this UI pass; restore when counts are real (counts only; no titles/prices — see `PRIVACY.md`).

## Suggested implementation order

1. **Period window helper** shared by Story (week / calendar month / all-time).
2. **Core counters** for metric tiles + decision funnel (reuse + extend `MoneyStorySnapshot`).
3. **Goal progress** from real goals (empty state when none).
4. **Category + source aggregations** (attention + influence).
5. **Attention vs intention heuristic** (document rules in code comments; keep soft language — correlation, not causation).
6. **Trade-off and next-step generators** (template strings; never invent bank balances).
7. Swap `MoneyStoryDemoContent.forFilter` for a `MoneyStoryNarrative` built from the snapshot; keep demo behind `#if DEBUG` or a Settings “Preview sample story” toggle if useful for TestFlight screenshots.

## Product / copy constraints

- Never say “money saved.” Prefer redirected / contributed / decided against.
- Influence copy must not claim platforms *caused* purchases.
- Shared images: counts and optional primary-goal % only.

## Done when

- Empty and sparse states look intentional (not blank glass).
- Weekly / Monthly / Over time all derive from the same pipeline.
- Unit tests cover aggregations (extend `PrismCoreTests` / `MoneyStoryService` tests).
- Demo constants are gone from the shipping path (or gated).
