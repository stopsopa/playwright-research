#
# Purpose of this script is to provide the same way to launch playwright tests natively
# on your host machine and, after adding one parameter (--docker), in docker/podman.
#
# Script has to be placed in root directory of the project - it does cd to its own directory,
# so all relative paths (test files, env file) are resolved from there.
#
# /bin/bash playwright.sh --help
#     # full description of all options
#
# /bin/bash playwright.sh -- tests/a.spec.js
#     # one test file on host machine
#
# /bin/bash playwright.sh --docker -- tests/a.spec.js
#     # the same in docker
#
# Generator of commands and required files: https://stopsopa.github.io/playwright-research/generator.html
#

set -o pipefail

S="\\" # used later to build multiline "docker run" command

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${DIR}" || exit 1

if [[ -f .env.sh ]]; then
  source .env.sh
fi

function set_podman {
  DOCKER_BIN="podman"
  DOCKER_HOST_INTERNAL="host.containers.internal"
}

function set_docker {
  DOCKER_BIN="docker"
  DOCKER_HOST_INTERNAL="host.docker.internal"
}

# PLAYWRIGHT_BIN is old name of PLAYWRIGHT_DOCKER_BIN, still honoured
PLAYWRIGHT_DOCKER_BIN="${PLAYWRIGHT_DOCKER_BIN:-${PLAYWRIGHT_BIN}}"

# container engine is needed only in "--docker" mode, so problem with it is not an error here
# (local mode, --help, --version, --image have to work on machines without docker/podman).
# It is reported later, in "--docker" branch, based on DOCKER_BIN_ERROR
DOCKER_BIN_ERROR=""

if [[ "${PLAYWRIGHT_DOCKER_BIN}" == "podman" ]]; then
  set_podman
elif [[ "${PLAYWRIGHT_DOCKER_BIN}" == "docker" ]]; then
  set_docker
elif [[ "${PLAYWRIGHT_DOCKER_BIN}" == "" ]]; then
  if command -v docker > /dev/null 2>&1; then
    set_docker
  elif command -v podman > /dev/null 2>&1; then
    set_podman
  else
    # fall back to docker names, just to have something to print in --help
    set_docker
    DOCKER_BIN_ERROR="no docker or podman available, required for '--docker' mode"
  fi
else
  set_docker
  DOCKER_BIN_ERROR="PLAYWRIGHT_DOCKER_BIN must be either docker or podman, PLAYWRIGHT_DOCKER_BIN=>${PLAYWRIGHT_DOCKER_BIN}<"
fi

GRAY=$'\033[38;5;244m'
BLACK=$'\033[30m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
WHITE=$'\033[37m'
BOLD=$'\033[1m'
REVERSE=$'\033[7m'
RESET=$'\033[0m'

# sets PLAYWRIGHT_VER (like 1.60.0) from locally installed playwright
function extractVersion() {
  local PW_OUTPUT
  local PW_EXIT_CODE

  PW_OUTPUT="$(NODE_OPTIONS= ./node_modules/.bin/playwright --version 2>&1)"
  PW_EXIT_CODE="${?}"

  if [[ "${PW_EXIT_CODE}" != "0" ]]; then
    printf "%s\n" "${PW_OUTPUT}" >&2
    echo "${0} error: './node_modules/.bin/playwright --version' failed with exit code ${PW_EXIT_CODE}" >&2
    exit "${PW_EXIT_CODE}"
  fi

  PLAYWRIGHT_VER="$(printf "%s" "${PW_OUTPUT}" | sed -n 's/^Version \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$/\1/p')"

  if ! [[ "${PLAYWRIGHT_VER}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf "%s\n" "${PW_OUTPUT}" >&2
    echo "${0} error: could not parse playwright version from output above" >&2
    exit 1
  fi
}

# sets IMAGE: PLAYWRIGHT_IMAGE env var if given, otherwise default image matching installed playwright version
function resolveImage() {

  if [[ "${PLAYWRIGHT_IMAGE}" == "" ]]; then

    extractVersion

    # HOMEPAGE FOR THE IMAGE: https://github.com/stopsopa/playwright-research/blob/master/docker/README.md
    # IMAGE="mcr.microsoft.com/playwright:v${PLAYWRIGHT_VER}-noble"
    # IMAGE="mcr.microsoft.com/playwright:v${PLAYWRIGHT_VER}-focal"
    # IMAGE="monstersmart/playwright:v${PLAYWRIGHT_VER}-focal-just-chromium"
    IMAGE="monstersmart/playwright:v${PLAYWRIGHT_VER}-noble-just-chromium"
  else

    IMAGE="${PLAYWRIGHT_IMAGE}"
  fi
}

# prints error and exits if option given as first argument has no value (second argument)
function requireValue() {

  if [[ "${2}" == "" ]]; then

    echo "${0} error: ${1} value can't be empty" >&2

    exit 1
  fi
}

_TARGET="local"
_HELP="0"
_HEADED="1"
_FORBIDONLY="1"
_PROJECT="chromium"
_TESTAGAINSTHOST="1"
_DOCKERDEFAULTS="./playwright-docker-defaults.sh"
_GENDOCKERDEFAULTS="0"
_GETPLAYWRIGHTVERSION="0"
_GETPLAYWRIGHTIMAGE="0"
ENVFILE="${ENVFILE:-.env}"

# everything what is not SCRIPT OPTIONS: [DOCKER ARGS] and [PLAYWRIGHT ARGS], split later.
# Kept in array to pass every argument further exactly as given (spaces, $, quotes ...)
REST=()

while (( "${#}" )); do
  case "${1}" in
    -h|--help)
      _HELP="1"
      shift
      ;;
    --generate-playwright-docker-defaults)
      _GENDOCKERDEFAULTS="1"
      shift
      ;;
    --version)
      _GETPLAYWRIGHTVERSION="1"
      shift
      ;;
    --image)
      _GETPLAYWRIGHTIMAGE="1"
      shift
      ;;
    --headless)
      _HEADED="0"
      shift
      ;;
    --nohost)
      _TESTAGAINSTHOST="0"
      shift
      ;;
    -dd|--docker-defaults)
      requireValue "-dd|--docker-defaults" "${2}"
      _DOCKERDEFAULTS="${2}"
      shift 2
      ;;
    -e|--env)
      requireValue "-e|--env" "${2}"
      if [[ ! -f "${2}" ]]; then
        echo "${0} error: -e|--env file >${2}< doesn't exist" >&2
        exit 1
      fi
      ENVFILE="${2}"
      shift 2
      ;;
    --allow-only)
      _FORBIDONLY="0"
      shift
      ;;
    -p|--project)
      requireValue "-p|--project" "${2}"
      _PROJECT="${2}"
      shift 2
      ;;
    -t|--target)
      requireValue "-t|--target" "${2}"
      _TARGET="${2}"
      shift 2
      ;;
    --docker)
      _TARGET="docker"
      shift
      ;;
    --) # end of SCRIPT OPTIONS
      shift
      REST+=("${@}")
      break
      ;;
    -*) # unsupported flags
      echo "${0} error: Unsupported flag >${1}<" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      REST+=("${1}")
      shift
      ;;
  esac
done

if [[ "${_HELP}" == "1" ]]; then

cat <<EOF

${BOLD}playwright.sh${RESET} - run playwright the same way on host and in ${DOCKER_BIN}

Script has to live in root directory of the project. It does cd to its own directory,
so relative paths (test files, env file) are resolved from there, not from where you call it.

Generator of commands and required files: ${CYAN}https://stopsopa.github.io/playwright-research/generator.html${RESET}

${BOLD}USAGE${RESET}
    ${YELLOW}/bin/bash playwright.sh          ${GREEN}[SCRIPT OPTIONS]${YELLOW} ${RED}--${YELLOW} ${CYAN}[PLAYWRIGHT ARGS]${RESET}
    ${YELLOW}/bin/bash playwright.sh --docker ${GREEN}[SCRIPT OPTIONS]${YELLOW} ${RED}--${YELLOW} ${CYAN}[PLAYWRIGHT ARGS]${RESET}
    ${YELLOW}/bin/bash playwright.sh --docker ${GREEN}[SCRIPT OPTIONS]${YELLOW} ${RED}--${YELLOW} ${MAGENTA}[DOCKER ARGS]${YELLOW} ${RED}--${YELLOW} ${CYAN}[PLAYWRIGHT ARGS]${RESET}

    ${GREEN}SCRIPT OPTIONS${RESET}    before first ${RED}--${RESET}                  consumed by this script, all listed below
    ${MAGENTA}DOCKER ARGS${RESET}       between two ${RED}--${RESET}, only --docker    passed untouched to "${DOCKER_BIN} run"
    ${CYAN}PLAYWRIGHT ARGS${RESET}   after last ${RED}--${RESET}                    passed untouched to "playwright test"

${BOLD}QUICK START${RESET}
    ${YELLOW}/bin/bash playwright.sh${RESET}                          # all tests, host, headed chromium
    ${YELLOW}/bin/bash playwright.sh -- tests/a.spec.js${RESET}       # one file
    ${YELLOW}/bin/bash playwright.sh --docker${RESET}                 # all tests in ${DOCKER_BIN}
    ${YELLOW}/bin/bash playwright.sh --docker -- tests/a.spec.js${RESET}

${BOLD}${GREEN}SCRIPT OPTIONS${RESET}${BOLD} (host and docker)${RESET}
    -t, --target local|docker   where to run (default: local)
        --docker                same as --target docker
    -p, --project NAME|all      browser project (default: chromium), "all" = don't pass --project,
                                run against all projects from playwright.config.js
                                WARNING: format is "--project firefox", not "--project=firefox"
    -e, --env FILE              env file (default: .env)
        --headless              don't add --headed
        --allow-only            don't add --forbid-only
        --version               print playwright version (from ./node_modules/.bin/playwright) and exit
        --image                 print ${DOCKER_BIN} image name used in --docker mode and exit
    -h, --help

${BOLD}${GREEN}SCRIPT OPTIONS${RESET}${BOLD} (docker only)${RESET}
        --nohost                        don't add "--net host" (linux) / "--env NODE_API_HOST=${DOCKER_HOST_INTERNAL}" (mac),
                                        use it to test something else than server on host machine
    -dd, --docker-defaults FILE         script printing default ${MAGENTA}DOCKER ARGS${RESET}
                                        (default: ./playwright-docker-defaults.sh, /dev/null = none)
        --generate-playwright-docker-defaults   create that file and exit

${BOLD}${CYAN}PLAYWRIGHT ARGS${RESET}
    Anything "playwright test" accepts: test files, --debug, --list, -g "title", --workers=5 ...

    This script always adds some on its own. To change them:

    added by default      change with            which goes in
    --headed              --headless             ${GREEN}SCRIPT OPTIONS${RESET}    (host only, docker is always headless)
    --forbid-only         --allow-only           ${GREEN}SCRIPT OPTIONS${RESET}
    --project=chromium    --project firefox|all  ${GREEN}SCRIPT OPTIONS${RESET}
    --workers=1           --workers=5            ${CYAN}PLAYWRIGHT ARGS${RESET}

${BOLD}${MAGENTA}DOCKER ARGS${RESET}
    Anything "${DOCKER_BIN} run" accepts: -v, --env, --name ...
    Needs both ${RED}--${RESET} delimiters, also when there are no ${CYAN}PLAYWRIGHT ARGS${RESET}:
        ${YELLOW}/bin/bash playwright.sh --docker ${RED}--${YELLOW} --name my_container ${RED}--${RESET}

    Added by default (when ${MAGENTA}DOCKER ARGS${RESET} are empty):
        output of playwright-docker-defaults.sh     what to mount from the project, rarely changes
        -v "\$(pwd)/.env:/code/.env"                 env file

    ${RED}Rule${RESET}: the moment you pass any ${MAGENTA}DOCKER ARGS${RESET}, the env file mount is NOT added anymore.
    Add it yourself:
        ${YELLOW}... --docker ${RED}--${YELLOW} -v "\$(pwd)/.env:/code/.env" --name my_container ${RED}--${YELLOW} --list${RESET}
    Swap env file for one run:
        ${YELLOW}... --docker --nohost ${RED}--${YELLOW} -v "\$(pwd)/.env_docker:/code/.env" ${RED}--${RESET}

${BOLD}ENV VARS${RESET}
    PLAYWRIGHT_DOCKER_BIN=docker|podman   force container engine (default: autodetect, docker first)
                                          (old name PLAYWRIGHT_BIN still works)
    PLAYWRIGHT_IMAGE=name:tag             image for --docker mode
                                          (default: monstersmart/playwright:v[playwright version]-noble-just-chromium,
                                          it has only chromium - for --project firefox|all provide other image)
    ENVFILE=FILE                          same as --env

${BOLD}FIRST TIME SETUP (docker)${RESET}
    ${YELLOW}/bin/bash playwright.sh --generate-playwright-docker-defaults${RESET}
    ${YELLOW}${DOCKER_BIN} pull "\$(/bin/bash playwright.sh --image)"${RESET}

EOF

  exit 0

fi

if [[ "${_TARGET}" != "local" && "${_TARGET}" != "docker" ]]; then

  echo "${0} error: unhandled --target >${_TARGET}<, allowed: local, docker" >&2

  exit 1
fi

if [[ "${_GENDOCKERDEFAULTS}" == "1" ]]; then

  if [[ -e "${_DOCKERDEFAULTS}" ]]; then

    echo "${0} error: file >${_DOCKERDEFAULTS}< already exists" >&2

    exit 1
  fi

cat <<'EEE' > "${_DOCKERDEFAULTS}"

# Prints default arguments for "docker run" executed by playwright.sh in --docker mode.
# Generated by: /bin/bash playwright.sh --generate-playwright-docker-defaults
# Adjust list of mounts to what your tests need inside container.

S="\\"

PLAYWRIGHT_TEST_MATCH_DEFAULT=""
if [[ "${PLAYWRIGHT_TEST_MATCH}" != "" ]]; then
    PLAYWRIGHT_TEST_MATCH_DEFAULT="--env PLAYWRIGHT_TEST_MATCH"
fi

NODE_API_PORT_DEFAULT=""
if [[ "${NODE_API_PORT}" != "" ]]; then
    NODE_API_PORT_DEFAULT="--env NODE_API_PORT"
fi

# mounted only when exists - mounting not existing file makes docker create directory in its place
PLAYWRIGHT_ASYNC_CONFIG_DEFAULT=""
if [[ -f "playwright-async.config.js" ]]; then
    PLAYWRIGHT_ASYNC_CONFIG_DEFAULT='-v "$(pwd)/playwright-async.config.js:/code/playwright-async.config.js"'
fi

cat <<EOF
-w "/code" ${S}
${NODE_API_PORT_DEFAULT} ${S}
${PLAYWRIGHT_TEST_MATCH_DEFAULT} ${S}
-v "\$(pwd)/tests:/code/tests" ${S}
-v "\$(pwd)/node_modules:/code/node_modules" ${S}
-v "\$(pwd)/playwright.config.js:/code/playwright.config.js" ${S}
${PLAYWRIGHT_ASYNC_CONFIG_DEFAULT}

EOF

EEE

  echo "${0}: file >${_DOCKERDEFAULTS}< created"

  exit 0
fi # end of    if [[ "${_GENDOCKERDEFAULTS}" == "1" ]]; then    condition

if ! command -v node > /dev/null 2>&1; then

  echo "${0} error: node.js is not available" >&2

  exit 1
fi

if [[ "${_GETPLAYWRIGHTVERSION}" == "1" ]]; then

  extractVersion

  printf '%s' "${PLAYWRIGHT_VER}"

  exit 0
fi

if [[ "${_GETPLAYWRIGHTIMAGE}" == "1" ]]; then

  resolveImage

  printf '%s' "${IMAGE}"

  exit 0
fi

export ENVFILE
# export it for playwright.config.js to read for -t local mode

if [[ ! -f "node_modules/.bin/playwright" ]]; then

  echo "${0} error: node_modules/.bin/playwright doesn't exist" >&2

  exit 1
fi

# [PLAYWRIGHT ARGS] added by default by this script, see --help how to change each
PW_DEFAULTS=()

if [[ "${_FORBIDONLY}" == "1" ]]; then
  PW_DEFAULTS+=(--forbid-only)
fi

if [[ "${_PROJECT}" != "all" ]]; then
  PW_DEFAULTS+=("--project=${_PROJECT}")
fi

PW_DEFAULTS+=(--workers=1)

if [[ "${_TARGET}" == "local" ]]; then

  PW_CMD=(./node_modules/.bin/playwright test)

  if [[ "${_HEADED}" == "1" ]]; then
    PW_CMD+=(--headed)
  fi

  PW_CMD+=("${PW_DEFAULTS[@]}" "${REST[@]}")

  cat <<EEE

  $(printf '%q ' "${PW_CMD[@]}")

EEE

  node -v

  "${PW_CMD[@]}"

  exit "${?}"
fi

# ------------------------------------------------------------------ --target docker

if [[ "${DOCKER_BIN_ERROR}" != "" ]]; then

  echo "${0} error: ${DOCKER_BIN_ERROR}" >&2

  exit 1
fi

if [[ "${_DOCKERDEFAULTS}" != "/dev/null" && ! -f "${_DOCKERDEFAULTS}" ]]; then

  cat >&2 <<EEE
${0} error: -dd|--docker-defaults file >${_DOCKERDEFAULTS}< doesn't exist, generate it with:

    /bin/bash playwright.sh --generate-playwright-docker-defaults --docker-defaults "${_DOCKERDEFAULTS}"

EEE

  exit 1
fi

_HOSTHANDLER=""
if [[ "${_TESTAGAINSTHOST}" == "1" ]]; then
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    _HOSTHANDLER="--env NODE_API_HOST=${DOCKER_HOST_INTERNAL}"
  else
    _HOSTHANDLER="--net host"
  fi
fi

# handling second -- on the list of arguments vvv
#   -- [DOCKER ARGS] -- [PLAYWRIGHT ARGS]     -> split on --
#   -- [PLAYWRIGHT ARGS]                      -> everything for playwright
DOUBLEDASH="0"
for ARG in "${REST[@]}"; do
  if [[ "${ARG}" == "--" ]]; then
    DOUBLEDASH="1"
  fi
done

DOCKER_ARGS=()
PW_ARGS=()

if [[ "${DOUBLEDASH}" == "1" ]]; then
  _FOR_DOCKER="1"
  for ARG in "${REST[@]}"; do
    if [[ "${ARG}" == "--" ]]; then
      _FOR_DOCKER="0"
      continue
    fi
    if [[ "${_FOR_DOCKER}" == "1" ]]; then
      DOCKER_ARGS+=("${ARG}")
    else
      PW_ARGS+=("${ARG}")
    fi
  done
else
  PW_ARGS=("${REST[@]}")
fi
# handling second -- on the list of arguments ^^^

# env file is mounted by default only when no [DOCKER ARGS] given, see --help
if (( "${#DOCKER_ARGS[@]}" == 0 )); then

  if [[ "${ENVFILE}" == /* ]]; then
    ENVPATH="${ENVFILE}"
  else
    ENVPATH="${DIR}/${ENVFILE}"
  fi

  if [[ ! -f "${ENVPATH}" ]]; then

    echo "${0} error: env file >${ENVPATH}< doesn't exist, can't mount it as /code/.env (use --env FILE or mount it through [DOCKER ARGS])" >&2

    exit 1
  fi

  DOCKER_ARGS=(-v "${ENVPATH}:/code/.env")
fi

PASS_NO_HOST=""
if [[ "${_TESTAGAINSTHOST}" == "0" ]]; then
  PASS_NO_HOST="--nohost"
fi

DOCKER_DEFAULTS="$(/bin/bash "${_DOCKERDEFAULTS}" ${PASS_NO_HOST})"

if [[ "${?}" != "0" ]]; then

  echo "${0} error: executing >${_DOCKERDEFAULTS}< have failed" >&2

  exit 1
fi

resolveImage

if [[ "${PLAYWRIGHT_IMAGE}" == "" && "${_PROJECT}" != "chromium" ]]; then

  cat >&2 <<EEE
${YELLOW}
${0} warning: --project >${_PROJECT}< with default image >${IMAGE}<
which has only chromium installed, provide image with other browsers through PLAYWRIGHT_IMAGE env var
${RESET}
EEE
fi

PW_CMD=(./node_modules/.bin/playwright test "${PW_DEFAULTS[@]}" "${PW_ARGS[@]}")

# DOCKER_DEFAULTS is a piece of shell code (it contains things like "$(pwd)") and has to go through eval,
# everything coming from arguments is escaped with %q to survive that eval untouched
CMD="$(cat <<EOF
${DOCKER_BIN} run -i --rm --ipc host --cap-add SYS_ADMIN --entrypoint="" ${S}
${DOCKER_DEFAULTS} ${S}
$(printf '%q ' "${DOCKER_ARGS[@]}") ${S}
${_HOSTHANDLER} ${S}
$(printf '%q' "${IMAGE}") ${S}
bash -s -- $(printf '%q ' "${PW_CMD[@]}")
EOF
)"

printf '\n%s\n\n' "${CMD}"

CMD="${CMD//\\$'\n'/}"

# script below is executed inside container, playwright command is passed to it as arguments ("${@}")
eval "${CMD}" <<'EEE'
set -e
echo "pwd: >$(pwd)<"
ls -la
echo "===========printenv== to see PLAYWRIGHT_TEST_MATCH ========="
printenv
echo "=========== playwright ==========="
./node_modules/.bin/playwright --version
echo "value for PLAYWRIGHT_TEST_MATCH >${PLAYWRIGHT_TEST_MATCH}<"
echo "fallback to $(NODE_OPTIONS="" node playwright.config.js | grep testMatch)"
echo "=========== run ==========="
printf '%q ' "${@}"
printf '\n\n'
"${@}"
EEE

exit "${?}"
