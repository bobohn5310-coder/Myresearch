# Cloudflare Pages 배포 설정

이 사이트는 빌드 과정이 없는 정적 사이트입니다 (HTML + `data/*.json`).

## 프로젝트 설정값
- 프레임워크 프리셋: None
- 빌드 명령어: (비워 둠)
- 빌드 출력 디렉터리: `/`
- 프로덕션 브랜치: `main`

`main` 에 커밋이 올라올 때마다 자동 배포됩니다. GitHub Actions 가 매일 3번 데이터를
커밋하므로 한 달 약 90회 빌드가 생기며, 무료 한도(월 500회) 안입니다.

## 함께 들어 있는 파일
- `_headers`: `data/*` 는 항상 최신본을 확인(no-cache), `assets/*` 는 하루 캐시, 기본 보안 헤더.

## 도메인 연결 후 할 일
1. `index.html` 의 `og:url`, `canonical` 주소를 새 도메인으로 바꾸기.
2. Supabase → Authentication → URL Configuration
   - Site URL: `https://새도메인`
   - Redirect URLs: `https://새도메인/**`, `https://*.pages.dev/**`

## Workers 로 배포하는 경우
Cloudflare 대시보드에서 Pages 만들기 메뉴가 보이지 않으면 Workers 로 배포합니다.
`wrangler.jsonc` 가 저장소 루트를 정적 파일로 올리고, `.assetsignore` 가 코드·SQL·문서를 제외합니다.
`_headers` 는 Workers 정적 자산에서도 그대로 적용됩니다.
- Build command: (비워 둠)
- Deploy command: `npx wrangler deploy`
