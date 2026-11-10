-- ════════════════════════════════════════════════
-- 🍀 클로버 지수: 내 연구실에만 남기기 + 관리자 승인 후 공개
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
-- (clover_index.sql · clover_comments.sql · clover_lab_matching.sql 다음에 실행)
--
-- 문제: 학교 메일이나 학교 인증만 있으면 아무 학교·아무 연구실에나, 여러 곳에 클로버를
--       남길 수 있었다. 운영자가 작성자와 연구실을 일일이 맞춰 봐야 했다.
-- 해결 (운영자 손이 안 가게, 서버가 자동으로)
--  ① 내 연구실 1곳 고정: 처음 클로버를 남긴 연구실이 그 회원의 '내 연구실'이 된다.
--     다른 연구실에는 남길 수 없고, 클로버를 지워도 고정은 풀리지 않는다.
--     졸업·이동 같은 예외는 관리자 회원 화면의 '내 연구실 풀기' 버튼으로만 푼다.
--  ② 학교 일치: 가입 메일 도메인(snu.ac.kr → 서울대학교) 또는 승인된 학교 인증의 학교와
--     연구실의 학교가 다르면 거절한다. 학교를 알 수 없는 메일(목록에 없는 도메인)은
--     ①만 적용하고, 관리자 화면에 '학교 미확인'으로 표시한다.
--  ③ 관리자 승인: 새 클로버·한줄평은 '검토 대기'로 저장되고, 관리자가 승인한 것만
--     참여 인원·평균·한줄평에 들어간다. 아무도 승인되지 않은 새 연구실은 목록에도 안 보인다.
--     반려하면 '내 연구실' 고정도 풀려서 회원이 맞는 연구실로 다시 남길 수 있다.
--     이미 공개된 기존 클로버는 '승인됨'으로 둔다.
-- ════════════════════════════════════════════════

-- 1) 학교 메일 도메인 → 정식 학교 이름 (하위 도메인도 인정: stu.jejunu.ac.kr, g.skku.edu …)
create table if not exists public.clover_univ_domains (
  domain text primary key,
  univ   text not null
);
alter table public.clover_univ_domains enable row level security;
drop policy if exists "도메인 보기" on public.clover_univ_domains;
create policy "도메인 보기" on public.clover_univ_domains for select using (true);
drop policy if exists "도메인 관리" on public.clover_univ_domains;
create policy "도메인 관리" on public.clover_univ_domains for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

insert into public.clover_univ_domains(domain, univ) values
  ('snu.ac.kr','서울대학교'), ('kaist.ac.kr','한국과학기술원'), ('postech.ac.kr','포항공과대학교'),
  ('yonsei.ac.kr','연세대학교'), ('korea.ac.kr','고려대학교'), ('skku.edu','성균관대학교'), ('skku.ac.kr','성균관대학교'),
  ('hanyang.ac.kr','한양대학교'), ('dgist.ac.kr','대구경북과학기술원'), ('gist.ac.kr','광주과학기술원'),
  ('unist.ac.kr','울산과학기술원'), ('kentech.ac.kr','한국에너지공과대학교'), ('ust.ac.kr','과학기술연합대학원대학교'),
  ('ewha.ac.kr','이화여자대학교'), ('sogang.ac.kr','서강대학교'), ('cau.ac.kr','중앙대학교'), ('khu.ac.kr','경희대학교'),
  ('hufs.ac.kr','한국외국어대학교'), ('uos.ac.kr','서울시립대학교'), ('konkuk.ac.kr','건국대학교'),
  ('dongguk.edu','동국대학교'), ('dongguk.ac.kr','동국대학교'), ('hongik.ac.kr','홍익대학교'), ('kookmin.ac.kr','국민대학교'),
  ('ssu.ac.kr','숭실대학교'), ('soongsil.ac.kr','숭실대학교'), ('sejong.ac.kr','세종대학교'), ('ajou.ac.kr','아주대학교'),
  ('inha.ac.kr','인하대학교'), ('inha.edu','인하대학교'), ('inu.ac.kr','인천대학교'), ('kw.ac.kr','광운대학교'),
  ('mju.ac.kr','명지대학교'), ('dankook.ac.kr','단국대학교'), ('gachon.ac.kr','가천대학교'), ('kau.ac.kr','한국항공대학교'),
  ('seoultech.ac.kr','서울과학기술대학교'), ('sookmyung.ac.kr','숙명여자대학교'), ('swu.ac.kr','서울여자대학교'),
  ('sungshin.ac.kr','성신여자대학교'), ('dongduk.ac.kr','동덕여자대학교'), ('catholic.ac.kr','가톨릭대학교'),
  ('kyonggi.ac.kr','경기대학교'), ('koreatech.ac.kr','한국기술교육대학교'), ('sch.ac.kr','순천향대학교'), ('hallym.ac.kr','한림대학교'),
  ('pusan.ac.kr','부산대학교'), ('pknu.ac.kr','부경대학교'), ('knu.ac.kr','경북대학교'), ('jnu.ac.kr','전남대학교'),
  ('jbnu.ac.kr','전북대학교'), ('cnu.ac.kr','충남대학교'), ('chungbuk.ac.kr','충북대학교'), ('cbnu.ac.kr','충북대학교'),
  ('kangwon.ac.kr','강원대학교'), ('gnu.ac.kr','경상국립대학교'), ('jejunu.ac.kr','제주대학교'),
  ('ulsan.ac.kr','울산대학교'), ('yu.ac.kr','영남대학교'), ('kmu.ac.kr','계명대학교'), ('dau.ac.kr','동아대학교'),
  ('kumoh.ac.kr','금오공과대학교'), ('hanbat.ac.kr','한밭대학교'), ('ut.ac.kr','한국교통대학교'), ('cha.ac.kr','차의과학대학교')
on conflict (domain) do update set univ = excluded.univ;

-- 2) 학교 이름 비교용 열쇠: 정식화 후 '국립'·띄어쓰기를 빼고 비교
create or replace function public.clover_univ_key(p text)
returns text language sql immutable set search_path = public as $$
  select regexp_replace(lower(regexp_replace(public.clover_canon_univ(coalesce(p,'')), '\s', '', 'g')), '^국립', '')
$$;

-- 3) 회원의 학교 (메일 도메인 + 승인된 학교 인증). 알 수 없으면 빈 목록
create or replace function public.clover_user_univs(p_user uuid)
returns text[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(distinct x) filter (where x is not null and x <> ''), '{}') from (
    -- 메일 도메인
    (select d.univ as x
       from auth.users u
       join public.clover_univ_domains d
         on split_part(lower(u.email),'@',2) = d.domain
         or split_part(lower(u.email),'@',2) like '%.' || d.domain
      where u.id = p_user and u.email_confirmed_at is not null
      order by length(d.domain) desc limit 1)
    union all
    -- 승인된 학교 인증 (예: '성균관대 반도체' → 첫 단어 '성균관대' → 성균관대학교)
    (select public.clover_canon_univ(split_part(btrim(r.school), ' ', 1))
       from public.verification_requests r
      where r.user_id = p_user and r.status = 'approved'
      order by r.created_at desc limit 1)
  ) t
$$;
revoke all on function public.clover_user_univs(uuid) from public, anon, authenticated;

create or replace function public.clover_my_univs()
returns text[] language sql stable security definer set search_path = public as $$
  select case when auth.uid() is null then '{}'::text[] else public.clover_user_univs(auth.uid()) end
$$;
grant execute on function public.clover_my_univs() to authenticated;

-- 연구실 학교가 회원의 학교 중 하나와 맞는지. 회원 학교를 알 수 없으면 null
create or replace function public.clover_univ_match_for(p_user uuid, p_lab_univ text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare mine text[] := public.clover_user_univs(p_user); k text := public.clover_univ_key(p_lab_univ); m text;
begin
  if coalesce(array_length(mine,1),0) = 0 then return null; end if;
  foreach m in array mine loop
    if public.clover_univ_key(m) = k then return true; end if;
    -- '성균관대반도체'처럼 정식화가 안 된 인증 학교명도 앞부분이 같으면 인정
    if k <> '' and position(regexp_replace(k,'학교$','') in public.clover_univ_key(m)) = 1 then return true; end if;
  end loop;
  return false;
end $$;
revoke all on function public.clover_univ_match_for(uuid, text) from public, anon, authenticated;

create or replace function public.clover_univ_match(p_lab_univ text)
returns boolean language sql stable security definer set search_path = public as $$
  select case when auth.uid() is null then null else public.clover_univ_match_for(auth.uid(), p_lab_univ) end
$$;

-- 4) 회원별 '내 연구실' (본인만 볼 수 있고, 쓰기는 서버 함수로만)
create table if not exists public.clover_members (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  lab_id     bigint not null references public.clover_labs(id) on delete cascade,
  univ_ok    boolean,               -- true: 학교 일치 확인 / null: 학교를 알 수 없음
  created_at timestamptz not null default now()
);
alter table public.clover_members enable row level security;
drop policy if exists "내 연구실 보기" on public.clover_members;
create policy "내 연구실 보기" on public.clover_members for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- 이미 남긴 클로버로 '내 연구실' 채우기 (가장 먼저 남긴 곳)
insert into public.clover_members(user_id, lab_id, created_at)
select distinct on (v.user_id) v.user_id, v.lab_id, v.created_at
  from public.clover_votes v
 order by v.user_id, v.created_at
on conflict (user_id) do nothing;
-- 이미 고정된 회원도 학교 일치 여부를 채워 두기
update public.clover_members m set univ_ok = public.clover_univ_match_for(m.user_id, l.univ)
  from public.clover_labs l where l.id = m.lab_id and m.univ_ok is null;

-- 5) 이 연구실에 남겨도 되는지 검사 (p_lab 이 null 이면 새 연구실을 만들려는 것)
create or replace function public.clover_check_my_lab(p_lab bigint, p_univ text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare mine bigint; ok boolean;
begin
  select lab_id into mine from public.clover_members where user_id = auth.uid();
  if mine is not null and (p_lab is null or p_lab <> mine) then raise exception 'not my lab'; end if;
  ok := public.clover_univ_match(p_univ);
  if ok = false then raise exception 'other school'; end if;
  return ok;
end $$;

-- 6) 연구실 찾기/등록: 남의 연구실을 새로 만들거나 고르지 못하게 먼저 검사
create or replace function public.clover_add_lab(p_univ text, p_dept text, p_name text, p_topic text, p_prof text)
returns bigint language plpgsql security definer set search_path = public as $$
declare lid bigint; u text; nu text; nd text; np text; lu text;
begin
  if not public.can_clover() then raise exception 'not allowed'; end if;
  u  := public.clover_canon_univ(p_univ);
  p_dept := btrim(p_dept); p_name := btrim(p_name); p_prof := btrim(coalesce(p_prof,''));
  nu := lower(regexp_replace(u,'\s','','g'));
  nd := lower(regexp_replace(p_dept,'\s','','g'));
  np := public.clover_norm_prof(p_prof);

  -- 이미 '내 연구실'이 있으면 적은 내용과 상관없이 그 연구실로 (성함을 몰라도 됨)
  select m.lab_id into lid from public.clover_members m where m.user_id = auth.uid();
  if lid is not null then
    if exists (select 1 from public.clover_labs where id = lid and hidden) then raise exception 'hidden lab'; end if;
    return lid;
  end if;

  if char_length(np) < 2 then raise exception 'prof required'; end if;

  -- ① 같은 학교 + 같은 교수님 (같은 성함이 여럿이면 학과가 같은 쪽 우선)
  select id into lid from public.clover_labs
   where prof is not null
     and lower(regexp_replace(univ,'\s','','g')) = nu
     and public.clover_norm_prof(prof) = np
   order by (lower(regexp_replace(dept,'\s','','g')) = nd) desc, id
   limit 1;

  -- ② 성함 없이 등록된 예전 연구실: 학교·학과·연구실 이름이 같으면 이어 붙임
  if lid is null then
    select id into lid from public.clover_labs
     where prof is null
       and lower(regexp_replace(univ,'\s','','g')) = nu
       and lower(regexp_replace(dept,'\s','','g')) = nd
       and lower(regexp_replace(name,'\s','','g')) = lower(regexp_replace(p_name,'\s','','g'))
     order by id limit 1;
  end if;

  -- 학교 검사 (연구실을 만들기 전에)
  select univ into lu from public.clover_labs where id = lid;
  perform public.clover_check_my_lab(lid, coalesce(lu, u));

  if lid is not null then
    if exists (select 1 from public.clover_labs where id = lid and hidden) then raise exception 'hidden lab'; end if;
    update public.clover_labs set prof = p_prof where id = lid and prof is null;
    return lid;
  end if;

  -- ③ 새 연구실
  insert into public.clover_labs(univ, dept, name, topic, prof, created_by)
  values (u, p_dept, p_name, nullif(btrim(coalesce(p_topic,'')), ''), p_prof, auth.uid())
  returning id into lid;
  return lid;
end $$;
grant execute on function public.clover_add_lab(text, text, text, text, text) to authenticated;

-- 7) 회원이 연구실을 직접 만들지 못하게 (반드시 clover_add_lab 을 거치도록)
drop policy if exists "연구실 등록" on public.clover_labs;

-- 8) 승인 상태 칸. 지금까지 남은 클로버·한줄평은 이미 공개됐으므로 '승인됨'으로 채우고,
--    그 다음부터 새로 들어오는 것은 '검토 대기'로 시작
alter table public.clover_votes add column if not exists status text not null default 'approved';
alter table public.clover_votes alter column status set default 'pending';
alter table public.clover_votes drop constraint if exists clover_votes_status_check;
alter table public.clover_votes add constraint clover_votes_status_check check (status in ('pending','approved','rejected'));
alter table public.clover_votes add column if not exists reviewed_at timestamptz;
alter table public.clover_votes add column if not exists reject_reason text check (char_length(reject_reason) <= 200);

alter table public.clover_comments add column if not exists status text not null default 'approved';
alter table public.clover_comments alter column status set default 'pending';
alter table public.clover_comments drop constraint if exists clover_comments_status_check;
alter table public.clover_comments add constraint clover_comments_status_check check (status in ('pending','approved','rejected'));

-- 관리자가 승인 함수 안에서 고칠 때는 아래 검사를 건너뛰기 위한 표시 (그 거래 안에서만 유효)
create or replace function public.is_admin_reviewing()
returns boolean language sql stable set search_path = public as $$
  select coalesce(current_setting('clover.reviewing', true), '') = 'on' and public.is_admin()
$$;

-- 회원이 쓰거나 고친 한줄평도 '검토 대기'로
create or replace function public.clover_comment_status_guard()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or public.is_admin_reviewing() then return new; end if;
  if tg_op = 'INSERT' or new.body is distinct from old.body then new.status := 'pending'; end if;
  return new;
end $$;
drop trigger if exists clover_comment_status_guard on public.clover_comments;
create trigger clover_comment_status_guard before insert or update on public.clover_comments
  for each row execute function public.clover_comment_status_guard();

-- 9) 클로버 저장 직전 검사 + 처음이면 '내 연구실'로 고정. 다른 연구실로 옮겨 적기도 막음
create or replace function public.clover_vote_guard()
returns trigger language plpgsql security definer set search_path = public as $$
declare ok boolean; lu text;
begin
  if auth.uid() is null or public.is_admin_reviewing() then return new; end if;  -- 서버 작업 / 관리자 승인 처리
  if tg_op = 'UPDATE' and new.lab_id is distinct from old.lab_id then raise exception 'not my lab'; end if;
  -- 회원이 남기거나 고친 클로버는 언제나 '검토 대기'로
  new.status := 'pending'; new.reviewed_at := null; new.reject_reason := null;
  if tg_op = 'INSERT' then
    select univ into lu from public.clover_labs where id = new.lab_id;
    ok := public.clover_check_my_lab(new.lab_id, lu);
    insert into public.clover_members(user_id, lab_id, univ_ok) values (new.user_id, new.lab_id, ok)
    on conflict (user_id) do nothing;
  end if;
  return new;
end $$;
drop trigger if exists clover_vote_guard on public.clover_votes;
create trigger clover_vote_guard before insert or update on public.clover_votes
  for each row execute function public.clover_vote_guard();

-- 10) 클로버 화면용: 내 연구실과 학교
drop function if exists public.clover_my_lab();
create function public.clover_my_lab()
returns table (lab_id bigint, univ text, dept text, name text, status text, reject_reason text, my_univs text[])
language sql stable security definer set search_path = public as $$
  select m.lab_id, l.univ, l.dept, l.name,
         (select v.status from public.clover_votes v where v.user_id = auth.uid() and v.lab_id = m.lab_id),
         (select v.reject_reason from public.clover_votes v where v.user_id = auth.uid()
           and v.status = 'rejected' order by v.reviewed_at desc nulls last limit 1),
         public.clover_my_univs()
    from (select auth.uid() as uid) me
    left join public.clover_members m on m.user_id = me.uid
    left join public.clover_labs l on l.id = m.lab_id
   where me.uid is not null
$$;
grant execute on function public.clover_my_lab() to authenticated;

-- 11) 관리자: 회원의 '내 연구실' 보기 / 풀기 (졸업·연구실 이동·잘못 고른 경우)
create or replace function public.admin_clover_member(p_user uuid)
returns table (lab_id bigint, univ text, dept text, name text, univ_ok boolean, voted boolean, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select m.lab_id, l.univ, l.dept, l.name, m.univ_ok,
         exists (select 1 from public.clover_votes v where v.user_id = p_user and v.lab_id = m.lab_id),
         m.created_at
    from public.clover_members m join public.clover_labs l on l.id = m.lab_id
   where m.user_id = p_user;
end $$;
revoke all on function public.admin_clover_member(uuid) from public, anon;
grant execute on function public.admin_clover_member(uuid) to authenticated;

-- p_drop_vote = true 이면 그 연구실에 남긴 클로버·한줄평도 지움
create or replace function public.admin_clover_release(p_user uuid, p_drop_vote boolean default false)
returns void language plpgsql security definer set search_path = public as $$
declare lid bigint;
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  delete from public.clover_members where user_id = p_user returning lab_id into lid;
  if p_drop_vote and lid is not null then
    delete from public.clover_comments where user_id = p_user and lab_id = lid;
    delete from public.clover_votes    where user_id = p_user and lab_id = lid;
  end if;
end $$;
revoke all on function public.admin_clover_release(uuid, boolean) from public, anon;
grant execute on function public.admin_clover_release(uuid, boolean) to authenticated;

-- 12) 공개 숫자는 '승인된' 클로버만으로. 승인된 클로버가 하나도 없는 연구실은 목록에서 빠짐
create or replace function public.clover_lab_public(p_lab bigint)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.clover_votes v where v.lab_id = p_lab and v.status = 'approved')
$$;
grant execute on function public.clover_lab_public(bigint) to anon, authenticated;

drop policy if exists "연구실 보기" on public.clover_labs;
create policy "연구실 보기" on public.clover_labs for select
  using ((not hidden and public.clover_lab_public(id)) or public.is_admin());

-- 위 정책 때문에 아직 승인 전인 연구실이 회원에게 안 보이므로, 남기기 검사는 서버 함수로
create or replace function public.clover_lab_open(p_lab bigint)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.clover_labs l where l.id = p_lab and not l.hidden)
$$;
grant execute on function public.clover_lab_open(bigint) to authenticated;
drop policy if exists "클로버 남기기" on public.clover_votes;
create policy "클로버 남기기" on public.clover_votes for insert to authenticated
  with check (user_id = auth.uid() and public.can_clover() and public.clover_lab_open(lab_id));

create or replace function public.clover_summary()
returns table (lab_id bigint, cnt int, pay numeric, guide numeric, mood numeric, balance numeric, total numeric)
language sql stable security definer set search_path = public as $$
  select l.id,
    case when count(v.user_id) >= 6 then count(v.user_id)::int end,
    case when count(v.user_id) >= 6 then round(avg(v.pay),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.guide),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.mood),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.balance),1) end,
    case when count(v.user_id) >= 6 then round(avg((v.pay+v.guide+v.mood+v.balance)/4.0),1) end
  from public.clover_labs l join public.clover_votes v on v.lab_id = l.id and v.status = 'approved'
  where not l.hidden
  group by l.id
$$;
grant execute on function public.clover_summary() to anon, authenticated;

create or replace function public.clover_board()
returns table (id bigint, univ text, dept text, name text, topic text, created_at timestamptz,
               cnt int, pay numeric, guide numeric, mood numeric, balance numeric, total numeric)
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
  from public.clover_labs l join public.clover_votes v on v.lab_id = l.id and v.status = 'approved'
  where not l.hidden
  group by l.id
  order by l.created_at desc
$$;
grant execute on function public.clover_board() to anon, authenticated;

create or replace function public.clover_comments_public()
returns table (id bigint, lab_id bigint, body text, created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select c.id, c.lab_id, c.body, c.created_at from (
    select c.*, row_number() over (partition by c.lab_id order by c.created_at desc) rn
    from public.clover_comments c
    join public.clover_labs l on l.id = c.lab_id and not l.hidden
    where not c.hidden and c.status = 'approved'
      and (select count(*) from public.clover_votes v where v.lab_id = c.lab_id and v.status = 'approved') >= 6
  ) c where c.rn <= 5
  order by c.lab_id, c.created_at desc
$$;
grant execute on function public.clover_comments_public() to anon, authenticated;

-- 13) 관리자 승인함: 누가(이메일·학교) 어느 연구실에 무엇을 남겼는지 한눈에
create or replace function public.admin_clover_queue(p_status text default 'pending')
returns table (lab_id bigint, user_id uuid, email text, name text, member_type text, is_verified boolean,
               user_univs text[], verify_school text, univ_ok boolean, other_votes int,
               univ text, dept text, lab_name text, prof text, lab_hidden boolean, lab_approved int,
               pay smallint, guide smallint, mood smallint, balance smallint,
               comment text, comment_status text, status text, reject_reason text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select v.lab_id, v.user_id, u.email::text, (u.raw_user_meta_data->>'name')::text,
         p.member_type, coalesce(p.is_verified, false),
         public.clover_user_univs(v.user_id),
         (select r.school from public.verification_requests r where r.user_id = v.user_id and r.status = 'approved'
           order by r.created_at desc limit 1)::text,
         m.univ_ok,
         (select count(*) from public.clover_votes v2 where v2.user_id = v.user_id and v2.lab_id <> v.lab_id)::int,
         l.univ, l.dept, l.name, l.prof, l.hidden,
         (select count(*) from public.clover_votes v3 where v3.lab_id = v.lab_id and v3.status = 'approved')::int,
         v.pay, v.guide, v.mood, v.balance,
         c.body, c.status, v.status, v.reject_reason, v.created_at
    from public.clover_votes v
    join public.clover_labs l on l.id = v.lab_id
    left join auth.users u on u.id = v.user_id
    left join public.profiles p on p.id = v.user_id
    left join public.clover_members m on m.user_id = v.user_id and m.lab_id = v.lab_id
    left join public.clover_comments c on c.lab_id = v.lab_id and c.user_id = v.user_id
   where p_status = 'all' or v.status = p_status
   order by v.created_at desc
   limit 300;
end $$;
revoke all on function public.admin_clover_queue(text) from public, anon;
grant execute on function public.admin_clover_queue(text) to authenticated;

-- p_action: 'approve'(클로버·한줄평 승인) / 'approve_no_comment'(클로버만 승인, 한줄평은 반려)
--           'reject'(반려: 공개 안 함, '내 연구실' 고정도 풀어서 맞는 연구실로 다시 남길 수 있게)
create or replace function public.admin_clover_review(p_lab bigint, p_user uuid, p_action text, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  if p_action not in ('approve','approve_no_comment','reject') then raise exception 'bad action'; end if;
  perform set_config('clover.reviewing', 'on', true);
  update public.clover_votes
     set status = case when p_action = 'reject' then 'rejected' else 'approved' end,
         reviewed_at = now(),
         reject_reason = case when p_action = 'reject' then left(nullif(btrim(coalesce(p_reason,'')),''), 200) end
   where lab_id = p_lab and user_id = p_user;
  if not found then raise exception 'no vote'; end if;
  update public.clover_comments
     set status = case when p_action = 'approve' then 'approved' else 'rejected' end
   where lab_id = p_lab and user_id = p_user;
  if p_action = 'reject' then
    delete from public.clover_members where user_id = p_user and lab_id = p_lab;
  end if;
  perform set_config('clover.reviewing', 'off', true);
end $$;
revoke all on function public.admin_clover_review(bigint, uuid, text, text) from public, anon;
grant execute on function public.admin_clover_review(bigint, uuid, text, text) to authenticated;

-- 14) 관리자 클로버 현황: 승인된 인원 + 검토 대기 + 학교 미확인 (반환 칸이 바뀌어서 지우고 다시 만듦)
drop function if exists public.admin_clover_labs();
create function public.admin_clover_labs()
returns table (id bigint, univ text, dept text, name text, prof text, topic text, hidden boolean,
               cnt int, comments int, pending_reports int, created_at timestamptz, pending int, unchecked int)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select l.id, l.univ, l.dept, l.name, l.prof, l.topic, l.hidden,
         (select count(*) from public.clover_votes v where v.lab_id = l.id and v.status = 'approved')::int,
         (select count(*) from public.clover_comments c where c.lab_id = l.id and c.status = 'approved')::int,
         (select count(*) from public.clover_reports r where r.lab_id = l.id and r.status = 'pending')::int,
         l.created_at,
         (select count(*) from public.clover_votes v where v.lab_id = l.id and v.status = 'pending')::int,
         (select count(*) from public.clover_votes v
            left join public.clover_members m on m.user_id = v.user_id and m.lab_id = v.lab_id
           where v.lab_id = l.id and v.status <> 'rejected' and m.univ_ok is not true)::int
  from public.clover_labs l
  order by 8 desc, l.created_at desc;
end $$;
revoke all on function public.admin_clover_labs() from public, anon;
grant execute on function public.admin_clover_labs() to authenticated;
