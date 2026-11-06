-- ════════════════════════════════════════════════
-- 🍀 클로버 지수: 자라는 중인 연구실은 '학교·학과'만 공개
-- 연구실 이름·연구 분야는 6명 이상 모였을 때만 서버가 내려준다.
-- (공개 기준 6명 변경 clover_threshold_6.sql 내용도 함께 들어 있어요)
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
-- ════════════════════════════════════════════════

-- 1) 공개 기준 6명
create or replace function public.clover_summary()
returns table (lab_id bigint, cnt int, pay numeric, guide numeric, mood numeric, balance numeric, total numeric)
language sql stable security definer set search_path = public as $$
  select l.id, coalesce(count(v.user_id),0)::int,
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

-- 2) 연구실 이름·분야 칸은 직접 읽지 못하게 (학교·학과만 읽기 허용)
revoke select on public.clover_labs from anon, authenticated;
grant select (id, univ, dept, hidden, created_at) on public.clover_labs to anon, authenticated;

-- 3) 목록용: 6명 이상이면 이름·분야·평균까지, 아니면 학교·학과와 참여 수만
create or replace function public.clover_board()
returns table (id bigint, univ text, dept text, name text, topic text, created_at timestamptz,
               cnt int, pay numeric, guide numeric, mood numeric, balance numeric, total numeric)
language sql stable security definer set search_path = public as $$
  select l.id, l.univ, l.dept,
    case when count(v.user_id) >= 6 then l.name end,
    case when count(v.user_id) >= 6 then l.topic end,
    l.created_at,
    count(v.user_id)::int,
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

-- 4) 클로버 남길 때: 같은 연구실이 있으면 그 번호를, 없으면 새로 등록해서 번호를 돌려줌
create or replace function public.clover_add_lab(p_univ text, p_dept text, p_name text, p_topic text)
returns bigint language plpgsql security definer set search_path = public as $$
declare k text; lid bigint;
begin
  if not public.can_clover() then raise exception 'not allowed'; end if;
  p_univ := btrim(p_univ); p_dept := btrim(p_dept); p_name := btrim(p_name);
  select id into lid from public.clover_labs
   where lower(regexp_replace(univ,'\s','','g')) = lower(regexp_replace(p_univ,'\s','','g'))
     and lower(regexp_replace(dept,'\s','','g')) = lower(regexp_replace(p_dept,'\s','','g'))
     and lower(regexp_replace(name,'\s','','g')) = lower(regexp_replace(p_name,'\s','','g'));
  if lid is not null then
    if exists (select 1 from public.clover_labs where id = lid and hidden) then raise exception 'hidden lab'; end if;
    return lid;
  end if;
  insert into public.clover_labs(univ, dept, name, topic, created_by)
  values (p_univ, p_dept, p_name, nullif(btrim(coalesce(p_topic,'')), ''), auth.uid())
  returning id into lid;
  return lid;
end $$;
grant execute on function public.clover_add_lab(text, text, text, text) to authenticated;
