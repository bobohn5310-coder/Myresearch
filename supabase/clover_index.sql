-- ════════════════════════════════════════════════
-- 🍀 클로버 지수 (연구실 환경 지수) 설정
-- Supabase → SQL Editor 에 붙여넣고 Run. 여러 번 실행해도 안전합니다.
--
-- 원칙
--  · 교수 개인이 아니라 '연구실 환경'을 4개 항목(인건비·지도·분위기·워라밸) 1~4잎으로 기록
--  · 글(자유 서술)은 받지 않음
--  · 학교 메일(.ac.kr/.edu) 계정 또는 관리자 인증 회원만 남길 수 있음, 연구실당 1번
--  · 개별 응답은 아무도(본인 제외) 볼 수 없고, 6명 이상 모였을 때 평균만 공개 (화면에는 "n명"으로만 안내)
--  · 신고·삭제 요청이 들어오면 그 연구실을 즉시 가리고(임시조치) 관리자가 검토
-- ════════════════════════════════════════════════

-- 0) 클로버를 남길 수 있는 사람인지 (학교 메일 인증 계정 또는 인증 회원)
create or replace function public.can_clover()
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and (
    exists (select 1 from auth.users u
             where u.id = auth.uid() and u.email_confirmed_at is not null
               and (lower(u.email) like '%.ac.kr' or lower(u.email) like '%.edu'))
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_verified)
  )
$$;
grant execute on function public.can_clover() to anon, authenticated;

-- 1) 연구실 목록
create table if not exists public.clover_labs (
  id         bigint generated always as identity primary key,
  univ       text not null check (char_length(univ) between 2 and 40),
  dept       text not null check (char_length(dept) between 2 and 40),
  name       text not null check (char_length(name) between 2 and 40),
  topic      text check (char_length(topic) <= 60),
  hidden     boolean not null default false,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);
create unique index if not exists clover_labs_uniq on public.clover_labs
  (lower(regexp_replace(univ,'\s','','g')), lower(regexp_replace(dept,'\s','','g')), lower(regexp_replace(name,'\s','','g')));
alter table public.clover_labs enable row level security;

drop policy if exists "연구실 보기" on public.clover_labs;
create policy "연구실 보기" on public.clover_labs for select
  using (not hidden or public.is_admin());
drop policy if exists "연구실 등록" on public.clover_labs;
create policy "연구실 등록" on public.clover_labs for insert to authenticated
  with check (public.can_clover() and created_by = auth.uid() and hidden = false);
drop policy if exists "연구실 관리" on public.clover_labs;
create policy "연구실 관리" on public.clover_labs for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 2) 클로버 기록 (개별 응답은 본인만 볼 수 있음)
create table if not exists public.clover_votes (
  lab_id     bigint not null references public.clover_labs(id) on delete cascade,
  user_id    uuid   not null references auth.users(id) on delete cascade default auth.uid(),
  pay        smallint not null check (pay between 1 and 4),
  guide      smallint not null check (guide between 1 and 4),
  mood       smallint not null check (mood between 1 and 4),
  balance    smallint not null check (balance between 1 and 4),
  created_at timestamptz not null default now(),
  primary key (lab_id, user_id)
);
alter table public.clover_votes enable row level security;

drop policy if exists "내 클로버 보기" on public.clover_votes;
create policy "내 클로버 보기" on public.clover_votes for select to authenticated
  using (user_id = auth.uid());
drop policy if exists "클로버 남기기" on public.clover_votes;
create policy "클로버 남기기" on public.clover_votes for insert to authenticated
  with check (user_id = auth.uid() and public.can_clover()
              and exists (select 1 from public.clover_labs l where l.id = lab_id and not l.hidden));
drop policy if exists "내 클로버 수정" on public.clover_votes;
create policy "내 클로버 수정" on public.clover_votes for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "내 클로버 취소" on public.clover_votes;
create policy "내 클로버 취소" on public.clover_votes for delete to authenticated
  using (user_id = auth.uid());

-- 3) 공개용 요약: 6명 이상일 때만 평균 공개
create or replace function public.clover_summary()
returns table (lab_id bigint, cnt int, pay numeric, guide numeric, mood numeric, balance numeric, total numeric)
language sql stable security definer set search_path = public as $$
  select l.id, coalesce(count(v.user_id),0)::int,
    case when count(v.user_id) >= 6 then round(avg(v.pay),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.guide),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.mood),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.balance),1) end,
    case when count(v.user_id) >= 6 then round(avg((v.pay+v.guide+v.mood+v.balance)/4.0),1) end
  from public.clover_labs l left join public.clover_votes v on v.lab_id = l.id
  where not l.hidden
  group by l.id
$$;
grant execute on function public.clover_summary() to anon, authenticated;

-- 4) 신고·삭제 요청 (로그인 없이도 가능) → 즉시 가림
create table if not exists public.clover_reports (
  id          bigint generated always as identity primary key,
  lab_id      bigint references public.clover_labs(id) on delete cascade,
  kind        text not null default 'report' check (kind in ('report','delete')),
  reason      text check (char_length(reason) <= 1000),
  contact     text check (char_length(contact) <= 120),
  reporter_id uuid default auth.uid(),
  status      text not null default 'pending' check (status in ('pending','restored','removed')),
  created_at  timestamptz not null default now()
);
alter table public.clover_reports enable row level security;
drop policy if exists "신고 관리" on public.clover_reports;
create policy "신고 관리" on public.clover_reports for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create or replace function public.clover_report(p_lab bigint, p_kind text, p_reason text, p_contact text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.clover_labs where id = p_lab) then
    raise exception 'no lab';
  end if;
  insert into public.clover_reports(lab_id, kind, reason, contact, reporter_id)
  values (p_lab, case when p_kind = 'delete' then 'delete' else 'report' end,
          left(p_reason, 1000), left(p_contact, 120), auth.uid());
  update public.clover_labs set hidden = true where id = p_lab;
end $$;
grant execute on function public.clover_report(bigint, text, text, text) to anon, authenticated;
