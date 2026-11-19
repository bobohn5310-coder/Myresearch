-- ════════════════════════════════════════════════════════════
--  🍀 관리자도 클로버 남기기 (2026-11-19)
--  · 지금은 관리자 계정이 학교 메일(ac.kr, edu)도 아니고 연구자 인증도 없어서
--    can_clover() 가 false → 클로버 남기기 창에서 막힌다.
--  · 관리자(admins 표에 있는 계정)는 학교 메일·학교 인증·회원 유형 조건 없이 남길 수 있게 한다.
--    관리자인지는 서버(is_admin)가 확인하므로, 일반 회원이 화면을 고쳐도 소용없다.
--  · can_clover() 하나만 바꾸면 클로버 남기기(clover_votes), 한줄평(clover_comments),
--    연구실 등록(clover_add_lab)이 모두 함께 풀린다.
--  · 나머지 규칙은 관리자도 똑같다:
--    정지 계정 금지 · 내 연구실 한 곳 고정 · 숨긴 연구실 금지 · 한줄평 금지어/연락처 금지 ·
--    남긴 클로버는 '확인 대기'로 들어가 운영자 확인 후 반영.
--    (관리자 계정은 학교 정보가 없어서 학교 일치 검사는 '알 수 없음'으로 통과한다)
--  Supabase SQL Editor 에서 한 번 실행하면 된다. 여러 번 실행해도 괜찮다.
-- ════════════════════════════════════════════════════════════

create or replace function public.can_clover()
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
    and not public.is_suspended()
    and (
      -- 관리자는 아래 조건 없이 남길 수 있음
      public.is_admin()
      or (
        not exists (select 1 from public.profiles p
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
      )
    )
$$;
grant execute on function public.can_clover() to anon, authenticated;
