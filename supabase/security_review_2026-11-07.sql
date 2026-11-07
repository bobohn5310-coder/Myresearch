-- ════════════════════════════════════════════════════════════════
-- 🔒 전체 보안 검토(2026-11-07)에서 찾은 문제 고치기
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run 한 번. 여러 번 실행해도 안전합니다.
-- (앞서 만든 SQL 파일들은 이미 실행된 상태라고 보고 작성했어요)
-- ════════════════════════════════════════════════════════════════


-- ── 1) 아이디(이메일) 찾기: 이름만 알아도 남의 가입 여부를 알 수 있던 문제 ──
--    지금은 학교 칸에 '대학' 두 글자만 넣어도 거의 모든 학교와 맞아서,
--    이름만 알면 그 사람이 가입했는지, 어느 메일을 쓰는지(일부)를 알 수 있었어요.
--    이제 학교는 3글자 이상, 가입 때 적은 학교 이름의 '앞부분'과 맞아야 해요.
--    (예: '서울대학교'로 가입 → '서울대' 또는 '서울대학교'는 OK, '대학'·'학교'는 안 됨)
create or replace function public.find_my_email(p_name text, p_school text)
returns setof text
language sql stable security definer set search_path = public as $$
  with q as (
    select btrim(coalesce(p_name, '')) as nm,
           lower(regexp_replace(coalesce(p_school, ''), '\s', '', 'g')) as sc
  )
  select
    left(split_part(u.email, '@', 1), least(2, greatest(length(split_part(u.email, '@', 1)) - 1, 1)))
      || repeat('*', greatest(length(split_part(u.email, '@', 1)) - 2, 2))
      || '@' || split_part(u.email, '@', 2)
  from auth.users u, q
  where char_length(q.nm) >= 2
    and char_length(q.sc) >= 3
    and btrim(u.raw_user_meta_data->>'name') = q.nm
    and starts_with(lower(regexp_replace(coalesce(u.raw_user_meta_data->>'school', ''), '\s', '', 'g')), q.sc)
  order by u.created_at
  limit 3
$$;
revoke all on function public.find_my_email(text, text) from public;
grant execute on function public.find_my_email(text, text) to anon, authenticated;


-- ── 2) 커뮤니티 '공감' 기록: 누가 어떤 글에 공감했는지 누구나 볼 수 있던 문제 ──
--    공감 표에 회원 번호가 같이 있어서, 같은 사람이 공감한 글들을 묶어 볼 수 있었어요.
--    이제 내 공감 기록만 볼 수 있어요. (글마다 공감 수는 지금처럼 보여요)
drop policy if exists "공감 누구나 보기" on public.post_likes;
drop policy if exists "내 공감 보기"   on public.post_likes;
create policy "내 공감 보기" on public.post_likes for select to authenticated
  using (user_id = auth.uid() or public.is_admin());


-- ── 3) 학교 인증 요청: 남의 서류 파일을 내 요청에 붙일 수 있던 문제 ──
--    서류 경로는 반드시 '내 폴더(<내 회원 번호>/...)' 안의 파일이어야 해요.
drop policy if exists "본인 인증요청 등록" on public.verification_requests;
create policy "본인 인증요청 등록" on public.verification_requests
  for insert to authenticated
  with check (auth.uid() = user_id
              and status = 'pending'
              and reviewed_at is null
              and reject_reason is null
              and (doc_url is null or doc_url = '' or starts_with(doc_url, auth.uid()::text || '/')));


-- ── 4) 클로버: 6명이 모이기 전에는 '몇 명이 남겼는지'도 내려보내지 않기 ──
--    화면에서는 숫자를 지웠지만, 서버는 여전히 인원수를 보내고 있었어요.
--    작은 연구실은 "1명이 남겼다" 같은 정보만으로도 누가 남겼는지 짐작될 수 있어요.
create or replace function public.clover_board()
returns table(id bigint, univ text, dept text, name text, topic text, created_at timestamptz,
              cnt integer, pay numeric, guide numeric, mood numeric, balance numeric, total numeric)
language sql stable security definer set search_path = public as $$
  select l.id, l.univ, l.dept,
    case when count(v.user_id) >= 6 then l.name end,
    case when count(v.user_id) >= 6 then l.topic end,
    l.created_at,
    case when count(v.user_id) >= 6 then count(v.user_id)::int end,
    case when count(v.user_id) >= 6 then round(avg(v.pay),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.guide),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.mood),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.balance),1) end,
    case when count(v.user_id) >= 6 then round(avg((v.pay+v.guide+v.mood+v.balance)/4.0),1) end
  from public.clover_labs l left join public.clover_votes v on v.lab_id = l.id
  where not l.hidden
  group by l.id
  order by l.created_at desc
$$;
grant execute on function public.clover_board() to anon, authenticated;

create or replace function public.clover_summary()
returns table(lab_id bigint, cnt integer, pay numeric, guide numeric, mood numeric, balance numeric, total numeric)
language sql stable security definer set search_path = public as $$
  select l.id,
    case when count(v.user_id) >= 6 then count(v.user_id)::int end,
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


-- ── 5) 클로버 신고 도배 막기 ──
--    로그인 없이도 신고할 수 있어서(교수님 삭제 요청용), 신고함을 수천 건으로 채울 수 있었어요.
--    한 연구실에 1시간 10건, 전체 1시간 200건까지만 받아요.
create or replace function public.clover_report(p_lab bigint, p_kind text, p_reason text, p_contact text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.clover_labs where id = p_lab) then
    raise exception 'no lab';
  end if;
  if (select count(*) from public.clover_reports where lab_id = p_lab and created_at > now() - interval '1 hour') >= 10
     or (select count(*) from public.clover_reports where created_at > now() - interval '1 hour') >= 200 then
    raise exception 'too many reports';
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
  select lab_id into lid from public.clover_comments where id = p_comment and not hidden;
  if lid is null then raise exception 'no comment'; end if;
  if (select count(*) from public.clover_reports where comment_id = p_comment and created_at > now() - interval '1 hour') >= 10
     or (select count(*) from public.clover_reports where created_at > now() - interval '1 hour') >= 200 then
    raise exception 'too many reports';
  end if;
  insert into public.clover_reports(lab_id, comment_id, kind, reason, reporter_id)
  values (lid, p_comment, 'report', left(p_reason, 1000), auth.uid());
end $$;
grant execute on function public.clover_report_comment(bigint, text) to anon, authenticated;


-- ── 6) 방문 통계 부풀리기 막기 ──
--    가짜 방문 번호를 마구 보내면 통계가 부풀고 DB가 차요. 하루 2만 명까지만 기록.
create or replace function public.log_visit(p_vid text)
returns void language sql security definer set search_path = public as $$
  insert into public.site_visits(day, vid)
  select (now() at time zone 'Asia/Seoul')::date, p_vid
  where char_length(coalesce(p_vid, '')) between 8 and 64
    and (select count(*) from public.site_visits
          where day = (now() at time zone 'Asia/Seoul')::date) < 20000
  on conflict do nothing
$$;
grant execute on function public.log_visit(text) to anon, authenticated;


-- ── 7) 뉴스 이미지 저장소: 파일 목록 전체를 누구나 훑어볼 수 있던 문제 ──
--    이미지 자체는 지금처럼 공개 주소로 잘 보여요. '목록 조회'만 관리자로 제한.
drop policy if exists "누구나 이미지 조회 1wjj44y_0" on storage.objects;
drop policy if exists "news-images 관리자 목록" on storage.objects;
create policy "news-images 관리자 목록" on storage.objects
  for select to authenticated
  using (bucket_id = 'news-images' and public.is_admin());


-- ── 확인용: 아래 4줄이 모두 true 로 나오면 정상 ──
select 'post_likes 공개 보기 닫힘' as 항목,
       not exists (select 1 from pg_policies where tablename = 'post_likes' and policyname = '공감 누구나 보기') as 결과
union all
select '인증요청 서류 경로 검사',
       exists (select 1 from pg_policies where tablename = 'verification_requests'
                and policyname = '본인 인증요청 등록' and with_check like '%starts_with%')
union all
select '이미지 목록 공개 닫힘',
       not exists (select 1 from pg_policies where schemaname = 'storage' and policyname = '누구나 이미지 조회 1wjj44y_0')
union all
select '아이디 찾기: 학교 두 글자로는 안 찾아짐',
       not exists (select 1 from public.find_my_email('홍길동', '대학'));
