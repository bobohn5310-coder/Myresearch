# Nature·Science 새 논문 자동 수집

- `.github/workflows/collect-papers.yml` 이 매일 한국시간 03:30 에 `scripts/collect_papers.py` 를 실행해 `data/papers.json` 을 갱신한다.
- 출처: Nature 공식 RSS(최신 게재, 최신호), Science 공식 RSS(최신호, 온라인 선공개). 모자라면 Crossref 공개 API 로 제목·날짜·링크를 보충한다.
- 연구 논문만 남긴다: Nature 는 주소가 `s41586-` 인 것, Science 는 DOI 가 `10.1126/science.` 인 것. 정정·철회 공지와 목차 안내는 뺀다.
- 저작권: 제목, 저널, 게재일, RSS 가 공개하는 한 줄 소개(최대 200자), 원문 링크만 저장한다. 본문·그림·초록 전문은 저장하지 않는다.
- 홈 화면(index.html)의 "🔬 Nature·Science 새 논문" 칸이 이 파일을 직접 읽는다. Supabase 설정은 필요 없다.
- 손으로 바로 돌리려면 GitHub > Actions > "Nature·Science 최신 논문 자동 수집" > Run workflow.
- 그림: Nature 논문은 논문 페이지가 링크 미리보기용으로 공개한 대표 그림(og:image)의 **주소만** 저장해 보여준다(파일 복사 없음, 출처 © Springer Nature 표기). Science 는 사이트가 자동 접속을 막아 그림 없이, 직접 그린 표지로 보여준다.
