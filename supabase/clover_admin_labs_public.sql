-- ════════════════════════════════════════════════
-- 🍀 클로버 지수: 운영자 등록 연구실을 회원에게도 보여 주기 + 연구실 정보 화면
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
-- (clover_admin_labs.sql 다음에 실행)
--
--  · 운영자 등록 연구실(공개 정보)은 클로버가 없어도 목록에 나오고, 이름·분야도 처음부터 보여요.
--  · 클로버 평균은 지금과 똑같이 6명이 모여야 공개돼요. 그 전에는 몇 명이 남겼는지도 보이지 않아요.
--  · 회원이 만든 연구실은 지금 그대로: 승인된 클로버가 있어야 목록에 나오고, 이름은 6명부터.
--  · 연구실 정보 화면(clover_lab_detail): 지도교수·홈페이지·대표 논문은 운영자 등록 연구실에만 보여요.
--    회원이 만든 연구실의 교수님 성함은 지금처럼 공개하지 않아요.
-- ════════════════════════════════════════════════

-- 1) 목록: 운영자 등록 연구실 포함 + 출처·홈페이지·논문 수 (반환 칸이 바뀌어서 지우고 다시 만듦)
drop function if exists public.clover_board();
create function public.clover_board()
returns table (id bigint, univ text, dept text, name text, topic text, created_at timestamptz,
               cnt int, pay numeric, guide numeric, mood numeric, balance numeric, total numeric,
               source text, homepage text, papers int)
language sql stable security definer set search_path = public as $$
  select l.id, l.univ, l.dept,
    case when l.source = 'admin' or count(v.user_id) >= 6 then l.name end,
    case when l.source = 'admin' or count(v.user_id) >= 6 then l.topic end,
    l.created_at,
    case when count(v.user_id) >= 6 then count(v.user_id)::int end,
    case when count(v.user_id) >= 6 then round(avg(v.pay),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.guide),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.mood),1) end,
    case when count(v.user_id) >= 6 then round(avg(v.balance),1) end,
    case when count(v.user_id) >= 6 then round(avg((v.pay+v.guide+v.mood+v.balance)/4.0),1) end,
    l.source,
    case when l.source = 'admin' then l.homepage end,
    case when l.source = 'admin' then (select count(*) from public.clover_lab_papers p where p.lab_id = l.id)::int else 0 end
  from public.clover_labs l
  left join public.clover_votes v on v.lab_id = l.id and v.status = 'approved'
  where not l.hidden
  group by l.id
  having l.source = 'admin' or count(v.user_id) > 0
  order by l.created_at desc
$$;
grant execute on function public.clover_board() to anon, authenticated;

-- 2) 연구실 정보 화면: 한 연구실의 공개 정보 + 대표 논문 + 클로버 평균(6명 이상일 때만)
drop function if exists public.clover_lab_detail(bigint);
create function public.clover_lab_detail(p_lab bigint)
returns table (id bigint, univ text, dept text, name text, topic text, source text,
               prof text, homepage text, source_url text, collected_at date,
               cnt int, pay numeric, guide numeric, mood numeric, balance numeric, total numeric,
               papers jsonb)
language sql stable security definer set search_path = public as $$
  with s as (
    select count(v.user_id) n, avg(v.pay) pay, avg(v.guide) guide, avg(v.mood) mood, avg(v.balance) balance,
           avg((v.pay+v.guide+v.mood+v.balance)/4.0) total
      from public.clover_votes v where v.lab_id = p_lab and v.status = 'approved'
  )
  select l.id, l.univ, l.dept,
    case when l.source = 'admin' or s.n >= 6 then l.name end,
    case when l.source = 'admin' or s.n >= 6 then l.topic end,
    l.source,
    case when l.source = 'admin' then l.prof end,
    case when l.source = 'admin' then l.homepage end,
    case when l.source = 'admin' then l.source_url end,
    case when l.source = 'admin' then l.collected_at end,
    case when s.n >= 6 then s.n::int end,
    case when s.n >= 6 then round(s.pay,1) end,
    case when s.n >= 6 then round(s.guide,1) end,
    case when s.n >= 6 then round(s.mood,1) end,
    case when s.n >= 6 then round(s.balance,1) end,
    case when s.n >= 6 then round(s.total,1) end,
    case when l.source = 'admin' then coalesce((
      select jsonb_agg(jsonb_build_object('title', p.title, 'venue', p.venue, 'year', p.year, 'url', p.url)
                       order by p.year desc nulls last, p.id)
        from public.clover_lab_papers p where p.lab_id = l.id), '[]'::jsonb)
    else '[]'::jsonb end
  from public.clover_labs l, s
  where l.id = p_lab and not l.hidden and (l.source = 'admin' or s.n > 0)
$$;
grant execute on function public.clover_lab_detail(bigint) to anon, authenticated;
