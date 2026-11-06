-- ════════════════════════════════════════════════
-- 🍀 클로버 지수: 교수님 성함(필수, 비공개) + 한줄평(선택)
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
--
--  · 교수님 성함은 같은 연구실을 정확히 묶는 데만 쓰고, 누구에게도 내려보내지 않음
--  · 한줄평은 80자 이내, 한 사람이 한 연구실에 하나
--  · 욕설·연락처가 들어간 한줄평은 저장 단계에서 거절
--  · 한줄평은 그 연구실에 6명 이상 모였을 때만, 작성자 없이 공개
--  · 신고가 들어온 한줄평은 즉시 가려지고 운영자가 검토
-- ════════════════════════════════════════════════

-- 1) 연구실에 교수님 성함 칸 (공개 칸 목록에 넣지 않으므로 직접 읽을 수 없음)
alter table public.clover_labs add column if not exists prof text check (char_length(prof) <= 30);

-- 2) 클로버 남길 때 연구실 찾기/등록 (교수님 성함 필수)
create or replace function public.clover_add_lab(p_univ text, p_dept text, p_name text, p_topic text, p_prof text)
returns bigint language plpgsql security definer set search_path = public as $$
declare lid bigint;
begin
  if not public.can_clover() then raise exception 'not allowed'; end if;
  p_univ := btrim(p_univ); p_dept := btrim(p_dept); p_name := btrim(p_name); p_prof := btrim(coalesce(p_prof,''));
  if char_length(p_prof) < 2 then raise exception 'prof required'; end if;
  select id into lid from public.clover_labs
   where lower(regexp_replace(univ,'\s','','g')) = lower(regexp_replace(p_univ,'\s','','g'))
     and lower(regexp_replace(dept,'\s','','g')) = lower(regexp_replace(p_dept,'\s','','g'))
     and lower(regexp_replace(name,'\s','','g')) = lower(regexp_replace(p_name,'\s','','g'));
  if lid is not null then
    if exists (select 1 from public.clover_labs where id = lid and hidden) then raise exception 'hidden lab'; end if;
    update public.clover_labs set prof = p_prof where id = lid and prof is null;
    return lid;
  end if;
  insert into public.clover_labs(univ, dept, name, topic, prof, created_by)
  values (p_univ, p_dept, p_name, nullif(btrim(coalesce(p_topic,'')), ''), p_prof, auth.uid())
  returning id into lid;
  return lid;
end $$;
grant execute on function public.clover_add_lab(text, text, text, text, text) to authenticated;

-- 3) 한줄평
create table if not exists public.clover_comments (
  id         bigint generated always as identity primary key,
  lab_id     bigint not null references public.clover_labs(id) on delete cascade,
  user_id    uuid   not null references auth.users(id) on delete cascade default auth.uid(),
  body       text   not null check (char_length(btrim(body)) between 2 and 80),
  hidden     boolean not null default false,
  created_at timestamptz not null default now(),
  unique (lab_id, user_id)
);
alter table public.clover_comments enable row level security;

drop policy if exists "내 한줄평 보기" on public.clover_comments;
create policy "내 한줄평 보기" on public.clover_comments for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists "한줄평 남기기" on public.clover_comments;
create policy "한줄평 남기기" on public.clover_comments for insert to authenticated
  with check (user_id = auth.uid() and hidden = false and public.can_clover()
              and exists (select 1 from public.clover_votes v where v.lab_id = clover_comments.lab_id and v.user_id = auth.uid()));
drop policy if exists "내 한줄평 지우기" on public.clover_comments;
create policy "내 한줄평 지우기" on public.clover_comments for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists "한줄평 관리" on public.clover_comments;
create policy "한줄평 관리" on public.clover_comments for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- 4) 욕설·연락처 거르기
create or replace function public.clover_comment_guard()
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
drop trigger if exists clover_comment_guard on public.clover_comments;
create trigger clover_comment_guard before insert or update of body on public.clover_comments
  for each row execute function public.clover_comment_guard();

-- 5) 공개용 한줄평: 6명 이상 모인 연구실만, 작성자 없이, 연구실당 최근 5개
create or replace function public.clover_comments_public()
returns table (id bigint, lab_id bigint, body text, created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select c.id, c.lab_id, c.body, c.created_at from (
    select c.*, row_number() over (partition by c.lab_id order by c.created_at desc) rn
    from public.clover_comments c
    join public.clover_labs l on l.id = c.lab_id and not l.hidden
    where not c.hidden
      and (select count(*) from public.clover_votes v where v.lab_id = c.lab_id) >= 6
  ) c where c.rn <= 5
  order by c.lab_id, c.created_at desc
$$;
grant execute on function public.clover_comments_public() to anon, authenticated;

-- 6) 한줄평 신고 → 즉시 가림
alter table public.clover_reports add column if not exists comment_id bigint references public.clover_comments(id) on delete cascade;
create or replace function public.clover_report_comment(p_comment bigint, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare lid bigint;
begin
  select lab_id into lid from public.clover_comments where id = p_comment;
  if lid is null then raise exception 'no comment'; end if;
  insert into public.clover_reports(lab_id, comment_id, kind, reason, reporter_id)
  values (lid, p_comment, 'report', left(p_reason, 1000), auth.uid());
  update public.clover_comments set hidden = true where id = p_comment;
end $$;
grant execute on function public.clover_report_comment(bigint, text) to anon, authenticated;
