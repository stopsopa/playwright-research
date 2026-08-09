
# to get gitignore.js https://stopsopa.github.io/gitignore_to_find

# 
# in Github actions run as early as possible:
# 
#      - name: Check what will be mounted to docker
#        run: /bin/bash playwright-docker-defaults.sh --test
# 
# Then compare that with running locally:
# 
#       /bin/bash playwright-docker-defaults.sh --test | tee var/playwright-docker-defaults.test
# 
# Put var/.gitignore rule 
# 
#       !playwright-docker-defaults.test
# 
# and even save that file in docker, why not
# 

COUNT_EXPECTED=56 # <---- adjust that

# ------------- checks -------------------- vvv

LIST="$(find . -maxdepth 1 \
  \( -type d \( -name node_modules -o -name .git -o -name jasmine -o -name coverage \) -prune \) -o \
  \( -type d -exec sh -c 'printf "%s/\n" "$1"' _ {} \; -o -type f -print \) |
sed 's|^\./||' | NODE_OPTIONS="" node gitignore.js playwright-docker-defaults.gitignore | sort)"

COUNT=$(echo "${LIST}" | wc -l | awk '{$1=$1};1')

WRONG_COUNT=0
if [ "${COUNT}" != "${COUNT_EXPECTED}" ]; then
    cat <<EEE

${0} error: Expected exactly ${COUNT_EXPECTED} files in the root directory, but found ${COUNT}, review playwright-docker-defaults.gitignore

EEE
    WRONG_COUNT=1
fi

FIND_MOUNT="$(
    printf '%s\n' "$LIST" |
    sed '/^[[:space:]]*$/d; s|/$||; s|^\(.*\)$|-v "\\$(pwd)/\1:/code/\1" \\|'
)"

if [ "${1}" = "--test" ]; then
    cat <<EEE

${FIND_MOUNT}

count list: ${COUNT}

EEE
exit ${WRONG_COUNT};
fi

if [ "$(find . -type d -name node_modules -prune -print | wc -l)" -ne 1 ]; then
    echo "${0} error: Expected exactly one node_modules directory";

    exit 1
fi
# ------------- checks -------------------- ^^^

S="\\"

MYSQL_DB_CHANGE_DEFAULT=""
if [ "${MYSQL_DB_CHANGE}" != "" ]; then
    MYSQL_DB_CHANGE_DEFAULT="--env MYSQL_DB_CHANGE"
fi  

PLAYWRIGHT_TEST_MATCH_DEFAULT=""
if [ "${PLAYWRIGHT_TEST_MATCH}" != "" ]; then
    PLAYWRIGHT_TEST_MATCH_DEFAULT="--env PLAYWRIGHT_TEST_MATCH"
fi   

NODE_API_PORT_DEFAULT=""
if [ "${NODE_API_PORT}" != "" ]; then
    NODE_API_PORT_DEFAULT="--env NODE_API_PORT"
fi  

MYSQL_HOST_PASS=""
if [ "${1}" != "--nohost" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        MYSQL_HOST_PASS="--env MYSQL_HOST=host.docker.internal"
    # else # this case if uncommented then in some cases might double passing --net host which wouldn't make much sense, so let's prevent it
    #     _HOSTHANDLER="--net host"
    fi
fi

cat <<EOF
-w "/code" $S
${NODE_API_PORT_DEFAULT} $S
${MYSQL_DB_CHANGE_DEFAULT} $S
${PLAYWRIGHT_TEST_MATCH_DEFAULT} $S
${MYSQL_HOST_PASS} $S
${FIND_MOUNT}
--env CI=true $S

EOF

