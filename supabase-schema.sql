create extension if not exists btree_gist;
create extension if not exists pgcrypto;

create table if not exists public.meeting_room_reservations (
  id uuid primary key default gen_random_uuid(),
  owner text not null,
  reason text not null,
  date date not null,
  start timestamptz not null,
  "end" timestamptz not null,
  cancel_code_hash text,
  created_at timestamptz not null default now(),
  constraint valid_time_range check ("end" > start),
  constraint no_time_overlap exclude using gist (
    tstzrange(start, "end", '[)') with &&
  )
);

alter table public.meeting_room_reservations
add column if not exists cancel_code_hash text;

alter table public.meeting_room_reservations
add column if not exists series_id uuid;

alter table public.meeting_room_reservations enable row level security;

drop policy if exists "Agenda publica para leitura" on public.meeting_room_reservations;
drop policy if exists "Agenda publica para criacao" on public.meeting_room_reservations;
drop policy if exists "Agenda publica para cancelamento" on public.meeting_room_reservations;
drop function if exists public.create_meeting_reservation(text, text, date, timestamptz, timestamptz, text);
drop function if exists public.create_meeting_reservation(text, text, date, timestamptz, timestamptz, text, uuid);
drop function if exists public.cancel_meeting_reservation(uuid, text);
drop function if exists public.cancel_meeting_series(uuid, text);

create policy "Agenda publica para leitura"
on public.meeting_room_reservations
for select
to anon
using (true);

revoke all on public.meeting_room_reservations from anon;
revoke all on public.meeting_room_reservations from authenticated;

grant select (
  id,
  owner,
  reason,
  date,
  start,
  "end",
  created_at,
  series_id
) on public.meeting_room_reservations to anon;

grant select (
  id,
  owner,
  reason,
  date,
  start,
  "end",
  created_at,
  series_id
) on public.meeting_room_reservations to authenticated;

create or replace function public.create_meeting_reservation(
  p_owner text,
  p_reason text,
  p_date date,
  p_start timestamptz,
  p_end timestamptz,
  p_cancel_code text,
  p_series_id uuid default null
)
returns table (
  id uuid,
  owner text,
  reason text,
  date date,
  start timestamptz,
  "end" timestamptz,
  created_at timestamptz,
  series_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_end <= p_start then
    raise exception 'Horario final precisa ser maior que horario inicial.';
  end if;

  if length(trim(coalesce(p_cancel_code, ''))) < 4 then
    raise exception 'Codigo de cancelamento precisa ter pelo menos 4 caracteres.';
  end if;

  return query
  insert into public.meeting_room_reservations (
    owner,
    reason,
    date,
    start,
    "end",
    cancel_code_hash,
    series_id
  )
  values (
    trim(p_owner),
    trim(p_reason),
    p_date,
    p_start,
    p_end,
    crypt(p_cancel_code, gen_salt('bf')),
    p_series_id
  )
  returning
    meeting_room_reservations.id,
    meeting_room_reservations.owner,
    meeting_room_reservations.reason,
    meeting_room_reservations.date,
    meeting_room_reservations.start,
    meeting_room_reservations."end",
    meeting_room_reservations.created_at,
    meeting_room_reservations.series_id;
end;
$$;

create or replace function public.cancel_meeting_reservation(
  p_id uuid,
  p_cancel_code text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count integer;
begin
  delete from public.meeting_room_reservations
  where id = p_id
    and cancel_code_hash = crypt(p_cancel_code, cancel_code_hash);

  get diagnostics deleted_count = row_count;

  if deleted_count = 0 then
    raise exception 'Codigo de cancelamento invalido.';
  end if;

  return true;
end;
$$;

create or replace function public.cancel_meeting_series(
  p_series_id uuid,
  p_cancel_code text
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count integer;
begin
  delete from public.meeting_room_reservations
  where series_id = p_series_id
    and cancel_code_hash = crypt(p_cancel_code, cancel_code_hash);

  get diagnostics deleted_count = row_count;

  if deleted_count = 0 then
    raise exception 'Codigo de cancelamento invalido.';
  end if;

  return deleted_count;
end;
$$;

grant execute on function public.create_meeting_reservation(text, text, date, timestamptz, timestamptz, text, uuid) to anon;
grant execute on function public.cancel_meeting_reservation(uuid, text) to anon;
grant execute on function public.cancel_meeting_series(uuid, text) to anon;
