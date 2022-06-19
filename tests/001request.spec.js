const { test, expect } = require("@playwright/test");

/**
 * https://playwright.dev/docs/api/class-request
 */
test.describe("", () => {
  test("basic test", async ({ page, browserName }) => {
    const buff = [];

    page.on("request", async (request) => {
      const headers = await request.allHeaders();

      const { "accept-language": al, ...rest } = headers;

      buff.push(["request", al]);

      // console.log("on request(request)", await request.allHeaders());
    });

    page.on("response", async (response) => {
      const header = await response.headerValue("x-special");

      buff.push([
        "response",
        {
          "x-special": header,
        },
      ]);

      // console.log("on response(response)", await response.allHeaders());
    });

    page.on("requestfinished", async (request) => {
      const headers = await request.allHeaders();

      const { "accept-language": al, ...rest } = headers;

      buff.push(["requestfinished", al]);

      // console.log("on requestfinished(request)", await request.allHeaders());
    });

    page.on("requestfailed", async (request) => {
      const headers = await request.allHeaders();

      const { "accept-language": al, ...rest } = headers;

      buff.push(["requestfailed", al]);

      // console.log("on requestfailed(request)", await request.allHeaders());
    });

    const response = await page.goto("/007redirect");

    const header = await response.headerValue("x-special");

    expect(header).toEqual("default");

    // console.log(JSON.stringify(browserName, null, 4));

    expect(buff).toEqual(
      [
        ["request", "en-US"],
        browserName === "firefox" ? false : ["requestfinished", "en-US"],
        [
          "response",
          {
            "x-special": browserName === "webkit" ? null : "redirect...",
          },
        ],
        browserName === "firefox" ? ["requestfinished", "en-US"] : false,
        ["request", "en-US"],
        [
          "response",
          {
            "x-special": "default",
          },
        ],
        browserName === "webkit" ? false : ["requestfinished", "en-US"],
      ].filter(Boolean)
    );
  });
});
