-- ════════════════════════════════════════════════
-- 💬 학회 한 줄 후기: 👍/👎 + 한 줄(80자)
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
--
--  · 학회는 해마다 따로 저장되고 끝나면 지워지므로, 후기는 '학회 이름표'(series_key)에 붙인다.
--    이름표 = 학회 이름에서 연도·회차를 뺀 것 (예: AAAI 2027 → aaai). 화면(index.html)이 만들어 보냄.
--  · 로그인한 사람만, 한 학회 이름표 · 한 해에 한 사람당 하나
--  · 공개 목록에는 작성자를 내보내지 않음 (익명)
--  · 욕설·연락처가 들어간 한 줄은 저장 단계에서 거절
--  · 신고가 들어온 후기는 즉시 가려지고 관리자 신고함에서 검토
-- ════════════════════════════════════════════════

-- 1) 후기
create table if not exists public.conf_reviews (
  id         bigint generated always as identity primary key,
  series_key text    not null check (char_length(series_key) between 1 and 120),
  conf_year  int     not null check (conf_year between 2000 and 2100),
  conf_name  text    check (char_length(conf_name) <= 200),
  user_id    uuid    not null references auth.users(id) on delete cascade default auth.uid(),
  good       boolean not null,
  body       text    not null check (char_length(btrim(body)) between 2 and 80),
  hidden     boolean not null default false,
  created_at timestamptz not null default now(),
  unique (series_key, conf_year, user_id)
);
create index if not exists conf_reviews_series_idx on public.conf_reviews (series_key);
alter table public.conf_reviews enable row level security;

drop policy if exists "내 학회 후기 보기" on public.conf_reviews;
create policy "내 학회 후기 보기" on public.conf_reviews for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists "학회 후기 남기기" on public.conf_reviews;
create policy "학회 후기 남기기" on public.conf_reviews for insert to authenticated
  with check (user_id = auth.uid() and hidden = false
              and conf_year <= extract(year from now())::int);
drop policy if exists "내 학회 후기 지우기" on public.conf_reviews;
create policy "내 학회 후기 지우기" on public.conf_reviews for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists "학회 후기 관리" on public.conf_reviews;
create policy "학회 후기 관리" on public.conf_reviews for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 2) 욕설·연락처 거르기
create or replace function public.conf_review_guard()
returns trigger language plpgsql set search_path = public as $$
declare t text := lower(regexp_replace(new.body, '[\s\.\-_*~!]', '', 'g'));
begin
  new.body := btrim(new.body);
  if t ~ '(씨발|시발|ㅅㅂ|ㅆㅂ|씨바|시바|병신|ㅂㅅ|븅신|개새|개색|개세|좆|존나|졸라|미친|ㅁㅊ|지랄|ㅈㄹ|꺼져|닥쳐|죽어|뒤져|썅|쌍놈|년놈|새끼|fuck|shit)' then
    raise exception 'bad word';
  end if;
  if new.body ~ '(\d{2,3}[-\s]?\d{3,4}[-\s]?\d{4}|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|https?://)' then
    raise exception 'contact info';
  end if;
  return new;
end $$;
drop trigger if exists conf_review_guard on public.conf_reviews;
create trigger conf_review_guard before insert or update of body on public.conf_reviews
  for each row execute function public.conf_review_guard();

-- 3) 공개용 목록: 작성자 없이 (내 글인지만 알려 줌)
create or replace function public.conf_reviews_public()
returns table (id bigint, series_key text, conf_year int, good boolean, body text, created_at timestamptz, mine boolean)
language sql stable security definer set search_path = public as $$
  select r.id, r.series_key, r.conf_year, r.good, r.body, r.created_at,
         coalesce(r.user_id = auth.uid(), false)
  from public.conf_reviews r
  where not r.hidden
  order by r.series_key, r.conf_year desc, r.created_at desc
$$;
grant execute on function public.conf_reviews_public() to anon, authenticated;

-- 4) 신고 → 즉시 가림
create table if not exists public.conf_review_reports (
  id          bigint generated always as identity primary key,
  review_id   bigint not null references public.conf_reviews(id) on delete cascade,
  reason      text check (char_length(reason) <= 500),
  reporter_id uuid default auth.uid(),
  status      text not null default 'pending' check (status in ('pending','dismissed','removed')),
  created_at  timestamptz not null default now()
);
alter table public.conf_review_reports enable row level security;
drop policy if exists "학회 후기 신고 관리" on public.conf_review_reports;
create policy "학회 후기 신고 관리" on public.conf_review_reports for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create or replace function public.conf_review_report(p_review bigint, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'login required'; end if;
  if not exists (select 1 from public.conf_reviews where id = p_review) then raise exception 'no review'; end if;
  if exists (select 1 from public.conf_review_reports where review_id = p_review and reporter_id = auth.uid()) then return; end if;
  insert into public.conf_review_reports(review_id, reason, reporter_id)
  values (p_review, left(p_reason, 500), auth.uid());
  update public.conf_reviews set hidden = true where id = p_review;
end $$;
revoke all on function public.conf_review_report(bigint, text) from public, anon;
grant execute on function public.conf_review_report(bigint, text) to authenticated;

-- 5) 관리자 신고함에 학회 후기도 함께 (admin_tools.sql 의 두 함수를 학회 후기까지 넓힌 것)
create or replace function public.admin_reports(p_status text default 'pending')
returns table (src text, id bigint, kind text, target text, detail text, reason text, contact text,
               status text, created_at timestamptz, ref_id bigint)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select 'clover'::text, r.id,
         case when r.comment_id is not null then '한줄평' when r.kind = 'delete' then '연구실 삭제 요청' else '연구실 신고' end,
         (l.univ || ' ' || l.dept || ' · ' || coalesce(l.name, ''))::text,
         c.body::text, r.reason, r.contact,
         case r.status when 'restored' then 'dismissed' else r.status end,
         r.created_at, coalesce(r.comment_id, r.lab_id)
  from public.clover_reports r
  left join public.clover_labs l on l.id = r.lab_id
  left join public.clover_comments c on c.id = r.comment_id
  where p_status = 'all' or (case r.status when 'restored' then 'dismissed' else r.status end) = p_status
  union all
  select 'community'::text, r.id,
         case when r.comment_id is not null then '댓글' else '게시글' end,
         coalesce(p.title, (select p2.title from public.posts p2 join public.comments c2 on c2.post_id = p2.id where c2.id = r.comment_id))::text,
         coalesce(cm.content, left(p.content, 300))::text, r.reason, null::text,
         r.status, r.created_at, coalesce(r.comment_id, r.post_id)
  from public.post_reports r
  left join public.posts p on p.id = r.post_id
  left join public.comments cm on cm.id = r.comment_id
  where p_status = 'all' or r.status = p_status
  union all
  select 'conf'::text, r.id, '학회 후기'::text,
         (coalesce(v.conf_name, v.series_key) || ' · ' || v.conf_year || '년')::text,
         ((case when v.good then '👍 ' else '👎 ' end) || v.body)::text, r.reason, null::text,
         r.status, r.created_at, r.review_id
  from public.conf_review_reports r
  join public.conf_reviews v on v.id = r.review_id
  where p_status = 'all' or r.status = p_status
  order by 9 desc;
end $$;
revoke all on function public.admin_reports(text) from public, anon;
grant execute on function public.admin_reports(text) to authenticated;

create or replace function public.admin_resolve_report(p_src text, p_id bigint, p_action text)
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  if p_action not in ('restore','remove') then raise exception 'bad action'; end if;
  if p_src = 'clover' then
    select * into r from public.clover_reports where id = p_id;
    if not found then raise exception 'no report'; end if;
    if r.comment_id is not null then
      update public.clover_comments set hidden = (p_action = 'remove') where id = r.comment_id;
      update public.clover_reports set status = case when p_action = 'remove' then 'removed' else 'restored' end
       where comment_id = r.comment_id and status = 'pending';
    else
      -- 연구실은 지우지 않고 가려 둠 (나중에 되살릴 수 있게)
      update public.clover_labs set hidden = (p_action = 'remove') where id = r.lab_id;
      update public.clover_reports set status = case when p_action = 'remove' then 'removed' else 'restored' end
       where lab_id = r.lab_id and comment_id is null and status = 'pending';
    end if;
  elsif p_src = 'community' then
    select * into r from public.post_reports where id = p_id;
    if not found then raise exception 'no report'; end if;
    if p_action = 'restore' then
      update public.post_reports set status = 'dismissed'
       where status = 'pending' and coalesce(post_id,0) = coalesce(r.post_id,0) and coalesce(comment_id,0) = coalesce(r.comment_id,0);
    else
      update public.post_reports set status = 'removed'
       where status = 'pending' and coalesce(post_id,0) = coalesce(r.post_id,0) and coalesce(comment_id,0) = coalesce(r.comment_id,0);
      if r.comment_id is not null then delete from public.comments where id = r.comment_id;
      else delete from public.posts where id = r.post_id; end if;
    end if;
  elsif p_src = 'conf' then
    select * into r from public.conf_review_reports where id = p_id;
    if not found then raise exception 'no report'; end if;
    -- 후기는 지우지 않고 가려 둠 (나중에 되살릴 수 있게)
    update public.conf_reviews set hidden = (p_action = 'remove') where id = r.review_id;
    update public.conf_review_reports set status = case when p_action = 'remove' then 'removed' else 'dismissed' end
     where review_id = r.review_id and status = 'pending';
  else
    raise exception 'bad source';
  end if;
end $$;
revoke all on function public.admin_resolve_report(text, bigint, text) from public, anon;
grant execute on function public.admin_resolve_report(text, bigint, text) to authenticated;
