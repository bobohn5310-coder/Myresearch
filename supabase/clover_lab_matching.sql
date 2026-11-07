-- ════════════════════════════════════════════════
-- 🍀 클로버 지수: 같은 연구실 묶는 기준을 '학교 + 지도교수님 성함'으로
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
--
--  · 학교 약칭(KAIST, 서울대 …)은 정식 이름으로 바꿔서 저장·비교
--  · 교수님 성함은 띄어쓰기·'교수님' 같은 호칭을 빼고 비교
--  · 같은 학교에 같은 성함이 여럿이면 학과가 같은 쪽으로 묶음
--  · 성함이 없던 예전 연구실은 학교·학과·연구실 이름이 같으면 이어 붙임
-- ════════════════════════════════════════════════

-- 1) 학교 이름 정식화
create or replace function public.clover_canon_univ(p text)
returns text language plpgsql immutable set search_path = public as $$
declare k text := lower(regexp_replace(coalesce(p,''), '\s', '', 'g'));
begin
  k := regexp_replace(k, '(대학원|본교|캠퍼스)$', '');
  return case
    when k in ('kaist','카이스트','한국과학기술원') then '한국과학기술원'
    when k in ('dgist','디지스트','대구경북과학기술원') then '대구경북과학기술원'
    when k in ('gist','지스트','광주과학기술원') then '광주과학기술원'
    when k in ('unist','유니스트','울산과학기술원') then '울산과학기술원'
    when k in ('postech','포스텍','포항공대','포항공과대학교') then '포항공과대학교'
    when k in ('snu','서울대','서울대학교') then '서울대학교'
    when k in ('이대','이화여대','이화여자대학교') then '이화여자대학교'
    when k in ('숙대','숙명여대','숙명여자대학교') then '숙명여자대학교'
    when k in ('성신여대','성신여자대학교') then '성신여자대학교'
    when k in ('동덕여대','동덕여자대학교') then '동덕여자대학교'
    when k in ('서울과기대','서울과학기술대학교') then '서울과학기술대학교'
    when k in ('한예종','한국예술종합학교') then '한국예술종합학교'
    when k in ('ust','과학기술연합대학원대학교') then '과학기술연합대학원대학교'
    when k in ('yonsei','연대','연세대') then '연세대학교'
    when k in ('korea','고대','고려대') then '고려대학교'
    when k in ('skku','성대','성균관대') then '성균관대학교'
    -- 'OO대' → 'OO대학교'
    when k ~ '[가-힣]대$' and k !~ '대학교$' then k || '학교'
    else btrim(p)
  end;
end $$;

-- 2) 교수님 성함 비교용 (띄어쓰기·호칭 제거)
create or replace function public.clover_norm_prof(p text)
returns text language sql immutable set search_path = public as $$
  select regexp_replace(lower(regexp_replace(coalesce(p,''), '\s', '', 'g')), '(교수님|교수|박사님|박사|님)$', '')
$$;

-- 3) 예전 '학교+학과+연구실 이름' 중복 금지 규칙은 없애고, 학교+학과+성함 기준으로
drop index if exists public.clover_labs_uniq;
create unique index if not exists clover_labs_prof_uniq on public.clover_labs
  (lower(regexp_replace(univ,'\s','','g')), lower(regexp_replace(dept,'\s','','g')), public.clover_norm_prof(prof))
  where prof is not null;

-- 4) 이미 등록된 연구실의 학교 이름도 정식 이름으로
update public.clover_labs set univ = public.clover_canon_univ(univ) where univ <> public.clover_canon_univ(univ);

-- 5) 연구실 찾기/등록
create or replace function public.clover_add_lab(p_univ text, p_dept text, p_name text, p_topic text, p_prof text)
returns bigint language plpgsql security definer set search_path = public as $$
declare lid bigint; u text; nu text; nd text; np text;
begin
  if not public.can_clover() then raise exception 'not allowed'; end if;
  u  := public.clover_canon_univ(p_univ);
  p_dept := btrim(p_dept); p_name := btrim(p_name); p_prof := btrim(coalesce(p_prof,''));
  nu := lower(regexp_replace(u,'\s','','g'));
  nd := lower(regexp_replace(p_dept,'\s','','g'));
  np := public.clover_norm_prof(p_prof);
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
    if lid is not null then update public.clover_labs set prof = p_prof where id = lid; end if;
  end if;

  if lid is not null then
    if exists (select 1 from public.clover_labs where id = lid and hidden) then raise exception 'hidden lab'; end if;
    return lid;
  end if;

  -- ③ 새 연구실
  insert into public.clover_labs(univ, dept, name, topic, prof, created_by)
  values (u, p_dept, p_name, nullif(btrim(coalesce(p_topic,'')), ''), p_prof, auth.uid())
  returning id into lid;
  return lid;
end $$;
grant execute on function public.clover_add_lab(text, text, text, text, text) to authenticated;

-- 6) 성함 없이 묶던 예전 방식(4칸)은 더 쓰지 않음
revoke execute on function public.clover_add_lab(text, text, text, text) from authenticated, anon, public;
