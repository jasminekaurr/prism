# Goal paste-first workflow + MacBook dummy — v1

**Date:** 2026-09-19

## Goal

1. Seed a demo **New laptop** goal (and companion hub goals) matching recreation screenshots.
2. Make **Paste anything** step 1 of the New Goal 5-step flow when starting from Goals → New goal.

## Five-step flow (fresh goal)

| Step | Headline | Notes |
|------|----------|--------|
| 1 | Paste anything | URL paste + preview + type chips; Continue → Define |
| 2 | Define the goal | Name, type, cost, where, date (prefilled from paste/mock) |
| 3 | Why this matters | Motivation radio list |
| 4 | Set the target | Amount, date, saved, frequency, buffer |
| 5 | Your plan | Priority + plan summary → Create goal |

When opened from an existing save/collection, skip Paste and use: Define → Why → Target → Rank → Plan (still 5 steps).

## Dummy goals (hub)

- Japan — Primary — $1,575 / $4,500 — Apr 2027
- New laptop — Active — $150 / $1,295 — Mar 2027 — components totaling projected $1,339
- Concert tickets — Active — $200 / $240
- New sofa — Flexible — $0 / $1,200
- Kyoto cooking class — Someday — $0 / $180

## New laptop components

| Name | Role | Cost |
|------|------|------|
| M4 MacBook Air 13" | Essential | $1,199 |
| Refurbished M4 Air, same specs | Alternative | $1,019 |
| Student pricing, explained | Inspiration | — |
| Hard case + two dongles | Optional | $45 |
| AppleCare — worth it? | Optional | $95 |

Projected cost = Essential + Optional only ($1,339). Target $1,199 → $140 over.

## Implementation notes

- Separate `goalsSeeded.v1` flag so existing installs still get goals.
- Add `role` on `GoalComponent` for Essential/Alternative/Inspiration/Optional tags.
- Capture flow remains for Home “add save”; Goals “New goal” opens GoalSetup with paste first.
