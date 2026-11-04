-- 학회 자동 수집용 컬럼 추가 (Supabase 대시보드 > SQL Editor 에서 한 번만 실행)
-- 기존 데이터와 관리자 화면은 그대로 동작합니다. 직접 등록한 행은 source 가 비어 있습니다.

alter table public.academic_info add column if not exists source       text;        -- 'ccfddl', 'wikicfp' 등 (직접 등록은 NULL)
alter table public.academic_info add column if not exists external_id  text;        -- 소스별 고유 ID, 중복 방지용
alter table public.academic_info add column if not exists last_seen_at timestamptz; -- 마지막으로 소스에서 확인된 시각

-- upsert(on_conflict=external_id)에 필요한 고유 인덱스. NULL 은 여러 개 허용되므로 기존 행에 영향 없음.
create unique index if not exists academic_info_external_id_key on public.academic_info (external_id);

-- 검색·정렬에 쓰는 인덱스
create index if not exists academic_info_type_start_idx on public.academic_info (type, start_date);
