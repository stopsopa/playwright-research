const { test, expect } = require("@playwright/test");

/**
 * Grouping tests https://playwright.dev/docs/test-annotations#tag-tests
 */
test.describe("two tests @filter", () => {
  test("basic test", async ({ page }) => {
    await page.goto("https://playwright.dev/");

    const title = page.locator(".navbar__inner .navbar__title");

    debugger;

    await expect(title).toHaveText("Playwright");

    // Expect a title "to contain" a substring.
    await expect(page).toHaveTitle(/Playwright/);

    // Expect an attribute "to be strictly equal" to the value.
    await expect(page.locator("text=Get Started").first()).toHaveAttribute("href", "/docs/intro");

    await page.click("text=Get Started");
    // Expect some text to be visible on the page.
    await expect(page.locator("text=Introduction").first()).toBeVisible();
  });
});
