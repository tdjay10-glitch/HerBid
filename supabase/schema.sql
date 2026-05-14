-- HerBid public beta capture schema
-- Run this in the Supabase SQL editor for your HerBid project.
-- Keep your service role key private. The website should only use the public anon key.

create table if not exists public.waitlist_submissions (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  source text not null default 'homepage',
  page_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.beta_feedback (
  id uuid primary key default gen_random_uuid(),
  tester_name text,
  feedback_type text not null,
  rating text not null,
  notes text not null,
  page_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.readiness_results (
  id uuid primary key default gen_random_uuid(),
  score integer not null check (score >= 0 and score <= 100),
  level text not null,
  selected_items jsonb not null default '[]'::jsonb,
  recommendations jsonb not null default '[]'::jsonb,
  page_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  business_name text,
  certification_type text,
  state text,
  naics_interests text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.saved_opportunities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  opportunity_id text not null,
  title text not null,
  agency text not null,
  deadline text not null,
  naics text not null,
  set_aside text not null,
  source_url text,
  created_at timestamptz not null default now(),
  unique (user_id, opportunity_id)
);

alter table public.waitlist_submissions enable row level security;
alter table public.beta_feedback enable row level security;
alter table public.readiness_results enable row level security;
alter table public.user_profiles enable row level security;
alter table public.saved_opportunities enable row level security;

drop policy if exists "Allow public waitlist inserts" on public.waitlist_submissions;
create policy "Allow public waitlist inserts"
on public.waitlist_submissions
for insert
to anon
with check (true);

drop policy if exists "Allow public beta feedback inserts" on public.beta_feedback;
create policy "Allow public beta feedback inserts"
on public.beta_feedback
for insert
to anon
with check (true);

drop policy if exists "Allow public readiness result inserts" on public.readiness_results;
create policy "Allow public readiness result inserts"
on public.readiness_results
for insert
to anon
with check (true);

drop policy if exists "Users can read their own profile" on public.user_profiles;
create policy "Users can read their own profile"
on public.user_profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Users can insert their own profile" on public.user_profiles;
create policy "Users can insert their own profile"
on public.user_profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.user_profiles;
create policy "Users can update their own profile"
on public.user_profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can read their saved opportunities" on public.saved_opportunities;
create policy "Users can read their saved opportunities"
on public.saved_opportunities
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can save their own opportunities" on public.saved_opportunities;
create policy "Users can save their own opportunities"
on public.saved_opportunities
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their saved opportunities" on public.saved_opportunities;
create policy "Users can delete their saved opportunities"
on public.saved_opportunities
for delete
to authenticated
using (auth.uid() = user_id);
