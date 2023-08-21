/**
 * Comment temporarly: testIgnore in playwright.config.js
 * and then
 * 
 * /bin/bash playwright.sh -- --debug tests/macro-tests/utorrent_turnoff_all.test.js
 * or
 * /bin/bash playwright.sh tests/macro-tests/utorrent_turnoff_all.test.js
 */

const url = `https://utweb.trontv.com/gui/index.html?v=1.2.10.5207&localauth=localapi460f5b7b8d4be49:#/library`;

const { test, expect } = require("@playwright/test");

function encodeFunctionToString(fn) {
  if (typeof fn === "function") {
    return fn.toString();
  }

  throw new Error("encodeFunction error: fn is not a function");
}

// from: https://stopsopa.github.io/pages/node/index.html#processing-url-uri
test.describe("utrorrent_turnoff_all", () => {
  test("utrorrent_turnoff_all", async ({ page, browserName }) => {
    await page.goto(url);

    await page.locator("#didomi-notice-agree-button").click(); // this will do exact match

    await page.evaluate(() => {
      window.box = function (msg) {
        var div = document.createElement("div");

        const style = {
          position: "fixed",
          zIndex: "10000000",
          top: "20%",
          left: "50%",
          border: "1px solid gray",
          backgroundColor: "white",
          transform: "translate(-50%, -50%)",
          padding: "10px",
          cursor: "pointer",
        };

        Object.assign(div.style, style);

        div.innerHTML = String(msg);

        document.body.appendChild(div);

        return function () {
          document.body.removeChild(div);
        };
      };

      window.decodeFunctionFromString = function (str) {
        if (typeof str !== "string") {
          throw new Error("encodeFunction error: str is not a string");
        }

        let fn;

        try {
          fn = new Function("return " + str)();
        } catch (e) {
          throw new Error(`decodeFunctionFromString error: evaluation of string failed: ${e}`);
        }

        if (typeof fn === "function") {
          return fn;
        }

        throw new Error("decodeFunctionFromString error: decoded string is not a function");
      };
    });
    async function wait(fn) {
      await page.evaluate(function (fn) {
        var stop = box(decodeFunctionFromString(fn)());
        return new Promise((resolve) =>
          setTimeout(() => {
            stop();
            resolve();
          }, 4000)
        );
      }, encodeFunctionToString(fn));
    }

    await wait(() => "after creating box and decodeFunctionFromString functions");

    await page.evaluate(() => {
      (function (css) {
        var head = document.head || document.getElementsByTagName("head")[0];

        var style = document.createElement("style");

        head.appendChild(style);

        style.type = "text/css";

        style.appendChild(document.createTextNode(css));
      })(`
body .media-element-details .media-element-files[class] {
  max-height: none;
}     
      `);
    });

    await wait(() => "after adding css");

    let list = await page.$$('[data-testid="media-element-show-torrent-files-icon"]');

    list.reverse();

    for (const el of list) {
      await el.click();
    }

    await page.evaluate(() => {
      Array.from(
        document.querySelectorAll(`[data-testid="media-file-download-toggle-checkbox"].toggle-wrapper`)
      ).forEach((el) => {
        const c = el.querySelector('input[type="checkbox"]');
        console.log(c, c.checked);
        if (c && c.checked) {
          el.setAttribute("found-checked", "true");
        }
      });
    });

    await wait(() => "after finding elements: " + document.querySelectorAll('[found-checked="true"]').length);

    list = await page.$$('[found-checked="true"]');

    list.reverse();

    for (const el of list) {
      await el.click();
    }

    await wait(() => "final wait");
  });
});
