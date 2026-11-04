-- ════════════════════════════════════════════════════════════════
-- 공개 전 보안 강화 (2026-11-04)
-- Supabase 대시보드 → SQL Editor 에 통째로 붙여넣고 Run 한 번.
-- 여러 번 실행해도 같은 결과가 나오도록 작성했습니다.
-- ════════════════════════════════════════════════════════════════

-- ── 1. 파일 저장소(Storage) ─────────────────────────────────────
-- 학생 인증 서류는 개인정보이므로 비공개로 전환하고,
-- 본인 폴더(<내 user id>/...)에만 올릴 수 있게 하며, 관리자만 열람.
update storage.buckets
   set public = false,
       file_size_limit = 10 * 1024 * 1024,
       allowed_mime_types = array['image/jpeg','image/png','image/webp','image/heic','application/pdf']
 where id = 'verify-docs';

-- 뉴스/배너 이미지는 공개 조회는 유지하되 업로드는 관리자만.
update storage.buckets
   set file_size_limit = 5 * 1024 * 1024,
       allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif']
 where id = 'news-images';

drop policy if exists "로그인 유저 업로드 121e973_0"          on storage.objects;
drop policy if exists "로그인 유저 이미지 업로드 1wjj44y_0"   on storage.objects;
drop policy if exists "verify-docs 본인 폴더 업로드"          on storage.objects;
drop policy if exists "verify-docs 관리자 열람"               on storage.objects;
drop policy if exists "news-images 관리자 업로드"             on storage.objects;
drop policy if exists "news-images 관리자 수정"               on storage.objects;
drop policy if exists "news-images 관리자 삭제"               on storage.objects;

create policy "verify-docs 본인 폴더 업로드" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'verify-docs'
              and (storage.foldername(name))[1] = auth.uid()::text);

create policy "verify-docs 관리자 열람" on storage.objects
  for select to authenticated
  using (bucket_id = 'verify-docs' and public.is_admin());

create policy "news-images 관리자 업로드" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'news-images' and public.is_admin());

create policy "news-images 관리자 수정" on storage.objects
  for update to authenticated
  using (bucket_id = 'news-images' and public.is_admin())
  with check (bucket_id = 'news-images' and public.is_admin());

create policy "news-images 관리자 삭제" on storage.objects
  for delete to authenticated
  using (bucket_id = 'news-images' and public.is_admin());


-- ── 2. 학생 인증 요청: 스스로 '승인됨'으로 넣지 못하게 ────────────
drop policy if exists "본인 인증요청 등록" on public.verification_requests;
create policy "본인 인증요청 등록" on public.verification_requests
  for insert to authenticated
  with check (auth.uid() = user_id
              and status = 'pending'
              and reviewed_at is null
              and reject_reason is null);


-- ── 3. 커뮤니티 글·댓글 ────────────────────────────────────────
-- (a) 글을 처음 쓸 때 공감/댓글 수를 임의로 넣지 못하게 0 으로 고정
-- (b) '관리자/운영자' 사칭 닉네임 차단 (관리자 본인은 허용)
-- (c) 도배 방지: 1시간에 글 10개, 10분에 댓글 30개까지
create or replace function public.guard_post_insert()
returns trigger language plpgsql set search_path = public as $$
begin
  if not public.is_admin() then
    new.likes := 0;
    new.comments := 0;
    new.created_at := now();
    if new.author_nickname ~* '(관리자|운영자|운영진|admin|마리캘|my ?research ?calendar)' then
      new.author_nickname := '연구자';
    end if;
    if (select count(*) from public.posts
         where author_id = auth.uid() and created_at > now() - interval '1 hour') >= 10 then
      raise exception '글을 너무 빠르게 올리고 있어요. 잠시 후 다시 시도해주세요.';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_post_insert on public.posts;
create trigger trg_guard_post_insert before insert on public.posts
  for each row execute function public.guard_post_insert();

create or replace function public.guard_comment_insert()
returns trigger language plpgsql set search_path = public as $$
begin
  if not public.is_admin() then
    new.created_at := now();
    if new.author_nickname ~* '(관리자|운영자|운영진|admin|마리캘|my ?research ?calendar)' then
      new.author_nickname := '연구자';
    end if;
    if (select count(*) from public.comments
         where author_id = auth.uid() and created_at > now() - interval '10 minutes') >= 30 then
      raise exception '댓글을 너무 빠르게 달고 있어요. 잠시 후 다시 시도해주세요.';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_guard_comment_insert on public.comments;
create trigger trg_guard_comment_insert before insert on public.comments
  for each row execute function public.guard_comment_insert();

-- 글 수정 시에도 작성 시간·사칭 닉네임을 바꾸지 못하게 (기존 함수 보강)
create or replace function public.keep_post_counts()
returns trigger language plpgsql set search_path = public as $$
begin
  if pg_trigger_depth() = 1 then
    new.likes := old.likes;
    new.comments := old.comments;
    new.author_id := old.author_id;
    new.created_at := old.created_at;
    if not public.is_admin()
       and new.author_nickname is distinct from old.author_nickname
       and new.author_nickname ~* '(관리자|운영자|운영진|admin|마리캘|my ?research ?calendar)' then
      new.author_nickname := old.author_nickname;
    end if;
  end if;
  return new;
end $$;

-- 너무 긴 글/댓글 차단 (기존 데이터는 검사하지 않음)
alter table public.posts    drop constraint if exists posts_len_chk;
alter table public.posts    add  constraint posts_len_chk
  check (char_length(coalesce(title,'')) <= 200 and char_length(coalesce(content,'')) <= 20000
         and char_length(coalesce(author_nickname,'')) <= 40) not valid;
alter table public.comments drop constraint if exists comments_len_chk;
alter table public.comments add  constraint comments_len_chk
  check (char_length(coalesce(content,'')) <= 3000
         and char_length(coalesce(author_nickname,'')) <= 40) not valid;


-- ── 4. 내부용 함수는 외부에서 직접 부르지 못하게 ───────────────────
-- (트리거로는 계속 정상 동작합니다)
revoke execute on function public.refresh_post_counts()  from public, anon, authenticated;
revoke execute on function public.protect_is_verified()  from public, anon, authenticated;
revoke execute on function public.keep_post_counts()     from public, anon, authenticated;
revoke execute on function public.guard_post_insert()    from public, anon, authenticated;
revoke execute on function public.guard_comment_insert() from public, anon, authenticated;
revoke execute on function public.sync_news()            from public, anon, authenticated;
revoke execute on function public.sync_conferences()     from public, anon, authenticated;

-- 관리자 명단 테이블은 API 로 아예 접근 불가 (is_admin() 함수만 내부에서 읽음)
revoke all on table public.admins from anon, authenticated;


-- ── 5. 확인용: 실행 후 아래 결과가 나오면 정상 ──────────────────
-- verify-docs | false ,  news-images | true
select id, public, file_size_limit from storage.buckets order by id;
