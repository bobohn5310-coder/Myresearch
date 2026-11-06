-- ════════════════════════════════════════════════
-- 🔎 아이디(이메일) 찾기
-- Supabase → SQL Editor 에 전체를 붙여넣고 Run. 여러 번 실행해도 안전합니다.
--
--  · 가입할 때 적은 '이름'과 '학교'가 맞으면, 가입한 이메일을 일부 가려서 알려 줌 (예: bo****@gmail.com)
--  · 전체 이메일은 절대 돌려주지 않음. 한 번에 최대 3개까지만.
-- ════════════════════════════════════════════════

create or replace function public.find_my_email(p_name text, p_school text)
returns setof text
language sql stable security definer set search_path = public as $$
  select
    left(split_part(u.email, '@', 1), least(2, greatest(length(split_part(u.email, '@', 1)) - 1, 1)))
      || repeat('*', greatest(length(split_part(u.email, '@', 1)) - 2, 2))
      || '@' || split_part(u.email, '@', 2)
  from auth.users u
  where char_length(btrim(coalesce(p_name, ''))) >= 2
    and char_length(regexp_replace(coalesce(p_school, ''), '\s', '', 'g')) >= 2
    and btrim(u.raw_user_meta_data->>'name') = btrim(p_name)
    and strpos(lower(regexp_replace(coalesce(u.raw_user_meta_data->>'school', ''), '\s', '', 'g')),
               lower(regexp_replace(p_school, '\s', '', 'g'))) > 0
  order by u.created_at
  limit 3
$$;
revoke all on function public.find_my_email(text, text) from public;
grant execute on function public.find_my_email(text, text) to anon, authenticated;
