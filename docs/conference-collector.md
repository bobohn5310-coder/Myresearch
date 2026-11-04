# 학회 정보 자동 수집

매일 새벽 3시(한국시간) GitHub Actions 가 공개 학회 소스를 읽어 Supabase `academic_info` 테이블에 학회(type `conf`)로 넣습니다. 학술정보 화면의 검색창·분야·개최지 필터로 바로 찾을 수 있습니다.

## 소스

| 소스 | 범위 | 방식 |
| --- | --- | --- |
| [ccfddl/ccf-deadlines](https://github.com/ccfddl/ccf-deadlines) | 컴퓨터·AI 분야 국제 학회 약 270건 (일정, 장소, 투고 마감, CCF/CORE 등급) | GitHub 공개 YAML 을 `git clone` |
| [WikiCFP](http://www.wikicfp.com) RSS | 생명/의학, 공학, 재료, 에너지, 양자, 통신 분야 CFP | 카테고리별 RSS, 요청 사이 3초 간격 |

- 개최지가 한국이면 `#국내개최`, 아니면 `#해외` 태그가 붙습니다.
- 같은 학회는 `external_id` 로 구분해 다시 수집될 때 갱신만 됩니다.
- 자동 수집한 학회는 종료 30일 뒤 자동으로 지워집니다. 관리자 화면에서 직접 등록한 학회는 건드리지 않습니다.

## 동작 구조

1. 매일 03:00 (KST) GitHub Actions 가 소스를 모아 `data/conferences.json` 을 커밋합니다.
2. 매일 03:30 (KST) Supabase 안의 예약 작업(pg_cron)이 `public.sync_conferences()` 를 실행해 그 파일을 `academic_info` 에 반영합니다.

GitHub 에 Supabase 키를 등록할 필요가 없습니다. DB 쪽 설정은 [`supabase/academic_info_collector.sql`](../supabase/academic_info_collector.sql) 에 있습니다.
지금 바로 반영하려면 Supabase SQL Editor 에서 `select public.sync_conferences();` 를 실행하세요.

## 로컬 실행

```bash
pip install pyyaml
python scripts/collect_conferences.py --dry-run --out conferences.json
```
