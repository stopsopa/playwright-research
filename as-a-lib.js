const {
  chromium,
  devices, // https://playwright.dev/docs/api/class-playwright#playwright-devices
} = require("@playwright/test"); // webkit | chromium | firefox

/**
 * https://playwright.dev/docs/api/class-page#page-event-request-failed
 */
(async () => {
  const browser = await chromium.launch({ headless: false });
  // more about browser: https://playwright.dev/docs/api/class-browser

  const context = await browser.newContext();
  // more about context: https://playwright.dev/docs/api/class-browsercontext

  const page = await context.newPage();

  await page.goto("https://example.com");

  // await page.screenshot({path: 'screenshot.png'});

  page.on("dialog", async (dialog) => {
    // https://playwright.dev/docs/api/class-dialog
    console.log("msg:", dialog.message());
    await dialog.dismiss();
  });
  await page.evaluate(() => alert("198"));

  await browser.close();
})();
