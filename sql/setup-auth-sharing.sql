-- Smart Diary: login + per-user data + (hidden) family sharing
-- Run in Supabase -> SQL Editor. Do the steps IN ORDER.
-- Before running: deploy the new index.html, create your user (Authentication -> Users -> Add user),
-- test signing in, and copy that user's UID.

-- 1. Add columns (safe to run more than once)
alter table entries add column if not exists user_id uuid default auth.uid() references auth.users(id);
alter table entries add column if not exists shared boolean not null default false;

-- 2. Give all your existing entries to your account. Replace the UID below, then run.
--    (Run this BEFORE step 4, because the guard trigger blocks owner changes.)
update entries set user_id = 'PASTE-YOUR-USER-UID-HERE' where user_id is null;
-- Check: this should return 0
select count(*) from entries where user_id is null;

-- 3. Replace the open policy: only signed-in users, and only their own entries (or shared ones)
drop policy if exists "open for now" on entries;
create policy "read own or shared"   on entries for select to authenticated using (user_id = auth.uid() or shared);
create policy "insert own"           on entries for insert to authenticated with check (user_id = auth.uid());
create policy "update own or shared" on entries for update to authenticated using (user_id = auth.uid() or shared) with check (user_id = auth.uid() or shared);
create policy "delete own"           on entries for delete to authenticated using (user_id = auth.uid());

-- 4. Guard: owner and created date can't be changed, and only the owner can change "shared"
create or replace function entries_guard() returns trigger language plpgsql as $$
begin
  new.user_id := old.user_id;
  new.created_at := old.created_at;
  if auth.uid() is distinct from old.user_id then
    new.shared := old.shared;
  end if;
  return new;
end $$;
drop trigger if exists entries_guard on entries;
create trigger entries_guard before update on entries for each row execute function entries_guard();
