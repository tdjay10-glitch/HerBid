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

alter table public.waitlist_submissions enable row level security;
alter table public.beta_feedback enable row level security;
alter table public.readiness_results enable row level security;

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
