// 임시: 실제 수집 결과로 미리보기 사진을 찍는다 (머지 전에 지움)
const { chromium, devices } = require('playwright');
const fs = require('fs');
(async () => {
  const b = await chromium.launch();
  for (const [name, opts] of [['pc', { viewport: { width: 1360, height: 900 }, deviceScaleFactor: 2 }], ['mobile', { ...devices['iPhone 13'] }]]) {
    const p = await b.newPage(opts);
    await p.route('**/supabase.js', r => r.fulfill({ contentType: 'application/javascript', body: fs.readFileSync('.github/preview/stub.js', 'utf8') }));
    await p.goto('http://localhost:8765/index.html', { waitUntil: 'domcontentloaded' });
    await p.addStyleTag({ content: 'nav,.nav{position:static !important}' });
    await p.waitForTimeout(6000);
    const el = await p.$('.hp-section');
    await el.screenshot({ path: `preview-shots/${name}.png` });
  }
  await b.close();
})();
