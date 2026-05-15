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
  alert_matches boolean not null default true,
  alert_deadlines boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_profiles
add column if not exists alert_matches boolean not null default true;

alter table public.user_profiles
add column if not exists alert_deadlines boolean not null default true;

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

create table if not exists public.opportunities (
  id text primary key,
  title text not null,
  agency text not null,
  state text not null,
  naics text not null,
  certification text not null,
  set_aside text not null,
  deadline text not null,
  deadline_date date,
  days_left integer not null default 0,
  estimated_value text,
  tags text[] not null default '{}'::text[],
  summary text not null,
  source_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.waitlist_submissions enable row level security;
alter table public.beta_feedback enable row level security;
alter table public.readiness_results enable row level security;
alter table public.user_profiles enable row level security;
alter table public.saved_opportunities enable row level security;
alter table public.opportunities enable row level security;

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

drop policy if exists "Signed-in users can read active opportunities" on public.opportunities;
create policy "Signed-in users can read active opportunities"
on public.opportunities
for select
to authenticated
using (is_active = true);

drop policy if exists "Signed-in users can add beta opportunities" on public.opportunities;
create policy "Signed-in users can add beta opportunities"
on public.opportunities
for insert
to authenticated
with check (true);

drop policy if exists "Signed-in users can update beta opportunities" on public.opportunities;
create policy "Signed-in users can update beta opportunities"
on public.opportunities
for update
to authenticated
using (true)
with check (true);

insert into public.opportunities (
  id, title, agency, state, naics, certification, set_aside, deadline, deadline_date,
  days_left, estimated_value, tags, summary, source_url, is_active
) values
  (
    'va-it-support',
    'IT Support and Managed Services',
    'Department of Veterans Affairs',
    'VA',
    '541512',
    'WOSB',
    'Women-Owned Small Business',
    'May 24, 2026',
    '2026-05-24',
    11,
    '$480K',
    array['WOSB', 'Federal', 'Due soon'],
    'Tier 1 help desk, device management, and cloud support for a regional VA office.',
    'https://sam.gov',
    true
  ),
  (
    'richmond-outreach',
    'Community Outreach and Program Coordination',
    'City of Richmond',
    'VA',
    '541611',
    'SWaM',
    'Small Business',
    'May 29, 2026',
    '2026-05-29',
    16,
    '$125K',
    array['SWaM', 'Local', 'Services'],
    'Program support, scheduling, stakeholder engagement, and reporting for community services.',
    'https://www.rva.gov/procurement-services',
    true
  ),
  (
    'gsa-supplies',
    'Office Supplies and Facilities Management',
    'General Services Administration',
    'DC',
    '561210',
    'EDWOSB',
    'Economically Disadvantaged WOSB',
    'June 4, 2026',
    '2026-06-04',
    22,
    '$340K',
    array['EDWOSB', 'Federal', 'Recurring'],
    'Multi-site supplies, light facilities support, and vendor coordination.',
    'https://sam.gov',
    true
  ),
  (
    'vdot-data',
    'Data Entry and Records Digitization',
    'Virginia Department of Transportation',
    'VA',
    '518210',
    'DBE',
    'Disadvantaged Business Enterprise',
    'May 20, 2026',
    '2026-05-20',
    7,
    '$210K',
    array['DBE', 'State', 'Due soon'],
    'Digitization of records, document QA, and secure file indexing for district offices.',
    'https://www.virginiadot.org/business/',
    true
  ),
  (
    'md-training',
    'Workforce Training Curriculum Support',
    'Maryland Department of Labor',
    'MD',
    '611430',
    'MBE',
    'Minority Business Enterprise',
    'June 12, 2026',
    '2026-06-12',
    30,
    '$275K',
    array['MBE', 'State', 'Training'],
    'Curriculum updates, facilitation support, and reporting for workforce readiness programs.',
    'https://procurement.maryland.gov',
    true
  ),
  (
    'nc-cyber',
    'Cybersecurity Readiness Assessment',
    'North Carolina Office of Technology',
    'NC',
    '541519',
    'WOSB',
    'Women-Owned Small Business',
    'June 20, 2026',
    '2026-06-20',
    38,
    '$390K',
    array['WOSB', 'Cyber', 'State'],
    'Assessment, gap analysis, and remediation roadmap for public sector systems.',
    'https://www.nc.gov/working/doing-business-nc',
    true
  )
on conflict (id) do update set
  title = excluded.title,
  agency = excluded.agency,
  state = excluded.state,
  naics = excluded.naics,
  certification = excluded.certification,
  set_aside = excluded.set_aside,
  deadline = excluded.deadline,
  deadline_date = excluded.deadline_date,
  days_left = excluded.days_left,
  estimated_value = excluded.estimated_value,
  tags = excluded.tags,
  summary = excluded.summary,
  source_url = excluded.source_url,
  is_active = excluded.is_active,
  updated_at = now();
