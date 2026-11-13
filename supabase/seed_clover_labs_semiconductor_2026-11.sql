-- ════════════════════════════════════════════════
-- 🍀 운영자 등록 연구실: 반도체 분야 시범 수집 (2026-11-13)
-- 먼저 clover_admin_labs.sql 을 실행한 뒤, 이 파일 전체를 Supabase → SQL Editor 에 붙여넣고 Run.
-- 여러 번 실행해도 안전합니다 (같은 학교 + 같은 교수님 연구실이 이미 있으면 건너뜀).
--
-- 담긴 것: 6개 대학 27개 연구실, 공개 서지정보로 확인한 대표 논문 40편
-- 담지 않은 것: 개인 연락처·학생 정보, 연구 과제(연구실과 확실히 맞는 것을 찾지 못해 이번엔 제외)
-- 원본 자료: data/clover-labs/semiconductor-pilot-2026-11.json
--
-- 화면 영향: 공개 목록에는 바로 나오지 않습니다. 회원이 같은 학교 + 교수님 성함으로 클로버를 남기면
--           새로 만들지 않고 이 연구실로 이어지고, 관리자 '클로버 현황'에 '운영자 등록'으로 표시됩니다.
-- 되돌리기: delete from public.clover_labs where source = 'admin' and collected_at = '2026-11-13'
--           and not exists (select 1 from public.clover_votes v where v.lab_id = clover_labs.id);
-- ════════════════════════════════════════════════

begin;

-- 서울대학교 재료공학부 · DTFL 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('서울대학교'), '재료공학부', 'DTFL 연구실', '차세대 메모리(DRAM·FeRAM·ReRAM)·산화물 TFT 박막', '황철성',
       'admin', 'http://dtfl.snu.ac.kr/', 'https://mse.snu.ac.kr/hwang-cheol-seong/', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('서울대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('황철성'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Resistive switching materials for information processing', 'Nature Reviews Materials', 2020, 'https://doi.org/10.1038/s41578-019-0159-3', 'openalex'),
  ('The fundamentals and applications of ferroelectric HfO2', 'Nature Reviews Materials', 2022, 'https://doi.org/10.1038/s41578-022-00431-2', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('서울대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('황철성')
on conflict do nothing;

-- 서울대학교 재료공학부 · 강유전체 소자 연구실(가칭)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('서울대학교'), '재료공학부', '강유전체 소자 연구실(가칭)', '강유전체 HfO2 소자, 뉴로모픽·메모리', '박민혁',
       'admin', 'https://nano.snu.ac.kr/', 'https://mse.snu.ac.kr/park-min-hyuk/', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('서울대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박민혁'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('The fundamentals and applications of ferroelectric HfO2', 'Nature Reviews Materials', 2022, 'https://doi.org/10.1038/s41578-022-00431-2', 'openalex'),
  ('Next generation ferroelectric materials for semiconductor process integration and their applications', 'Journal of Applied Physics', 2021, 'https://doi.org/10.1063/5.0037617', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('서울대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박민혁')
on conflict do nothing;

-- 서울대학교 재료공학부 · 저차원 소재·소자 연구실(가칭)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('서울대학교'), '재료공학부', '저차원 소재·소자 연구실(가칭)', '2D 반도체 소재(TMD·그래핀) 소자, 대면적 성장', '이관형',
       'admin', 'https://gwangroup.snu.ac.kr', 'https://mse.snu.ac.kr/%ec%9d%b4%ea%b4%80%ed%98%95/', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('서울대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이관형'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('2D semiconducting materials for electronic and optoelectronic applications: potential and challenge', '2D Materials', 2019, 'https://doi.org/10.1088/2053-1583/ab6267', 'openalex'),
  ('Artificial Neuron and Synapse Devices Based on 2D Materials', 'Small', 2021, 'https://doi.org/10.1002/smll.202100640', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('서울대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이관형')
on conflict do nothing;

-- 한국과학기술원 전기및전자공학부 · DSIL 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한국과학기술원'), '전기및전자공학부', 'DSIL 연구실', '3D IC·첨단 패키징, 산화물 채널 DRAM 트랜지스터', '권지민',
       'admin', 'https://dsil.kaist.ac.kr/', 'https://ee.kaist.ac.kr/professor-s1/', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한국과학기술원'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('권지민'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Monolithic 3D-Integrated All-Solid Ion-Gated Carbon Nanotube Transistors With Tunable Ionic Conductance for Multi-Timescale Reservoir Computing', 'Advanced Materials', 2026, 'https://doi.org/10.1002/adma.202523703', 'openalex'),
  ('High-Bandwidth Interconnects Fabricated by Electrohydrodynamic Printing on Glass', 'IEEE FLEPS 2026', 2026, 'https://doi.org/10.1109/fleps69128.2026.11645041', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한국과학기술원'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('권지민')
on conflict do nothing;

-- 한국과학기술원 전기및전자공학부 · LESL 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한국과학기술원'), '전기및전자공학부', 'LESL 연구실', '저차원 반도체 소재·소자, 반도체 물리', '이가영',
       'admin', 'https://lesl.kaist.ac.kr/', 'https://ee.kaist.ac.kr/professor-s1/?page=2', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한국과학기술원'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이가영'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Binary-to-Ternary Reconfigurable Transistors Using Plasma-Assisted MoS2', 'Advanced Functional Materials', 2026, 'https://doi.org/10.1002/adfm.77555', 'openalex'),
  ('Cryogenic Hole Transport in 2D Indium Selenide', 'ACS Nano', 2026, 'https://doi.org/10.1021/acsnano.6c07680', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한국과학기술원'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이가영')
on conflict do nothing;

-- 한국과학기술원 전기및전자공학부 · 고속나노전자 연구실(HSNL)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한국과학기술원'), '전기및전자공학부', '고속나노전자 연구실(HSNL)', 'GaN HEMT·THz 소자, MMIC', '양경훈',
       'admin', 'http://hsnl.kaist.ac.kr', 'https://ee.kaist.ac.kr/professor-s1/?page=2', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한국과학기술원'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('양경훈'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Investigation of Gate Field-Plate Effects on fmax Improvement in GaN HEMTs for RF Applications', 'IEEE Transactions on Electron Devices', 2026, 'https://doi.org/10.1109/ted.2026.3705009', 'openalex'),
  ('fmax of 411 GHz in Al0.4Ga0.6N/GaN HEMTs with Al0.08Ga0.92N Back-barrier for Future RF Applications', 'APMC 2025', 2025, 'https://doi.org/10.1109/apmc65046.2025.11378567', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한국과학기술원'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('양경훈')
on conflict do nothing;

-- 한국과학기술원 전기및전자공학부 · VLSI 회로 연구실(가칭)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한국과학기술원'), '전기및전자공학부', 'VLSI 회로 연구실(가칭)', 'VLSI 회로·칩 설계, 저전력 가속기', '김봉진',
       'admin', 'http://bongjin.com', 'https://ee.kaist.ac.kr/professor-s1/', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한국과학기술원'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김봉진'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Verifica: Near-Memory Symbolic Interval Computing Formal Neural Network Verification Accelerator', 'IEEE Journal of Solid-State Circuits', 2026, 'https://doi.org/10.1109/jssc.2026.3707324', 'openalex'),
  ('COBI: A Degree-of-56 Column-Bipartite Densely Connected Digital Ising Chip with 8b Spin Coefficients', 'IEEE ISSCC 2026', 2026, 'https://doi.org/10.1109/isscc49663.2026.11409141', 'openalex'),
  ('Verifica: A 65nm In-Memory Symbolic Interval Computing Accelerator for a Formal Neural Network Verification', 'IEEE A-SSCC 2025', 2025, 'https://doi.org/10.1109/a-sscc67472.2025.11349404', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한국과학기술원'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김봉진')
on conflict do nothing;

-- 포항공과대학교 전자전기공학과 · 나노소자 및 공정 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('포항공과대학교'), '전자전기공학과', '나노소자 및 공정 연구실', '나노소자·공정, 3D NAND 신뢰성', '이정수',
       'admin', 'http://ndp.postech.ac.kr', 'https://ee.postech.ac.kr/faculty-research/professor/view.php?id=310', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('포항공과대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이정수'));

-- 포항공과대학교 전자전기공학과 · 미래소자및회로 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('포항공과대학교'), '전자전기공학과', '미래소자및회로 연구실', '로직·메모리 소자(FinFET/GAA, 3D NAND, DRAM), 공정 최적화', '백록현',
       'admin', 'https://team.postech.ac.kr', 'https://ee.postech.ac.kr/faculty-research/professor/view.php?id=303', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('포항공과대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('백록현'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Tailored Local Dielectrics via Area-Selective ALD for Co-Optimizing Performance and Reliability in 3D NAND Flash Memory', 'ACS Applied Electronic Materials', 2026, 'https://doi.org/10.1021/acsaelm.6c01057', 'openalex+연구실 홈페이지'),
  ('Physical Analysis of Stress-Induced Multilevel and Fast Random Telegraph Noise in BCAT DRAM Devices', 'IEEE Transactions on Electron Devices', 2026, 'https://doi.org/10.1109/ted.2026.3735280', 'openalex'),
  ('Submelt continuous-wave laser annealing for diffusion-suppressed and highly activated boron ultra-shallow junction formation', 'Materials Science in Semiconductor Processing', 2026, 'https://doi.org/10.1016/j.mssp.2026.111325', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('포항공과대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('백록현')
on conflict do nothing;

-- 포항공과대학교 전자전기공학과 · RF Circuit and System Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('포항공과대학교'), '전자전기공학과', 'RF Circuit and System Lab', 'THz·mmWave RFIC, InP/CMOS 회로, 레이더', '송호진',
       'admin', 'http://mad.postech.ac.kr/', 'https://ee.postech.ac.kr/faculty-research/professor/view.php?id=320', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('포항공과대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('송호진'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('A D-Band 2-D Phased-Array Transceiver Module With Aperiodic Subarray Configuration in Fan-Out Wafer-Level Packaging', 'IEEE Transactions on Microwave Theory and Techniques', 2026, 'https://doi.org/10.1109/tmtt.2026.3712400', 'openalex+연구실 홈페이지'),
  ('An E-Band Radar Transceiver With Daisy-Chained Wireless Chirp Synchronization for Scalable Multistatic Radar Networks', 'IEEE Transactions on Microwave Theory and Techniques', 2026, 'https://doi.org/10.1109/tmtt.2026.3678366', 'openalex+연구실 홈페이지')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('포항공과대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('송호진')
on conflict do nothing;

-- 포항공과대학교 전자전기공학과 · 지능형 반도체 및 웨어러블 디바이스 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('포항공과대학교'), '전자전기공학과', '지능형 반도체 및 웨어러블 디바이스 연구실', '산화물 반도체(IGZO) 소자, 메모리·시냅스 소자', '정윤영',
       'admin', 'http://chunglab.postech.ac.kr', 'https://ee.postech.ac.kr/faculty-research/professor/view.php?id=307', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('포항공과대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('정윤영'));

-- 포항공과대학교 전자전기공학과 · CAD 및 SoC 설계 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('포항공과대학교'), '전자전기공학과', 'CAD 및 SoC 설계 연구실', '집적회로 CAD, SoC 설계 자동화', '강석형',
       'admin', 'http://soc.postech.ac.kr', 'https://ee.postech.ac.kr/faculty-research/professor/view.php?id=5663', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('포항공과대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('강석형'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Timing- and Power-Aware Differentiable Repair of Minimum Implant Area Violations', 'ISLPED 2026', 2026, 'https://doi.org/10.1145/3816440.3818572', 'openalex'),
  ('Differentiable Fill Insertion with Explicit Delay Optimization', 'DAC 2026', 2026, 'https://doi.org/10.1145/3770743.3804006', 'openalex'),
  ('GTX: Graph Transformer for Parasitic EXtraction on Analog Circuits', 'DAC 2026', 2026, 'https://doi.org/10.1145/3770743.3804289', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('포항공과대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('강석형')
on conflict do nothing;

-- 연세대학교 전기전자공학부 · 반도체 공학 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('연세대학교'), '전기전자공학부', '반도체 공학 연구실', '반도체 소자·공정 (산화물 TFT, GaN 소자, TCAD)', '윤일구',
       'admin', 'https://semicim.yonsei.ac.kr', 'https://ee.yonsei.ac.kr/ee/research/lab.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('연세대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('윤일구'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Model Implementations and analysis of MIS-gated GaN light emitting transistor', 'Displays', 2026, 'https://doi.org/10.1016/j.displa.2026.103586', 'openalex'),
  ('High-performance oxide semiconductor TFT with a-IGZO/In-rich a-IGZO heterostructure using quantum confinement effects: Enhancing mobility and reliability', 'Journal of Alloys and Compounds', 2025, 'https://doi.org/10.1016/j.jallcom.2025.182035', 'openalex'),
  ('Comparative analysis of capacitorless DRAM performance according to stacked junctionless gate-all-around structures', 'Solid-State Electronics', 2024, 'https://doi.org/10.1016/j.sse.2024.109036', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('연세대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('윤일구')
on conflict do nothing;

-- 연세대학교 전기전자공학부 · 차세대 반도체 소자 및 시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('연세대학교'), '전기전자공학부', '차세대 반도체 소자 및 시스템 연구실', '차세대 반도체 소자 및 시스템', '이명재',
       'admin', 'https://sites.google.com/view/adslab', 'https://ee.yonsei.ac.kr/ee/research/lab.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('연세대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이명재'));

-- 연세대학교 전기전자공학부 · 나노소자 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('연세대학교'), '전기전자공학부', '나노소자 연구실', '나노소자·원자층증착(ALD)·2D 반도체 박막', '김형준',
       'admin', 'http://nanodevice.yonsei.ac.kr', 'https://ee.yonsei.ac.kr/ee/research/lab.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('연세대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김형준'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Surface-Reaction-Controlled Initial Growth of Ir-Rich IrTex Thin Films via ABC-Type Atomic Layer Deposition', 'Nano Letters', 2026, 'https://doi.org/10.1021/acs.nanolett.6c03219', 'openalex'),
  ('Regulating surface reaction pathways in Al2O3 atomic layer deposition through sequential oxidant exposure for MoS2 transistors', 'Surfaces and Interfaces', 2026, 'https://doi.org/10.1016/j.surfin.2026.110643', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('연세대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김형준')
on conflict do nothing;

-- 연세대학교 전기전자공학부 · IDC 시스템 설계 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('연세대학교'), '전기전자공학부', 'IDC 시스템 설계 연구실', '집적 소자·회로 설계, 저전력 회로', '윤홍일',
       'admin', 'https://sites.google.com/yonsei.ac.kr/idclaboratory/%ED%99%88', 'https://ee.yonsei.ac.kr/ee/research/lab.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('연세대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('윤홍일'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('A Compact Low-Voltage and Low-Power Flip-Flop with Static, Contention-Free, and Redundant-Transition-Free Operation', 'IEEE ISCAS 2026', 2026, 'https://doi.org/10.1109/iscas66217.2026.11562632', 'openalex'),
  ('A Low-Power Sense Amplifier-Based Flip-Flop Using a Conditional Capture Method', 'Electronics (MDPI)', 2026, 'https://doi.org/10.3390/electronics15091819', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('연세대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('윤홍일')
on conflict do nothing;

-- 연세대학교 전기전자공학부 · 컴퓨터 시스템 및 고신뢰성 SoC 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('연세대학교'), '전기전자공학부', '컴퓨터 시스템 및 고신뢰성 SoC 연구실', '고신뢰성 SoC, VLSI 테스트·내결함성', '강성호',
       'admin', 'http://soc.yonsei.ac.kr/', 'https://ee.yonsei.ac.kr/ee/research/lab.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('연세대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('강성호'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('PRAISE: Parallel Redundancy Analysis Using Isomorphism-Based Solution Encoding', 'IEEE Transactions on VLSI Systems', 2026, 'https://doi.org/10.1109/tvlsi.2026.3704618', 'openalex'),
  ('Deep-Learning-Based PRPG Configuration Inference for Efficient LBIST', 'IEEE Transactions on VLSI Systems', 2026, 'https://doi.org/10.1109/tvlsi.2026.3700112', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('연세대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('강성호')
on conflict do nothing;

-- 한양대학교 융합전자공학부 · Advanced Reliable Component Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '융합전자공학부', 'Advanced Reliable Component Lab', '차세대 반도체 소자 신뢰성', '신상훈',
       'admin', 'https://sites.google.com/view/semi-arclab/home', 'https://eece.hanyang.ac.kr/-26', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('신상훈'));

-- 한양대학교 융합전자공학부 · 나노전자소자 연구실(NDL)
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '융합전자공학부', '나노전자소자 연구실(NDL)', '나노전자소자, 차세대 비휘발성 메모리', '이승백',
       'admin', 'https://sites.google.com/view/ndllab', 'https://semi.hanyang.ac.kr/about/professor.php', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('이승백'));

-- 한양대학교 융합전자공학부 · 첨단반도체소재/소자개발 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '융합전자공학부', '첨단반도체소재/소자개발 연구실', '반도체 소재·소자 (STT-MRAM, CBRAM, CMP)', '박재근',
       'admin', 'http://asmddc.hanyang.ac.kr', 'https://semi.hanyang.ac.kr/about/professor.php', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박재근'));

-- 한양대학교 융합전자공학부 · Thin Films and Nano-Device Lab
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '융합전자공학부', 'Thin Films and Nano-Device Lab', '박막·나노소자, 유연 전자소자', '박진석',
       'admin', 'https://eece.hanyang.ac.kr/-26', 'https://eece.hanyang.ac.kr/-26', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('박진석'));

-- 한양대학교 융합전자공학부 · 인공지능 반도체 소자 및 센서 시스템 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('한양대학교'), '융합전자공학부', '인공지능 반도체 소자 및 센서 시스템 연구실', '인공지능 반도체 소자, 2D 소재, 뉴로모픽', '오세용',
       'admin', 'https://seyongoh89site.wixsite.com/profseyongoh', 'https://eece.hanyang.ac.kr/-26', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('한양대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('오세용'));

-- 성균관대학교 반도체시스템공학과 · TEBL 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('성균관대학교'), '반도체시스템공학과', 'TEBL 연구실', '반도체 회로·소자 (메모리 회로, 3D IC)', '권기원',
       'admin', 'https://sites.google.com/view/skku-tebl/home', 'https://semi.skku.edu/semi/intro/professor_concurrent.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('성균관대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('권기원'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('Hybrid bonding base grounded thermal through silicone vias(G-TTSV) for 3D heterogenous integration', 'Materials Science in Semiconductor Processing', 2026, 'https://doi.org/10.1016/j.mssp.2026.110901', 'openalex'),
  ('Electro-thermal analysis of CFETs with a dual-substrate architecture', 'Semiconductor Science and Technology', 2026, 'https://doi.org/10.1088/1361-6641/ae6362', 'openalex'),
  ('A Balanced Shorted-Latch Sense Amplifier with PMOS Equalizer for Latency-Yield-Area Co-Optimization', 'ICEIC 2026', 2026, 'https://doi.org/10.1109/iceic69189.2026.11386330', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('성균관대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('권기원')
on conflict do nothing;

-- 성균관대학교 반도체시스템공학과 · ISDL 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('성균관대학교'), '반도체시스템공학과', 'ISDL 연구실', 'VLSI 시스템 설계 (혼합신호 IC)', '공배선',
       'admin', 'https://sites.google.com/view/skkuisdl', 'https://semi.skku.edu/semi/intro/professor_concurrent.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('성균관대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('공배선'));

-- 성균관대학교 반도체시스템공학과 · 전파공학연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('성균관대학교'), '반도체시스템공학과', '전파공학연구실', 'RFIC·밀리미터파 IC 설계, 레이더', '김병성',
       'admin', 'http://rfmd.skku.ac.kr', 'https://semi.skku.edu/semi/intro/professor_concurrent.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('성균관대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김병성'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('A 0.04-mm2 59.3-to-66 GHz Continuously Tunable VCO Using a Class-F Push-Push Technique with Compact Double-Tuned Resonator', 'Journal of Electromagnetic Engineering and Science', 2026, 'https://doi.org/10.26866/jees.2026.6.l.33', 'openalex'),
  ('Compact Near-Field Calibration of Sparse MIMO Array Radar via Two-Range Interferometric Processing', 'EuRAD 2026', 2026, 'https://doi.org/10.23919/eurad69232.2026.11747789', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('성균관대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('김병성')
on conflict do nothing;

-- 성균관대학교 반도체시스템공학과 · EEMIX 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('성균관대학교'), '반도체시스템공학과', 'EEMIX 연구실', 'CMOS 이미지·LiDAR 센서, 혼합신호 IC', '최재혁',
       'admin', 'https://sites.google.com/view/eemix', 'https://semi.skku.edu/semi/intro/professor_concurrent.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('성균관대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최재혁'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('QVGA CMOS LiDAR Sensor With nMOS-Only SPAD Analog Front-End and Area-Efficient Priority Histogramming TDC', 'IEEE Journal of Solid-State Circuits', 2026, 'https://doi.org/10.1109/jssc.2026.3687569', 'openalex'),
  ('A Neural-Feedback-Driven Event Camera for Robust and Efficient Vision Processing', 'ISLPED 2026', 2026, 'https://doi.org/10.1145/3816440.3818514', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('성균관대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최재혁')
on conflict do nothing;

-- 성균관대학교 반도체시스템공학과 · ADND 연구실
insert into public.clover_labs (univ, dept, name, topic, prof, source, homepage, source_url, collected_at, created_by)
select public.clover_canon_univ('성균관대학교'), '반도체시스템공학과', 'ADND 연구실', '반도체·디스플레이 소자 신뢰성, TFT, 메모리', '최병덕',
       'admin', 'http://swb.skku.edu/adnd', 'https://semi.skku.edu/semi/intro/professor_concurrent.do', date '2026-11-13', null
where not exists (select 1 from public.clover_labs x
  where lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('성균관대학교'),'\s','','g'))
    and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최병덕'));
insert into public.clover_lab_papers (lab_id, title, venue, year, url, verified_via)
select x.id, p.title, p.venue, p.year, p.url, p.via
from public.clover_labs x, (values
  ('A Flexible Complementary Memristive Synapse for Convolutional Neural Network Applications', 'ACS Nano', 2026, 'https://doi.org/10.1021/acsnano.6c14396', 'openalex')
) as p(title, venue, year, url, via)
where x.source = 'admin'
  and lower(regexp_replace(x.univ,'\s','','g')) = lower(regexp_replace(public.clover_canon_univ('성균관대학교'),'\s','','g'))
  and public.clover_norm_prof(x.prof) = public.clover_norm_prof('최병덕')
on conflict do nothing;

commit;

-- 확인: 방금 들어간 운영자 등록 연구실과 논문 수
select l.id, l.univ, l.dept, l.name, l.prof, l.topic, l.homepage,
       (select count(*) from public.clover_lab_papers p where p.lab_id = l.id) as papers
  from public.clover_labs l where l.source = 'admin' order by l.univ, l.dept, l.name;
