const { test, expect } = require("@playwright/test");

function getPath(url) {
  const uri = new URL(url);

  return uri.pathname + uri.search + uri.hash;
}

// from: https://stopsopa.github.io/pages/node/index.html#processing-url-uri
test.describe("001loading", () => {
  test("001loading - test", async ({ page, browserName }) => {
    await page.goto(`/001dynamic_element.html`);

    console.log(`after loading`);

    await expect(page.locator(".dynamic")).toHaveText("dynamic"); // this will do exact match

    await expect(page).toHaveURL("/001dynamic_element.html"); // also exact match

    const url = await page.url();

    const path = getPath(url);

    expect(path).toEqual("/001dynamic_element.html");
  });
});
