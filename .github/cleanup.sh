#
# Removes big directories/files not needed on github pages, right before the pages artifact
# is packed in .github/workflows/playwright.yml (job "pages").
# Whole root directory of the project is published, so everything not removed here lands in the artifact.
#
# Steps:
#   1. refuse to run outside of CI (it deletes node_modules and others) unless --force given
#   2. remove everything from REMOVE list
#   3. print what is left in root directory: type (dir/file), size, name - sorted from biggest
#
# /bin/bash .github/cleanup.sh
#     # in github actions (CI=true): cleans and prints the list
#     # locally: exits with error, nothing removed
#
# /bin/bash .github/cleanup.sh --force
#     # cleans also on local machine
#
# /bin/bash .github/cleanup.sh --list
#     # removes nothing, only prints the list (safe everywhere)
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ROOT="$(cd "${DIR}/.." && pwd)"

# paths relative to ROOT, add here anything big which shows up in the list printed at the end
REMOVE=(
  node_modules
  test-results
  playwright-report
  playwright/.cache
  .idea
  screenshot.png
)

FORCE="0"
LIST_ONLY="0"

for ARG in "${@}"; do

  if [[ "${ARG}" == "--force" ]]; then

    FORCE="1"
  elif [[ "${ARG}" == "--list" ]]; then

    LIST_ONLY="1"
  else

    echo "${0} error: unknown argument ARG=>${ARG}<, supported: --force, --list" >&2

    exit 1
  fi
done

cd "${ROOT}" || exit 1

if [[ "${LIST_ONLY}" == "0" ]]; then

  if [[ "${CI}" != "true" && "${FORCE}" != "1" ]]; then

    echo "${0} error: not in CI (CI=>${CI}<), this script deletes node_modules and others, use --force to run it locally" >&2

    exit 1
  fi

  for ITEM in "${REMOVE[@]}"; do

    if [[ -e "${ROOT}/${ITEM}" ]]; then

      echo "${0}: removing ${ITEM}"

      rm -rf "${ROOT:?}/${ITEM}"
    else

      echo "${0}: skipping ${ITEM} (doesn't exist)"
    fi
  done
fi

# "ls -la" and "du -sh *" combined: every entry of root directory (hidden too)
# with type and size, sorted from biggest to smallest
cat <<EEE

content of ${ROOT} (biggest first):

EEE

find . -mindepth 1 -maxdepth 1 -exec du -sk {} + | sort -rn | while read -r KB NAME; do

  if [[ -d "${NAME}" ]]; then

    TYPE="dir "
  else

    TYPE="file"
  fi

  printf '%s  %8s  %s\n' "${TYPE}" "$(du -sh "${NAME}" | cut -f1)" "${NAME#./}"
done

cat <<EEE

total: $(du -sh . | cut -f1)

EEE
