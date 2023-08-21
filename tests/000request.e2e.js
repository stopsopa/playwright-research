const { test, expect } = require("@playwright/test");

/**
 * https://playwright.dev/docs/api/class-request
 */
test.describe("", () => {
  test("basic test", async ({ page, browserName }) => { // more objects, not only page, browserName: https://playwright.dev/docs/api/class-fixtures
    const buff = [];

    page.on("request", async (request) => {
      const headers = await request.allHeaders();

      const { "accept-language": al, ...rest } = headers;

      buff.push(["request", al]);

      // console.log("on request(request)", await request.allHeaders());
    });

    page.on("response", async (response) => {
      const headers = await response.allHeaders();

      const header = await response.headerValue("x-special");

      buff.push([
        "response",
        {
          "x-special": header,
        },
      ]);

      // console.log(JSON.stringify([browserName, headers], null, 4));
      // [
      //   "firefox",
      //   {
      //     "x-powered-by": "Express",
      //     "x-special": "redirect...",
      //     "location": "/007landingpage.html",
      //     "vary": "Accept",
      //     "content-type": "text/html; charset=utf-8",
      //     "content-length": "84",
      //     "date": "Sun, 19 Jun 2022 21:13:32 GMT",
      //     "connection": "keep-alive",
      //     "keep-alive": "timeout=5"
      //   }
      // ]
      //   [
      //   "firefox",
      //     {
      //       "x-powered-by": "Express",
      //       "x-special": "default",
      //       "accept-ranges": "bytes",
      //       "cache-control": "public, max-age=30758400",
      //       "last-modified": "Mon, 30 May 2022 22:27:18 GMT",
      //       "etag": "W/\"153-1811714a6b5\"",
      //       "content-type": "text/html; charset=UTF-8",
      //       "content-length": "339",
      //       "date": "Sun, 19 Jun 2022 21:13:32 GMT",
      //       "connection": "keep-alive",
      //       "keep-alive": "timeout=5"
      //     }
      //   ]
      //
      //   [
      //   "chromium",
      //     {
      //       "connection": "keep-alive",
      //       "content-length": "84",
      //       "content-type": "text/html; charset=utf-8",
      //       "date": "Sun, 19 Jun 2022 21:13:32 GMT",
      //       "keep-alive": "timeout=5",
      //       "location": "/007landingpage.html",
      //       "vary": "Accept",
      //       "x-powered-by": "Express",
      //       "x-special": "redirect..."
      //     }
      //   ]
      //   [
      //   "chromium",
      //     {
      //       "accept-ranges": "bytes",
      //       "cache-control": "public, max-age=30758400",
      //       "connection": "keep-alive",
      //       "content-length": "339",
      //       "content-type": "text/html; charset=UTF-8",
      //       "date": "Sun, 19 Jun 2022 21:13:32 GMT",
      //       "etag": "W/\"153-1811714a6b5\"",
      //       "keep-alive": "timeout=5",
      //       "last-modified": "Mon, 30 May 2022 22:27:18 GMT",
      //       "x-powered-by": "Express",
      //       "x-special": "default"
      //     }
      //   ]
      //
      //   [
      //   "webkit",
      //     {
      //       "location": "/007landingpage.html",
      //       "vary": "Accept",
      //       "date": "Sun, 19 Jun 2022 21:13:31 GMT"
      //     }
      //   ]
      //   [
      //   "webkit",
      //     {
      //       "cache-control": "public, max-age=30758400",
      //       "content-type": "text/html; charset=UTF-8",
      //       "last-modified": "Mon, 30 May 2022 22:27:18 GMT",
      //       "etag": "W/\"153-1811714a6b5\"",
      //       "accept-ranges": "bytes",
      //       "date": "Sun, 19 Jun 2022 21:13:31 GMT",
      //       "keep-alive": "timeout=5",
      //       "content-length": "339",
      //       "connection": "keep-alive",
      //       "x-powered-by": "Express",
      //       "x-special": "default"
      //     }
      //   ]
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
        browserName === "firefox" ? false : ["requestfinished", "en-US"], // in firefox requestfinished is registered in different order
        [
          "response",
          {
            "x-special": browserName === "webkit" ? null : "redirect...", // webkit can't see all headers in redirect response? (see above)
          },
        ],
        browserName === "firefox" ? ["requestfinished", "en-US"] : false, // in firefox requestfinished is registered in different order
        ["request", "en-US"],
        [
          "response",
          {
            "x-special": "default",
          },
        ],
        browserName === "webkit" ? false : ["requestfinished", "en-US"], // does not fire for webkit
      ].filter(Boolean)
    );
  });
});
