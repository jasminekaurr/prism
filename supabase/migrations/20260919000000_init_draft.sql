-- Prism draft schema (not applied in local MVP).
-- Enable RLS on every table. Never use service-role key in the client.

create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  onboarding_completed boolean not null default false
);

create table if not exists collections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  description text,
  cover_media_id uuid,
  color_theme text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists saved_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  collection_id uuid references collections (id) on delete set null,
  title text not null,
  notes text,
  reflection text,
  source_url text,
  source_domain text,
  merchant_name text,
  intent text not null,
  cost_significance text,
  priority text,
  estimated_price numeric,
  estimated_currency_code text,
  confirmed_purchase_price numeric,
  confirmed_purchase_currency_code text,
  status text not null,
  primary_media_id uuid,
  notifications_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  review_at timestamptz,
  decided_at timestamptz,
  archived_at timestamptz,
  deleted_at timestamptz
);

create table if not exists decision_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  saved_item_id uuid not null references saved_items (id) on delete cascade,
  decision text not null,
  previous_status text not null,
  new_status text not null,
  confirmed_price numeric,
  currency_code text,
  note text,
  created_at timestamptz not null default now(),
  undone_by_event_id uuid
);

alter table profiles enable row level security;
alter table collections enable row level security;
alter table saved_items enable row level security;
alter table decision_events enable row level security;

create policy profiles_own on profiles for all using (id = auth.uid()) with check (id = auth.uid());
create policy collections_own on collections for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy saved_items_own on saved_items for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy decision_events_own on decision_events for all using (user_id = auth.uid()) with check (user_id = auth.uid());
