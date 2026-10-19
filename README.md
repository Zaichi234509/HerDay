# 🌸 HerDay

**HerDay** is a personal everyday companion app built with **Flutter + Dart + Supabase** —
created as a real-life personal app for one special person. 💕

> Calendar + Tasks + Journal + Mood + Budget + Self-Care + Goals + Memories,
> wrapped in a cute, personalized UI instead of a corporate productivity app.

---

## ✨ Features

| Area | What it does |
|---|---|
| 🏠 **Home Dashboard** | Greeting by name, today's date, mood picker + this-week mood strip, today's tasks, today's spending vs daily budget, daily-goal progress, goal spotlight, a daily love quote / latest message, self-care snapshot, quick actions |
| ✅ **Tasks** | Create/edit/delete, categories (Home/School/Work/Shopping/Personal/Self-care), priority, due dates, daily-recurring tasks that roll over to tomorrow, Today / Upcoming / All / Done filters, swipe-to-delete |
| 📅 **Calendar** | Month grid with event/task dots, day detail list, add events with time & category |
| 📝 **Journal** | Write entries with mood + #tags, search, favorites, edit past entries (journaling also logs the day's mood) |
| 😊 **Mood Tracker** | Daily mood (😭 😔 😐 🙂 😍) from Home or Journal, weekly mood strip |
| 💰 **Budget** | Income/expense logging, monthly budget, remaining balance, per-category breakdown bars, full history, month navigation |
| 🛒 **Shopping List** | Items with qty + estimated price, estimated total for what's left, clear-bought |
| 🎯 **Goals** | Targets with units (₱, books, %), progress slider + quick +1/+10, deadlines |
| 💧 **Self-Care** | Habit tracker (water, skincare, vitamins, exercise, reading…) with daily counts — 5 starter habits are seeded on sign-up |
| 🍱 **Meals** | Breakfast/Lunch/Dinner/Snack logging per day, optional calories |
| 💕 **Us** | Days-together counter from your anniversary, love messages, photo memories |
| 🔒 **Private Vault** | Private notes protected by Supabase Row Level Security |
| 👤 **Me / Profile** | Edit name, bio, partner name, anniversary, daily budget; stats (tasks done, journal count, goals); shortcuts to everything |
| 🎨 **Themes** | 🌸 Sakura · 🌙 Midnight · 🍓 Strawberry · 🌊 Ocean · 🌿 Nature · 🖤 Minimal — saved to her profile and synced |

**Navigation:** `Home · Tasks · Calendar · 💕 Us · Me`

---

## 🔌 Supabase backend (already connected)

This repo is wired to a **live Supabase project** created for HerDay:

- **Project:** `herday` (ref `qewzyquyeqgpixliqfyz`, region `ap-southeast-1` / Singapore)
- **URL:** `https://qewzyquyeqgpixliqfyz.supabase.co`
- **Connection:** `lib/core/config.dart` (anon key is safe to ship — RLS protects all data)
- **Schema:** 15 tables (`profiles, tasks, events, journal_entries, moods, transactions, budgets, goals, shopping_items, habits, habit_logs, meals, memories, messages, vault_notes`), all with **Row Level Security** (`auth.uid() = user_id`), plus a trigger that auto-creates a profile on sign-up. Email auto-confirm is ON, so sign-up works instantly.
- **Recreate it anywhere:** run [`supabase/migrations/20261019000000_herday_schema.sql`](supabase/migrations/20261019000000_herday_schema.sql) in the Supabase SQL editor, or `supabase db push`.

> ⚠️ Never put the `service_role` / secret key in the app. Only the anon/publishable key belongs in client code.

Override the backend at any time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

---

## 🚀 Run it

**Requirements:** Flutter 3.29+ (latest stable recommended) — [install Flutter](https://docs.flutter.dev/get-started/install)

```bash
# 1. Get dependencies
flutter pub get

# 2. Run on a connected Android phone / emulator
flutter run

# …or in Chrome (fastest way to try it)
flutter run -d chrome

# …or release build for Android
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk — send this APK to her phone 💕
```

This repo ships with hand-written `android/` and `web/` scaffolding, so the commands above work immediately.

**iOS (on a Mac):** generate the iOS shell once, then run as usual:

```bash
flutter create . --platforms=ios --project-name herday
flutter run
```

(If `pubspec.yaml` or `lib/` are ever touched by that command, restore them with `git checkout -- pubspec.yaml lib`.)

**Tests:**

```bash
flutter test
flutter analyze
```

---

## 🗂️ Project structure

```text
lib/
├── main.dart                  # Supabase init + runApp
├── app.dart                   # MaterialApp, theme switching, auth gate
├── core/
│   ├── config.dart            # Supabase URL + anon key (dart-define overridable)
│   ├── theme.dart             # 6 cute themes (Sakura default)
│   └── format.dart            # ₱ peso, dates, greetings
├── models/models.dart         # Profile, TaskItem, Goal, Habit, …
├── data/herday_db.dart        # All Supabase queries (single data layer)
├── widgets/common.dart        # Shared UI: cards, progress, empty states
└── screens/
    ├── auth_screen.dart       # Login / sign-up
    ├── shell_screen.dart      # Bottom nav: Home·Tasks·Calendar·Us·Me
    ├── dashboard_screen.dart  # 🏠 Today's overview
    ├── tasks_screen.dart      # ✅ Tasks
    ├── calendar_screen.dart   # 📅 Calendar
    ├── journal_screen.dart    # 📝 Journal + mood editor
    ├── budget_screen.dart     # 💰 Budget & expenses
    ├── shopping_screen.dart   # 🛒 Shopping list
    ├── goals_screen.dart      # 🎯 Goals
    ├── habits_screen.dart     # 💧 Self-care tracker
    ├── meals_screen.dart      # 🍱 Meal log
    ├── us_screen.dart         # 💕 Days together, messages, memories
    ├── vault_screen.dart      # 🔒 Private vault
    └── me_screen.dart         # 👤 Profile, themes, settings
supabase/migrations/           # Database schema (already applied live)
```

---

## 🗺️ Roadmap ideas (future)

- 🤖 Upgrade "Ask HerDay" to a full LLM via a Supabase Edge Function (the chat UI already isolates the answer logic)
- 🔐 Signed/private photo URLs instead of a public bucket
- 📍 Location-based reminders, shared couple accounts (two users, one shared "Us" space)
- 🌐 Deploy the web build (Flutter web + Vercel) as an installable PWA

---

Made with ❤️ using Flutter + Supabase.
