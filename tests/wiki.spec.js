const { test, expect } = require("@playwright/test");

test('test', async ({ page }) => {

  // Go to https://www.wikipedia.org/
  await page.goto('https://www.wikipedia.org/');

  // Click strong:has-text("English")
  await page.locator('strong:has-text("English")').click();

  await expect(page).toHaveURL('https://en.wikipedia.org/wiki/Main_Page');

  // Click [placeholder="Search Wikipedia"]
  await page.locator('[placeholder="Search Wikipedia"]').click();

  // Fill [placeholder="Search Wikipedia"]
  await page.locator('[placeholder="Search Wikipedia"]').fill('trst');

  // Go to https://en.wikipedia.org/w/index.php?search=trst&title=Special%3ASearch&fulltext=Search&ns0=1
  await page.goto('https://en.wikipedia.org/w/index.php?search=trst&title=Special%3ASearch&fulltext=Search&ns0=1');

  // Click text=Advanced search:Sort by relevance >> a[role="button"]
  await page.locator('text=Advanced search:Sort by relevance >> a[role="button"]').click();

  // Click text=Advanced search:Sort by relevance >> a[role="button"]
  await page.locator('text=Advanced search:Sort by relevance >> a[role="button"]').click();

  // Click text=Advanced search:Sort by relevance >> a[role="button"]
  await page.locator('text=Advanced search:Sort by relevance >> a[role="button"]').click();

  // Click a[role="button"]:has-text("Advanced search:Sort by relevance")
  await page.locator('a[role="button"]:has-text("Advanced search:Sort by relevance")').click();

  // Click span[role="combobox"]:has-text("Select file type")
  await page.locator('span[role="combobox"]:has-text("Select file type")').click();

});