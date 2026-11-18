# generator

**Goal: this generator always has to represent how [playwright.sh](./playwright.sh) is supposed to be handled, as best as possible.**
Whenever `playwright.sh` changes (options, defaults, files it expects), generator has to be updated to match. `playwright.sh` is the source of truth.

This document is a plan for AI to build the generator again from scratch.

## Files

| file             | role                                                                                |
| ---------------- | ----------------------------------------------------------------------------------- |
| `generator.html` | github page. Raw html + raw css (inline `<style>`, css nesting). Loads `generator.js` |
| `generator.ts`   | all logic. Single file, no imports, no framework                                    |
| `generator.js`   | generated from `generator.ts`, native ESM, never edit by hand                       |
| `transpile.sh`   | `/bin/bash transpile.sh` - `tsc` typecheck + emit `generator.ts` -> `generator.js`    |

`typescript` is in `devDependencies`. `tsc` flags: `--target es2022 --module es2022 --lib es2022,dom,dom.iterable --strict --noEmitOnError`.

## Layout

Styled like Cloudflare dashboard: gray page `#f2f2f2`, white cards with 1px border, orange `#f6821f` primary buttons / active states, blue `#0051c3` links, system font.

- header: title, link to repo, Reset (link to `generator.html` without params)
- left column (`<form id="form">`):
  1. **Where to run** - radio `mode`: `local` (host machine) / `docker` (`--target docker`)
  2. **Commands** - two `<pre>` with Copy buttons: all tests, given test file
  3. **Parameters** - inputs listed below
- right column: `#tabs` - tabs, each with one readonly ace editor

Every interactive element has unique `data-testid`.

## Inputs

Each input: `name` attribute = state key in `DEFAULTS` in `generator.ts`. Boolean default = checkbox, string default = anything else.

| key              | url  | default                           | effect on command                                                       |
| ---------------- | ---- | --------------------------------- | ----------------------------------------------------------------------- |
| `mode`           | `m`  | `local`                           | `docker` adds `-t docker`                                               |
| `file`           | `f`  | ``                                | last playwright arg in "given test file" command                        |
| `project`        | `p`  | `chromium`                        | `--project X` when not default                                          |
| `env`            | `e`  | `.env`                            | `--env X` when not default                                              |
| `workers`        | `w`  | `1`                               | `-- --workers=N` when not default                                       |
| `headless`       | `hl` | off                               | `--headless`, host only (hidden in docker)                              |
| `allowOnly`      | `ao` | off                               | `--allow-only`                                                          |
| `extra`          | `x`  | ``                                | raw text appended after `--`                                            |
| `bin`            | `bin`| `auto`                            | docker only: `PLAYWRIGHT_BIN=docker\|podman` prefix                     |
| `nohost`         | `nh` | off                               | docker only: `--nohost`                                                 |
| `dockerDefaults` | `dd` | `./playwright-docker-defaults.sh` | docker only: `--docker-defaults X` when not default                     |
| `dockerParams`   | `dp` | ``                                | docker only: raw text between two `--`                                  |
| `asyncConfig`    | `ac` | off                               | docker only: adds mount of `playwright-async.config.js` to defaults file |
| `testDir`        | `td` | `tests`                           | generated files only                                                    |
| `port`           | `port`| `3000`                           | generated files only                                                    |

Docker-only inputs sit in one fieldset, hidden in `local` mode.

## Command shape

```
[PLAYWRIGHT_BIN=x] /bin/bash playwright.sh [-t docker] [--env F] [--project P] [--headless] [--allow-only] [--nohost] [--docker-defaults F] -- [playwright args]
```

With `dockerParams`:

```
... -- -v "$(pwd)/<env>:/code/.env" <dockerParams> -- [playwright args]
```

`playwright.sh` drops its default `.env` mount the moment any docker run arg is given, so generator prepends it (unless `dockerParams` already contains `:/code/.env`).
`--` is omitted when nothing follows it. Values are shell-quoted only when needed; `extra` and `dockerParams` are inserted raw.
"Given test file" command uses `<testDir>/example.spec.js` when `file` is empty.

## Tabs

Built by `buildFiles(state)`. List depends on params:

| tab                                  | when        | lang       | content                                                                                   |
| ------------------------------------ | ----------- | ---------- | ----------------------------------------------------------------------------------------- |
| `preparation`                        | always      | sh         | all commands before first run: get script, `npm install -D @playwright/test dotenv`, browser install (host) or generate defaults + pull image (docker), check, run |
| `playwright.config.js`               | always      | javascript | CJS config: loads `ENVFILE` with dotenv, `testMatch` from `PLAYWRIGHT_TEST_MATCH`, `baseURL` from `NODE_API_*`, prints itself when run with `node` (docker mode calls `node playwright.config.js`) |
| `<env>`                              | always      | sh         | `NODE_API_PROTOCOL/HOST/PORT`                                                             |
| `<dockerDefaults>`                   | docker mode | sh         | same output as `playwright.sh --generate-playwright-docker-defaults`                      |
| `<testDir>/example.spec.js`          | always      | javascript | minimal test                                                                              |

When `playwright.sh` starts requiring another file, add tab for it here.

## Libraries

### Tabs - https://stopsopa.github.io/tabs/

- `<link rel="stylesheet" href="https://stopsopa.github.io/tabs/vanilla-tabs.css">`
- `<script src="https://stopsopa.github.io/tabs/vanilla-tabs.js?vanilla-tabs-autoenable">` at the end of body
- markup: `[data-vanilla-tabs] > [data-buttons] > *` and `[data-vanilla-tabs] > [data-tabs] > div`, same count, matched by position, `class="active"` on initial button
- no add/remove api: `renderTabs()` builds whole structure detached and swaps it in at once (library picks it up by MutationObserver). Rebuild only when list of tab names changes, otherwise only editor content is updated
- `vanilla-tabs:change` event (`detail.index`) is used to restore open tab after rebuild

### Ace - https://stopsopa.github.io/ace-editor-webcomponent/learning/008_ace_async_loader/dynamic.html

- `<script type="module" src="https://stopsopa.github.io/ace-editor-webcomponent/ace-web-component.js" data-main-ace="<url of ace.js>">`
- `data-main-ace` points to `ace-builds` `src-min-noconflict/ace.js` on jsdelivr
- created with `document.createElement("ace-editor")`, attributes `lang`, `readonly`, `min-height-px`
- content set/updated with `setAttribute("value", content)`

### Url params - https://github.com/stopsopa/select-component/tree/main/vite-project/src/pages/params

That library (`modURLSearchParams.ts`) is a React hook, generator has no React and is single file. Its rules are reimplemented in `generator.ts` (`stateFromUrl` / `stateToUrl`):

- config per param: default + url name (`DEFAULTS` + `PARAM`)
- value equal to default is removed from url
- params sorted, written with `history.replaceState` only when changed
- booleans encoded as `1`

## Data flow

1. `stateFromUrl()` -> `stateToForm()` -> `render()`
2. form `input` event -> `stateFromForm()` -> `stateToUrl()` -> `render()`
3. `render()`: show/hide docker-only inputs, fill two commands, `renderTabs(buildFiles(state))`
