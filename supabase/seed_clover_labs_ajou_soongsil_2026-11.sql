-- ════════════════════════════════════════════════
-- 🍀 운영자 등록 연구실: 아주대학교·숭실대학교 공학 계열 (2026-11-19)
-- 먼저 clover_admin_labs.sql 을 실행한 상태여야 합니다 (반도체 시범 수집 때 이미 실행됨).
-- 이 파일 전체를 Supabase → SQL Editor 에 붙여넣고 Run. 여러 번 실행해도 안전합니다
-- (같은 학교 + 같은 교수님 연구실이 이미 있으면 건너뜀).
--
-- 담긴 것: 아주대학교 76곳 · 숭실대학교 57곳 = 133곳
-- 담지 않은 것: 클로버 점수·평가(회원 투표로 채워짐), 개인 연락처·학생 정보, 대표 논문
-- 원본 자료: data/clover-labs/ajou-soongsil-2026-11.json
--
-- 되돌리기: delete from public.clover_labs where source = 'admin' and collected_at = '2026-11-19'
--           and not exists (select 1 from public.clover_votes v where v.lab_id = clover_labs.id);
-- ════════════════════════════════════════════════

begin;

-- 아주대학교 전자공학과 · 집적회로시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '집적회로시스템 연구실', 'Analog/RF IC 설계, PMIC 설계', '권익진',
       'admin', 'http://icas.ajou.ac.kr/', 'https://www.ajou.ac.kr/ece/faculty/semiconductor-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('권익진'));

-- 아주대학교 전자공학과 · 김남헌 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '김남헌 연구실', '디스플레이, 포토닉스, 반도체 레이저, LED', '김남헌',
       'admin', null, 'https://www.ajou.ac.kr/ece/faculty/semiconductor-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김남헌'));

-- 아주대학교 전자공학과 · 다중레벨 정보 메모리 소자 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '다중레벨 정보 메모리 소자 연구실', 'CMOS 소자, 메모리 소자', '김장현',
       'admin', 'https://sites.google.com/ajou.ac.kr/midl', 'https://www.ajou.ac.kr/ece/faculty/semiconductor-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김장현'));

-- 아주대학교 전자공학과 · 유연소자 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '유연소자 연구실', '플렉서블 전자소자', '박성준',
       'admin', 'https://sites.google.com/view/softelectronics', 'https://www.ajou.ac.kr/ece/faculty/semiconductor-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박성준'));

-- 아주대학교 전자공학과 · 나노 및 마이크로시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '나노 및 마이크로시스템 연구실', 'MEMS, 센서, 표면탄성파(SAW), 태양전지', '이기근',
       'admin', null, 'https://www.ajou.ac.kr/ece/faculty/semiconductor-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이기근'));

-- 아주대학교 전자공학과 · 나노소자 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '나노소자 연구실', '화합물반도체, 태양전지, LED, LD', '이재진',
       'admin', null, 'https://www.ajou.ac.kr/ece/faculty/semiconductor-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이재진'));

-- 아주대학교 전자공학과 · 집적시스템설계 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '집적시스템설계 연구실', '아날로그/혼성신호 집적회로 설계', '지동우',
       'admin', 'https://sites.google.com/site/dongwoojee/', 'https://www.ajou.ac.kr/ece/faculty/semiconductor-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('지동우'));

-- 아주대학교 전자공학과 · 무선인터넷 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '무선인터넷 연구실', '6G 비지상 네트워크(NTN), 무선통신', '김재현',
       'admin', 'http://winner.ajou.ac.kr/', 'https://www.ajou.ac.kr/ece/faculty/communications-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김재현'));

-- 아주대학교 전자공학과 · RF 시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', 'RF 시스템 연구실', '무선 시스템, AI 신호처리', '김정욱',
       'admin', 'https://sites.google.com/view/rfst/home', 'https://www.ajou.ac.kr/ece/faculty/communications-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김정욱'));

-- 아주대학교 전자공학과 · 전자파 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '전자파 연구실', '전자파의 국방·통신·AI 응용', '박용배',
       'admin', 'http://wave.ajou.ac.kr', 'https://www.ajou.ac.kr/ece/faculty/communications-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박용배'));

-- 아주대학교 전자공학과 · 멀티미디어 네트워킹 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '멀티미디어 네트워킹 연구실', '멀티미디어 네트워킹', '이채우',
       'admin', null, 'https://www.ajou.ac.kr/ece/faculty/communications-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이채우'));

-- 아주대학교 전자공학과 · 응용전자기학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '응용전자기학 연구실', '전자기학, 전파공학', '이학준',
       'admin', 'https://sites.google.com/view/metawavelab', 'https://www.ajou.ac.kr/ece/faculty/communications-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이학준'));

-- 아주대학교 전자공학과 · 인공지능 기반 통신시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '인공지능 기반 통신시스템 연구실', '통신시스템, 인공지능', '이호원',
       'admin', 'https://acelab.ajou.ac.kr/home', 'https://www.ajou.ac.kr/ece/faculty/communications-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이호원'));

-- 아주대학교 전자공학과 · SCL 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', 'SCL 연구실', '무선통신, AI통신, 무선센싱', '장수환',
       'admin', 'https://sites.google.com/ajou.ac.kr/smartcomm', 'https://www.ajou.ac.kr/ece/faculty/communications-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('장수환'));

-- 아주대학교 전자공학과 · RF무선통신 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', 'RF무선통신 연구실', '무선통신, 신호처리, 머신러닝', '정방철',
       'admin', 'https://sites.google.com/site/bangchuljung/', 'https://www.ajou.ac.kr/ece/faculty/communications-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정방철'));

-- 아주대학교 전자공학과 · 초고주파 집적회로 및 시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '초고주파 집적회로 및 시스템 연구실', '차세대 무선통신용 초고주파 회로 및 시스템', '주인찬',
       'admin', 'https://sige.ajou.ac.kr/', 'https://www.ajou.ac.kr/ece/faculty/communications-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('주인찬'));

-- 아주대학교 전자공학과 · 컴퓨터 비전 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '컴퓨터 비전 연구실', '컴퓨터 비전, 머신러닝', '구형일',
       'admin', 'https://sites.google.com/view/ajoucvml', 'https://www.ajou.ac.kr/ece/faculty/computer-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('구형일'));

-- 아주대학교 전자공학과 · 시스템 제어이론 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '시스템 제어이론 연구실', '이산사건 시스템 제어', '박성진',
       'admin', 'https://sites.google.com/a/ajou.ac.kr/parksjin/home', 'https://www.ajou.ac.kr/ece/faculty/computer-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박성진'));

-- 아주대학교 전자공학과 · 양자컴퓨팅 소프트웨어 및 시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '양자컴퓨팅 소프트웨어 및 시스템 연구실', '양자컴퓨팅 소프트웨어 및 시스템', '박성혜',
       'admin', 'https://sites.google.com/view/qcss-lab', 'https://www.ajou.ac.kr/ece/faculty/computer-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박성혜'));

-- 아주대학교 전자공학과 · 인공지능 시스템 및 컴퓨터 구조 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '인공지능 시스템 및 컴퓨터 구조 연구실', '인공지능 시스템, 컴퓨터 구조', '오영환',
       'admin', 'https://aisa.ajou.ac.kr', 'https://www.ajou.ac.kr/ece/faculty/computer-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('오영환'));

-- 아주대학교 전자공학과 · 임베디드&소프트웨어 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '임베디드&소프트웨어 연구실', '임베디드 소프트웨어, 소프트웨어 테스팅, 온톨로지 모델링', '이정원',
       'admin', 'https://eslab.ajou.ac.kr/', 'https://www.ajou.ac.kr/ece/faculty/computer-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이정원'));

-- 아주대학교 전자공학과 · 비선형제어로봇 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '비선형제어로봇 연구실', '비선형·적응·강인 제어, 로봇 시스템', '좌동경',
       'admin', 'http://robot.ajou.ac.kr', 'https://www.ajou.ac.kr/ece/faculty/computer-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('좌동경'));

-- 아주대학교 전자공학과 · 멀티미디어 신호처리 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '멀티미디어 신호처리 연구실', '컴퓨터 비전, 계산 사진학', '허용석',
       'admin', 'https://sites.google.com/view/ajoumspl', 'https://www.ajou.ac.kr/ece/faculty/computer-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('허용석'));

-- 아주대학교 전자공학과 · 휴먼로보틱스 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '휴먼로보틱스 연구실', '로봇 제어', '홍영대',
       'admin', 'https://sites.google.com/a/ajou.ac.kr/hrlab/', 'https://www.ajou.ac.kr/ece/faculty/computer-faculty.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('홍영대'));

-- 아주대학교 전자공학과 · 광통신 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '광통신 연구실', '나노포토닉스', '김상인',
       'admin', null, 'https://www.ajou.ac.kr/ece/faculty/system-faculty01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김상인'));

-- 아주대학교 전자공학과 · 차세대 반도체 소자 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '차세대 반도체 소자 연구실', '차세대 메모리 소자', '문태환',
       'admin', 'https://sites.google.com/view/emtl-ajou', 'https://www.ajou.ac.kr/ece/faculty/system-faculty01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('문태환'));

-- 아주대학교 전자공학과 · 반도체 소자 공정 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '반도체 소자 공정 연구실', '반도체 소자 및 공정', '오일권',
       'admin', 'https://sdpl.ajou.ac.kr/', 'https://www.ajou.ac.kr/ece/faculty/system-faculty01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('오일권'));

-- 아주대학교 전자공학과 · 반도체 회로 및 시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '반도체 회로 및 시스템 연구실', '디지털 집적회로 및 시스템 설계', '이종민',
       'admin', 'https://sites.google.com/ajou.ac.kr/aisic', 'https://www.ajou.ac.kr/ece/faculty/system-faculty01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이종민'));

-- 아주대학교 전자공학과 · SRSC 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', 'SRSC 연구실', '디지털 시스템 설계, SoC 테스트', '이하영',
       'admin', 'https://sites.google.com/ajou.ac.kr/srsc-lab', 'https://www.ajou.ac.kr/ece/faculty/system-faculty01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이하영'));

-- 아주대학교 전자공학과 · 반도체 소자 및 집적 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '반도체 소자 및 집적 연구실', '반도체 소자', '허준석',
       'admin', 'https://sites.google.com/view/isdilab/isdi', 'https://www.ajou.ac.kr/ece/faculty/system-faculty01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('허준석'));

-- 아주대학교 전자공학과 · 임베디드 컴퓨팅 및 시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '임베디드 컴퓨팅 및 시스템 연구실', '임베디드 시스템 및 소프트웨어', '김영진',
       'admin', 'http://ecsl.ajou.ac.kr/', 'https://www.ajou.ac.kr/ece/faculty/system-faculty02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김영진'));

-- 아주대학교 전자공학과 · 전력전자 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '전력전자 연구실', '전력전자, 전기차 응용', '이교범',
       'admin', 'http://pel.ajou.ac.kr/', 'https://www.ajou.ac.kr/ece/faculty/system-faculty02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이교범'));

-- 아주대학교 전자공학과 · 지능자율시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '지능자율시스템 연구실', '모빌리티 네트워크 제어', '정소이',
       'admin', 'https://ias.ajou.ac.kr/', 'https://www.ajou.ac.kr/ece/faculty/system-faculty02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정소이'));

-- 아주대학교 전자공학과 · 전력시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '전자공학과', '전력시스템 연구실', '전력시스템, 신재생에너지', '정재성',
       'admin', 'http://powerlab.ajou.ac.kr/', 'https://www.ajou.ac.kr/ece/faculty/system-faculty02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정재성'));

-- 아주대학교 첨단신소재공학과 · 고분자 나노재료 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '첨단신소재공학과', '고분자 나노재료 연구실', '고분자 재료, 반도체 나노패터닝, 차세대 반도체 소자', '김장환',
       'admin', null, 'https://www.ajou.ac.kr/mse/research/lab12.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김장환'));

-- 아주대학교 첨단신소재공학과 · 김준규 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '첨단신소재공학과', '김준규 연구실', '금속산화물 표면편석 제어, 연료전지, 수소생산 촉매', '김준규',
       'admin', null, 'https://www.ajou.ac.kr/mse/faculty/faculty001.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김준규'));

-- 아주대학교 첨단신소재공학과 · 김형도 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '첨단신소재공학과', '김형도 연구실', '유·무기 반도체 광전자 소재 및 소자, 소자물리', '김형도',
       'admin', null, 'https://www.ajou.ac.kr/mse/faculty/faculty001.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김형도'));

-- 아주대학교 첨단신소재공학과 · 저차원재료 성장 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '첨단신소재공학과', '저차원재료 성장 연구실', '저차원 나노 재료, 박막 X-선 회절, 물리화학', '류학기',
       'admin', null, 'https://www.ajou.ac.kr/mse/research/lab10.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('류학기'));

-- 아주대학교 첨단신소재공학과 · 문석호 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '첨단신소재공학과', '문석호 연구실', '이차원 소재, 양자소재, 차세대 광·전자 소자', '문석호',
       'admin', null, 'https://www.ajou.ac.kr/mse/faculty/faculty001.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('문석호'));

-- 아주대학교 첨단신소재공학과 · 다차원 에너지재료 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '첨단신소재공학과', '다차원 에너지재료 연구실', '이차전지 전극소재, 차세대배터리, 전고체전지', '박진성',
       'admin', null, 'https://www.ajou.ac.kr/mse/research/lab06.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박진성'));

-- 아주대학교 첨단신소재공학과 · 광전자 재료 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '첨단신소재공학과', '광전자 재료 연구실', '에너지 소재, 디스플레이 소재, 나노 전자 소재 및 소자', '서형탁',
       'admin', null, 'https://www.ajou.ac.kr/mse/research/lab05.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('서형탁'));

-- 아주대학교 첨단신소재공학과 · 첨단구조 재료 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '첨단신소재공학과', '첨단구조 재료 연구실', '고엔트로피합금, 금속 3D프린팅, 수소저장합금, 분말재료', '안병민',
       'admin', null, 'https://www.ajou.ac.kr/mse/research/lab04.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('안병민'));

-- 아주대학교 첨단신소재공학과 · 에너지/촉매 재료 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '첨단신소재공학과', '에너지/촉매 재료 연구실', '에너지·촉매 재료, 광열 재료, (광)전기화학 소재·소자', '조인선',
       'admin', null, 'https://www.ajou.ac.kr/mse/research/lab03.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('조인선'));

-- 아주대학교 화학공학과 · 미세공정유체연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '화학공학과', '미세공정유체연구실', '유변학, 이차전지 제조공정, 미세유체공학', '김주민',
       'admin', 'https://www.smml-ajou.com/', 'https://www.ajou.ac.kr/che/research/research02-1.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김주민'));

-- 아주대학교 화학공학과 · 김주형 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '화학공학과', '김주형 연구실', '유기전자재료, 표면/계면 분석 및 제어', '김주형',
       'admin', null, 'https://www.ajou.ac.kr/che/faculty/professor01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김주형'));

-- 아주대학교 화학공학과 · 박명준 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '화학공학과', '박명준 연구실', '반응속도식 및 반응기 개발, 공정 모델링 및 제어', '박명준',
       'admin', null, 'https://www.ajou.ac.kr/che/faculty/professor01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박명준'));

-- 아주대학교 화학공학과 · 박은덕 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '화학공학과', '박은덕 연구실', '촉매 및 반응공학', '박은덕',
       'admin', null, 'https://www.ajou.ac.kr/che/faculty/professor01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박은덕'));

-- 아주대학교 화학공학과 · 심태섭 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '화학공학과', '심태섭 연구실', '고분자 합성, 유연 에너지소재, 콜로이드 자기조립체', '심태섭',
       'admin', null, 'https://www.ajou.ac.kr/che/faculty/professor01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('심태섭'));

-- 아주대학교 화학공학과 · 이지영 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '화학공학과', '이지영 연구실', '친환경 배터리, 유기재료, 고분자, 전기화학', '이지영',
       'admin', null, 'https://www.ajou.ac.kr/che/faculty/professor01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이지영'));

-- 아주대학교 화학공학과 · 황종국 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '화학공학과', '황종국 연구실', '나노다공소재, 차세대 이차전지, 폐배터리 자원화', '황종국',
       'admin', null, 'https://www.ajou.ac.kr/che/faculty/professor01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('황종국'));

-- 아주대학교 기계공학과 · 기계 진단 실험실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '기계공학과', '기계 진단 실험실', '기계 상태 모니터링·진단', '채장범',
       'admin', null, 'https://www.ajou.ac.kr/me/research/mechenic01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('채장범'));

-- 아주대학교 기계공학과 · 고분자 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '기계공학과', '고분자 연구실', '고분자, 나노복합재, 생체재료, 연성물질', '권준표',
       'admin', 'https://godjunpyo.com', 'https://www.ajou.ac.kr/me/research/kwon01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('권준표'));

-- 아주대학교 기계공학과 · 구조나노바이오역학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '기계공학과', '구조나노바이오역학 연구실', '구조 나노바이오 역학', '이재영',
       'admin', 'https://sun.ajou.ac.kr', 'https://www.ajou.ac.kr/me/research/structural01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이재영'));

-- 아주대학교 기계공학과 · 나노유체 실험실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '기계공학과', '나노유체 실험실', '나노유체, 열에너지 저장, 열전달', '조병남',
       'admin', 'https://www.ajounatelab.com/', 'https://www.ajou.ac.kr/me/research/nano01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('조병남'));

-- 아주대학교 기계공학과 · 멀티스케일 소음 진동 실험실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '기계공학과', '멀티스케일 소음 진동 실험실', '진동·소음, 최적설계, 음향·진동 메타물질, AI', '이진우',
       'admin', null, 'https://www.ajou.ac.kr/me/research/noise01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이진우'));

-- 아주대학교 기계공학과 · 소프트 실험실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '기계공학과', '소프트 실험실', '소프트 실험실(SoftLab), 하종현 교수 공동 지도', '최정일',
       'admin', 'https://www.softlab.ajou.ac.kr/', 'https://www.ajou.ac.kr/me/research/soft01.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최정일'));

-- 아주대학교 소프트웨어학과 · 강경란 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '강경란 연구실', '컴퓨터 네트워크, 분산 학습', '강경란',
       'admin', 'http://madang.ajou.ac.kr/~korykang', 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('강경란'));

-- 아주대학교 소프트웨어학과 · 강기천 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '강기천 연구실', '피지컬 AI, 로봇 학습, 인간-로봇 상호작용', '강기천',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('강기천'));

-- 아주대학교 소프트웨어학과 · 고영배 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '고영배 연구실', 'IoT, UWB 실내 측위, 블록체인', '고영배',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('고영배'));

-- 아주대학교 소프트웨어학과 · 곽재헌 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '곽재헌 연구실', '모바일 시스템', '곽재헌',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('곽재헌'));

-- 아주대학교 소프트웨어학과 · 김상훈 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '김상훈 연구실', '운영체제, 메모리 시스템, 스토리지 시스템', '김상훈',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김상훈'));

-- 아주대학교 소프트웨어학과 · 김영훈 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '김영훈 연구실', '네트워킹 시스템', '김영훈',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김영훈'));

-- 아주대학교 소프트웨어학과 · 노병희 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '노병희 연구실', '연합학습, 미래인터넷(SDN), IoT, 혼합현실', '노병희',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('노병희'));

-- 아주대학교 소프트웨어학과 · 류기열 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '류기열 연구실', '대규모 소프트웨어 시스템', '류기열',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('류기열'));

-- 아주대학교 소프트웨어학과 · 박성현 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '박성현 연구실', '로보틱스, 컴퓨터비전', '박성현',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박성현'));

-- 아주대학교 소프트웨어학과 · 손경아 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '손경아 연구실', '머신러닝, 바이오메디컬 인포매틱스', '손경아',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('손경아'));

-- 아주대학교 소프트웨어학과 · 오상윤 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '오상윤 연구실', '분산·병렬 시스템, 웹 시스템, 클라우드 컴퓨팅', '오상윤',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('오상윤'));

-- 아주대학교 소프트웨어학과 · 유리 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '유리 연구실', '디지털 휴먼, 캐릭터 애니메이션 및 제어', '유리',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('유리'));

-- 아주대학교 소프트웨어학과 · 유종빈 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '유종빈 연구실', '딥러닝, 인공지능, 컴퓨터 비전', '유종빈',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('유종빈'));

-- 아주대학교 소프트웨어학과 · 이상훈 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '이상훈 연구실', '음성 AI, 생성 모델', '이상훈',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이상훈'));

-- 아주대학교 소프트웨어학과 · 이석원 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '이석원 연구실', '소프트웨어공학, 인공지능, 정보보호', '이석원',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이석원'));

-- 아주대학교 소프트웨어학과 · 이슬 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '이슬 연구실', '헬스케어 머신러닝, 텐서 분석', '이슬',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이슬'));

-- 아주대학교 소프트웨어학과 · 이환용 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '이환용 연구실', '컴퓨터 그래픽스, 영상처리', '이환용',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이환용'));

-- 아주대학교 소프트웨어학과 · 조다정 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '조다정 연구실', '오토마타 및 형식 언어 이론', '조다정',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('조다정'));

-- 아주대학교 소프트웨어학과 · 조현석 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '조현석 연구실', '멀티모달 데이터, 대규모 언어모델, 추천시스템', '조현석',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('조현석'));

-- 아주대학교 소프트웨어학과 · 최영준 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('아주대학교'), '소프트웨어학과', '최영준 연구실', '모바일 플랫폼, 무선네트워크', '최영준',
       'admin', null, 'https://www.ajou.ac.kr/sw/faculty/professor02.do', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('아주대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최영준'));

-- 숭실대학교 컴퓨터학부 · 고성능 컴퓨터시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '고성능 컴퓨터시스템 연구실', '컴퓨터시스템, 지능형 IoT 임베디드시스템, GPU 구조', '김철홍',
       'admin', 'https://sites.google.com/view/hpcs-ssu', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김철홍'));

-- 숭실대학교 컴퓨터학부 · 나현숙 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '나현숙 연구실', '알고리즘, 계산기하학, 정보이론', '나현숙',
       'admin', 'https://geocomp.ssu.ac.kr', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('나현숙'));

-- 숭실대학교 컴퓨터학부 · 데이터베이스 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '데이터베이스 연구실', '데이터베이스, 멀티미디어 데이터베이스, 임베디드 SW', '박동주',
       'admin', 'http://dblab.ssu.ac.kr/', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박동주'));

-- 숭실대학교 컴퓨터학부 · 송현주 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '송현주 연구실', '인간-컴퓨터 상호작용, 기계학습', '송현주',
       'admin', 'http://vis.ssu.ac.kr', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('송현주'));

-- 숭실대학교 컴퓨터학부 · ICN 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', 'ICN 연구실', '컴퓨터 네트워크, 그룹통신, 분산 컴퓨팅', '신용태',
       'admin', 'http://icn.ssu.ac.kr/', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('신용태'));

-- 숭실대학교 컴퓨터학부 · 유용석 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '유용석 연구실', '인공지능, 계산 뇌과학, 자연어 처리', '유용석',
       'admin', 'https://ssuai.pages.dev', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('유용석'));

-- 숭실대학교 컴퓨터학부 · Deep Imaging Laboratory
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', 'Deep Imaging Laboratory', '딥러닝, 컴퓨터 비전, 컴퓨터 그래픽스', '이정진',
       'admin', 'http://www.gilab.co.kr/', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이정진'));

-- 숭실대학교 컴퓨터학부 · 이현욱 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '이현욱 연구실', '기계학습, 인공지능, 설명 가능한 AI(XAI)', '이현욱',
       'admin', null, 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이현욱'));

-- 숭실대학교 컴퓨터학부 · 조은상 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '조은상 연구실', '컴퓨터 네트워크, 보안, 인공지능', '조은상',
       'admin', null, 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('조은상'));

-- 숭실대학교 컴퓨터학부 · 천명준 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '천명준 연구실', '컴퓨터 아키텍처, 메모리·저장장치 시스템', '천명준',
       'admin', 'https://isa.ssu.ac.kr', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('천명준'));

-- 숭실대학교 컴퓨터학부 · 최봉준 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '최봉준 연구실', '사물인터넷, 에너지 시스템, 분산컴퓨팅, 정보보호', '최봉준',
       'admin', 'https://sites.google.com/view/davidchoi', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최봉준'));

-- 숭실대학교 컴퓨터학부 · 최승훈 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', '최승훈 연구실', '운영체제, 시스템소프트웨어, 온디바이스 AI', '최승훈',
       'admin', 'https://sites.google.com/view/icsl-ssu/', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최승훈'));

-- 숭실대학교 컴퓨터학부 · OS 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', 'OS 연구실', '운영체제, 임베디드 SW, 실시간 시스템', '홍지만',
       'admin', 'http://os.ssu.ac.kr', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('홍지만'));

-- 숭실대학교 컴퓨터학부 · Machine Learning Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '컴퓨터학부', 'Machine Learning Lab', '기계학습, 생물정보학', '황규백',
       'admin', 'http://ml.ssu.ac.kr/', 'https://cse.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('황규백'));

-- 숭실대학교 소프트웨어학부 · COSMOS 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', 'COSMOS 연구실', '딥러닝, 블록체인, 클라우드, 온톨로지, 병렬처리', '김명호',
       'admin', 'http://cosmos.ssu.ac.kr', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김명호'));

-- 숭실대학교 소프트웨어학부 · Computer Vision Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', 'Computer Vision Lab', '로봇 비전, 형태인식, 증강현실', '김계영',
       'admin', 'http://cv.ssu.ac.kr', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김계영'));

-- 숭실대학교 소프트웨어학부 · 이상준 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '이상준 연구실', '데이터베이스, 모바일 데이터 처리', '이상준',
       'admin', 'http://bigcloud.ssu.ac.kr', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이상준'));

-- 숭실대학교 소프트웨어학부 · 이정현 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '이정현 연구실', '네트워크 보안, 시스템 보안, 모바일 보안', '이정현',
       'admin', 'http://csec.ssu.ac.kr', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이정현'));

-- 숭실대학교 소프트웨어학부 · Intelligent Security Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', 'Intelligent Security Lab', 'AI 보안, 사용자 인증, 개인정보보호', '최대선',
       'admin', 'http://aisc.ssu.ac.kr', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최대선'));

-- 숭실대학교 소프트웨어학부 · 조해현 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '조해현 연구실', '시스템 보안, 소프트웨어 보안', '조해현',
       'admin', 'https://haehyun.github.io', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('조해현'));

-- 숭실대학교 소프트웨어학부 · 공영호 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '공영호 연구실', '컴퓨터구조, 메모리시스템', '공영호',
       'admin', 'https://aica.ssu.ac.kr', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('공영호'));

-- 숭실대학교 소프트웨어학부 · 정진홍 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '정진홍 연구실', '데이터마이닝, 그래프 머신러닝', '정진홍',
       'admin', 'https://dmlab.ssu.ac.kr', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정진홍'));

-- 숭실대학교 소프트웨어학부 · 주경호 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '주경호 연구실', '자동차·무인이동체 보안, 무선통신 보안, 센서 보안', '주경호',
       'admin', 'https://sites.google.com/view/commsecssu', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('주경호'));

-- 숭실대학교 소프트웨어학부 · 한승훈 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '한승훈 연구실', '운영체제, 가상화, 하드웨어 및 시스템 보안', '한승훈',
       'admin', 'https://sites.google.com/view/osvslabssu', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98&page=2', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('한승훈'));

-- 숭실대학교 소프트웨어학부 · 김창훈 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '김창훈 연구실', '생성형 AI, AI 강건성', '김창훈',
       'admin', 'https://rpg-ai.org/', 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98&page=2', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김창훈'));

-- 숭실대학교 소프트웨어학부 · 김영종 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '김영종 연구실', '클라우드컴퓨팅, 블록체인', '김영종',
       'admin', null, 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98&page=2', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김영종'));

-- 숭실대학교 소프트웨어학부 · 박광영 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '박광영 연구실', '기술정책, 영상처리, 인공지능', '박광영',
       'admin', null, 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98&page=2', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박광영'));

-- 숭실대학교 소프트웨어학부 · 최형광 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '최형광 연구실', '오픈소스 리눅스, R 프로그래밍', '최형광',
       'admin', null, 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98&page=2', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최형광'));

-- 숭실대학교 소프트웨어학부 · 이재일 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '이재일 연구실', '디지털 인증, 정보보호정책, 사이버침해사고 대응', '이재일',
       'admin', null, 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98&page=2', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이재일'));

-- 숭실대학교 소프트웨어학부 · 옥도민 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '소프트웨어학부', '옥도민 연구실', '네트워킹, 스트리밍, 모바일 컴퓨팅', '옥도민',
       'admin', null, 'https://sw.ssu.ac.kr/bbs/board.php?bo_table=faculty&sca=%EC%A0%84%EC%9E%84%EA%B5%90%EC%88%98&page=2', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('옥도민'));

-- 숭실대학교 화학공학과 · 공정시스템공학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '공정시스템공학 연구실', '공정 모델링·모사, 공정 설계·조업·관리', '김병직',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김병직'));

-- 숭실대학교 화학공학과 · 신소재공정 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '신소재공정 연구실', '나노튜브 태양전지, 페이퍼형 디스플레이, 나노섬유', '허완수',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('허완수'));

-- 숭실대학교 화학공학과 · 환경생물공학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '환경생물공학 연구실', '스마트팜, 버섯 기반 소재, 악취·VOC·온실가스 저감', '류희욱',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('류희욱'));

-- 숭실대학교 화학공학과 · 수처리공학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '수처리공학 연구실', '활성탄 흡착, 정수 공정 개선, 고도처리', '홍성호',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('홍성호'));

-- 숭실대학교 화학공학과 · 촉매 및 대기공학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '촉매 및 대기공학 연구실', '대기오염물질 처리, 연료개질·산화 촉매', '권혁회',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('권혁회'));

-- 숭실대학교 화학공학과 · 에너지 소자 및 소재 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '에너지 소자 및 소재 연구실', '저온 연료전지·수전해, 이차전지, 전기화학', '박경원',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박경원'));

-- 숭실대학교 화학공학과 · 바이오재료공학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '바이오재료공학 연구실', '제약물질 결정화, 바이오미네랄, 유무기 결정 재료', '김일원',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김일원'));

-- 숭실대학교 화학공학과 · 세포 및 생체분자공학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '세포 및 생체분자공학 연구실', '바이오마커, 바이오의약품 공정, 장내환경 모사', '김윤곤',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김윤곤'));

-- 숭실대학교 화학공학과 · 하이브리드 나노바이오 공학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '하이브리드 나노바이오 공학 연구실', '나노전달체, 생체모방 소재, 세포기반 바이오 액추에이터', '정재현',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정재현'));

-- 숭실대학교 화학공학과 · 전기화학공정 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '전기화학공정 연구실', '에너지·환경 전기화학 공정, 반도체 배선 공정', '임태호',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('임태호'));

-- 숭실대학교 화학공학과 · 기능성 고분자 재료 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '기능성 고분자 재료 연구실', '기능성 고분자 합성, 열가소성 탄성체, 유기전자용 고분자', '강범구',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('강범구'));

-- 숭실대학교 화학공학과 · 고분자 엔지니어링 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '고분자 엔지니어링 연구실', '정보전자용 고분자, 디스플레이 소재, 자동차용 복합소재', '이준협',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이준협'));

-- 숭실대학교 화학공학과 · 다공성 유·무기 나노 소재 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '다공성 유·무기 나노 소재 연구실', 'MOF·제올라이트 나노다공성 소재, 흡착·분리 공정', '엄기원',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('엄기원'));

-- 숭실대학교 화학공학과 · 에너지환경시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '화학공학과', '에너지환경시스템 연구실', '가스 하이드레이트, 온실가스 포집·저장', '안윤호',
       'admin', null, 'http://chemeng.ssu.ac.kr/sub/sub05_01.php', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('안윤호'));

-- 숭실대학교 전기공학부 · Power System Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전기공학부', 'Power System Lab', '전력시스템', '김재철',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김재철'));

-- 숭실대학교 전기공학부 · Smart Grid Communications Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전기공학부', 'Smart Grid Communications Lab', '스마트그리드 통신', '윤성국',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('윤성국'));

-- 숭실대학교 전기공학부 · NanoPhotonics Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전기공학부', 'NanoPhotonics Lab', '나노포토닉스', '정해준',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정해준'));

-- 숭실대학교 전기공학부 · Vibration Laboratory
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전기공학부', 'Vibration Laboratory', '진동', '김진오',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김진오'));

-- 숭실대학교 전기공학부 · e-모빌리티 Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전기공학부', 'e-모빌리티 Lab', 'e-모빌리티', '이진욱',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이진욱'));

-- 숭실대학교 전기공학부 · Renewable Energy Applications Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전기공학부', 'Renewable Energy Applications Lab', '신재생에너지 응용', '박태현',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박태현'));

-- 숭실대학교 전기공학부 · 다기능 표면 및 나노복합재 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전기공학부', '다기능 표면 및 나노복합재 연구실', '다기능 표면, 나노복합재', '박성훈',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박성훈'));

-- 숭실대학교 전자정보공학부 · Communication Network Security Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전자정보공학부', 'Communication Network Security Lab', '통신 네트워크 보안', '정수환',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정수환'));

-- 숭실대학교 전자정보공학부 · Wireless Communications Laboratory
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전자정보공학부', 'Wireless Communications Laboratory', '무선통신', '신오순',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('신오순'));

-- 숭실대학교 전자정보공학부 · Semiconductor Devices & Sensors Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전자정보공학부', 'Semiconductor Devices & Sensors Lab', '반도체 소자, 센서', '유건욱',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('유건욱'));

-- 숭실대학교 전자정보공학부 · Brain and Machine Intelligence Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '전자정보공학부', 'Brain and Machine Intelligence Lab', '뇌·기계 지능', '권민혜',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('권민혜'));

-- 숭실대학교 산업정보시스템공학과 · Systems Optimization Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '산업정보시스템공학과', 'Systems Optimization Lab', '시스템 최적화', '한진일',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('한진일'));

-- 숭실대학교 유기신소재파이버공학과 · Carbon Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('숭실대학교'), '유기신소재파이버공학과', 'Carbon Lab', '탄소 소재', '정영진',
       'admin', null, 'https://research.ssu.ac.kr/ipr/lab', date '2026-11-19', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('숭실대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정영진'));

commit;

-- 확인: 아주대·숭실대 운영자 등록 연구실 수 (아주대 76, 숭실대 57이 나오면 정상)
select l.univ, count(*) as labs
  from public.clover_labs l
 where l.source = 'admin' and l.univ in (public.clover_canon_univ('아주대학교'), public.clover_canon_univ('숭실대학교'))
 group by l.univ;
