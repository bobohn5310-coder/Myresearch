-- ════════════════════════════════════════════════
-- 🔧 전체 점검(2026-11-06)에서 찾은 문제 고치기
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
-- ════════════════════════════════════════════════

-- 1) '내 캘린더 → 프로필 수정'이 항상 "저장 실패"가 나던 문제
--    화면은 닉네임·소속·전공·과정·관심 키워드를 저장하는데, profiles 표에 그 칸이 없었어요.
alter table public.profiles add column if not exists nickname    text check (char_length(nickname) <= 40);
alter table public.profiles add column if not exists institution text check (char_length(institution) <= 80);
alter table public.profiles add column if not exists major       text check (char_length(major) <= 80);
alter table public.profiles add column if not exists degree      text check (char_length(degree) <= 20);
alter table public.profiles add column if not exists keywords    text[];
alter table public.profiles add column if not exists updated_at  timestamptz;

-- 2) 관리자 '탈퇴 처리'가 글을 쓴 회원에게는 실패하던 문제
--    글을 '탈퇴한 회원'으로 바꿀 때, 글쓴이를 못 바꾸게 막는 장치가 관리자 작업까지 막고 있었어요.
--    (관리자만 예외. 일반 회원은 지금처럼 글쓴이·공감 수·댓글 수·작성 시간을 못 바꿉니다)
create or replace function public.keep_post_counts()
returns trigger language plpgsql set search_path = public as $$
begin
  if pg_trigger_depth() = 1 then
    new.likes := old.likes;
    new.comments := old.comments;
    new.created_at := old.created_at;
    if not public.is_admin() then
      new.author_id := old.author_id;
      if new.author_nickname is distinct from old.author_nickname
         and new.author_nickname ~* '(관리자|운영자|운영진|admin|마리캘|my ?research ?calendar)' then
        new.author_nickname := old.author_nickname;
      end if;
    end if;
  end if;
  return new;
end $$;
revoke execute on function public.keep_post_counts() from public, anon, authenticated;

-- 3) 예전 '연구실 등록' 방법 닫기 (교수님 성함 없이 등록되는 길)
--    지금 화면은 교수님 성함을 받는 새 방법만 씁니다.
drop function if exists public.clover_add_lab(text, text, text, text);
revoke execute on function public.clover_add_lab(text, text, text, text, text) from public, anon;
grant  execute on function public.clover_add_lab(text, text, text, text, text) to authenticated;
drop policy if exists "연구실 등록" on public.clover_labs;   -- 표에 직접 넣는 길도 닫음 (위 함수로만 등록)

-- 4) 정지된 회원은 글 수정·공감도 못 하게
drop policy if exists "본인 글 수정" on public.posts;
create policy "본인 글 수정" on public.posts for update
  using (auth.uid() = author_id) with check (auth.uid() = author_id and not public.is_suspended());
drop policy if exists "공감 본인만 누르기" on public.post_likes;
create policy "공감 본인만 누르기" on public.post_likes for insert to authenticated
  with check (user_id = auth.uid() and not public.is_suspended());

-- 5) 내부용(트리거) 함수는 외부에서 부르지 못하게 정리 (보안 점검 경고 줄이기)
revoke execute on function public.guard_is_verified()           from public, anon, authenticated;
revoke execute on function public.guard_member_type()           from public, anon, authenticated;
revoke execute on function public.guard_suspension()            from public, anon, authenticated;
revoke execute on function public.handle_new_user_member_type() from public, anon, authenticated;
revoke execute on function public.clover_comment_guard()        from public, anon, authenticated;

-- 확인용: 아래가 6개 칸 이름을 보여 주면 정상
select column_name from information_schema.columns
 where table_schema = 'public' and table_name = 'profiles'
   and column_name in ('nickname','institution','major','degree','keywords','updated_at');
