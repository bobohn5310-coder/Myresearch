-- 학회 자동 수집: GitHub Actions 가 매일 data/conferences.json 을 갱신하고,
-- DB 안의 예약 작업(pg_cron)이 그 파일을 읽어 academic_info 에 반영한다.
-- GitHub 에 Supabase 키를 둘 필요가 없다. (2026-11-04 myresearch 프로젝트에 적용됨)

-- 1) 수집용 컬럼. 관리자가 직접 등록한 행은 source 가 NULL 로 남는다.
alter table public.academic_info add column if not exists source       text;
alter table public.academic_info add column if not exists external_id  text;
alter table public.academic_info add column if not exists last_seen_at timestamptz;
create unique index if not exists academic_info_external_id_key on public.academic_info (external_id);
create index if not exists academic_info_type_start_idx on public.academic_info (type, start_date);

-- 2) 확장
create extension if not exists http with schema extensions;
create extension if not exists pg_cron;

-- 3) 저장소의 JSON 을 읽어 upsert 하고, 종료 30일 지난 자동 수집 행을 지운다.
create or replace function public.sync_conferences()
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
    'https://raw.githubusercontent.com/bobohn5310-coder/Myresearch/main/data/conferences.json');
  if resp.status <> 200 then
    raise exception 'conferences.json 을 가져오지 못했습니다 (HTTP %)', resp.status;
  end if;

  insert into public.academic_info
    (type, field, title, org, start_date, end_date, date, content, url, tags, location,
     source, external_id, last_seen_at)
  select r->>'type', coalesce(r->>'field', 'all'), r->>'title', r->>'org',
         (r->>'start_date')::date, (r->>'end_date')::date, nullif(r->>'date', '')::date,
         r->>'content', r->>'url', r->>'tags', r->>'location',
         r->>'source', r->>'external_id', now()
  from jsonb_array_elements(resp.content::jsonb) as r
  where r->>'external_id' is not null and r->>'title' <> ''
  on conflict (external_id) do update set
    field = excluded.field, title = excluded.title, org = excluded.org,
    start_date = excluded.start_date, end_date = excluded.end_date, date = excluded.date,
    content = excluded.content, url = excluded.url, tags = excluded.tags,
    location = excluded.location, source = excluded.source, last_seen_at = now();
  get diagnostics n = row_count;

  delete from public.academic_info
  where source is not null and end_date < current_date - 30;

  return n;
end;
$$;

-- 웹사이트 방문자(anon)나 로그인 사용자가 이 함수를 호출하지 못하게 막는다.
revoke execute on function public.sync_conferences() from public, anon, authenticated;

-- 4) 매일 18:30 UTC (한국시간 03:30), Actions 수집(03:00) 30분 뒤 실행
select cron.schedule('sync-conferences', '30 18 * * *', 'select public.sync_conferences()');
