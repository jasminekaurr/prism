# Privacy

## Principles

Saved items, reflections, and purchase decisions are sensitive personal information.

## On-device MVP

In the local ship, data remains on the device (SwiftData + Documents media). Export produces JSON you control. Delete local data wipes the store and media folder.

## Collection

Prism does **not** collect contacts, location, banking data, or browsing history.

## Analytics (optional)

Events only: `onboarding_completed`, `item_saved`, `review_completed`, `item_purchased_confirmed`, `item_let_go`, `notification_enabled`, `goal_created`, `goal_contribution_added`, `goal_completed`, `goal_outcome_recorded`, `regret_check_in_answered`, `weekly_recap_enabled`, `redirect_nudge_accepted`, `goal_from_collection_created`.

Notifications (weekly recap, purchase check-in, cooling-off) never include item titles, goal titles, or prices. The weekly recap shows only a count. Shared Money Story images contain counts and a goal percentage only.

Never: item title, reflection, URL, price, per-item feelings, media, merchant, PII.

## Retention

Local data retained until you delete it or uninstall. Future cloud retention will be documented when sync ships.

## Account deletion

Local wipe available in Settings. Cloud account deletion will require Sign in with Apple + Supabase (deferred).

## Placeholder policy

This file is the in-repo privacy policy placeholder for TestFlight review. Replace with a hosted URL before App Store submission.
