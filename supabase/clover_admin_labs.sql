-- ════════════════════════════════════════════════
-- 🍀 클로버 지수: 운영자가 미리 등록하는 연구실 ('운영자 등록' 표시)
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
-- (clover_my_lab.sql · clover_alumni.sql 다음에 실행)
--
-- 왜: 지금은 회원이 처음 클로버를 남길 때만 연구실이 생긴다. 운영자가 공개된 연구실
--     정보를 미리 넣어 두면, 회원이 같은 '학교 + 지도교수님 성함'을 적었을 때
--     새로 만들지 않고 그 연구실에 바로 이어 붙는다 (clover_add_lab 의 기존 묶기 규칙 그대로).
--
-- 원칙
--  · 연구실 단위 공개 정보만: 학교·학과·연구실 이름·교수님 성함·연구 분야·홈페이지·대표 논문
--  · 개인 연락처·학생 정보는 넣지 않는다
--  · 공개 화면은 바뀌지 않는다. 운영자 등록 연구실도 승인된 클로버가 생기기 전에는 목록에 안 나오고,
--    이름·분야는 지금처럼 6명이 모여야 보인다. 새 칸(출처·홈페이지)과 논문·과제 표는 관리자만 본다.
-- ════════════════════════════════════════════════

-- 1) 연구실 표에 '누가 등록했는지'와 공개 출처 칸 추가 (기존 연구실은 모두 '회원 등록')
alter table public.clover_labs add column if not exists source text not null default 'member';
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'clover_labs_source_chk') then
    alter table public.clover_labs add constraint clover_labs_source_chk check (source in ('member','admin'));
  end if;
end $$;
alter table public.clover_labs add column if not exists homepage     text check (char_length(homepage) <= 300);
alter table public.clover_labs add column if not exists source_url   text check (char_length(source_url) <= 300);
alter table public.clover_labs add column if not exists collected_at date;
-- 공개 읽기 권한은 그대로 (id, univ, dept, hidden, created_at) → 새 칸은 관리자 함수로만 보인다

-- 2) 대표 논문 (공개 서지정보로 교차 확인한 것만)
create table if not exists public.clover_lab_papers (
  id           bigint generated always as identity primary key,
  lab_id       bigint not null references public.clover_labs(id) on delete cascade,
  title        text not null check (char_length(title) between 2 and 400),
  venue        text check (char_length(venue) <= 200),
  year         smallint check (year between 1950 and 2100),
  url          text check (char_length(url) <= 300),      -- DOI 링크 등
  verified_via text check (char_length(verified_via) <= 60), -- 예: 'openalex', 'dblp', '연구실 홈페이지'
  created_at   timestamptz not null default now()
);
create unique index if not exists clover_lab_papers_uniq on public.clover_lab_papers
  (lab_id, lower(regexp_replace(title, '\W', '', 'g')));
alter table public.clover_lab_papers enable row level security;
drop policy if exists "논문 관리" on public.clover_lab_papers;
create policy "논문 관리" on public.clover_lab_papers for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 3) 연구 과제 (연구실과 매칭이 확실한 것만. 시범 수집에서는 비워 둠)
create table if not exists public.clover_lab_projects (
  id           bigint generated always as identity primary key,
  lab_id       bigint not null references public.clover_labs(id) on delete cascade,
  title        text not null check (char_length(title) between 2 and 400),
  agency       text check (char_length(agency) <= 120),   -- 지원 기관
  period       text check (char_length(period) <= 60),    -- 예: '2024~2027'
  url          text check (char_length(url) <= 300),
  verified_via text check (char_length(verified_via) <= 60), -- 예: 'NTIS'
  created_at   timestamptz not null default now()
);
alter table public.clover_lab_projects enable row level security;
drop policy if exists "과제 관리" on public.clover_lab_projects;
create policy "과제 관리" on public.clover_lab_projects for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 4) 관리자 클로버 현황에 '출처'(member/admin)·홈페이지·논문 수 추가 (반환 칸이 바뀌어서 지우고 다시 만듦)
drop function if exists public.admin_clover_labs();
create function public.admin_clover_labs()
returns table (id bigint, univ text, dept text, name text, prof text, topic text, hidden boolean,
               cnt int, comments int, pending_reports int, created_at timestamptz, pending int, unchecked int,
               source text, homepage text, papers int)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select l.id, l.univ, l.dept, l.name, l.prof, l.topic, l.hidden,
         (select count(*) from public.clover_votes v where v.lab_id = l.id and v.status = 'approved')::int,
         (select count(*) from public.clover_comments c where c.lab_id = l.id and c.status = 'approved')::int,
         (select count(*) from public.clover_reports r where r.lab_id = l.id and r.status = 'pending')::int,
         l.created_at,
         (select count(*) from public.clover_votes v where v.lab_id = l.id and v.status = 'pending')::int,
         (select count(*) from public.clover_votes v
            left join public.clover_members m on m.user_id = v.user_id and m.lab_id = v.lab_id
           where v.lab_id = l.id and v.status <> 'rejected' and m.univ_ok is not true)::int,
         l.source, l.homepage,
         (select count(*) from public.clover_lab_papers p where p.lab_id = l.id)::int
  from public.clover_labs l
  order by 8 desc, l.created_at desc;
end $$;
revoke all on function public.admin_clover_labs() from public, anon;
grant execute on function public.admin_clover_labs() to authenticated;
