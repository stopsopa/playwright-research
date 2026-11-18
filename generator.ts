/**
 * Logic of generator.html - UI representing how playwright.sh is supposed to be used.
 * See generator.md for the full description/plan.
 *
 * Flow:
 *   1. read state from url query params (missing param = default)
 *   2. fill the form from state
 *   3. on every form input: form -> state -> url (history.replaceState) -> render
 *   4. render: cli commands on the left, tabs with ace editors (files + preparation) on the right
 *
 * Transpile to generator.js with: /bin/bash transpile.sh
 */

/**
 * Single source of truth: every key here is one form control (matched by "name" attribute)
 * and one url param. Type of default decides the type of control:
 *   boolean -> checkbox, string -> text/number/select/radio
 */
const DEFAULTS = {
  mode: "local", // local | docker
  file: "",
  project: "chromium",
  env: ".env",
  workers: "1",
  headless: false,
  allowOnly: false,
  extra: "",
  bin: "auto", // auto | docker | podman
  nohost: false,
  dockerDefaults: "./playwright-docker-defaults.sh",
  dockerParams: "",
  asyncConfig: false,
  testDir: "tests",
  port: "3000",
};

type State = typeof DEFAULTS;
type Key = keyof State;
type Loose = Record<string, string | boolean>;

/**
 * state key -> url param name.
 * Same idea as ParamDef.getParam in
 * https://github.com/stopsopa/select-component/tree/main/vite-project/src/pages/params
 * (that lib is a React hook, here the same rules are applied without React:
 * value equal to default is removed from url, params are sorted, replaceState is used)
 */
const PARAM: Record<Key, string> = {
  mode: "m",
  file: "f",
  project: "p",
  env: "e",
  workers: "w",
  headless: "hl",
  allowOnly: "ao",
  extra: "x",
  bin: "bin",
  nohost: "nh",
  dockerDefaults: "dd",
  dockerParams: "dp",
  asyncConfig: "ac",
  testDir: "td",
  port: "port",
};

const KEYS = Object.keys(DEFAULTS) as Key[];

type FileTab = { name: string; lang: string; content: string };

function $<T extends HTMLElement>(selector: string): T {
  const el = document.querySelector<T>(selector);

  if (el) {
    return el;
  }

  throw new Error(`generator.ts error: element '${selector}' not found`);
}

const form = $<HTMLFormElement>("#form");

// ---------------------------------------------------------------- url <-> state <-> form

function stateFromUrl(): State {
  const search = new URLSearchParams(window.location.search);
  const state: Loose = { ...DEFAULTS };

  for (const key of KEYS) {
    const raw = search.get(PARAM[key]);

    if (raw !== null) {
      state[key] = typeof DEFAULTS[key] === "boolean" ? raw === "1" : raw;
    }
  }

  return state as State;
}

// only values different than default land in the url - keeps url short
function stateToUrl(state: State): void {
  const search = new URLSearchParams();

  for (const key of KEYS) {
    const value = state[key];

    if (value !== DEFAULTS[key]) {
      search.set(PARAM[key], typeof value === "boolean" ? "1" : value);
    }
  }

  search.sort();

  const query = search.toString();
  const url = window.location.pathname + (query ? `?${query}` : "");

  if (url !== window.location.pathname + window.location.search) {
    window.history.replaceState(null, "", url);
  }
}

function stateToForm(state: State): void {
  for (const key of KEYS) {
    const value = state[key];

    form.querySelectorAll<HTMLInputElement | HTMLSelectElement>(`[name="${key}"]`).forEach((el) => {
      if (el instanceof HTMLInputElement && el.type === "checkbox") {
        el.checked = value === true;
      } else if (el instanceof HTMLInputElement && el.type === "radio") {
        el.checked = el.value === value;
      } else {
        el.value = String(value);
      }
    });
  }
}

function stateFromForm(): State {
  const data = new FormData(form);
  const state: Loose = { ...DEFAULTS };

  for (const key of KEYS) {
    if (typeof DEFAULTS[key] === "boolean") {
      state[key] = data.has(key);
    } else {
      state[key] = String(data.get(key) ?? DEFAULTS[key]).trim();
    }
  }

  return state as State;
}

// ---------------------------------------------------------------- cli command

// quote value for shell only when it is needed
function shellQuote(value: string): string {
  if (/^[\w@%+=:,./-]+$/.test(value)) {
    return value;
  }

  return `'${value.replace(/'/g, `'\\''`)}'`;
}

/**
 * Builds call of playwright.sh exactly how the script expects it:
 *
 *   [PLAYWRIGHT_BIN=podman] /bin/bash playwright.sh [script options] -- [playwright args]
 *
 * and in docker mode when extra "docker run" args are given:
 *
 *   /bin/bash playwright.sh -t docker [script options] -- [docker run args] -- [playwright args]
 *
 * In that second form the script stops adding default -v "$(pwd)/.env:/code/.env",
 * so it is prepended here unless user mounted /code/.env on his own.
 */
function buildCommand(state: State, file: string): string {
  const docker = state.mode === "docker";
  const env = state.env || DEFAULTS.env;
  const project = state.project || DEFAULTS.project;
  const workers = state.workers || DEFAULTS.workers;
  const dockerDefaults = state.dockerDefaults || DEFAULTS.dockerDefaults;
  const args: string[] = [];

  if (docker && state.bin !== "auto") {
    args.push(`PLAYWRIGHT_BIN=${state.bin}`);
  }

  args.push("/bin/bash playwright.sh");

  if (docker) {
    args.push("-t docker");
  }

  if (env !== DEFAULTS.env) {
    args.push(`--env ${shellQuote(env)}`);
  }

  if (project !== DEFAULTS.project) {
    args.push(`--project ${shellQuote(project)}`);
  }

  // --headed is never added in docker mode, so --headless makes sense only on host
  if (state.headless && !docker) {
    args.push("--headless");
  }

  if (state.allowOnly) {
    args.push("--allow-only");
  }

  if (docker && state.nohost) {
    args.push("--nohost");
  }

  if (docker && dockerDefaults !== DEFAULTS.dockerDefaults) {
    args.push(`--docker-defaults ${shellQuote(dockerDefaults)}`);
  }

  const playwright: string[] = [];

  if (workers !== DEFAULTS.workers) {
    playwright.push(`--workers=${shellQuote(workers)}`);
  }

  if (state.extra) {
    playwright.push(state.extra);
  }

  if (file) {
    playwright.push(shellQuote(file));
  }

  if (docker && state.dockerParams) {
    args.push("--");

    if (!state.dockerParams.includes(":/code/.env")) {
      args.push(`-v "$(pwd)/${env}:/code/.env"`);
    }

    args.push(state.dockerParams, "--", ...playwright);
  } else if (playwright.length > 0) {
    args.push("--", ...playwright);
  }

  return args.join(" ");
}

// ---------------------------------------------------------------- generated files

function filePlaywrightConfig(state: State): string {
  const testDir = state.testDir || DEFAULTS.testDir;
  const port = state.port || DEFAULTS.port;

  return `/**
 * playwright.config.js prepared to work with playwright.sh
 *
 * What playwright.sh expects from this file:
 *   - reads env file pointed by ENVFILE env var (playwright.sh --env FILE exports it in local mode,
 *     in docker mode chosen env file is mounted as /code/.env)
 *   - honours PLAYWRIGHT_TEST_MATCH, NODE_API_HOST, NODE_API_PORT env vars
 *     (docker mode overrides NODE_API_HOST to reach server on the host machine)
 *   - executed directly ("node playwright.config.js") prints resolved config
 *     (docker mode does that to show testMatch before running tests)
 */
const path = require("path");

const { defineConfig, devices } = require("@playwright/test");

// dotenv doesn't override already defined env vars - "docker run --env NODE_API_HOST=..." wins
require("dotenv").config({
  path: path.resolve(__dirname, process.env.ENVFILE || ".env"),
});

const { NODE_API_PROTOCOL = "http", NODE_API_HOST = "localhost", NODE_API_PORT = "${port}" } = process.env;

const config = defineConfig({
  testDir: "./${testDir}",
  testMatch: process.env.PLAYWRIGHT_TEST_MATCH || "**/*.spec.js",
  reporter: "list",
  use: {
    baseURL: \`\${NODE_API_PROTOCOL}://\${NODE_API_HOST}:\${NODE_API_PORT}\`,
    trace: "on-first-retry",
  },
  // playwright.sh passes --project=chromium by default, change with: --project firefox | --project all
  // WARNING: default docker image (...-just-chromium) has only chromium installed
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
});

module.exports = config;

if (require.main === module) {
  console.log(JSON.stringify(config, null, 2));
}
`;
}

function fileEnv(state: State): string {
  return [
    "# read by playwright.config.js",
    "# in docker mode (macOS) NODE_API_HOST is overridden with host.docker.internal unless --nohost is used",
    "NODE_API_PROTOCOL=http",
    "NODE_API_HOST=localhost",
    `NODE_API_PORT=${state.port || DEFAULTS.port}`,
    "",
  ].join("\n");
}

/**
 * The same content as "playwright.sh --generate-playwright-docker-defaults" produces,
 * with tests directory from the form and optional mount of playwright-async.config.js.
 * Script prints (to stdout) default arguments for "docker run".
 */
function fileDockerDefaults(state: State): string {
  const testDir = state.testDir || DEFAULTS.testDir;

  const mounts = [
    `-v "\\$(pwd)/${testDir}:/code/${testDir}"`,
    '-v "\\$(pwd)/node_modules:/code/node_modules"',
    '-v "\\$(pwd)/playwright.config.js:/code/playwright.config.js"',
  ];

  if (state.asyncConfig) {
    mounts.push('-v "\\$(pwd)/playwright-async.config.js:/code/playwright-async.config.js"');
  }

  return [
    "",
    'S="\\\\"',
    "",
    'PLAYWRIGHT_TEST_MATCH_DEFAULT=""',
    'if [ "${PLAYWRIGHT_TEST_MATCH}" != "" ]; then',
    '    PLAYWRIGHT_TEST_MATCH_DEFAULT="--env PLAYWRIGHT_TEST_MATCH"',
    "fi",
    "",
    'NODE_API_PORT_DEFAULT=""',
    'if [ "${NODE_API_PORT}" != "" ]; then',
    '    NODE_API_PORT_DEFAULT="--env NODE_API_PORT"',
    "fi",
    "",
    "cat <<EOF",
    '-w "/code" $S',
    "${NODE_API_PORT_DEFAULT} $S",
    "${PLAYWRIGHT_TEST_MATCH_DEFAULT} $S",
    mounts.join(" $S\n"),
    "",
    "EOF",
    "",
  ].join("\n");
}

function fileExampleTest(): string {
  return `const { test, expect } = require("@playwright/test");

test("homepage responds", async ({ page }) => {
  // relative to baseURL from playwright.config.js
  const response = await page.goto("/");

  expect(response.ok()).toBeTruthy();
});
`;
}

// all commands needed before first run of playwright.sh
function filePreparation(state: State): string {
  const docker = state.mode === "docker";
  const env = state.env || DEFAULTS.env;
  const project = state.project || DEFAULTS.project;
  const testDir = state.testDir || DEFAULTS.testDir;
  const dockerDefaults = state.dockerDefaults || DEFAULTS.dockerDefaults;
  const engine = state.bin === "podman" ? "podman" : "docker";
  const prefix = state.bin === "auto" ? "" : `PLAYWRIGHT_BIN=${state.bin} `;

  const lines = [
    "# 1. get playwright.sh into root directory of your project (script does cd to its own directory)",
    "curl -O https://raw.githubusercontent.com/stopsopa/playwright-research/master/playwright.sh",
    "",
    "# 2. install libraries (node.js is required on host in both modes)",
    "npm install -D @playwright/test dotenv",
    "",
    "# 3. create files from other tabs:",
    "#      playwright.config.js",
    `#      ${env}`,
    `#      ${testDir}/example.spec.js`,
    "",
  ];

  if (docker) {
    lines.push(
      `# 4. generate ${dockerDefaults} - default args for "${engine} run"`,
      "#    (or save content of the tab with that file)",
      dockerDefaults === DEFAULTS.dockerDefaults
        ? "/bin/bash playwright.sh --generate-playwright-docker-defaults"
        : `/bin/bash playwright.sh --generate-playwright-docker-defaults --docker-defaults ${shellQuote(dockerDefaults)}`,
      "",
      "# 5. pull image matching installed version of playwright",
      `${engine} pull "$(${prefix}/bin/bash playwright.sh --image)"`,
      "",
      "# 6. check",
      `${prefix}/bin/bash playwright.sh --version`,
      `${prefix}/bin/bash playwright.sh --image`,
    );
  } else {
    lines.push(
      "# 4. install browser on host machine",
      project === "all" ? "npx playwright install" : `npx playwright install ${shellQuote(project)}`,
      "",
      "# 5. check",
      "/bin/bash playwright.sh --version",
    );
  }

  lines.push("", "# then run tests", buildCommand(state, ""), "");

  return lines.join("\n");
}

// list of tabs depends on params: docker defaults file is needed only in docker mode
function buildFiles(state: State): FileTab[] {
  const files: FileTab[] = [
    { name: "preparation", lang: "sh", content: filePreparation(state) },
    { name: "playwright.config.js", lang: "javascript", content: filePlaywrightConfig(state) },
    { name: state.env || DEFAULTS.env, lang: "sh", content: fileEnv(state) },
  ];

  if (state.mode === "docker") {
    const name = (state.dockerDefaults || DEFAULTS.dockerDefaults).replace(/^\.\//, "");

    files.push({ name, lang: "sh", content: fileDockerDefaults(state) });
  }

  files.push({
    name: `${state.testDir || DEFAULTS.testDir}/example.spec.js`,
    lang: "javascript",
    content: fileExampleTest(),
  });

  return files;
}

// ---------------------------------------------------------------- tabs with ace editors

const tabsContainer = $<HTMLDivElement>("#tabs");

let tabsSignature = "";
let activeTabIndex = 0;
let editors: HTMLElement[] = [];

// remember which tab is open to restore it after tabs are rebuilt
document.addEventListener("vanilla-tabs:change", (e) => {
  activeTabIndex = (e as CustomEvent<{ index: number }>).detail.index;
});

/**
 * Markup required by https://stopsopa.github.io/tabs/ :
 *
 *   <div data-vanilla-tabs>
 *     <div data-buttons> <div class="active">name</div> ... </div>
 *     <div data-tabs>    <div> panel </div> ... </div>
 *   </div>
 *
 * Whole structure is built detached and appended at once, library (autoenable mode)
 * picks it up through its MutationObserver.
 * Rebuild happens only when list of tab names changes, otherwise only editors content is updated.
 */
function renderTabs(files: FileTab[]): void {
  const signature = files.map((f) => `${f.name}:${f.lang}`).join("|");

  if (signature !== tabsSignature) {
    tabsSignature = signature;

    const active = Math.min(activeTabIndex, files.length - 1);
    const root = document.createElement("div");
    const buttons = document.createElement("div");
    const panels = document.createElement("div");

    root.setAttribute("data-vanilla-tabs", "");
    buttons.setAttribute("data-buttons", "");
    panels.setAttribute("data-tabs", "");

    editors = files.map((file, i) => {
      const button = document.createElement("div");
      button.textContent = file.name;
      button.setAttribute("data-testid", `tab-${file.name}`);
      if (i === active) {
        button.className = "active";
      }
      buttons.appendChild(button);

      const editor = document.createElement("ace-editor");
      editor.setAttribute("lang", file.lang);
      editor.setAttribute("readonly", "");
      editor.setAttribute("min-height-px", "600");
      editor.setAttribute("data-testid", `editor-${file.name}`);

      const panel = document.createElement("div");
      panel.appendChild(editor);
      panels.appendChild(panel);

      return editor;
    });

    root.append(buttons, panels);
    tabsContainer.replaceChildren(root);
  }

  files.forEach((file, i) => {
    if (editors[i].getAttribute("value") !== file.content) {
      editors[i].setAttribute("value", file.content);
    }
  });
}

// ---------------------------------------------------------------- render

const cmdAll = $<HTMLPreElement>("#cmd-all");
const cmdFile = $<HTMLPreElement>("#cmd-file");

function render(state: State): void {
  const docker = state.mode === "docker";

  $("#docker-only").hidden = !docker;
  $("#field-headless").hidden = docker;

  cmdAll.textContent = buildCommand(state, "");
  cmdFile.textContent = buildCommand(state, state.file || `${state.testDir || DEFAULTS.testDir}/example.spec.js`);

  renderTabs(buildFiles(state));
}

form.addEventListener("input", () => {
  const state = stateFromForm();

  stateToUrl(state);
  render(state);
});

form.addEventListener("submit", (e) => e.preventDefault());

// copy buttons: data-copy="id of element with text to copy"
document.addEventListener("click", (e) => {
  const button = (e.target as HTMLElement).closest<HTMLElement>("[data-copy]");

  if (button) {
    const text = $(`#${button.dataset.copy}`).textContent ?? "";

    navigator.clipboard.writeText(text).then(() => {
      button.textContent = "Copied";
      setTimeout(() => (button.textContent = "Copy"), 1000);
    });
  }
});

const initial = stateFromUrl();

stateToForm(initial);
render(initial);
