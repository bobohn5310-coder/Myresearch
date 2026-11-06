-- 학회 초록 마감일·등록 마감일 컬럼 추가 (Supabase SQL Editor 에서 한 번 실행)
-- 논문 투고 마감일은 기존 date 컬럼을 그대로 쓴다.
alter table public.academic_info add column if not exists abstract_deadline date;
alter table public.academic_info add column if not exists registration_deadline date;

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
    (type, field, title, org, start_date, end_date, date, abstract_deadline, registration_deadline,
     content, url, tags, location, source, external_id, last_seen_at)
  select r->>'type', coalesce(r->>'field', 'all'), r->>'title', r->>'org',
         (r->>'start_date')::date, (r->>'end_date')::date, nullif(r->>'date', '')::date,
         nullif(r->>'abstract_deadline', '')::date, nullif(r->>'registration_deadline', '')::date,
         r->>'content', r->>'url', r->>'tags', r->>'location',
         r->>'source', r->>'external_id', now()
  from jsonb_array_elements(resp.content::jsonb) as r
  where r->>'external_id' is not null and r->>'title' <> ''
  on conflict (external_id) do update set
    field = excluded.field, title = excluded.title, org = excluded.org,
    start_date = excluded.start_date, end_date = excluded.end_date, date = excluded.date,
    abstract_deadline = excluded.abstract_deadline, registration_deadline = excluded.registration_deadline,
    content = excluded.content, url = excluded.url, tags = excluded.tags,
    location = excluded.location, source = excluded.source, last_seen_at = now();
  get diagnostics n = row_count;

  delete from public.academic_info
  where source is not null and end_date < current_date - 30;

  return n;
end;
$$;

revoke execute on function public.sync_conferences() from public, anon, authenticated;
