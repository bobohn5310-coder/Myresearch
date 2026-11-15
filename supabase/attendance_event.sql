-- ════════════════════════════════════════════════
-- 📅 일주일 출석체크 이벤트 (회원 전용)
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
-- (admin_tools.sql 을 먼저 실행한 상태여야 해요: is_admin(), is_suspended() 사용)
--
--  · 출석 날짜는 서버 시계(한국 시간)로 정해서, 하루에 한 번만 찍힙니다.
--  · 회원은 자기 출석만 볼 수 있고, 직접 쓰거나 지울 수 없습니다 (attend_stamp 함수로만 기록).
--  · 이벤트 기간·목표 도장 수는 아래 attendance_events 표에서 정합니다.
--    새 이벤트를 열려면 새 id 로 한 줄을 더 넣고, index.html 의 ATTEND_EVENT.id 도 같게 바꿔 주세요.
-- ════════════════════════════════════════════════

create table if not exists public.attendance_events (
  id text primary key,
  start_day date not null,
  end_day date not null,
  goal int not null default 7 check (goal between 1 and 31)
);
alter table public.attendance_events enable row level security;
drop policy if exists "출석 이벤트 보기" on public.attendance_events;
create policy "출석 이벤트 보기" on public.attendance_events for select using (true);
drop policy if exists "출석 이벤트 관리" on public.attendance_events;
create policy "출석 이벤트 관리" on public.attendance_events for all
  using (public.is_admin()) with check (public.is_admin());

insert into public.attendance_events(id, start_day, end_day, goal)
values ('2026-11-week', '2026-11-15', '2026-12-31', 7)
on conflict (id) do nothing;

create table if not exists public.attendance (
  event_id text not null references public.attendance_events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id, day)
);
alter table public.attendance enable row level security;
revoke insert, update, delete on public.attendance from anon, authenticated;
drop policy if exists "내 출석 보기" on public.attendance;
create policy "내 출석 보기" on public.attendance for select
  using (user_id = auth.uid() or public.is_admin());

-- 오늘 도장 찍기: 로그인한 회원만, 이벤트 기간 안에서, 하루 한 번, 목표 수까지만
create or replace function public.attend_stamp(p_event text)
returns setof date
language plpgsql security definer set search_path = public as $$
declare
  ev public.attendance_events;
  today date := (now() at time zone 'Asia/Seoul')::date;
begin
  if auth.uid() is null then raise exception 'login required'; end if;
  if public.is_suspended() then raise exception 'suspended'; end if;
  select * into ev from public.attendance_events where id = p_event;
  if not found then raise exception 'no event'; end if;
  if today < ev.start_day or today > ev.end_day then raise exception 'event closed'; end if;
  if (select count(*) from public.attendance a where a.event_id = p_event and a.user_id = auth.uid()) < ev.goal then
    insert into public.attendance(event_id, user_id, day) values (p_event, auth.uid(), today)
    on conflict do nothing;
  end if;
  return query select a.day from public.attendance a
    where a.event_id = p_event and a.user_id = auth.uid() order by a.day;
end $$;
revoke all on function public.attend_stamp(text) from public, anon;
grant execute on function public.attend_stamp(text) to authenticated;

-- 관리자: 이벤트 참여 회원 목록 (많이 찍은 순)
create or replace function public.admin_attendance(p_event text)
returns table (user_id uuid, name text, email text, days int, last_day date, dates date[], completed boolean)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select u.id, (u.raw_user_meta_data->>'name')::text, u.email::text,
         count(*)::int, max(a.day), array_agg(a.day order by a.day),
         count(*) >= (select e.goal from public.attendance_events e where e.id = p_event)
  from public.attendance a join auth.users u on u.id = a.user_id
  where a.event_id = p_event
  group by u.id
  order by count(*) desc, max(a.day) asc;
end $$;
revoke all on function public.admin_attendance(text) from public, anon;
grant execute on function public.admin_attendance(text) to authenticated;
