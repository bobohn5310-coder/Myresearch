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

-- 6) 익명 글·댓글의 글쓴이를 누구도 알아낼 수 없게
--    지금까지는 글마다 글쓴이 번호(author_id)가 누구에게나 내려가서, 익명 글끼리 같은 사람인지 묶어 볼 수 있었어요.
--    이제 그 칸은 직접 읽을 수 없고, 화면에는 '내 글인지 / 글쓴이 댓글인지 / 익명 몇 번인지'만 알려 줍니다.
revoke select on public.posts    from anon, authenticated;
revoke select on public.comments from anon, authenticated;
grant select (id, category, field, title, content, likes, comments, is_anonymous, author_nickname, created_at)
  on public.posts to anon, authenticated;
grant select (id, post_id, content, is_anonymous, author_nickname, created_at)
  on public.comments to anon, authenticated;

-- 도배 방지 장치가 글쓴이 칸을 읽을 수 있게 (서버 내부 권한으로 실행)
alter function public.guard_post_insert()    security definer;
alter function public.guard_comment_insert() security definer;

-- 내가 쓴 글 번호들 (삭제 버튼·신고 버튼 표시용)
create or replace function public.my_post_ids()
returns setof bigint language sql stable security definer set search_path = public as $$
  select id from public.posts where auth.uid() is not null and author_id = auth.uid()
$$;
revoke all on function public.my_post_ids() from public;
grant execute on function public.my_post_ids() to anon, authenticated;

-- 글 하나의 댓글: 글쓴이 번호 대신 is_mine(내 댓글) · is_op(글쓴이 댓글) · anon_no(익명 번호)
create or replace function public.post_comments(p_post bigint)
returns table (id bigint, post_id bigint, content text, is_anonymous boolean, author_nickname text,
               created_at timestamptz, is_mine boolean, is_op boolean, anon_no int)
language sql stable security definer set search_path = public as $$
  with c as (
    select c.*, (c.author_id is not null and c.author_id = p.author_id) as op
    from public.comments c join public.posts p on p.id = c.post_id
    where c.post_id = p_post
  ), firsts as (
    select coalesce(author_id::text, 'x' || id) as k, min(created_at) as first_at
    from c where is_anonymous and not op group by 1
  ), nums as (
    select k, row_number() over (order by first_at)::int as n from firsts
  )
  select c.id, c.post_id, c.content, c.is_anonymous, c.author_nickname, c.created_at,
         (auth.uid() is not null and c.author_id = auth.uid()),
         c.op,
         case when c.is_anonymous and not c.op then (select n from nums where nums.k = coalesce(c.author_id::text, 'x' || c.id)) end
  from c order by c.created_at, c.id
$$;
revoke all on function public.post_comments(bigint) from public;
grant execute on function public.post_comments(bigint) to anon, authenticated;

-- 7) 신고해도 바로 가리지 않기: 운영자가 신고함에서 '삭제'를 누를 때만 가려짐
create or replace function public.clover_report(p_lab bigint, p_kind text, p_reason text, p_contact text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.clover_labs where id = p_lab) then
    raise exception 'no lab';
  end if;
  insert into public.clover_reports(lab_id, kind, reason, contact, reporter_id)
  values (p_lab, case when p_kind = 'delete' then 'delete' else 'report' end,
          left(p_reason, 1000), left(p_contact, 120), auth.uid());
end $$;
grant execute on function public.clover_report(bigint, text, text, text) to anon, authenticated;

create or replace function public.clover_report_comment(p_comment bigint, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare lid bigint;
begin
  select lab_id into lid from public.clover_comments where id = p_comment;
  if lid is null then raise exception 'no comment'; end if;
  insert into public.clover_reports(lab_id, comment_id, kind, reason, reporter_id)
  values (lid, p_comment, 'report', left(p_reason, 1000), auth.uid());
end $$;
grant execute on function public.clover_report_comment(bigint, text) to anon, authenticated;

-- 확인용: 아래가 6개 칸 이름을 보여 주면 정상
select column_name from information_schema.columns
 where table_schema = 'public' and table_name = 'profiles'
   and column_name in ('nickname','institution','major','degree','keywords','updated_at');
