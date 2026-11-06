-- ════════════════════════════════════════════════
-- 👥 관리자용 회원 목록
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
--
--  · 관리자(is_admin())만 부를 수 있음. 관리자가 아니면 오류.
--  · 이름·이메일·회원 유형·학교·학과·메일 인증·학교 인증·가입일·마지막 로그인
-- ════════════════════════════════════════════════
create or replace function public.admin_members()
returns table (
  id uuid, email text, name text, member_type text, school text, dept text,
  email_confirmed boolean, is_verified boolean, created_at timestamptz, last_sign_in_at timestamptz
)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'not allowed';
  end if;
  return query
  select u.id, u.email::text,
         (u.raw_user_meta_data->>'name')::text,
         p.member_type::text,
         (u.raw_user_meta_data->>'school')::text,
         (u.raw_user_meta_data->>'dept')::text,
         u.email_confirmed_at is not null,
         coalesce(p.is_verified, false),
         u.created_at, u.last_sign_in_at
  from auth.users u
  left join public.profiles p on p.id = u.id
  order by u.created_at desc;
end $$;
revoke all on function public.admin_members() from public, anon;
grant execute on function public.admin_members() to authenticated;
