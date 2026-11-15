# vendor

외부 라이브러리를 우리 사이트에서 직접 내려주기 위한 사본입니다. (외부 CDN을 한 번 더 거치지 않아 첫 로딩이 빨라집니다)

- `supabase-js-2.117.3.js`: `@supabase/supabase-js@2.117.3` 의 `dist/umd/supabase.js` 그대로 (MIT 라이선스). `npm pack @supabase/supabase-js@2.117.3` 으로 받은 파일입니다.
- `xlsx-0.18.5.full.min.js`: `xlsx@0.18.5` 의 `dist/xlsx.full.min.js` 그대로 (Apache-2.0 라이선스). `npm pack xlsx@0.18.5` 로 받았고, npm 에 등록된 무결성 값(sha512-dmg3LCjB…TEtFQ==)과 일치함을 확인했습니다. 관리자 페이지의 엑셀 내려받기에만 쓰며, 엑셀 파일을 읽는 기능은 쓰지 않습니다.

파일 이름에 버전이 들어 있어 1년 동안 캐시됩니다 (`_headers`). 버전을 올릴 때는 새 이름으로 파일을 추가하고 `index.html`·`admin.html`·`dashboard.html` 의 주소를 바꿔 주세요.
