-- ════════════════════════════════════════════════
-- 👤 회원 유형 '기타' 나누기 (2026-11-16)
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
-- (member_type.sql · clover_alumni.sql · clover_my_lab.sql 다음에 실행)
--
--  · '기타'를 없애고 '교수·연구교수' · '기업·연구소 연구원' 을 새로 둠
--    (지금 '기타'인 회원은 '유형 없음'으로 바꿈 → 관리자 화면에서 알맞은 유형으로 골라 주세요)
--  · 두 유형은 학교 메일만으로는 클로버가 열리지 않고, 소속 인증(관리자 승인)을 받아야 열림
--  · 교수·연구교수는 본인 이름이 지도교수로 적힌 연구실에는 클로버를 남길 수 없음
--  · 공개 한줄평에 남긴 사람의 유형 묶음(재학생·졸업생·교수·연구원 등)을 함께 보여 줌
-- ════════════════════════════════════════════════

-- 1) 회원 유형 목록 바꾸기 ('기타' → 유형 없음)
alter table public.profiles drop constraint if exists profiles_member_type_check;
update public.profiles set member_type = null where member_type = '기타';
alter table public.profiles add constraint profiles_member_type_check
  check (member_type is null or member_type in
    ('예비대학원생','학부연구생','석사과정','박사과정','석박통합','박사후연구원','졸업생',
     '교수·연구교수','기업·연구소 연구원'));

-- 2) 가입 순간, 가입 때 고른 유형을 profiles 에 옮겨 적기 (예전 화면의 '기타'는 유형 없음)
create or replace function public.handle_new_user_member_type()
returns trigger language plpgsql security definer set search_path = public as $$
declare t text := new.raw_user_meta_data->>'member_type';
begin
  if t is null or t not in ('예비대학원생','학부연구생','석사과정','박사과정','석박통합','박사후연구원','졸업생',
                            '교수·연구교수','기업·연구소 연구원') then
    t := null;
  end if;
  insert into public.profiles(id, member_type) values (new.id, t)
  on conflict (id) do update set member_type = coalesce(public.profiles.member_type, excluded.member_type);
  return new;
end $$;
revoke execute on function public.handle_new_user_member_type() from public, anon, authenticated;

-- 3) 클로버 자격
--    · 예비대학원생: 안 됨
--    · 졸업생: 학교 인증 + 졸업 후 10년 이내
--    · 교수·연구교수 / 기업·연구소 연구원: 소속 인증(관리자 승인)을 받으면 가능
--    · 나머지(재학생·박사후연구원): 학교 메일 또는 학교 인증
create or replace function public.can_clover()
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
    and not public.is_suspended()
    and not exists (select 1 from public.profiles p
                     where p.id = auth.uid() and p.member_type = '예비대학원생')
    and not exists (select 1 from public.profiles p
                     where p.id = auth.uid() and p.member_type = '졸업생'
                       and not (coalesce(p.is_verified, false)
                                and p.grad_year is not null
                                and p.grad_year >= extract(year from (now() at time zone 'Asia/Seoul'))::int - public.clover_alumni_years()))
    and not exists (select 1 from public.profiles p
                     where p.id = auth.uid()
                       and p.member_type in ('교수·연구교수','기업·연구소 연구원')
                       and not coalesce(p.is_verified, false))
    and (
      exists (select 1 from auth.users u
               where u.id = auth.uid() and u.email_confirmed_at is not null
                 and (lower(u.email) like '%.ac.kr' or lower(u.email) like '%.edu'))
      or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_verified)
    )
$$;
grant execute on function public.can_clover() to anon, authenticated;

-- 4) 교수·연구교수는 본인이 지도교수인 연구실에 클로버를 남길 수 없음
--    (가입 이름과 연구실의 교수 성함을 띄어쓰기·'교수님' 등을 빼고 비교. 운영자 검토도 함께 거침)
create or replace function public.clover_is_own_lab(p_user uuid, p_lab bigint)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
      from public.profiles p
      join auth.users u on u.id = p.id
      join public.clover_labs l on l.id = p_lab
     where p.id = p_user
       and p.member_type = '교수·연구교수'
       and l.prof is not null
       and public.clover_norm_prof(l.prof) <> ''
       and public.clover_norm_prof(l.prof) = public.clover_norm_prof(u.raw_user_meta_data->>'name')
  )
$$;
revoke execute on function public.clover_is_own_lab(uuid, bigint) from public, anon, authenticated;

create or replace function public.clover_vote_guard()
returns trigger language plpgsql security definer set search_path = public as $$
declare ok boolean; lu text;
begin
  if auth.uid() is null or public.is_admin_reviewing() then return new; end if;  -- 서버 작업 / 관리자 승인 처리
  if tg_op = 'UPDATE' and new.lab_id is distinct from old.lab_id then raise exception 'not my lab'; end if;
  if public.clover_is_own_lab(new.user_id, new.lab_id) then raise exception 'own lab'; end if;
  -- 회원이 남기거나 고친 클로버는 언제나 '검토 대기'로
  new.status := 'pending'; new.reviewed_at := null; new.reject_reason := null;
  if tg_op = 'INSERT' then
    select univ into lu from public.clover_labs where id = new.lab_id;
    ok := public.clover_check_my_lab(new.lab_id, lu);
    insert into public.clover_members(user_id, lab_id, univ_ok) values (new.user_id, new.lab_id, ok)
    on conflict (user_id) do nothing;
  end if;
  return new;
end $$;

-- 5) 공개 한줄평에 남긴 사람의 유형 묶음을 함께 (이름·학교는 그대로 숨김)
create or replace function public.clover_voter_group(t text)
returns text language sql immutable set search_path = public as $$
  select case
    when t in ('학부연구생','석사과정','박사과정','석박통합') then '재학생'
    when t = '박사후연구원' then '박사후연구원'
    when t = '졸업생' then '졸업생'
    when t in ('교수·연구교수','기업·연구소 연구원') then '교수·연구원'
  end
$$;

drop function if exists public.clover_comments_public();
create function public.clover_comments_public()
returns table (id bigint, lab_id bigint, body text, created_at timestamptz, voter_group text)
language sql stable security definer set search_path = public as $$
  select c.id, c.lab_id, c.body, c.created_at, c.voter_group from (
    select c.*, public.clover_voter_group(p.member_type) voter_group,
           row_number() over (partition by c.lab_id order by c.created_at desc) rn
    from public.clover_comments c
    join public.clover_labs l on l.id = c.lab_id and not l.hidden
    left join public.profiles p on p.id = c.user_id
    where not c.hidden and c.status = 'approved'
      and (select count(*) from public.clover_votes v where v.lab_id = c.lab_id and v.status = 'approved') >= 6
  ) c where c.rn <= 5
  order by c.lab_id, c.created_at desc
$$;
grant execute on function public.clover_comments_public() to anon, authenticated;
