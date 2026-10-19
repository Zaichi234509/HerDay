-- HerDay Phase 4 — already applied to the live "herday" project
-- (ref: qewzyquyeqgpixliqfyz) via migration "herday_phase4".
-- Adds: reminders table, journal photos, and the public `memories`
-- Storage bucket used for photo uploads (memories + journal).

alter table public.journal_entries add column if not exists image_url text not null default '';

create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null default '',
  remind_time text not null default '08:00',
  kind text not null default 'custom',
  notif_id int not null default 0,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_reminders_user on public.reminders(user_id);
alter table public.reminders enable row level security;
create policy reminders_all on public.reminders for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Photo storage: public bucket so the app can display photos by URL.
-- Uploads still require a signed-in account, and only the uploader can
-- update/delete their files (auth.uid() = owner).
insert into storage.buckets (id, name, public) values ('memories', 'memories', true) on conflict (id) do nothing;

create policy herday_images_public_read on storage.objects for select using (bucket_id = 'memories');
create policy herday_images_auth_upload on storage.objects for insert to authenticated with check (bucket_id = 'memories');
create policy herday_images_owner_update on storage.objects for update using (auth.uid() = owner) with check (bucket_id = 'memories');
create policy herday_images_owner_delete on storage.objects for delete using (auth.uid() = owner);
