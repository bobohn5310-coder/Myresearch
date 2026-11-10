-- ════════════════════════════════════════════════
-- 💬 학회 한 줄 후기: 인증 회원 + 참석 증빙 사진 + 관리자 승인
-- conf_reviews.sql 을 먼저 실행한 뒤, 이 파일 전체를 SQL Editor 에 붙여넣고 Run.
-- 여러 번 실행해도 안전합니다.
--
--  · 학교 메일(ac.kr, edu) 가입자 또는 학교 인증 회원만 쓸 수 있음 (클로버와 같은 조건 can_clover)
--  · 쓸 때 참석 증빙 사진(명찰, 등록 확인 메일, 영수증 등)을 꼭 올려야 함
--  · 새 후기는 '확인 중'으로 들어가고, 관리자가 승인해야 사이트에 보임
--  · 증빙 사진은 비공개 저장소(conf-proofs)에 올라가고, 관리자가 승인·반려하면 바로 지움
-- ════════════════════════════════════════════════

-- 1) 후기에 승인 상태와 증빙 사진 칸 추가 (이미 있던 후기는 승인된 것으로 둠)
alter table public.conf_reviews add column if not exists status text not null default 'approved'
  check (status in ('pending','approved','rejected'));
alter table public.conf_reviews alter column status set default 'pending';
alter table public.conf_reviews add column if not exists proof_path    text check (char_length(proof_path) <= 300);
alter table public.conf_reviews add column if not exists reject_reason text check (char_length(reject_reason) <= 200);
alter table public.conf_reviews add column if not exists reviewed_at   timestamptz;

-- 2) 쓰기 규칙: 인증 회원 + 증빙 사진(내 폴더) + '확인 중' 상태로만
drop policy if exists "학회 후기 남기기" on public.conf_reviews;
create policy "학회 후기 남기기" on public.conf_reviews for insert to authenticated
  with check (user_id = auth.uid() and hidden = false and status = 'pending'
              and public.can_clover()
              and proof_path is not null
              and split_part(proof_path, '/', 1) = auth.uid()::text
              and conf_year <= extract(year from now())::int);

-- 3) 공개 목록: 승인된 후기만. 내 후기는 확인 중·반려도 나에게만 보임
drop function if exists public.conf_reviews_public();
create or replace function public.conf_reviews_public()
returns table (id bigint, series_key text, conf_year int, good boolean, body text, created_at timestamptz,
               mine boolean, status text, reject_reason text, proof_path text)
language sql stable security definer set search_path = public as $$
  select r.id, r.series_key, r.conf_year, r.good, r.body, r.created_at,
         coalesce(r.user_id = auth.uid(), false), r.status,
         case when r.user_id = auth.uid() then r.reject_reason end,
         case when r.user_id = auth.uid() then r.proof_path end
  from public.conf_reviews r
  where (r.status = 'approved' and not r.hidden)
     or (auth.uid() is not null and r.user_id = auth.uid())
  order by r.series_key, r.conf_year desc, r.created_at desc
$$;
grant execute on function public.conf_reviews_public() to anon, authenticated;

-- 4) 증빙 사진 저장소: 비공개, 사진만, 10MB
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('conf-proofs', 'conf-proofs', false, 10 * 1024 * 1024,
        array['image/jpeg','image/png','image/webp','image/heic'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "conf-proofs 본인 폴더 업로드" on storage.objects;
create policy "conf-proofs 본인 폴더 업로드" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'conf-proofs' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "conf-proofs 관리자 열람" on storage.objects;
create policy "conf-proofs 관리자 열람" on storage.objects
  for select to authenticated
  using (bucket_id = 'conf-proofs' and public.is_admin());
drop policy if exists "conf-proofs 삭제" on storage.objects;
create policy "conf-proofs 삭제" on storage.objects
  for delete to authenticated
  using (bucket_id = 'conf-proofs' and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text));

-- 5) 관리자: 승인함 목록
create or replace function public.admin_conf_review_queue(p_status text default 'pending')
returns table (id bigint, user_id uuid, email text, name text, is_verified boolean,
               series_key text, conf_name text, conf_year int, good boolean, body text,
               proof_path text, status text, reject_reason text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  return query
  select r.id, r.user_id, u.email::text, (u.raw_user_meta_data->>'name')::text, coalesce(p.is_verified, false),
         r.series_key, r.conf_name, r.conf_year, r.good, r.body,
         r.proof_path, r.status, r.reject_reason, r.created_at
  from public.conf_reviews r
  left join auth.users u on u.id = r.user_id
  left join public.profiles p on p.id = r.user_id
  where p_status = 'all' or r.status = p_status
  order by r.created_at desc
  limit 300;
end $$;
revoke all on function public.admin_conf_review_queue(text) from public, anon;
grant execute on function public.admin_conf_review_queue(text) to authenticated;

-- 6) 관리자: 승인 / 반려. 처리하면 증빙 사진 경로를 비우고, 지울 경로를 돌려준다
--    (Supabase 는 SQL 로 저장소 파일을 지우지 못하게 막아 두어서, 실제 파일 삭제는 관리자 화면이 한다)
create or replace function public.admin_conf_review_decide(p_id bigint, p_action text, p_reason text default null)
returns text language plpgsql security definer set search_path = public as $$
declare old_path text;
begin
  if not public.is_admin() then raise exception 'not allowed'; end if;
  if p_action not in ('approve','reject') then raise exception 'bad action'; end if;
  select proof_path into old_path from public.conf_reviews where id = p_id;
  if not found then raise exception 'no review'; end if;
  update public.conf_reviews
     set status = case when p_action = 'approve' then 'approved' else 'rejected' end,
         reject_reason = case when p_action = 'reject' then nullif(left(btrim(coalesce(p_reason,'')), 200), '') end,
         reviewed_at = now(),
         proof_path = null
   where id = p_id;
  return old_path;
end $$;
revoke all on function public.admin_conf_review_decide(bigint, text, text) from public, anon;
grant execute on function public.admin_conf_review_decide(bigint, text, text) to authenticated;
