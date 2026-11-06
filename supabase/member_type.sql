-- ════════════════════════════════════════════════
-- 👤 회원 유형 (예비대학원생 · 학부연구생 · 석사과정 …) + 예비대학원생 클로버 제한
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
--
--  · 가입할 때 고른 회원 유형을 profiles.member_type 에 저장 (가입 순간 서버가 자동으로)
--  · 회원 본인은 유형을 바꿀 수 없음. 관리자만 바꿀 수 있음 (학교 인증 승인 시 과정으로 갱신)
--  · 예비대학원생은 연구실 클로버를 남길 수 없음 (서버에서 막음). 학부연구생은 가능.
-- ════════════════════════════════════════════════

-- 1) 회원 유형 칸
alter table public.profiles add column if not exists member_type text;
alter table public.profiles drop constraint if exists profiles_member_type_check;
alter table public.profiles add constraint profiles_member_type_check
  check (member_type is null or member_type in
    ('예비대학원생','학부연구생','석사과정','박사과정','석박통합','박사후연구원','기타'));

-- 2) 가입 순간, 가입 때 고른 유형을 profiles 에 옮겨 적기
create or replace function public.handle_new_user_member_type()
returns trigger language plpgsql security definer set search_path = public as $$
declare t text := new.raw_user_meta_data->>'member_type';
begin
  if t is null or t not in ('예비대학원생','학부연구생','석사과정','박사과정','석박통합','박사후연구원','기타') then
    t := null;
  end if;
  insert into public.profiles(id, member_type) values (new.id, t)
  on conflict (id) do update set member_type = coalesce(public.profiles.member_type, excluded.member_type);
  return new;
end $$;
drop trigger if exists on_auth_user_member_type on auth.users;
create trigger on_auth_user_member_type
  after insert on auth.users
  for each row execute function public.handle_new_user_member_type();

-- 3) 회원이 스스로 유형을 바꾸지 못하게 (관리자·서버 작업만 가능)
create or replace function public.guard_member_type()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() or auth.uid() is null then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.member_type := null;
  elsif new.member_type is distinct from old.member_type then
    new.member_type := old.member_type;
  end if;
  return new;
end $$;
drop trigger if exists guard_member_type on public.profiles;
create trigger guard_member_type
  before insert or update on public.profiles
  for each row execute function public.guard_member_type();

-- 4) 클로버 자격: 예비대학원생은 제외 (학부연구생은 학교 메일 또는 인증이 있으면 가능)
create or replace function public.can_clover()
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
    and not exists (select 1 from public.profiles p
                     where p.id = auth.uid() and p.member_type = '예비대학원생')
    and (
      exists (select 1 from auth.users u
               where u.id = auth.uid() and u.email_confirmed_at is not null
                 and (lower(u.email) like '%.ac.kr' or lower(u.email) like '%.edu'))
      or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_verified)
    )
$$;
grant execute on function public.can_clover() to anon, authenticated;

-- 5) 클로버 수정도 같은 자격이 있어야 가능
drop policy if exists "내 클로버 수정" on public.clover_votes;
create policy "내 클로버 수정" on public.clover_votes for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid() and public.can_clover());
