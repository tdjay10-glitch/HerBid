# HerBid Supabase Setup

This setup keeps HerBid data collection away from personal Gmail and sends public form submissions into a HerBid-owned Supabase project.

## 1. Create the Supabase project

Create a Supabase project under a HerBid-owned account. Do not use a personal email if you want to keep your identity separate.

## 2. Create the tables

Open the Supabase SQL editor and run:

```sql
-- See supabase/schema.sql in this repo.
```

The schema creates:

- `waitlist_submissions`
- `beta_feedback`
- `readiness_results`
- `user_profiles`
- `saved_opportunities`

Row Level Security is enabled. Anonymous visitors can insert public capture rows, but no public read policy is created. Signed-in users can read and update only their own profile and saved opportunities.

## 3. Add the public project credentials

Open:

```text
assets/supabase-client.js
```

Replace:

```js
const SUPABASE_URL = "https://YOUR_PROJECT_ID.supabase.co";
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
```

with your Supabase Project URL and public anon key.

Important: never paste the Supabase service role key into the website. The anon key is designed to be public when Row Level Security is configured.

## 4. What is connected

The site now attempts to send:

- Homepage waitlist submissions to `waitlist_submissions`
- Dashboard beta feedback to `beta_feedback`
- Readiness quiz results to `readiness_results`
- Dashboard signup/login through Supabase Auth
- User profile details to `user_profiles`
- Saved bid selections to `saved_opportunities`

If Supabase is not configured yet, the forms show a preview success message and save locally in the browser.

## 5. Auth settings

In Supabase, open Authentication settings before beta testing:

- Confirm email/password signups are enabled.
- Decide whether new users must confirm email before login.
- Add your production site URL and local preview URL to the allowed redirect URLs if you use email confirmation links.
