-- ════════════════════════════════════════════════════════════════
-- 학교 인증 보안 보강 (2026-11-06)
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 Run 한 번. 여러 번 실행해도 안전.
--
-- 문제: profiles 의 '본인 프로필 쓰기/업데이트' 정책 때문에 회원이 직접
--       is_verified = true 로 바꿔 스스로 '인증됨'이 될 수 있었다.
-- 해결: 관리자(is_admin())가 아니면 is_verified 를 바꿀 수 없게 막는다.
--       인증 서류는 삭제하지 않고 verify-docs 저장소에 그대로 보관한다.
-- ════════════════════════════════════════════════════════════════

create or replace function public.guard_is_verified()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_admin() or auth.uid() is null then
    return new;  -- 관리자, 또는 서버 내부 작업(SQL Editor 등)
  end if;
  if tg_op = 'INSERT' then
    new.is_verified := false;
  elsif new.is_verified is distinct from old.is_verified then
    new.is_verified := old.is_verified;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_is_verified on public.profiles;
create trigger guard_is_verified
  before insert or update on public.profiles
  for each row execute function public.guard_is_verified();

-- 같은 사람이 '대기중' 요청을 여러 개 쌓지 못하게
create unique index if not exists verification_requests_one_pending
  on public.verification_requests (user_id) where status = 'pending';
