create extension if not exists btree_gist;

create table if not exists public.meeting_room_reservations (
  id uuid primary key default gen_random_uuid(),
  owner text not null,
  reason text not null,
  date date not null,
  start timestamptz not null,
  "end" timestamptz not null,
  created_at timestamptz not null default now(),
  constraint valid_time_range check ("end" > start),
  constraint no_time_overlap exclude using gist (
    tstzrange(start, "end", '[)') with &&
  )
);

alter table public.meeting_room_reservations enable row level security;

drop policy if exists "Agenda publica para leitura" on public.meeting_room_reservations;
drop policy if exists "Agenda publica para criacao" on public.meeting_room_reservations;
drop policy if exists "Agenda publica para cancelamento" on public.meeting_room_reservations;

create policy "Agenda publica para leitura"
on public.meeting_room_reservations
for select
to anon
using (true);

create policy "Agenda publica para criacao"
on public.meeting_room_reservations
for insert
to anon
with check (true);

create policy "Agenda publica para cancelamento"
on public.meeting_room_reservations
for delete
to anon
using (true);
