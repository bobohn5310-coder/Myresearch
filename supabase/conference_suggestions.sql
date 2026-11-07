-- 학회 제보: 로그인한 사용자가 빠진 학회를 알려 주면 관리자가 확인해서 올린다.
create table if not exists public.conference_suggestions (
  id bigint generated always as identity primary key,
  title text not null check (char_length(title) between 2 and 200),
  org text check (char_length(org) <= 200),
  start_date date,
  end_date date,
  location text check (char_length(location) <= 120),
  url text check (char_length(url) <= 500),
  abstract_deadline date,
  registration_deadline date,
  field text,
  note text check (char_length(note) <= 1000),
  user_id uuid default auth.uid() references auth.users(id) on delete set null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

alter table public.conference_suggestions enable row level security;

-- 로그인한 사용자는 '대기' 상태로만 제보할 수 있다
drop policy if exists "suggest insert" on public.conference_suggestions;
create policy "suggest insert" on public.conference_suggestions
  for insert to authenticated
  with check (status = 'pending' and user_id = auth.uid());

-- 관리자만 보고 처리한다
drop policy if exists "suggest admin all" on public.conference_suggestions;
create policy "suggest admin all" on public.conference_suggestions
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
