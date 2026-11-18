# Suggested changes for playwright.sh

Nothing here is applied yet. Review, pick, then ask to implement.

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
    /bin/bash playwright.sh [options] -- [playwright args]
    /bin/bash playwright.sh --docker [options] -- [playwright args]
    /bin/bash playwright.sh --docker [options] -- [docker run args] -- [playwright args]

    Everything before first -- is for this script.
    Everything after is passed to "playwright test" untouched.

QUICK START
    /bin/bash playwright.sh                          # all tests, host, headed chromium
    /bin/bash playwright.sh -- tests/a.spec.js       # one file
    /bin/bash playwright.sh --docker                 # all tests in docker
    /bin/bash playwright.sh --docker -- tests/a.spec.js

DEFAULTS ADDED BY THIS SCRIPT (and how to turn them off)
    --headed            off with: --headless            (host only, docker is always headless)
    --forbid-only       off with: --allow-only
    --project=chromium  change:   --project firefox | --project all
    --workers=1         change:   -- --workers=5

OPTIONS (host and docker)
    -t, --target local|docker   where to run (default: local)
        --docker                same as --target docker
    -p, --project NAME|all      browser project, "all" = don't pass --project
    -e, --env FILE              env file (default: .env)
        --headless
        --allow-only
        --version               print playwright version and exit
        --image                 print docker image name and exit
    -h, --help

OPTIONS (docker only)
        --nohost                        don't add "--net host" / NODE_API_HOST=host.docker.internal
    -dd, --docker-defaults FILE         file printing default "docker run" args
                                        (default: ./playwright-docker-defaults.sh, /dev/null = none)
        --generate-playwright-docker-defaults   create that file and exit

DOCKER: PASSING ARGS TO "docker run"
    Use two -- delimiters:
        /bin/bash playwright.sh --docker -- [docker run args] -- [playwright args]

    Rule: the moment you pass any docker run args, default mount
        -v "$(pwd)/.env:/code/.env"
    is NOT added anymore. Add it yourself:
        ... -- -v "$(pwd)/.env:/code/.env" --name my_container -- --list
    Swap env file for one run:
        ... --nohost -- -v "$(pwd)/.env_docker:/code/.env" --

    playwright-docker-defaults.sh = what to mount from the project (rarely changes)
    double --                     = per-run extras, mostly different .env

ENV VARS
    PLAYWRIGHT_BIN=docker|podman   force container engine (default: autodetect)
    ENVFILE                        same as --env

FIRST TIME SETUP (docker)
    /bin/bash playwright.sh --generate-playwright-docker-defaults
    docker pull "$(/bin/bash playwright.sh --image)"
```

Key ideas: synopsis first, `--` explained once at the top, defaults in one table, host/docker options as two aligned lists, one short section for double `--`, setup last.

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
