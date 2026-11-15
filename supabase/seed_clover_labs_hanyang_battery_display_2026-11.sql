-- ════════════════════════════════════════════════
-- 🍀 운영자 등록 연구실: 한양대학교 이차전지·디스플레이 분야 (2026-11-15)
-- 먼저 clover_admin_labs.sql 을 실행한 상태여야 합니다 (반도체 시범 수집 때 이미 실행했다면 다시 안 해도 됨).
-- 이 파일 전체를 Supabase → SQL Editor 에 붙여넣고 Run. 여러 번 실행해도 안전합니다
-- (같은 학교 + 같은 교수님 연구실이 이미 있으면 건너뜀).
--
-- 담긴 것: 한양대학교 13개 연구실 (이차전지 6 · 디스플레이 7)
-- 담지 않은 것: 클로버 점수·평가(회원 투표로 채워짐), 개인 연락처·학생 정보, 대표 논문·연구 과제
-- 원본 자료: data/clover-labs/hanyang-battery-display-2026-11.json
--
-- 되돌리기: delete from public.clover_labs where source = 'admin' and collected_at = '2026-11-15'
--           and not exists (select 1 from public.clover_votes v where v.lab_id = clover_labs.id);
-- ════════════════════════════════════════════════

begin;

-- 한양대학교 대학원 배터리공학과 · 에너지저장 및 변환소재 연구실 (이차전지)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 배터리공학과', '에너지저장 및 변환소재 연구실', '리튬이온전지 양극·음극 소재 합성과 전지 성능 분석', '선양국',
       'admin', 'http://escml.hanyang.ac.kr/', 'https://battery.hanyang.ac.kr/lab1', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('선양국'));

-- 한양대학교 대학원 배터리공학과 · 메소스케일 재료분석 합성 연구실 (이차전지)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 배터리공학과', '메소스케일 재료분석 합성 연구실', '리튬이온전지 양극 소재 합성(단결정·도핑·미세구조)과 TEM 분석', '윤종승',
       'admin', 'http://meso.hanyang.ac.kr/', 'https://battery.hanyang.ac.kr/lab2', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('윤종승'));

-- 한양대학교 대학원 배터리공학과 · 전기화학소재연구실 (이차전지)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 배터리공학과', '전기화학소재연구실', '고분자·유무기 복합 전기화학 소재, 리튬금속·전고체·무음극 전지', '김동원',
       'admin', 'http://www.echemmat.com/', 'https://battery.hanyang.ac.kr/lab3', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김동원'));

-- 한양대학교 대학원 배터리공학과 · 차세대 전기화학 연구실 (이차전지)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 배터리공학과', '차세대 전기화학 연구실', '차세대 리튬전지 고용량 음극(실리콘·리튬금속), 무기 전해질 전지', '김한수',
       'admin', 'http://hkim.hanyang.ac.kr/aetl/main/', 'https://battery.hanyang.ac.kr/lab4', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김한수'));

-- 한양대학교 대학원 배터리공학과 · 표면과학연구실 (이차전지)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 배터리공학과', '표면과학연구실', '리튬이온·수계 아연이온 전지 전극, 슈퍼커패시터, 신축성 에너지저장', '안희준',
       'admin', 'https://sites.google.com/view/surfacesciencelab', 'https://battery.hanyang.ac.kr/lab6', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('안희준'));

-- 한양대학교 대학원 배터리공학과 · 나노재료 에너지소자 연구실 (이차전지)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 배터리공학과', '나노재료 에너지소자 연구실', '리튬금속·전고체 고용량 저장 소재, 수전해 촉매, 신축성 소자', '송태섭',
       'admin', 'https://hyunmed1.wixsite.com/nmedl', 'https://battery.hanyang.ac.kr/lab7', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('송태섭'));

-- 한양대학교 융합전자공학부 · 디스플레이소자 연구실 (디스플레이)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '융합전자공학부', '디스플레이소자 연구실', 'LCD·OLED·전자종이 디스플레이 소자, 액정 물리, 유기전자소자', '김재훈',
       'admin', 'http://ddlab.hanyang.ac.kr', 'http://electronic.hanyang.ac.kr/kor/professor/professor_view.php?idx=26&gubun=7&pNo=1', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김재훈'));

-- 한양대학교 융합전자공학부 · 정재경 연구실 (디스플레이)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '융합전자공학부', '정재경 연구실', 'TFT, 센서, 신축성 전자소자', '정재경',
       'admin', 'http://sndlab.hanyang.ac.kr/', 'http://electronic.hanyang.ac.kr/eng/professor/professor_view.php?idx=34&gubun=7&pNo=1', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정재경'));

-- 한양대학교 대학원 디스플레이융합공학과 · 유창재 연구실 (디스플레이)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 디스플레이융합공학과', '유창재 연구실', 'LCD, OLED, 디스플레이 광학', '유창재',
       'admin', 'https://sites.google.com/view/noveldisplaylab', 'https://displayeng.hanyang.ac.kr/index.php?hCode=MEMBERS_02_01', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('유창재'));

-- 한양대학교 대학원 디스플레이융합공학과 · 박진성 연구실 (디스플레이)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 디스플레이융합공학과', '박진성 연구실', '차세대 박막 공정, 차세대 TFT', '박진성',
       'admin', 'http://hylime.kr', 'https://displayeng.hanyang.ac.kr/index.php?hCode=MEMBERS_02_01', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박진성'));

-- 한양대학교 대학원 디스플레이융합공학과 · 한태희 연구실 (디스플레이)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 디스플레이융합공학과', '한태희 연구실', 'OLED, 페로브스카이트 LED, 태양전지', '한태희',
       'admin', 'http://hanyang-aomd.com', 'https://displayeng.hanyang.ac.kr/index.php?hCode=MEMBERS_02_01', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('한태희'));

-- 한양대학교 대학원 디스플레이융합공학과 · 최병덕 연구실 (디스플레이)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 디스플레이융합공학과', '최병덕 연구실', '아날로그 회로설계, 디스플레이 구동, 보안', '최병덕',
       'admin', 'http://siclab.hanyang.ac.kr', 'https://displayeng.hanyang.ac.kr/index.php?hCode=MEMBERS_02_01', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최병덕'));

-- 한양대학교 대학원 디스플레이융합공학과 · 임재명 연구실 (디스플레이)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '대학원 디스플레이융합공학과', '임재명 연구실', '디스플레이 구동회로 및 백플레인 설계', '임재명',
       'admin', 'https://sites.google.com/hanyang.ac.kr/isoclab', 'https://displayeng.hanyang.ac.kr/index.php?hCode=MEMBERS_02_01', date '2026-11-15', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('임재명'));

commit;

-- 확인: 한양대학교 운영자 등록 연구실 (클로버 수 0 = '자라는 중')
select l.id, l.dept, l.name, l.prof, l.topic, l.homepage,
       (select count(*) from public.clover_votes v where v.lab_id = l.id) as clovers
  from public.clover_labs l
 where l.source = 'admin' and l.univ = public.clover_canon_univ('한양대학교')
 order by l.collected_at, l.dept, l.name;
