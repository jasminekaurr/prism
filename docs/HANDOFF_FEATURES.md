## IA update (2026-09-19 — App Screens recreation)

Source of truth: `Prism App Screens Recreation/`. Full vision: [PRODUCT_VISION.md](PRODUCT_VISION.md).

- **Tabs:** Home · Collections · Goals · Money Story (Settings and Review are no longer tabs).
- **Review entry:** from Collections swipe-sort CTA and Review buttons — collection-scoped Buy Options + Discarded rows (not the old tab deck alone).
- **Capture:** “Paste anything” staged sheet; Instagram / Share Extension still opens Capture via `prism://share`.
- **Home:** saves archive only (goals moved to Goals tab). Paused/finished goals live under Goals, not Home.
- **Regret check-in card:** surfaces inside the Review *flow* (and can remain reachable from Collections → Review), not a dedicated tab.
- **AI DESCRIPTION:** local mock on item detail for MVP; real generation is Future (see PRODUCT_VISION).

---

# Handoff: reflection features (goal outcomes, regret check-in, weekly recap, share card, redirect nudge, goal from collection)


Audience: teammates and their AI coding agents who will build, test, and extend this work.
Branch: `mmn_dev` (uncommitted working-tree changes at time of writing). A copy of the full diff is in `docs/handoff/features.patch`.

## Read this first

- **None of this code has been compiled or run.** It was written on a Windows machine with no Xcode. Every claim below is from reading the code, not running it.
- **Step 1 for whoever has a Mac:** open `Prism.xcodeproj`, build the `Prism` scheme (iOS 17 simulator), fix any compile errors, then run `PrismTests`. No new source files were added, so `xcodegen generate` is not required (running it is harmless).
- **Likely first-compile trouble spots** (fix these first, they are the usual suspects):
  1. `MoneyStoryView.swift`: `ImageRenderer` / `renderShareImage` (main-actor isolation, `await` on a `@MainActor` helper).
  2. `AppEnvironment.swift` / `NotificationScheduler.swift`: the protocol `NotificationScheduling` gained four methods; the real scheduler and `MockNotificationScheduler` both implement them.
  3. Memberwise initializers: `SavedItem`, `PrismGoal`, `NotificationPreferences`, `MoneyStorySnapshot` gained trailing properties with default values so existing call sites still compile. If a call site breaks, add the argument or a default.
  4. SwiftData: new optional properties on `SDSavedItem` and `SDGoal` (lightweight migration). If the simulator crashes on launch after upgrading an old install, delete the app and reinstall.
- Product guardrails still apply to every change (see the last section).

## What was added (6 features + 2 fixes)

| # | Feature | User-visible behavior | Main files |
|---|---|---|---|
| 2 | **Goal completion moment** | Completing a goal shows a celebration and asks "Was it worth it?" (Worth it / Mixed / Not really) plus an optional note. Skippable. | `GoalDetailView.swift` (`GoalCompletionView`), `GoalPlanningService.swift`, `GoalModels.swift` |
| 3 | **Redirect nudge** | After letting go of a save while a goal is active, a sheet offers to note it as progress. Optional amount is only what the user actually moved. | `ReviewViews.swift` (`RedirectNudgeView`, `RedirectPrompt`) |
| 4 | **Weekly recap** | Opt-in local notification, Sundays 18:00: "You paused N impulses this week." Count only. | `MoneyStoryService.swift` (`RecapPlanner`), `AppEnvironment.swift` (`refreshWeeklyRecap`), `NotificationScheduler.swift`, `SettingsView.swift` |
| 5 | **Goal from a collection** | "Make a goal" button on a collection. Pre-fills name, lets the user pick items, target = sum of their own estimates, items saved as plan components and linked. **Experimental.** | `CollectionsView.swift`, `GoalSetupFlowView.swift`, `AppRouter.swift` (`GoalFromCollectionLoader`), `GoalDetailView.swift` (components list) |
| 6 | **Regret check-in** | 30 days after a confirmed purchase (1 minute with the DEBUG demo switch), a "Check-in" card in the Review tab asks Glad / Neutral / Regret. Money Story shows "Glad you bought X of Y". | `DecisionService.swift` (`RegretCheckIn`), `ReviewViews.swift`, `MoneyStoryService.swift`, `MoneyStoryView.swift` |
| 7 | **Shareable Money Story card** | "Share my story" button on the Story tab shares an image with counts only (no titles, no prices). | `MoneyStoryView.swift` (`MoneyStoryShareCard`, `ShareCardData`) |
| fix | **Low-cost goals can now be completed**; goals can be paused, resumed, abandoned | New buttons on the goal detail screen. Previously completion only happened when saved amount reached a target, so goals with no target could never finish. | `GoalDetailView.swift`, `GoalPlanningService.swift` |
| fix | **Paused/finished goals are reachable** | New "Paused & finished" section on Home. Without it a paused goal could not be resumed. | `HomeView.swift` |

Note on an earlier assumption: the "only one Primary goal" rule **is** enforced (`LocalStore.upsert` demotes any other Primary to Active), so no change was needed there.

## Data model changes (all optional / defaulted, so old data still loads)

- `PrismGoal`: `outcomeRating: GoalOutcomeRating?`, `outcomeNote: String?`. Mirrored in `SDGoal` as `outcomeRatingRaw`, `outcomeNote`.
- `SavedItem`: `regretCheckInAt: Date?`, `regretAnswer: RegretAnswer?`, `regretAnsweredAt: Date?`. Mirrored in `SDSavedItem` as `regretCheckInAt`, `regretAnswerRaw`, `regretAnsweredAt`.
- `NotificationPreferences`: `weeklyRecapEnabled: Bool?`, `regretCheckInsEnabled: Bool?` (optional on purpose: this struct is stored as JSON inside the profile, and a non-optional new field would fail to decode old data and silently reset preferences). Read them through `isWeeklyRecapOn` / `isRegretCheckInOn`.
- `MoneyStorySnapshot`: `regretGlad`, `regretNeutral`, `regretRegret` (default 0), computed `regretAnswered`.
- New enums in `Enums.swift`: `GoalOutcomeRating`, `RegretAnswer`.
- New analytics events (`Analytics.swift`): `goal_completed`, `goal_outcome_recorded`, `regret_check_in_answered`, `weekly_recap_enabled`, `redirect_nudge_accepted`, `goal_from_collection_created`. None carry titles, prices, or notes.
- `AppRouter.Sheet` gained `.goalFromCollection(UUID)` (declared in `AppEnvironment.swift`).
- Protocol `NotificationScheduling` gained: `scheduleRegretCheckIn`, `cancelRegretCheckIn`, `scheduleWeeklyRecap`, `cancelWeeklyRecap`.

## How each feature works (for agents editing it)

**Goal lifecycle (2 + fixes).** Pure functions on `GoalPlanningService`: `markComplete`, `pause`, `resume`, `abandon`, `recordOutcome`, `focusGoal(in:)`. `GoalDetailView.load()` auto-presents `GoalCompletionView` once per screen open when a goal is `.completed` with no `outcomeRating`; a "Reflect on this goal" button covers the skipped case. Money Story shows "Goals completed" and "Goals that felt worth it".

**Redirect nudge (3).** `ReviewDeckView.letGo` calls `focusGoal(in:)` (primary first, then first active; skips paused/completed/abandoned). If found, `RedirectNudgeView` appears. Accepting always writes a *behavioral* contribution ("Let go of a lower-priority save"). A *financial* contribution is written only if the user types an amount. Estimates are never used as amounts.

**Regret check-in (6).** `DecisionService.applyBuy` sets `regretCheckInAt = now + RegretCheckIn.interval` on a confirmed purchase; `undo` clears it. `RegretCheckIn.due(items:)` drives the Review-tab card (works without notifications). If the user enabled "Purchase check-ins" in Settings, `BuyConfirmationView.confirm` also schedules a generic local notification (`regret.<itemID>`), cancelled on answer or undo. DEBUG builds have a Settings toggle that makes the interval 60 seconds (UserDefaults key `prism.debug.shortRegret`).

**Weekly recap (4).** `AppEnvironment.refreshWeeklyRecap()` runs on launch (`RootView.task`) and when Settings saves. It counts items created in the last 7 days (`RecapPlanner.pausedCount`), and schedules one notification (`recap.weekly`) for the next Sunday 18:00 (`RecapPlanner.nextRecapDate`). It cancels when the toggle is off or local data is wiped.

**Share card (7).** `MoneyStoryShareCard` (360x450 pt, rendered at 3x via `ImageRenderer`) is built from `ShareCardData` (period, paused, let go, purchased, goals completed, primary goal percent). It is regenerated in `MoneyStoryView.reload()` and shared with `ShareLink`. It deliberately uses plain shapes, because materials/blur do not render reliably in `ImageRenderer`.

**Goal from collection (5).** `CollectionsView` shows "Make a goal" when a collection has open saves (status considering or ready-to-review). `GoalFromCollectionLoader` loads the collection and items, then presents `GoalSetupFlowView(sourceCollection:collectionItems:)`. Step 1 shows a toggle per item; the target is auto-set to the sum of included estimates and can be edited on the Target step. On save, each included item becomes a `GoalComponent` and a `GoalAspirationLink` (role `.essential`).

## Manual test script (needs a Mac, about 10 minutes)

1. Onboarding, "Explore locally", create a collection ("Japan"), save two items in it. In Reflection, give each an estimated price.
2. **Goal from collection:** Collections, "Make a goal". Confirm both items are toggled on, target = sum of estimates. Finish setup. Open the goal: "Plan components" lists both, labeled estimated.
3. **Redirect nudge:** Save a third item, wait for review (or set the cooling-off to a short period), Review, Start review, Let go. The redirect sheet appears. Tap "Note it as progress" with a blank amount: goal detail shows a behavioral entry. Repeat and enter an amount: saved amount increases.
4. **Regret check-in:** In Settings (DEBUG build) turn on "Demo: check-in 1 minute after a purchase". Review, Buy, confirm with a price. Wait one minute, open Review: a "Check-in" card appears. Answer Glad. Story tab shows "Glad you bought 1 of 1".
5. **Goal completion:** On a goal, "Mark complete" (also test a Low / no cost goal). The completion sheet appears; pick "Worth it", add a note, save. Goal detail shows "How it turned out". Story tab shows "Goals completed".
6. **Pause and resume:** Pause a goal, confirm it moves to "Paused & finished" on Home, open it, Resume.
7. **Share card:** Story tab, "Share my story". Inspect the preview image: counts and percent only, no titles or prices.
8. **Weekly recap:** Settings, turn on "Weekly recap", Save nudges, allow notifications. Verify a pending notification (Xcode, Debug, or `UNUserNotificationCenter.getPendingNotificationRequests`) with id `recap.weekly` for the next Sunday 18:00.

## Unit tests added (`PrismTests/PrismCoreTests.swift`)

`RegretCheckInTests` (schedule, no schedule when not confirmed, undo clears, due filter, Money Story counts, mock scheduler), `GoalLifecycleTests` (low-cost completion, focus goal rules, outcome note trimming, pause/resume), `RecapPlannerTests` (Sunday 18:00, 7-day window, notification body). Test helpers `makeTestItem` and `makeTestGoal` are file-private at the bottom of the file.

## Known limitations and decisions to revisit

- **Weekly recap count can be stale:** it is computed when the app is opened, not on Sunday. A better version would refresh from a background task.
- **Regret notifications** need both the Settings toggle and OS notification permission; the in-app Review card does not.
- **Undoing a let-go** does not remove the progress note or amount added through the redirect nudge.
- **Component costs** are summed as entered, without currency conversion. Items with no estimate count as zero and are labeled "No estimate yet".
- **Completion prompt** appears once per screen open; skipping keeps the "Reflect on this goal" button.
- **Goal from collection** is experimental: no editing of components after creation, and no automatic re-sum when estimates change (the vision doc lists automatic plan cost as deferred).
- **DEBUG-only** demo switch for the regret interval is compiled out of release builds.
- Existing gaps not touched here: Share Extension `consumePending()` is still never called; `SignInView.swift` is unused; the app icon has no images; Supabase and Sign in with Apple are still stubs.

## Product guardrails (do not break)

No bank links or affordability engine. Every money figure is labeled confirmed or estimated. A let-go estimate is never called "money saved" and is never auto-added to a goal. Notifications and share images never contain item titles, goal titles, or prices. Analytics events carry no user content.
