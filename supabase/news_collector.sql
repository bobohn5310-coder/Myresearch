-- 국내 연구소식 자동 수집: GitHub Actions 가 매일 data/news.json 을 갱신하고,
-- DB 안의 예약 작업(pg_cron)이 그 파일을 읽어 news 테이블에 반영한다.
-- GitHub 에 Supabase 키를 둘 필요가 없다.
-- Supabase 대시보드 > SQL Editor 에 이 파일 전체를 붙여 넣고 Run 을 누르면 된다. 여러 번 실행해도 안전하다.

-- 1) 수집용 컬럼. 관리자가 직접 등록한 소식은 source 가 NULL 로 남는다.
alter table public.news add column if not exists source       text;
alter table public.news add column if not exists external_id  text;
alter table public.news add column if not exists last_seen_at timestamptz;
create unique index if not exists news_external_id_key on public.news (external_id);

-- 2) 확장 (학회 자동 수집 때 이미 켜져 있으면 그대로 넘어간다)
create extension if not exists http with schema extensions;
create extension if not exists pg_cron;

-- 3) 저장소의 JSON 을 읽어 upsert 하고, 30일 지난 자동 수집 소식을 지운다.
create or replace function public.sync_news()
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  resp  extensions.http_response;
  n     integer;
begin
  select * into resp from extensions.http_get(
    'https://raw.githubusercontent.com/bobohn5310-coder/Myresearch/main/data/news.json');
  if resp.status <> 200 then
    raise exception 'news.json 을 가져오지 못했습니다 (HTTP %)', resp.status;
  end if;

  insert into public.news
    (org, field, tag, title, content, url, date, source, external_id, last_seen_at)
  select left(regexp_replace(r->>'org', '[<>]', '', 'g'), 60),
         coalesce(nullif(r->>'field', ''), 'eng'),
         left(regexp_replace(r->>'tag', '[<>]', '', 'g'), 30),
         left(regexp_replace(r->>'title', '[<>]', '', 'g'), 200),
         left(regexp_replace(coalesce(r->>'content', ''), '[<>]', '', 'g'), 200),
         r->>'url',
         (r->>'date')::date,
         r->>'source', r->>'external_id', now()
  from jsonb_array_elements(resp.content::jsonb) as r
  where r->>'external_id' is not null
    and coalesce(r->>'title', '') <> ''
    and r->>'url' ~* '^https?://'
  on conflict (external_id) do update set
    last_seen_at = now();   -- 이미 있는 소식은 관리자가 고친 내용을 덮어쓰지 않는다
  get diagnostics n = row_count;

  delete from public.news
  where source is not null and is_featured is not true and date < current_date - 30;

  return n;
end;
$$;

-- 웹사이트 방문자(anon)나 로그인 사용자가 이 함수를 호출하지 못하게 막는다.
revoke execute on function public.sync_news() from public, anon, authenticated;

-- 4) 매일 18:40 UTC (한국시간 03:40), Actions 수집(03:10) 30분 뒤 실행
select cron.schedule('sync-news', '40 18 * * *', 'select public.sync_news()');
