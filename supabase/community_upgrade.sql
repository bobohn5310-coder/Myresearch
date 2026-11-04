-- ════════════════════════════════════════════════
-- 커뮤니티 개편용 설정 (한 번만 실행하면 됩니다)
-- Supabase → SQL Editor → New query 에 전체를 붙여넣고 Run
-- 여러 번 실행해도 안전하게 만들었습니다.
-- ════════════════════════════════════════════════

-- 1) 글에 '분야' 칸 추가 (AI·컴퓨터, 공학·반도체 …)
alter table public.posts add column if not exists field text;

-- 2) 공감(좋아요) 기록 표: 한 사람이 한 글에 한 번만
create table if not exists public.post_likes (
  post_id    bigint not null references public.posts(id) on delete cascade,
  user_id    uuid   not null references auth.users(id) on delete cascade default auth.uid(),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.post_likes enable row level security;

drop policy if exists "공감 누구나 보기" on public.post_likes;
create policy "공감 누구나 보기" on public.post_likes
  for select using (true);
drop policy if exists "공감 본인만 누르기" on public.post_likes;
create policy "공감 본인만 누르기" on public.post_likes
  for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "공감 본인만 취소" on public.post_likes;
create policy "공감 본인만 취소" on public.post_likes
  for delete to authenticated using (user_id = auth.uid());

-- 3) 글·댓글 쓰기: 로그인한 사람이 '자기 이름으로만' 쓸 수 있게
drop policy if exists "로그인 유저 작성" on public.posts;
create policy "로그인 유저 작성" on public.posts
  for insert to authenticated with check (author_id = auth.uid());

drop policy if exists "로그인 유저 작성" on public.comments;
create policy "로그인 유저 작성" on public.comments
  for insert to authenticated with check (author_id = auth.uid());

-- 4) 지우기: 본인 글/댓글 + 관리자는 모두
drop policy if exists "본인 글 삭제" on public.posts;
create policy "본인 글 삭제" on public.posts
  for delete using (auth.uid() = author_id or public.is_admin());

drop policy if exists "본인 댓글 삭제" on public.comments;
create policy "본인 댓글 삭제" on public.comments
  for delete using (auth.uid() = author_id or public.is_admin());

drop policy if exists "본인 글 수정" on public.posts;
create policy "본인 글 수정" on public.posts
  for update using (auth.uid() = author_id) with check (auth.uid() = author_id);

-- 5) 공감 수·댓글 수는 서버가 자동으로 세기 (누구도 숫자를 직접 못 바꾸게)
create or replace function public.refresh_post_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare pid bigint;
begin
  pid := coalesce(new.post_id, old.post_id);
  update public.posts p set
    likes    = (select count(*) from public.post_likes l where l.post_id = pid),
    comments = (select count(*) from public.comments  c where c.post_id = pid)
  where p.id = pid;
  return null;
end $$;

drop trigger if exists trg_likes_count on public.post_likes;
create trigger trg_likes_count after insert or delete on public.post_likes
  for each row execute function public.refresh_post_counts();

drop trigger if exists trg_comments_count on public.comments;
create trigger trg_comments_count after insert or delete on public.comments
  for each row execute function public.refresh_post_counts();

-- 5-1) 지금 있는 글들의 숫자를 한 번 맞춰두기
update public.posts p set
  likes    = (select count(*) from public.post_likes l where l.post_id = p.id),
  comments = (select count(*) from public.comments  c where c.post_id = p.id);

-- 글쓴이가 '수정'으로 숫자를 바꾸는 것도 막기
create or replace function public.keep_post_counts()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if pg_trigger_depth() = 1 then
    new.likes := old.likes;
    new.comments := old.comments;
    new.author_id := old.author_id;
  end if;
  return new;
end $$;

drop trigger if exists trg_keep_post_counts on public.posts;
create trigger trg_keep_post_counts before update on public.posts
  for each row execute function public.keep_post_counts();

-- 끝! 아래처럼 나오면 성공입니다: Success. No rows returned
