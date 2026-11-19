-- 클로버 한줄평: 필수 · 5자 이상 (2026-11-19)
-- 화면(index.html)에서는 한줄평이 비었거나 5자 미만이면 클로버 남기기를 막는다.
-- 서버에서도 새로 저장되는 한줄평은 앞뒤 공백을 뺀 길이가 5~80자여야 한다.
-- (school_lights.sql 과 같은 btrim 기준)
-- can_clover()·clover_votes 정책은 건드리지 않으므로 clover_admin_vote.sql 과 충돌하지 않는다.
-- Supabase SQL Editor 에 통째로 붙여 넣고 Run 하면 된다. 여러 번 실행해도 안전하다.

alter table public.clover_comments drop constraint if exists clover_comments_body_check;
alter table public.clover_comments drop constraint if exists clover_comments_body_min5;
-- 이미 남아 있는 2~4자 한줄평은 그대로 두고(not valid), 새로 쓰거나 고치는 것부터 검사한다
alter table public.clover_comments
  add constraint clover_comments_body_min5
  check (char_length(btrim(body)) between 5 and 80) not valid;
