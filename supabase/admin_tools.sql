-- ════════════════════════════════════════════════
-- 🛠 관리자 도구: 신고함 · 회원 관리(정지/탈퇴/유형) · 클로버 현황 · 공지사항 · 통계
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
-- (member_type.sql, clover_comments.sql, admin_members.sql 을 먼저 실행한 상태여야 해요)
--
-- 관리자 전용 함수는 모두 처음에 is_admin() 을 확인하고, 관리자가 아니면 오류를 냅니다.
-- ════════════════════════════════════════════════


-- ───────── 1) 회원 정지 ─────────
alter table public.profiles add column if not exists suspended_until timestamptz;
alter table public.profiles add column if not exists suspend_reason text;

-- 회원이 스스로 정지를 풀 수 없게
create or replace function public.guard_suspension()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() or auth.uid() is null then return new; end if;
  if tg_op = 'INSERT' then
    new.suspended_until := null; new.suspend_reason := null;
  else
    new.suspended_until := old.suspended_until; new.suspend_reason := old.suspend_reason;
  end if;
  return new;
end $$;
drop trigger if exists guard_suspension on public.profiles;
create trigger guard_suspension before insert or update on public.profiles
  for each row execute function public.guard_suspension();

create or replace function public.is_suspended()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles p
                  where p.id = auth.uid() and p.suspended_until is not null and p.suspended_until > now())
$$;
grant execute on function public.is_suspended() to anon, authenticated;

-- 정지된 회원은 글·댓글·클로버를 남길 수 없음
drop policy if exists "로그인 유저 작성" on public.posts;
create policy "로그인 유저 작성" on public.posts for insert to authenticated
  with check (author_id = auth.uid() and not public.is_suspended());
drop policy if exists "로그인 유저 작성" on public.comments;
create policy "로그인 유저 작성" on public.comments for insert to authenticated
  with check (author_id = auth.uid() and not public.is_suspended());

create or replace function public.can_clover()
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
    and not public.is_suspended()
    and not exists (select 1 from public.profiles p
                     where p.id = auth.uid() and p.member_type = '예비대학원생')
    and (
      exists (select 1 from auth.users u
               where u.id = auth.uid() and u.email_confirmed_at is not null
                 and (lower(u.email) like '%.ac.kr' or lower(u.email) like '%.edu'))
      or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_verified)
    )
$$;
grant execute on function public.can_clover() to anon, authenticated;


-- ───────── 2) 탈퇴 요청 ─────────
create table if not exists public.withdraw_requests (
  user_id    uuid primary key references auth.users(id) on delete cascade default auth.uid(),
  reason     text check (char_length(reason) <= 500),
  created_at timestamptz not null default now()
);
alter table public.withdraw_requests enable row level security;
drop policy if exists "내 탈퇴 요청" on public.withdraw_requests;
create policy "내 탈퇴 요청" on public.withdraw_requests for all to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- 관리자: 회원 완전히 삭제 (글·댓글은 '탈퇴한 회원'으로 남김)
create or replace function public.admin_delete_user(p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  if p_user = auth.uid() then raise exception 'cannot delete yourself'; end if;
  if exists (select 1 from public.admins where user_id = p_user) then raise exception 'cannot delete admin'; end if;
  update public.posts    set author_id = null, author_nickname = '탈퇴한 회원' where author_id = p_user;
  update public.comments set author_id = null, author_nickname = '탈퇴한 회원' where author_id = p_user;
  delete from auth.users where id = p_user;
end $$;
revoke all on function public.admin_delete_user(uuid) from public, anon;
grant execute on function public.admin_delete_user(uuid) to authenticated;

-- 회원 목록에 정지·탈퇴 요청 정보 추가 (반환 칸이 바뀌어서 지우고 다시 만듦)
drop function if exists public.admin_members();
create function public.admin_members()
returns table (
  id uuid, email text, name text, member_type text, school text, dept text,
  email_confirmed boolean, is_verified boolean, created_at timestamptz, last_sign_in_at timestamptz,
  suspended_until timestamptz, suspend_reason text, withdraw_at timestamptz, withdraw_reason text, is_admin boolean
)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select u.id, u.email::text,
         (u.raw_user_meta_data->>'name')::text,
         p.member_type::text,
         (u.raw_user_meta_data->>'school')::text,
         (u.raw_user_meta_data->>'dept')::text,
         u.email_confirmed_at is not null,
         coalesce(p.is_verified, false),
         u.created_at, u.last_sign_in_at,
         p.suspended_until, p.suspend_reason,
         w.created_at, w.reason,
         exists (select 1 from public.admins a where a.user_id = u.id)
  from auth.users u
  left join public.profiles p on p.id = u.id
  left join public.withdraw_requests w on w.user_id = u.id
  order by u.created_at desc;
end $$;
revoke all on function public.admin_members() from public, anon;
grant execute on function public.admin_members() to authenticated;


-- ───────── 3) 커뮤니티 신고 ─────────
create table if not exists public.post_reports (
  id          bigint generated always as identity primary key,
  post_id     bigint references public.posts(id) on delete cascade,
  comment_id  bigint references public.comments(id) on delete cascade,
  reason      text check (char_length(reason) <= 500),
  reporter_id uuid default auth.uid(),
  status      text not null default 'pending' check (status in ('pending','dismissed','removed')),
  created_at  timestamptz not null default now(),
  check (post_id is not null or comment_id is not null)
);
create unique index if not exists post_reports_once
  on public.post_reports (reporter_id, coalesce(post_id, 0), coalesce(comment_id, 0));
alter table public.post_reports enable row level security;
drop policy if exists "신고하기" on public.post_reports;
create policy "신고하기" on public.post_reports for insert to authenticated
  with check (reporter_id = auth.uid() and status = 'pending');
drop policy if exists "신고 관리" on public.post_reports;
create policy "신고 관리" on public.post_reports for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 신고함: 클로버 신고 + 커뮤니티 신고를 한 목록으로
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
  order by 9 desc;
end $$;
revoke all on function public.admin_reports(text) from public, anon;
grant execute on function public.admin_reports(text) to authenticated;

-- 신고 처리: p_action = 'restore'(문제 없음, 다시 보이기) / 'remove'(삭제)
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
  else
    raise exception 'bad source';
  end if;
end $$;
revoke all on function public.admin_resolve_report(text, bigint, text) from public, anon;
grant execute on function public.admin_resolve_report(text, bigint, text) to authenticated;


-- ───────── 4) 클로버 현황 ─────────
create or replace function public.admin_clover_labs()
returns table (id bigint, univ text, dept text, name text, prof text, topic text, hidden boolean,
               cnt int, comments int, pending_reports int, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select l.id, l.univ, l.dept, l.name, l.prof, l.topic, l.hidden,
         (select count(*) from public.clover_votes v where v.lab_id = l.id)::int,
         (select count(*) from public.clover_comments c where c.lab_id = l.id)::int,
         (select count(*) from public.clover_reports r where r.lab_id = l.id and r.status = 'pending')::int,
         l.created_at
  from public.clover_labs l
  order by 8 desc, l.created_at desc;
end $$;
revoke all on function public.admin_clover_labs() from public, anon;
grant execute on function public.admin_clover_labs() to authenticated;

create or replace function public.admin_set_lab_hidden(p_lab bigint, p_hidden boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  update public.clover_labs set hidden = p_hidden where id = p_lab;
end $$;
revoke all on function public.admin_set_lab_hidden(bigint, boolean) from public, anon;
grant execute on function public.admin_set_lab_hidden(bigint, boolean) to authenticated;


-- ───────── 5) 공지사항 ─────────
create table if not exists public.notices (
  id         bigint generated always as identity primary key,
  title      text not null check (char_length(title) between 1 and 100),
  body       text check (char_length(body) <= 2000),
  url        text check (char_length(url) <= 500),
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.notices enable row level security;
drop policy if exists "공지 보기" on public.notices;
create policy "공지 보기" on public.notices for select using (is_active or public.is_admin());
drop policy if exists "공지 관리" on public.notices;
create policy "공지 관리" on public.notices for all to authenticated
  using (public.is_admin()) with check (public.is_admin());


-- ───────── 6) 방문 기록 · 통계 ─────────
-- 방문자는 브라우저마다 만든 무작위 번호로만 셈 (이름·IP 저장 안 함), 하루에 한 번만 기록
create table if not exists public.site_visits (
  day date not null,
  vid text not null check (char_length(vid) between 8 and 64),
  primary key (day, vid)
);
alter table public.site_visits enable row level security;
revoke all on public.site_visits from anon, authenticated;

create or replace function public.log_visit(p_vid text)
returns void language sql security definer set search_path = public as $$
  insert into public.site_visits(day, vid)
  select (now() at time zone 'Asia/Seoul')::date, p_vid
  where char_length(coalesce(p_vid, '')) between 8 and 64
  on conflict do nothing
$$;
grant execute on function public.log_visit(text) to anon, authenticated;

create or replace function public.admin_daily_stats(p_days int default 30)
returns table (day date, signups int, visitors int)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select d::date,
         (select count(*) from auth.users u where (u.created_at at time zone 'Asia/Seoul')::date = d::date)::int,
         (select count(*) from public.site_visits s where s.day = d::date)::int
  from generate_series((now() at time zone 'Asia/Seoul')::date - (least(greatest(p_days,1),180) - 1),
                       (now() at time zone 'Asia/Seoul')::date, interval '1 day') d
  order by 1 desc;
end $$;
revoke all on function public.admin_daily_stats(int) from public, anon;
grant execute on function public.admin_daily_stats(int) to authenticated;
