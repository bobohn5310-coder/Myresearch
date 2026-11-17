-- ════════════════════════════════════════════════════════════
--  🕯️ 학교 불빛 지도 (2026-11-17)
--  · 고민을 한 줄 남기면 '내 학교'에 불이 하나 켜진다. 항상 익명.
--  · 학교는 회원이 고르지 않고, 학교 메일 도메인·승인된 학교 인증으로 서버가 정한다
--    (클로버에서 쓰는 clover_my_univs() 재사용).
--  · 글쓴이 번호(user_id)는 표에 있지만 누구도 직접 읽을 수 없다(정책 없음 = 표 직접 접근 불가).
--    화면은 아래 함수들만 부르고, 함수는 글쓴이 정보를 절대 돌려주지 않는다.
--  · 시간도 '오늘/어제/이번 주/지난주/이번 달'처럼 뭉뚱그려 돌려준다.
--  · 관리자 화면 '신고' 탭에 불빛 신고도 같이 나온다.
--  필요 함수: is_admin(), is_suspended(), is_school_member(), clover_my_univs()
--  Supabase SQL Editor 에서 한 번 실행하면 된다. 여러 번 실행해도 괜찮다.
-- ════════════════════════════════════════════════════════════

-- 1) 고민(불빛)
create table if not exists public.school_lights (
  id          bigserial primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  univ        text not null,
  body        text not null check (char_length(btrim(body)) between 5 and 140),
  status      text not null default 'visible' check (status in ('visible','hidden','removed')),
  created_at  timestamptz not null default now()
);
create index if not exists school_lights_univ_time on public.school_lights (univ, created_at desc) where status = 'visible';
create index if not exists school_lights_user_time on public.school_lights (user_id, created_at desc);
alter table public.school_lights enable row level security;
-- 정책을 하나도 만들지 않는다 = 화면에서 표를 직접 읽거나 쓸 수 없음 (함수로만)

-- 2) 공감 (나도 그래요 / 힘내요)
create table if not exists public.school_light_reacts (
  light_id   bigint not null references public.school_lights(id) on delete cascade,
  user_id    uuid   not null default auth.uid() references auth.users(id) on delete cascade,
  kind       text   not null check (kind in ('same','cheer')),
  created_at timestamptz not null default now(),
  primary key (light_id, user_id, kind)
);
alter table public.school_light_reacts enable row level security;

-- 3) 신고
create table if not exists public.school_light_reports (
  id          bigserial primary key,
  light_id    bigint not null references public.school_lights(id) on delete cascade,
  reporter_id uuid   not null default auth.uid() references auth.users(id) on delete cascade,
  reason      text,
  status      text not null default 'pending' check (status in ('pending','dismissed','removed')),
  created_at  timestamptz not null default now(),
  unique (light_id, reporter_id)
);
alter table public.school_light_reports enable row level security;

-- 4) 금지어 (관리자가 추가·삭제)
create table if not exists public.school_light_banned (word text primary key);
alter table public.school_light_banned enable row level security;
drop policy if exists "금지어 관리" on public.school_light_banned;
create policy "금지어 관리" on public.school_light_banned for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
insert into public.school_light_banned(word) values ('시발'),('씨발'),('병신'),('ㅅㅂ'),('ㅂㅅ'),('개새끼'),('좆')
on conflict do nothing;

-- 뭉뚱그린 시간
create or replace function public.school_light_when(t timestamptz)
returns text language sql stable set search_path = public as $$
  select case
    when (t at time zone 'Asia/Seoul')::date = (now() at time zone 'Asia/Seoul')::date then '오늘'
    when (t at time zone 'Asia/Seoul')::date = (now() at time zone 'Asia/Seoul')::date - 1 then '어제'
    when t > now() - interval '7 days' then '이번 주'
    when t > now() - interval '14 days' then '지난주'
    else '이번 달' end
$$;

-- 5) 지도: 학교별 최근 30일 불빛 수 (로그인 없이도 볼 수 있음)
create or replace function public.school_light_map()
returns table (univ text, cnt int, today int)
language sql stable security definer set search_path = public as $$
  select l.univ, count(*)::int,
         count(*) filter (where (l.created_at at time zone 'Asia/Seoul')::date = (now() at time zone 'Asia/Seoul')::date)::int
    from public.school_lights l
   where l.status = 'visible' and l.created_at > now() - interval '30 days'
   group by l.univ
$$;
grant execute on function public.school_light_map() to anon, authenticated;

-- 6) 한 학교의 고민 목록 (글쓴이 정보 없음)
create or replace function public.school_light_list(p_univ text, p_sort text default 'new', p_limit int default 30, p_before bigint default null)
returns table (id bigint, body text, at_label text, same_cnt int, cheer_cnt int, i_same boolean, i_cheer boolean, mine boolean)
language sql stable security definer set search_path = public as $$
  select l.id, l.body, public.school_light_when(l.created_at),
         (select count(*) from public.school_light_reacts r where r.light_id = l.id and r.kind = 'same')::int,
         (select count(*) from public.school_light_reacts r where r.light_id = l.id and r.kind = 'cheer')::int,
         exists(select 1 from public.school_light_reacts r where r.light_id = l.id and r.kind = 'same'  and r.user_id = auth.uid()),
         exists(select 1 from public.school_light_reacts r where r.light_id = l.id and r.kind = 'cheer' and r.user_id = auth.uid()),
         (auth.uid() is not null and l.user_id = auth.uid())
    from public.school_lights l
   where l.status = 'visible' and l.univ = p_univ
     and l.created_at > now() - interval '30 days'
     and (p_before is null or l.id < p_before)
   order by case when p_sort = 'hot' then (select count(*) from public.school_light_reacts r where r.light_id = l.id) end desc nulls last,
            l.id desc
   limit least(coalesce(p_limit, 30), 50)
$$;
grant execute on function public.school_light_list(text, text, int, bigint) to anon, authenticated;

-- 7) 불 켜기 (고민 남기기)
create or replace function public.school_light_add(p_body text)
returns text language plpgsql security definer set search_path = public as $$
declare
  b text := btrim(regexp_replace(coalesce(p_body,''), '\s+', ' ', 'g'));
  u text;
  today date := (now() at time zone 'Asia/Seoul')::date;
begin
  if auth.uid() is null then raise exception 'login required'; end if;
  if public.is_suspended() then raise exception 'suspended'; end if;
  if not public.is_school_member() then raise exception 'school only'; end if;
  u := (public.clover_my_univs())[1];
  if u is null or u = '' then raise exception 'no school'; end if;
  if char_length(b) < 5 or char_length(b) > 140 then raise exception 'length'; end if;
  if exists (select 1 from public.school_light_banned w where position(w.word in regexp_replace(b, '\s', '', 'g')) > 0)
    then raise exception 'bad word'; end if;
  -- 도배 방지: 하루 3개, 1분에 1개, 같은 글 다시 못 올림
  if (select count(*) from public.school_lights l where l.user_id = auth.uid()
        and (l.created_at at time zone 'Asia/Seoul')::date = today) >= 3 then raise exception 'daily limit'; end if;
  if exists (select 1 from public.school_lights l where l.user_id = auth.uid() and l.created_at > now() - interval '60 seconds')
    then raise exception 'too fast'; end if;
  if exists (select 1 from public.school_lights l where l.user_id = auth.uid() and l.body = b and l.created_at > now() - interval '30 days')
    then raise exception 'duplicate'; end if;
  insert into public.school_lights(user_id, univ, body) values (auth.uid(), u, b);
  return u;
end $$;
revoke all on function public.school_light_add(text) from public, anon;
grant execute on function public.school_light_add(text) to authenticated;

-- 8) 공감 누르기/취소 (학교 회원만, 다른 학교 고민에도 가능)
create or replace function public.school_light_react(p_id bigint, p_kind text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if not public.is_school_member() then raise exception 'school only'; end if;
  if p_kind not in ('same','cheer') then raise exception 'kind'; end if;
  if exists (select 1 from public.school_light_reacts where light_id = p_id and user_id = auth.uid() and kind = p_kind) then
    delete from public.school_light_reacts where light_id = p_id and user_id = auth.uid() and kind = p_kind;
    return false;
  end if;
  insert into public.school_light_reacts(light_id, user_id, kind)
    select p_id, auth.uid(), p_kind where exists (select 1 from public.school_lights where id = p_id and status = 'visible');
  return true;
end $$;
revoke all on function public.school_light_react(bigint, text) from public, anon;
grant execute on function public.school_light_react(bigint, text) to authenticated;

-- 9) 신고: 3명이 신고하면 바로 가려지고 관리자 확인 대기
create or replace function public.school_light_report(p_id bigint, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'login required'; end if;
  insert into public.school_light_reports(light_id, reporter_id, reason)
    values (p_id, auth.uid(), left(p_reason, 200)) on conflict do nothing;
  if (select count(*) from public.school_light_reports where light_id = p_id and status = 'pending') >= 3 then
    update public.school_lights set status = 'hidden' where id = p_id and status = 'visible';
  end if;
end $$;
revoke all on function public.school_light_report(bigint, text) from public, anon;
grant execute on function public.school_light_report(bigint, text) to authenticated;

-- 10) 내 고민 지우기 (관리자는 모두)
create or replace function public.school_light_delete(p_id bigint)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.school_lights set status = 'removed'
   where id = p_id and (user_id = auth.uid() or public.is_admin());
  if not found then raise exception 'not allowed'; end if;
end $$;
revoke all on function public.school_light_delete(bigint) from public, anon;
grant execute on function public.school_light_delete(bigint) to authenticated;

-- 10-1) 내가 남긴 고민 (모든 학교, 가려진 것도 보임)
create or replace function public.school_light_mine()
returns table (id bigint, univ text, body text, at_label text, same_cnt int, cheer_cnt int, hidden boolean)
language sql stable security definer set search_path = public as $$
  select l.id, l.univ, l.body, public.school_light_when(l.created_at),
         (select count(*) from public.school_light_reacts r where r.light_id = l.id and r.kind = 'same')::int,
         (select count(*) from public.school_light_reacts r where r.light_id = l.id and r.kind = 'cheer')::int,
         l.status = 'hidden'
    from public.school_lights l
   where l.user_id = auth.uid() and l.status <> 'removed'
   order by l.id desc limit 50
$$;
revoke all on function public.school_light_mine() from public, anon;
grant execute on function public.school_light_mine() to authenticated;

-- 11) 관리자 신고함: 기존 신고(클로버·커뮤니티·학회 후기)에 불빛 고민 신고를 더한다
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
  union all
  select 'light'::text, r.id, '불빛 고민'::text,
         l.univ::text, l.body::text, r.reason, null::text,
         r.status, r.created_at, r.light_id
  from public.school_light_reports r
  join public.school_lights l on l.id = r.light_id
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
  elsif p_src = 'light' then
    select * into r from public.school_light_reports where id = p_id;
    if not found then raise exception 'no report'; end if;
    -- 고민은 지우지 않고 상태만 바꿈 (문제 없음 → 다시 보이기)
    update public.school_lights set status = case when p_action = 'remove' then 'removed' else 'visible' end
     where id = r.light_id;
    update public.school_light_reports set status = case when p_action = 'remove' then 'removed' else 'dismissed' end
     where light_id = r.light_id and status = 'pending';
  else
    raise exception 'bad source';
  end if;
end $$;
revoke all on function public.admin_resolve_report(text, bigint, text) from public, anon;
grant execute on function public.admin_resolve_report(text, bigint, text) to authenticated;
