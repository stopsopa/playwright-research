const path = require("path");

const fs = require("fs");

const env = path.resolve(__dirname, ".env");

const lightFetch = require("nlab/lightFetch");

if (!fs.existsSync(env)) {
  throw new Error(`File ${env} doesn't exist`);
}

require("dotenv").config({
  path: env,
});

const host = process.env.HOST;

const port = process.env.PORT;

// const url = `http://${host}:${port}/ready?timeout=2000`;
const url = `http://${host}:${port}/ready`;

const delay = (ms) => new Promise((res) => setTimeout(res, ms));

(async function () {
  let res;
  try {

    // await delay(4000);

    res = await lightFetch(url, {
      debugRequest: 'all',
      timeout: 3000,
    });

    if (res.status === 200) {
      process.exit(0);
    }
  } catch (e) {
    console.log(`${__filename} error: ${e}`);
    process.exit(1);
  }
})();
