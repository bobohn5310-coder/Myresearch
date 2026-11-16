-- ════════════════════════════════════════════════════════════
--  학교 회원만 쓰기 (2026-11-16)
--  · 학교 메일(.ac.kr, .edu)을 확인했거나, 학교 인증을 승인받은 회원(또는 관리자)만
--    글·댓글·공감·학회 제보·캘린더/CV 저장·출석 도장을 할 수 있다.
--  · 지메일·네이버 등 다른 메일로 가입한 회원은 학교 메일 확인이나 학교 인증 전까지 '보기만' 된다.
--  · 지우기, 신고하기, 프로필 수정, 학교 인증 신청, 탈퇴 요청은 그대로 할 수 있다.
--  · 클로버·학회 후기는 원래대로 can_clover() 로 막혀 있다.
--  Supabase SQL Editor 에서 한 번 실행하면 된다. 여러 번 실행해도 괜찮다.
-- ════════════════════════════════════════════════════════════

-- 1) 학교 회원인지
create or replace function public.is_school_member()
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
    and not public.is_suspended()
    and (
      public.is_admin()
      or exists (select 1 from auth.users u
                  where u.id = auth.uid() and u.email_confirmed_at is not null
                    and (lower(u.email) like '%.ac.kr' or lower(u.email) like '%.edu'))
      or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_verified)
    )
$$;
revoke all on function public.is_school_member() from public;
grant execute on function public.is_school_member() to anon, authenticated;

-- 2) 쓰기(추가·수정)에 '학교 회원' 조건을 덧붙인다 (restrictive 정책은 기존 정책과 AND 로 묶임)
do $$
declare t text;
begin
  foreach t in array array['posts','comments','post_likes','conference_suggestions',
                           'conferences','schedules','papers','projects','cv_items','cv_profile'] loop
    if to_regclass('public.' || t) is null then continue; end if;
    execute format('drop policy if exists "학교 회원만 추가" on public.%I', t);
    execute format('create policy "학교 회원만 추가" on public.%I as restrictive for insert with check (public.is_school_member())', t);
    execute format('drop policy if exists "학교 회원만 수정" on public.%I', t);
    execute format('create policy "학교 회원만 수정" on public.%I as restrictive for update using (public.is_school_member())', t);
  end loop;
end $$;

-- 3) 출석 도장도 학교 회원만
create or replace function public.attend_stamp(p_event text)
returns setof date language plpgsql security definer set search_path = public as $$
declare
  ev public.attendance_events;
  today date := (now() at time zone 'Asia/Seoul')::date;
begin
  if auth.uid() is null then raise exception 'login required'; end if;
  if public.is_suspended() then raise exception 'suspended'; end if;
  if not public.is_school_member() then raise exception 'school only'; end if;
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
