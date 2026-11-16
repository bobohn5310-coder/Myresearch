-- ════════════════════════════════════════════════════════════
--  보안 규칙(RLS) 속도 개선 (2026-11-16)
--  · 보안 규칙 안의 auth.uid(), is_admin(), is_suspended(), can_clover(), is_school_member() 를
--    (select ...) 로 감싸서, 줄마다 다시 계산하지 않고 요청마다 한 번만 계산하게 한다.
--    (Supabase 성능 점검 'auth_rls_initplan' 34곳 + 같은 원리의 관리자·학교 회원 확인)
--  · 누가 무엇을 보고 쓸 수 있는지는 그대로다. 규칙의 이름·대상·종류(읽기/쓰기)는 건드리지 않고
--    조건식만 같은 뜻으로 다시 쓴다.
--  · 자주 찾는 칸(작성자·회원 번호 등)에 빠진 색인(index)을 더한다.
--  Supabase SQL Editor 에서 한 번 실행하면 된다. 여러 번 실행해도 괜찮다.
--  규칙이 없으면(이름이 바뀐 경우) 건너뛰고 알림만 남긴다.
-- ════════════════════════════════════════════════════════════

begin;

create or replace function pg_temp.fix_policy(t text, n text, body text) returns void
language plpgsql as $f$
begin
  if exists (select 1 from pg_policies where schemaname = 'public' and tablename = t and policyname = n) then
    execute format('alter policy %I on public.%I ', n, t) || body;
  else
    raise notice '규칙 없음, 건너뜀: %.%', t, n;
  end if;
end $f$;

do $$
begin
  perform pg_temp.fix_policy('attendance', '내 출석 보기', $p$using (((user_id = (select auth.uid())) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('clover_comments', '내 한줄평 보기', $p$using (((user_id = (select auth.uid())) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('clover_comments', '내 한줄평 지우기', $p$using (((user_id = (select auth.uid())) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('clover_comments', '한줄평 남기기', $p$with check (((user_id = (select auth.uid())) AND (hidden = false) AND (select public.can_clover()) AND (EXISTS ( SELECT 1 FROM clover_votes v WHERE ((v.lab_id = clover_comments.lab_id) AND (v.user_id = (select auth.uid())))))))$p$);
  perform pg_temp.fix_policy('clover_members', '내 연구실 보기', $p$using (((user_id = (select auth.uid())) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('clover_votes', '내 클로버 보기', $p$using ((user_id = (select auth.uid())))$p$);
  perform pg_temp.fix_policy('clover_votes', '내 클로버 수정', $p$using ((user_id = (select auth.uid()))) with check (((user_id = (select auth.uid())) AND (select public.can_clover())))$p$);
  perform pg_temp.fix_policy('clover_votes', '내 클로버 취소', $p$using ((user_id = (select auth.uid())))$p$);
  perform pg_temp.fix_policy('clover_votes', '클로버 남기기', $p$with check (((user_id = (select auth.uid())) AND (select public.can_clover()) AND clover_lab_open(lab_id)))$p$);
  perform pg_temp.fix_policy('comments', '로그인 유저 작성', $p$with check (((author_id = (select auth.uid())) AND (NOT (select public.is_suspended()))))$p$);
  perform pg_temp.fix_policy('comments', '본인 댓글 삭제', $p$using ((((select auth.uid()) = author_id) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('conf_reviews', '내 학회 후기 보기', $p$using (((user_id = (select auth.uid())) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('conf_reviews', '내 학회 후기 지우기', $p$using (((user_id = (select auth.uid())) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('conf_reviews', '학회 후기 남기기', $p$with check (((user_id = (select auth.uid())) AND (hidden = false) AND (status = 'pending'::text) AND (select public.can_clover()) AND (proof_path IS NOT NULL) AND (split_part(proof_path, '/'::text, 1) = ((select auth.uid()))::text) AND (conf_year <= (EXTRACT(year FROM now()))::integer)))$p$);
  perform pg_temp.fix_policy('conference_suggestions', 'suggest insert', $p$with check (((status = 'pending'::text) AND (user_id = (select auth.uid()))))$p$);
  perform pg_temp.fix_policy('conferences', '본인만', $p$using (((select auth.uid()) = user_id)) with check (((select auth.uid()) = user_id))$p$);
  perform pg_temp.fix_policy('cv_items', 'cv_items 본인만', $p$using (((select auth.uid()) = user_id)) with check (((select auth.uid()) = user_id))$p$);
  perform pg_temp.fix_policy('cv_profile', 'cv_profile 본인만', $p$using (((select auth.uid()) = user_id)) with check (((select auth.uid()) = user_id))$p$);
  perform pg_temp.fix_policy('papers', '본인만', $p$using (((select auth.uid()) = user_id)) with check (((select auth.uid()) = user_id))$p$);
  perform pg_temp.fix_policy('post_likes', '공감 본인만 누르기', $p$with check (((user_id = (select auth.uid())) AND (NOT (select public.is_suspended()))))$p$);
  perform pg_temp.fix_policy('post_likes', '공감 본인만 취소', $p$using ((user_id = (select auth.uid())))$p$);
  perform pg_temp.fix_policy('post_likes', '내 공감 보기', $p$using (((user_id = (select auth.uid())) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('post_reports', '신고하기', $p$with check (((reporter_id = (select auth.uid())) AND (status = 'pending'::text)))$p$);
  perform pg_temp.fix_policy('posts', '로그인 유저 작성', $p$with check (((author_id = (select auth.uid())) AND (NOT (select public.is_suspended()))))$p$);
  perform pg_temp.fix_policy('posts', '본인 글 삭제', $p$using ((((select auth.uid()) = author_id) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('posts', '본인 글 수정', $p$using (((select auth.uid()) = author_id)) with check ((((select auth.uid()) = author_id) AND (NOT (select public.is_suspended()))))$p$);
  perform pg_temp.fix_policy('profiles', '본인 프로필 쓰기', $p$with check (((select auth.uid()) = id))$p$);
  perform pg_temp.fix_policy('profiles', '본인 프로필 업데이트', $p$using (((select auth.uid()) = id))$p$);
  perform pg_temp.fix_policy('profiles', '본인 프로필 읽기', $p$using (((select auth.uid()) = id))$p$);
  perform pg_temp.fix_policy('projects', '본인만', $p$using (((select auth.uid()) = user_id)) with check (((select auth.uid()) = user_id))$p$);
  perform pg_temp.fix_policy('schedules', '본인만', $p$using (((select auth.uid()) = user_id))$p$);
  perform pg_temp.fix_policy('verification_requests', '본인 인증요청 등록', $p$with check ((((select auth.uid()) = user_id) AND (status = 'pending'::text) AND (reviewed_at IS NULL) AND (reject_reason IS NULL) AND ((doc_url IS NULL) OR (doc_url = ''::text) OR starts_with(doc_url, (((select auth.uid()))::text || '/'::text)))))$p$);
  perform pg_temp.fix_policy('verification_requests', '본인 인증요청 읽기', $p$using (((select auth.uid()) = user_id))$p$);
  perform pg_temp.fix_policy('withdraw_requests', '내 탈퇴 요청', $p$using (((user_id = (select auth.uid())) OR (select public.is_admin()))) with check (((user_id = (select auth.uid())) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('academic_info', '관리자만 쓰기', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('attendance_events', '출석 이벤트 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('banners', '관리자만 쓰기', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('clover_comments', '한줄평 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('clover_lab_papers', '논문 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('clover_lab_projects', '과제 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('clover_labs', '연구실 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('clover_labs', '연구실 보기', $p$using ((((NOT hidden) AND clover_lab_public(id)) OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('clover_reports', '신고 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('clover_univ_domains', '도메인 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('conf_review_reports', '학회 후기 신고 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('conf_reviews', '학회 후기 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('conference_suggestions', 'suggest admin all', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('news', '관리자만 쓰기', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('notices', '공지 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('notices', '공지 보기', $p$using ((is_active OR (select public.is_admin())))$p$);
  perform pg_temp.fix_policy('post_reports', '신고 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('profiles', '관리자 프로필 관리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('verification_requests', '관리자 읽기', $p$using ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('verification_requests', '관리자 처리', $p$using ((select public.is_admin())) with check ((select public.is_admin()))$p$);
  perform pg_temp.fix_policy('comments', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('comments', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('conference_suggestions', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('conference_suggestions', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('conferences', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('conferences', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('cv_items', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('cv_items', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('cv_profile', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('cv_profile', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('papers', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('papers', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('post_likes', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('post_likes', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('posts', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('posts', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('projects', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('projects', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('schedules', '학교 회원만 수정', $p$using ((select public.is_school_member()))$p$);
  perform pg_temp.fix_policy('schedules', '학교 회원만 추가', $p$with check ((select public.is_school_member()))$p$);
end $$;

-- 빠진 색인
create index if not exists attendance_user_id_idx on public.attendance (user_id);
create index if not exists clover_comments_user_id_idx on public.clover_comments (user_id);
create index if not exists clover_lab_projects_lab_id_idx on public.clover_lab_projects (lab_id);
create index if not exists clover_labs_created_by_idx on public.clover_labs (created_by);
create index if not exists clover_members_lab_id_idx on public.clover_members (lab_id);
create index if not exists clover_reports_comment_id_idx on public.clover_reports (comment_id);
create index if not exists clover_reports_lab_id_idx on public.clover_reports (lab_id);
create index if not exists clover_votes_user_id_idx on public.clover_votes (user_id);
create index if not exists comments_author_id_idx on public.comments (author_id);
create index if not exists comments_post_id_idx on public.comments (post_id);
create index if not exists conf_review_reports_review_id_idx on public.conf_review_reports (review_id);
create index if not exists conf_reviews_user_id_idx on public.conf_reviews (user_id);
create index if not exists conference_suggestions_user_id_idx on public.conference_suggestions (user_id);
create index if not exists conferences_user_id_idx on public.conferences (user_id);
create index if not exists papers_user_id_idx on public.papers (user_id);
create index if not exists post_likes_user_id_idx on public.post_likes (user_id);
create index if not exists post_reports_comment_id_idx on public.post_reports (comment_id);
create index if not exists post_reports_post_id_idx on public.post_reports (post_id);
create index if not exists posts_author_id_idx on public.posts (author_id);
create index if not exists projects_user_id_idx on public.projects (user_id);
create index if not exists schedules_user_id_idx on public.schedules (user_id);

commit;

-- 확인: 아래가 0 이면 줄마다 다시 계산하는 규칙이 남지 않은 것
select count(*) as 남은_느린_규칙
from pg_policies
where schemaname = 'public'
  and (coalesce(qual,'') || ' ' || coalesce(with_check,'')) ~ '(?<!SELECT )auth\.uid\(\)';
