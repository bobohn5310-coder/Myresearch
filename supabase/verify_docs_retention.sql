-- ════════════════════════════════════════════════════════════════
-- 학교 인증 서류 6개월 보관 후 삭제 (2026-11-06)
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 Run 한 번. 여러 번 실행해도 안전.
--
-- 개인정보처리방침: "학교 인증 서류는 제출일로부터 6개월 후 삭제".
-- Supabase 는 SQL 로 저장소 파일을 직접 지우는 것을 막아 두었기 때문에,
-- 실제 삭제는 관리자 화면(admin.html)을 열 때 저장소 API 로 자동 실행된다.
-- 이 파일은 그 삭제를 관리자에게 허용하는 규칙만 추가한다.
-- ════════════════════════════════════════════════════════════════

drop policy if exists "verify-docs 관리자 삭제" on storage.objects;
create policy "verify-docs 관리자 삭제" on storage.objects
  for delete to authenticated
  using (bucket_id = 'verify-docs' and public.is_admin());

-- 확인용: 6개월이 지났는데 아직 남아 있는 서류 수 (0 이면 정상)
-- select count(*) from storage.objects
--  where bucket_id = 'verify-docs' and created_at < now() - interval '183 days';
