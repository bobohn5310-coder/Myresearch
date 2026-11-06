-- 🍀 클로버 지수 공개 기준을 5명 → 6명으로 바꾸기
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
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
