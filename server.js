const fs = require("fs");

const path = require("path");

const express = require("express");

const serveIndex = require("serve-index");

const log = (function () {
  try {
    return console.log;
  } catch (e) {
    return function () {};
  }
})();

const env = path.resolve(__dirname, ".env");

if (!fs.existsSync(env)) {
  throw new Error(`File ${env} doesn't exist`);
}

require("dotenv").config({
  path: env,
});

function check(val, name) {
  if (typeof val !== "string") {
    throw new Error(`${name} is not a string`);
  }

  if (!val.trim()) {
    throw new Error(`${name} is an empty string`);
  }
}

check(process.env.NODE_API_HOST, "NODE_API_HOST");

check(process.env.NODE_API_PORT, "NODE_API_PORT");

const web = path.resolve(__dirname, "public");

const app = express();

app.use(express.urlencoded({ extended: false }));

let ready = false;

app.use((req, res, next) => {
  console.log(`${req.method}: ${req.url}`);

  res.set("X-special", "default");

  next();
});

app.all("/ready", (req, res) => {
  let timeout = 0;

  try {
    if (/^\d+$/.test(req.query?.timeout?.[0])) {
      timeout = parseInt(req.query?.timeout?.[0], 10);
    }
  } catch (e) {
    console.log(`/ready error: ${e}`);
  }

  if (timeout > 0) {
    console.log(`/ready reached with timeout: >${timeout}<`);
  }

  setTimeout(() => {
    console.log(`/ready exit`, ready ? 200 : 500);

    res.status(ready ? 200 : 500);

    res.end();
  }, timeout);
});

app.use(express.urlencoded({ extended: false }));

app.use(express.json());

app.all("/redirect", (req, res) => {
  log("/redirect", {
    url: req.url,
    query: req.query,
  });
  res.redirect(req.query.target);
});

app.all("/007redirect", (req, res) => {
  res.set("X-special", "redirect...");
  res.redirect("/007landingpage.html");
});

app.use(
  express.static(web, {
    // http://expressjs.com/en/resources/middleware/serve-static.html
    // maxAge: 60 * 60 * 24 * 1000 // in milliseconds
    maxAge: "356 days", // in milliseconds max-age=30758400
    setHeaders: (res, path) => {
      if (/\.bmp$/i.test(path)) {
        // for some reason by default express.static sets here Content-Type: image/x-ms-bmp

        res.setHeader("Content-type", "image/bmp");
      }

      // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
      // res.setHeader('Cache-Control', 'public, no-cache, max-age=30758400')
      // res.setHeader('Cache-Control', 'public, only-if-cached')
    },
  }),
  serveIndex(web, { icons: true })
);

app.listen(process.env.NODE_API_PORT, process.env.NODE_API_HOST, () => {
  console.log(`\n 🌎  Server is running ` + `http://${process.env.NODE_API_HOST}:${process.env.NODE_API_PORT}\n`);
  ready = true;
});
