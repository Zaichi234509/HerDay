-- HerDay schema — already applied to the live "herday" Supabase project
-- (ref: qewzyquyeqgpixliqfyz) via migration "herday_schema".
-- Kept here so the backend can be recreated on any Supabase project:
--   supabase link --project-ref <ref> && supabase db push
-- Every table is owned by a user (user_id / id = auth.users.id) and is
-- protected by Row Level Security: a signed-in user can only touch their
-- own rows.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  bio text not null default '',
  partner_name text not null default '',
  anniversary date,
  theme text not null default 'sakura',
  daily_budget numeric not null default 500,
  created_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  notes text not null default '',
  category text not null default 'Personal',
  priority text not null default 'Normal',
  due_date date not null default current_date,
  is_done boolean not null default false,
  is_recurring boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  notes text not null default '',
  event_date date not null default current_date,
  start_time text not null default '',
  category text not null default 'Personal',
  created_at timestamptz not null default now()
);

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  content text not null default '',
  mood text not null default '🙂',
  tags text not null default '',
  is_favorite boolean not null default false,
  entry_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.moods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mood text not null default '🙂',
  note text not null default '',
  logged_date date not null default current_date,
  created_at timestamptz not null default now(),
  unique (user_id, logged_date)
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  category text not null default 'Others',
  amount numeric not null default 0,
  type text not null default 'expense' check (type in ('income','expense')),
  txn_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  month text not null,
  amount numeric not null default 0,
  created_at timestamptz not null default now(),
  unique (user_id, month)
);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  target numeric not null default 1,
  current_value numeric not null default 0,
  unit text not null default '',
  deadline date,
  created_at timestamptz not null default now()
);

create table if not exists public.shopping_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  quantity text not null default '1',
  estimated_price numeric not null default 0,
  category text not null default 'Others',
  is_bought boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  icon text not null default '🌸',
  goal_per_day int not null default 1,
  unit text not null default 'times',
  created_at timestamptz not null default now()
);

create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id uuid not null references public.habits(id) on delete cascade,
  log_date date not null default current_date,
  count int not null default 0,
  created_at timestamptz not null default now(),
  unique (habit_id, log_date)
);

create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_type text not null default 'Lunch',
  description text not null default '',
  calories int,
  meal_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  image_url text not null default '',
  memory_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '💌 A message for you',
  body text not null default '',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.vault_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  content text not null default '',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.events enable row level security;
alter table public.journal_entries enable row level security;
alter table public.moods enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.goals enable row level security;
alter table public.shopping_items enable row level security;
alter table public.habits enable row level security;
alter table public.habit_logs enable row level security;
alter table public.meals enable row level security;
alter table public.memories enable row level security;
alter table public.messages enable row level security;
alter table public.vault_notes enable row level security;

create policy profiles_all on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
create policy tasks_all on public.tasks for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy events_all on public.events for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy journal_all on public.journal_entries for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy moods_all on public.moods for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy transactions_all on public.transactions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy budgets_all on public.budgets for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy goals_all on public.goals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy shopping_all on public.shopping_items for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy habits_all on public.habits for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy habit_logs_all on public.habit_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy meals_all on public.meals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy memories_all on public.memories for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy messages_all on public.messages for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy vault_all on public.vault_notes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
