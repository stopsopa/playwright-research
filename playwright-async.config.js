
/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// require('dotenv').config();

const delay = ms => new Promise(res => setTimeout(res, ms));

/**
 * Collect any params you need here, sync or async way
 * You will end up with object which you can use to assemble playwright.config.js
 * normal synchronous way.
 */
(async function () {

  const data = {
    start: true,
  };

  await delay(3000);

  data.end = true;

  console.log(JSON.stringify(data));
}());