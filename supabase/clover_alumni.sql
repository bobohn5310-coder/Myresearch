-- ════════════════════════════════════════════════
-- 🎓 졸업생도 클로버 남기기 (졸업 후 10년 이내)
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
-- (member_type.sql · clover_my_lab.sql 다음에 실행)
--
--  · 회원 유형에 '졸업생'을 추가
--  · 학교 인증 때 졸업생은 졸업 연도와 졸업증명서(또는 학위증명서)를 올림
--  · 관리자가 인증을 승인하면 profiles.grad_year 에 졸업 연도가 저장됨 (회원은 못 바꿈)
--  · 졸업생은 '학교 인증 승인 + 졸업 후 10년 이내'일 때만 클로버를 남길 수 있음
--    (학교 메일이 살아 있어도 졸업 연도 확인이 필요해서 인증을 받아야 함)
--  · 내 연구실 1곳 고정 · 학교 일치 · 관리자 승인 규칙은 재학생과 똑같이 적용
-- ════════════════════════════════════════════════

-- 0) 기한 (년). 나중에 바꾸려면 숫자만 고치고 다시 실행
create or replace function public.clover_alumni_years()
returns int language sql immutable as $$ select 10 $$;

-- 1) 회원 유형에 '졸업생' 추가
alter table public.profiles drop constraint if exists profiles_member_type_check;
alter table public.profiles add constraint profiles_member_type_check
  check (member_type is null or member_type in
    ('예비대학원생','학부연구생','석사과정','박사과정','석박통합','박사후연구원','졸업생','기타'));

create or replace function public.handle_new_user_member_type()
returns trigger language plpgsql security definer set search_path = public as $$
declare t text := new.raw_user_meta_data->>'member_type';
begin
  if t is null or t not in ('예비대학원생','학부연구생','석사과정','박사과정','석박통합','박사후연구원','졸업생','기타') then
    t := null;
  end if;
  insert into public.profiles(id, member_type) values (new.id, t)
  on conflict (id) do update set member_type = coalesce(public.profiles.member_type, excluded.member_type);
  return new;
end $$;

-- 2) 졸업 연도: 인증 요청에 적고, 관리자가 승인하면 profiles 에 저장
alter table public.verification_requests add column if not exists grad_year smallint
  check (grad_year is null or grad_year between 1950 and 2100);
alter table public.profiles add column if not exists grad_year smallint
  check (grad_year is null or grad_year between 1950 and 2100);

-- 회원이 스스로 졸업 연도를 바꾸지 못하게 (관리자·서버 작업만 가능)
create or replace function public.guard_grad_year()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() or auth.uid() is null then return new; end if;
  if tg_op = 'INSERT' then new.grad_year := null;
  elsif new.grad_year is distinct from old.grad_year then new.grad_year := old.grad_year;
  end if;
  return new;
end $$;
drop trigger if exists guard_grad_year on public.profiles;
create trigger guard_grad_year before insert or update on public.profiles
  for each row execute function public.guard_grad_year();

-- 3) 클로버 자격: 졸업생은 학교 인증 승인 + 졸업 후 10년 이내
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
    and (
      exists (select 1 from auth.users u
               where u.id = auth.uid() and u.email_confirmed_at is not null
                 and (lower(u.email) like '%.ac.kr' or lower(u.email) like '%.edu'))
      or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_verified)
    )
$$;
grant execute on function public.can_clover() to anon, authenticated;

-- 클로버 창 안내용: 졸업생이면 졸업 연도와 기한
create or replace function public.clover_alumni_status()
returns table (member_type text, is_verified boolean, grad_year smallint, years int)
language sql stable security definer set search_path = public as $$
  select p.member_type, coalesce(p.is_verified, false), p.grad_year, public.clover_alumni_years()
    from public.profiles p where p.id = auth.uid()
$$;
grant execute on function public.clover_alumni_status() to authenticated;

-- 4) 관리자 승인함에 졸업 연도 추가 (반환 칸이 바뀌어서 지우고 다시 만듦)
drop function if exists public.admin_clover_queue(text);
create function public.admin_clover_queue(p_status text default 'pending')
returns table (lab_id bigint, user_id uuid, email text, name text, member_type text, is_verified boolean,
               user_univs text[], verify_school text, univ_ok boolean, other_votes int,
               univ text, dept text, lab_name text, prof text, lab_hidden boolean, lab_approved int,
               pay smallint, guide smallint, mood smallint, balance smallint,
               comment text, comment_status text, status text, reject_reason text, created_at timestamptz,
               grad_year smallint)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select v.lab_id, v.user_id, u.email::text, (u.raw_user_meta_data->>'name')::text,
         p.member_type, coalesce(p.is_verified, false),
         public.clover_user_univs(v.user_id),
         (select r.school from public.verification_requests r where r.user_id = v.user_id and r.status = 'approved'
           order by r.created_at desc limit 1)::text,
         m.univ_ok,
         (select count(*) from public.clover_votes v2 where v2.user_id = v.user_id and v2.lab_id <> v.lab_id)::int,
         l.univ, l.dept, l.name, l.prof, l.hidden,
         (select count(*) from public.clover_votes v3 where v3.lab_id = v.lab_id and v3.status = 'approved')::int,
         v.pay, v.guide, v.mood, v.balance,
         c.body, c.status, v.status, v.reject_reason, v.created_at,
         p.grad_year
    from public.clover_votes v
    join public.clover_labs l on l.id = v.lab_id
    left join auth.users u on u.id = v.user_id
    left join public.profiles p on p.id = v.user_id
    left join public.clover_members m on m.user_id = v.user_id and m.lab_id = v.lab_id
    left join public.clover_comments c on c.lab_id = v.lab_id and c.user_id = v.user_id
   where p_status = 'all' or v.status = p_status
   order by v.created_at desc
   limit 300;
end $$;
revoke all on function public.admin_clover_queue(text) from public, anon;
grant execute on function public.admin_clover_queue(text) to authenticated;
