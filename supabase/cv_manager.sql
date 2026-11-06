-- ─────────────────────────────────────────────────────────────
-- 내 CV 관리 (내 캘린더 > 내 CV)
-- Supabase SQL Editor에 전체를 붙여넣고 Run 하세요. 여러 번 실행해도 안전해요.
-- 기존 데이터는 지우거나 바꾸지 않고, 칸과 표만 새로 더해요.
-- ─────────────────────────────────────────────────────────────

-- 1) 기존 논문·학회·과제 표에 CV에 필요한 칸 더하기
alter table public.papers      add column if not exists authors    text;  -- 저자 목록 (예: Kim B., Lee C.)
alter table public.papers      add column if not exists year       text;  -- 게재/투고 연도
alter table public.papers      add column if not exists paper_type text;  -- intl_journal / dom_journal / intl_conf / dom_conf / etc
alter table public.papers      add column if not exists link       text;  -- DOI 또는 주소

alter table public.conferences add column if not exists presentation_title text; -- 발표 제목
alter table public.conferences add column if not exists location           text; -- 개최 장소

alter table public.projects    add column if not exists start_date text;  -- YYYY-MM
alter table public.projects    add column if not exists end_date   text;  -- YYYY-MM

-- 기존 '본인만' 정책은 읽기 조건만 있어서, 쓸 때도 본인 것만 넣도록 확인을 더한다
do $$
declare t text;
begin
  foreach t in array array['papers','conferences','projects'] loop
    execute format('drop policy if exists "본인만" on public.%I', t);
    execute format('create policy "본인만" on public.%I for all using (auth.uid() = user_id) with check (auth.uid() = user_id)', t);
  end loop;
end $$;

-- 2) 학력·경력·특허·수상·강의·스킬·활동을 담는 표
create table if not exists public.cv_items (
  id          bigint generated always as identity primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  section     text not null check (section in
                ('education','experience','patent','award','teaching','skill','activity')),
  title       text not null check (char_length(title) <= 300),
  org         text check (char_length(org) <= 200),
  role        text check (char_length(role) <= 100),
  start_date  text check (char_length(start_date) <= 20),
  end_date    text check (char_length(end_date) <= 20),
  detail      text check (char_length(detail) <= 2000),
  link        text check (char_length(link) <= 500),
  created_at  timestamptz not null default now()
);
create index if not exists cv_items_user_idx on public.cv_items(user_id, section);

alter table public.cv_items enable row level security;
drop policy if exists "cv_items 본인만" on public.cv_items;
create policy "cv_items 본인만" on public.cv_items
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 3) CV 머리글 정보 (실명·연락처는 커뮤니티 프로필과 분리해서 본인만 봄)
create table if not exists public.cv_profile (
  user_id     uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  name_ko     text check (char_length(name_ko) <= 50),
  name_en     text check (char_length(name_en) <= 100),
  email       text check (char_length(email) <= 200),
  phone       text check (char_length(phone) <= 50),
  website     text check (char_length(website) <= 300),
  affiliation text check (char_length(affiliation) <= 200),
  interests   text check (char_length(interests) <= 500),
  summary     text check (char_length(summary) <= 2000),
  updated_at  timestamptz not null default now()
);

alter table public.cv_profile enable row level security;
drop policy if exists "cv_profile 본인만" on public.cv_profile;
create policy "cv_profile 본인만" on public.cv_profile
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select, insert, update, delete on public.cv_items   to authenticated;
grant select, insert, update, delete on public.cv_profile to authenticated;
revoke all on public.cv_items   from anon;
revoke all on public.cv_profile from anon;
