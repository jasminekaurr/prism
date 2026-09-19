# Supabase Setup (deferred)

The local MVP does **not** require Supabase. Use this when enabling cloud sync.

## Safe client config

Provide only:

- Project URL
- Publishable / anon key

Never put the **service-role** key in the iOS app, git, build settings, logs, or docs examples.

Copy [`.env.example`](../.env.example) to a gitignored `.env` / `Secrets.local.xcconfig`.

## Suggested tables

`profiles`, `collections`, `saved_items`, `media_assets`, `tags`, `saved_item_tags`, `feelings`, `saved_item_feelings`, `review_events`, `decision_events`, `user_settings`

Every user-owned row includes `user_id` referencing `auth.uid()`.

## RLS (required)

Enable RLS on every user-data table:

- SELECT / INSERT / UPDATE / DELETE only where `user_id = auth.uid()`
- Child rows must not attach to parents owned by another user
- Storage paths user-scoped; private buckets; short-lived signed URLs

See draft SQL under [`supabase/migrations/`](../supabase/migrations/).

## Sign in with Apple

Configure Apple provider in Supabase Auth, nonce verification on the backend, redirect URLs, and Keychain session persistence in the iOS client.

## Conflict policy

Latest scalar edit wins; tags/feelings merge by id; decision events append-only; never overwrite newer local reflections with stale cloud data.
