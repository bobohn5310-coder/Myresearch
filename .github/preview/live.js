// 임시: 실제 홈페이지의 논문 칸 사진 (머지하지 않음)
const { chromium, devices } = require('playwright');
(async () => {
  const b = await chromium.launch();
  for (const [name, opts] of [['pc', { viewport: { width: 1360, height: 900 }, deviceScaleFactor: 2 }], ['mobile', { ...devices['iPhone 13'] }]]) {
    const p = await b.newPage(opts);
    await p.goto('https://bobohn5310-coder.github.io/Myresearch/?v=' + Date.now(), { waitUntil: 'networkidle', timeout: 60000 });
    await p.waitForTimeout(4000);
    await p.addStyleTag({ content: 'nav,.nav{position:static !important}' });
    const el = await p.$('.hp-section');
    if (el) await el.screenshot({ path: `preview-shots/${name}.png` });
    else { console.log('논문 칸 없음'); await p.screenshot({ path: `preview-shots/${name}-full.png` }); }
  }
  await b.close();
})();
