-- 관리자만 학술정보·뉴스·배너를 쓰고, 학생 인증 요청을 보고 승인할 수 있게 한다.
-- 관리자 목록은 public.admins 테이블. 웹(API)에서는 이 테이블을 읽거나 바꿀 수 없다.

create table if not exists public.admins (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;   -- 정책이 없으므로 API 접근 전면 차단

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admins where user_id = auth.uid()) $$;
grant execute on function public.is_admin() to anon, authenticated;

insert into public.admins (user_id)
select id from auth.users where email = 'bobohn5310@naver.com'
on conflict do nothing;

-- 학술정보·뉴스·배너: 읽기는 누구나, 쓰기는 관리자만
drop policy if exists "로그인 유저만 쓰기 가능" on public.academic_info;
create policy "관리자만 쓰기" on public.academic_info for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "로그인 유저만 쓰기 가능" on public.news;
create policy "관리자만 쓰기" on public.news for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "auth users can write banners" on public.banners;
create policy "관리자만 쓰기" on public.banners for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 학생 인증 요청: 누구나 읽고 고칠 수 있던 것을 본인(읽기·등록)과 관리자만으로
drop policy if exists "전체 읽기" on public.verification_requests;
drop policy if exists "전체 업데이트" on public.verification_requests;
create policy "관리자 읽기" on public.verification_requests for select to authenticated
  using (public.is_admin());
create policy "관리자 처리" on public.verification_requests for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 프로필: 관리자가 인증 승인(is_verified)을 할 수 있게 하고, 본인이 스스로 인증 처리하는 것은 막는다
create policy "관리자 프로필 관리" on public.profiles for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create or replace function public.protect_is_verified()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() and auth.uid() is not null then
    new.is_verified := case when tg_op = 'UPDATE' then old.is_verified else false end;
  end if;
  return new;
end $$;
drop trigger if exists protect_is_verified on public.profiles;
create trigger protect_is_verified before insert or update on public.profiles
  for each row execute function public.protect_is_verified();
