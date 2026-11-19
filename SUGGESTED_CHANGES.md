# Suggested changes for playwright.sh

Status: all applied to `playwright.sh` (and mirrored in generator). Notes on how:

- image override is env var only: `PLAYWRIGHT_IMAGE=... /bin/bash playwright.sh ...` (no `--image-name` flag)
- improvement 4 (`printenv`): rejected, full `printenv` inside container is fine and stays
- improvement 10 (`--workers`): default `--workers=1` unchanged, no new option, only documented in help (PLAYWRIGHT ARGS defaults table)
- improvement 11 (link): help and README link to https://stopsopa.github.io/playwright-research/generator.html
- args: bash arrays + `printf '%q'`; `eval` stays only because output of `playwright-docker-defaults.sh` is shell code (`$(pwd)`)
- image alternatives comment kept, other commented-out experiments removed

## 1. What was asked

- `playwright.sh` has one job: normalize running playwright on host and in docker, so both are called the same way, differing only by one flag (`--docker`).
- `--help` is hard to follow top to bottom. It has two parts: basic things for host machine, and extras available only in docker mode. Make it easier to read and comprehend.
- Review script and collect any other improvements here.

## 2. Help page - proposed new shape

Problems now:

- No synopsis. Reader has to infer the call shape from 15 examples.
- Setup (`--generate-playwright-docker-defaults`) comes first, before reader knows what the script does.
- Every option is explained as example + comment block; same warning repeated 4 times ("consumed by this script only").
- The `--` delimiter (most important concept) is explained in the middle of the docker part, after it was used in every example above.
- Long essay at the end about `.env` vs `playwright-docker-defaults.sh` (5 paragraphs saying the same thing in different ways).
- Help talks about `--target docker`, the intro of the project talks about `--docker`.

Proposed layout (man-page like, short top, details lower):

```
playwright.sh - run playwright the same way on host and in docker

USAGE
    /bin/bash playwright.sh          [SCRIPT OPTIONS] -- [PLAYWRIGHT ARGS]
    /bin/bash playwright.sh --docker [SCRIPT OPTIONS] -- [PLAYWRIGHT ARGS]
    /bin/bash playwright.sh --docker [SCRIPT OPTIONS] -- [DOCKER ARGS] -- [PLAYWRIGHT ARGS]

    SCRIPT OPTIONS    before first --                  consumed by this script, all listed below
    DOCKER ARGS       between two --, only --docker    passed untouched to "docker run"
    PLAYWRIGHT ARGS   after last --                    passed untouched to "playwright test"

QUICK START
    /bin/bash playwright.sh                          # all tests, host, headed chromium
    /bin/bash playwright.sh -- tests/a.spec.js       # one file
    /bin/bash playwright.sh --docker                 # all tests in docker
    /bin/bash playwright.sh --docker -- tests/a.spec.js

SCRIPT OPTIONS (host and docker)
    -t, --target local|docker   where to run (default: local)
        --docker                same as --target docker
    -p, --project NAME|all      browser project, "all" = don't pass --project
    -e, --env FILE              env file (default: .env)
        --headless
        --allow-only
        --version               print playwright version and exit
        --image                 print docker image name and exit
    -h, --help

SCRIPT OPTIONS (docker only)
        --nohost                        don't add "--net host" / NODE_API_HOST=host.docker.internal
    -dd, --docker-defaults FILE         file printing default DOCKER ARGS
                                        (default: ./playwright-docker-defaults.sh, /dev/null = none)
        --generate-playwright-docker-defaults   create that file and exit

PLAYWRIGHT ARGS
    Anything "playwright test" accepts: test files, --debug, --list, -g "title", --workers=5 ...

    This script always adds some on its own. To change them:

    added by default      change with            which goes in
    --headed              --headless             SCRIPT OPTIONS    (host only, docker is always headless)
    --forbid-only         --allow-only           SCRIPT OPTIONS
    --project=chromium    --project firefox|all  SCRIPT OPTIONS
    --workers=1           --workers=5            PLAYWRIGHT ARGS

DOCKER ARGS
    Anything "docker run" accepts: -v, --env, --name ...
    Needs both -- delimiters, also when there are no PLAYWRIGHT ARGS:
        /bin/bash playwright.sh --docker -- --name my_container --

    Added by default (when DOCKER ARGS are empty):
        output of playwright-docker-defaults.sh     what to mount from the project, rarely changes
        -v "$(pwd)/.env:/code/.env"                 env file

    Rule: the moment you pass any DOCKER ARGS, the env file mount is NOT added anymore.
    Add it yourself:
        ... --docker -- -v "$(pwd)/.env:/code/.env" --name my_container -- --list
    Swap env file for one run:
        ... --docker --nohost -- -v "$(pwd)/.env_docker:/code/.env" --

ENV VARS
    PLAYWRIGHT_BIN=docker|podman   force container engine (default: autodetect)
    ENVFILE                        same as --env

FIRST TIME SETUP (docker)
    /bin/bash playwright.sh --generate-playwright-docker-defaults
    docker pull "$(/bin/bash playwright.sh --image)"
```

Key ideas:

- synopsis first, with three named slots: `SCRIPT OPTIONS`, `DOCKER ARGS`, `PLAYWRIGHT ARGS`
- those three names are the only vocabulary used below: every section is titled with the slot it describes, and every param is listed under the slot it goes in
- `--` explained once at the top (slot position), never again
- defaults table says for each default in which slot the override goes
- setup last

## 3. Bugs

1. `--docker-defaults` validation checks wrong variable (`playwright.sh:170`). It tests `${_DOCKERDEFAULTS}` (old default) instead of `${2}`. Effects:
   - `--docker-defaults ./other.sh` fails when default `./playwright-docker-defaults.sh` doesn't exist, even if `./other.sh` exists.
   - documented `--generate-playwright-docker-defaults --docker-defaults ./x.sh` can't work: check demands existing file, generate demands non-existing one. Existence check should be moved to the place where file is used (docker mode).
2. docker/podman required even for local mode and for `--help`, `--version` (`playwright.sh:47-66`). On machine without docker script exits with error. Detect engine only inside docker branch.
3. `quote` escapes only `"` (`playwright.sh:99`). Args go through `eval`, so `$`, backticks and `\` in args get expanded/executed, e.g. `-- -g 'costs $5'`. Fix: keep args in bash arrays (`PW_ARGS+=("${1}")`) and drop `eval set --` - removes `quote`, `PARAMS`, `_EVAL`, `trim` and both duplicated quoting blocks.
4. `-p|--project` with no value: `shift 2` fails / `--project=` is passed. Add empty check like other options have.
5. `printf "${PLAYWRIGHT_VER}"` / `printf "${IMAGE}"` - variable used as format string. Use `printf '%s'`.
6. Error messages for missing node / missing docker / unhandled target go to stdout, others to stderr. Send all to stderr.
7. Generated `playwright-docker-defaults.sh` always mounts `playwright-async.config.js`. If project doesn't have it, docker creates a directory with that name on host. Mount only when file exists.
8. `--headless` help says `--headed` is default; in docker `--headed` is never passed. Fine, but help should say it plainly (covered in new layout).

## 4. Improvements

1. Add `--docker` as alias for `--target docker`. This is how the script is described everywhere ("just add --docker"), and target has only two values anyway.
2. Rename `PLAYWRIGHT_BIN` to `PLAYWRIGHT_DOCKER_BIN` (keep old as fallback). Current name suggests path to playwright binary. Also document it in help - now it is not mentioned at all.
3. Allow overriding image: `PLAYWRIGHT_IMAGE` env var or `--image-name`, default stays `monstersmart/playwright:v${VER}-noble-just-chromium`. Now using other image (e.g. official one with firefox) needs editing script. Related: `--project firefox|all` in docker can't work with `just-chromium` image - warn or document.
4. Docker run prints whole `printenv` into log - leaks secrets from `.env` in CI logs. Print only relevant vars (`PLAYWRIGHT_TEST_MATCH`, `NODE_API_*`) or hide behind `--debug`/`--verbose`.
5. Move help printing before the node/docker checks so `--help` always works.
6. Remove dead code: zsh/sh detection (script is always called with `/bin/bash`), unused `_SHELL`, `_0`, `_SCRIPT`, `_BINARY`, `_PWD`, `BG_*` colors, `_EVAL`, `DOCKER_PARAMS`, `DOCKER__EVAL`, commented-out experiments.
7. Script does `cd "${_DIR}"`, so it works only when placed in project root, and relative test paths are resolved from there, not from caller's cwd. Say that in help.
8. Follow `bash-scripting` skill when touching it: `[[ ]]` conditions, `${VAR}` everywhere, error messages with `>${VALUE}<`.
9. Unknown `--target` value is detected only at the very end, after everything else. Validate right after arg parsing.
10. `--workers=1` is hardcoded and overridden by passing second `--workers` later. Works, but a `-w|--workers` option (or just documenting it in "defaults" table) is clearer.
11. `README` / help should link to generator page (`generator.html` on github pages) once it is published.
