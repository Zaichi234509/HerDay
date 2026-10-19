# 🗄️ HerDay — Supabase Setup Guide

HerDay's backend is **Supabase** (Postgres + Auth + Storage). This guide covers:

1. ✅ What's already set up for you (nothing to do!)
2. 👀 How to look at / manage the data
3. 💌 How YOU can leave her messages & memories from the dashboard
4. 🔁 How to set up a brand-new Supabase project from scratch (if you ever want your own)
5. 🔑 Keys explained — what's safe to share and what isn't

---

## 1. ✅ Already set up (done for you)

A dedicated Supabase project was created and fully configured:

| Item | Value |
|---|---|
| Project name | `herday` |
| Project ref | `qewzyquyeqgpixliqfyz` |
| Region | `ap-southeast-1` (Singapore — closest to PH) |
| Project URL | `https://qewzyquyeqgpixliqfyz.supabase.co` |
| Dashboard | https://supabase.com/dashboard/project/qewzyquyeqgpixliqfyz |
| Database | 16 tables, **Row Level Security ON for all** (each user only sees their own rows) |
| Auth | Email/password, **auto-confirm ON** (sign-up works instantly, no email verification wait) |
| Storage | Public bucket `memories` for photo uploads |
| App connection | Already baked into `lib/core/config.dart` |

**So to just use the app: do nothing here. Run the Flutter app and create her account.** 🎉

Tables: `profiles, tasks, events, journal_entries, moods, transactions, budgets, goals, shopping_items, habits, habit_logs, meals, memories, messages, reminders, vault_notes` — plus a trigger that auto-creates a profile row the moment someone signs up.

---

## 2. 👀 Viewing & managing data

Open the dashboard → https://supabase.com/dashboard/project/qewzyquyeqgpixliqfyz

- **Table Editor** — browse/edit every table (her tasks, journal, expenses…)
- **Authentication → Users** — see who has signed up (you'll need her `user_id` below)
- **Storage → memories** — uploaded photos
- **SQL Editor** — run queries (the migrations in `supabase/migrations/` live here too)
- **Project Settings → API** — the Project URL + API keys (see §5)

> ⚠️ Anyone with access to this dashboard can see everything — treat the Supabase login like a master key.

---

## 3. 💌 Leaving her messages & memories yourself (the sweet part)

You don't need the app to send her love notes — you can insert them straight into the database, and they'll appear in her app (dashboard message card + **Us 💕** tab).

**Step 1 — find her `user_id`:** Dashboard → **Authentication → Users** → copy her user's UUID.

**Step 2 — leave a message:** **Table Editor → `messages` → Insert row**

| Column | What to put |
|---|---|
| `user_id` | Her UUID from step 1 |
| `title` | e.g. `💌 A message for you` |
| `body` | e.g. `Don't forget to eat today. I'm proud of you ❤️` |
| `is_read` | `false` |

**Step 3 — add a memory:** **Table Editor → `memories` → Insert row** with `user_id`, `title` (e.g. `First Date ❤️`), `description`, `memory_date`, and optionally `image_url` (any photo link — or upload a photo in **Storage → memories** and use its public URL).

She'll see it next time she opens the app. 🥹

---

## 4. 🔁 Setting up a NEW Supabase project from scratch

Only needed if you want a fresh backend (e.g. your own Supabase account). Takes ~5 minutes:

**Step 1 — Create the project**
1. Go to https://supabase.com → sign in → **New project**
2. Name: `herday`, pick a strong database password (save it!), region: **Southeast Asia (Singapore)**
3. Wait ~2 minutes for it to provision

**Step 2 — Create the database schema**
1. Dashboard → **SQL Editor → New query**
2. Paste the full contents of [`supabase/migrations/20261019000000_herday_schema.sql`](supabase/migrations/20261019000000_herday_schema.sql) → **Run**
3. New query again → paste [`supabase/migrations/20261020000000_herday_phase4.sql`](supabase/migrations/20261020000000_herday_phase4.sql) → **Run**

That creates all tables, RLS policies, the sign-up trigger, and the photo bucket.

**Step 3 — Make sign-up instant**
Dashboard → **Authentication → Providers → Email** → turn **"Confirm email" OFF** (this is what `mailer_autoconfirm` does — HerDay is a personal app, so skipping email confirmation keeps sign-up friction-free). Save.

**Step 4 — Point the app at your project**
Dashboard → **Project Settings → API** → copy the **Project URL** and the **anon / publishable key**. Then either:

- **Option A (edit code):** paste them into `lib/core/config.dart` (`supabaseUrl` / `supabaseAnonKey`), or
- **Option B (no code change):**
  ```bash
  flutter run \
    --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
  ```

**Step 5 — Optional: Supabase CLI instead of copy-paste**
```bash
npm install -g supabase   # or see supabase.com/docs/guides/cli
supabase link --project-ref YOUR_PROJECT_REF
supabase db push          # applies everything in supabase/migrations/
```

---

## 5. 🔑 Keys explained (important!)

| Key | Safe in the app? | Why |
|---|---|---|
| **Project URL** | ✅ Yes | It's just the address |
| **anon / publishable key** | ✅ Yes | This is what `config.dart` contains. It's public **by design** — Row Level Security is what actually protects the data: a signed-in user can only read/write rows where `user_id` = their own account ID |
| **service_role / secret key** (`sb_secret_…`) | ❌ **NEVER** | Bypasses ALL security. Never put it in the app, in GitHub, or in screenshots. The app never needs it |
| **Database password** | ❌ Keep private | Only for direct database/CLI access. Reset it in Dashboard → Project Settings → Database if it ever leaks |

How the privacy actually works, in one picture:

```text
Her account ──login──► Supabase Auth ──► her user_id (UUID)
                                              │
Every request carries her token ──► RLS checks auth.uid() = user_id
                                              │
                              ✅ her rows only — nobody else's, ever
```

---

## 💡 Tips & troubleshooting

- **First account:** the first account created in the app is hers — after that, you can disable public sign-ups (Dashboard → Authentication → Settings → "Allow new users to sign up" OFF) so strangers can't register, since HerDay is really just for her. Existing users keep working.
- **"No connection" in the app:** check internet; the free Supabase plan also *pauses* projects after ~1 week of inactivity — just open the dashboard and click **Restore/Resume** if that ever happens.
- **Photos not uploading:** confirm the `memories` bucket exists (Storage) — re-run migration file #2 if not.
- **Want a fresh start for a table?** Table Editor → select rows → Delete. Her account and profile stay intact.

Questions or want changes (disable sign-ups, custom email templates, your own project)? Just ask 💕
