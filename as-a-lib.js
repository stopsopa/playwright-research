const { chromium } = require('@playwright/test');  // webkit | chromium | firefox

/**
 * https://playwright.dev/docs/api/class-page#page-event-request-failed
 */
(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto('https://example.com');
  await page.screenshot({path: 'screenshot.png'});
  await browser.close();
})();