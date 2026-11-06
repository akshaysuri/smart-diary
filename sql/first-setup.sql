create table entries (
  id uuid primary key,
  type text not null,
  title text not null,
  tags text[] default '{}',
  data jsonb default '{}',
  created_at timestamptz default now()
);
alter table entries enable row level security;
create policy "open for now" on entries for all using (true) with check (true);
