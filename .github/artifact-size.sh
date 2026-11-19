#
# Prints size and number of entries of github pages artifact, right after
# actions/upload-pages-artifact packed it in .github/workflows/playwright.yml (job "pages").
# In github actions the same information is also added to the job summary.
#
# /bin/bash .github/artifact-size.sh
#     # reads ${RUNNER_TEMP}/artifact.tar (where upload-pages-artifact leaves it)
#
# /bin/bash .github/artifact-size.sh path/to/artifact.tar
#     # reads given tar file
#

ARTIFACT="${1:-${RUNNER_TEMP}/artifact.tar}"

if [[ ! -f "${ARTIFACT}" ]]; then

  echo "${0} error: artifact file ARTIFACT=>${ARTIFACT}< doesn't exist" >&2

  exit 1
fi

SIZE="$(du -h "${ARTIFACT}" | cut -f1)"

FILES="$(tar -tf "${ARTIFACT}" | wc -l | tr -d ' ')"

ls -la "${ARTIFACT}"

echo "pages artifact size: ${SIZE}, entries: ${FILES}"

# GITHUB_STEP_SUMMARY is defined only in github actions
if [[ -n "${GITHUB_STEP_SUMMARY}" ]]; then

  echo "### Pages artifact: ${SIZE} (${FILES} entries)" >> "${GITHUB_STEP_SUMMARY}"
fi
