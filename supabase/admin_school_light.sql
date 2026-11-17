-- ════════════════════════════════════════════════════════════
--  🕯️ 불빛 지도: 관리자도 불 켜기 (2026-11-17)
--  · 지금은 관리자 계정에 학교 메일·학교 인증이 없어서 '어느 학교인지 알 수 없음(no school)'으로 막힌다.
--  · 관리자(admins 표에 있는 계정)만 켤 학교를 직접 고를 수 있게 한다.
--    관리자인지는 서버(is_admin)가 확인하므로, 일반 회원이 화면을 고쳐 학교를 보내도 무시된다.
--  · 고를 수 있는 학교는 학교 목록(clover_univ_domains)에 있는 정식 이름뿐이다.
--  · 나머지 규칙(5~140자, 금지어, 하루 3개, 1분에 1개, 같은 글 금지, 정지 계정 금지)은 관리자도 똑같다.
--  Supabase SQL Editor 에서 한 번 실행하면 된다. 여러 번 실행해도 괜찮다.
-- ════════════════════════════════════════════════════════════

-- 예전 함수(글만 받는 것)를 지우고, 학교를 하나 더 받는 함수로 바꾼다
drop function if exists public.school_light_add(text);

create or replace function public.school_light_add(p_body text, p_univ text default null)
returns text language plpgsql security definer set search_path = public as $$
declare
  b text := btrim(regexp_replace(coalesce(p_body,''), '\s+', ' ', 'g'));
  u text;
  today date := (now() at time zone 'Asia/Seoul')::date;
begin
  if auth.uid() is null then raise exception 'login required'; end if;
  if public.is_suspended() then raise exception 'suspended'; end if;
  if not public.is_school_member() then raise exception 'school only'; end if;

  if nullif(btrim(coalesce(p_univ,'')), '') is not null and public.is_admin() then
    -- 관리자만: 고른 학교 (학교 목록에 있는 이름만)
    u := public.clover_canon_univ(btrim(p_univ));
    if not exists (select 1 from public.clover_univ_domains d where d.univ = u) then raise exception 'unknown school'; end if;
  else
    -- 일반 회원: 학교 메일·학교 인증으로 서버가 정한 학교 (보낸 학교는 무시)
    u := (public.clover_my_univs())[1];
  end if;
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
revoke all on function public.school_light_add(text, text) from public, anon;
grant execute on function public.school_light_add(text, text) to authenticated;
