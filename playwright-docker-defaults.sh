
# to get gitignore.js https://stopsopa.github.io/gitignore_to_find

# 
# in Github actions run as early as possible:
# 
#      - name: Docker mount test
#        run: /bin/bash playwright-docker-defaults.sh --test
# 
#           WARNING: mount this after pnpm install in the github context
# 
# Then compare that with running locally:
# 
#       FORCE_SUCCESS=1 /bin/bash playwright-docker-defaults.sh --test | tee var/playwright-docker-defaults.test
# 
# Put var/.gitignore rule 
# 
#       !playwright-docker-defaults.test
# 
# and even save that file in docker, why not
# 

COUNT_EXPECTED=62 # <---- adjust that

# ------------- checks -------------------- vvv

FIND_MOUNT="$(
    find . -maxdepth 1 \
        \( -type d \( -name .git -o -name coverage \) -prune \) -o \
        \( -type d -exec sh -c 'printf "%s/\n" "$1"' _ {} \; -o -type f -print \) |
    sed 's|^./||' |
    NODE_OPTIONS="" node gitignore.js playwright-docker-defaults.gitignore |
    sort |
    sed '/^[[:space:]]*$/d; s|\(.*\)|-v "$(pwd)/\1:/code/\1" \\|'
)"

COUNT=$(echo "${FIND_MOUNT}" | wc -l | awk '{$1=$1};1')

ERROR=
if [ "${COUNT}" != "${COUNT_EXPECTED}" ]; then
ERROR=$(cat <<EOF
${0} error: Expected exactly ${COUNT_EXPECTED} files in the root directory, but found ${COUNT}, review playwright-docker-defaults.gitignore

EOF
  );
fi

if [ "${1}" = "--test" ]; then
    if [ "${ERROR}" = "" ] || [ "${FORCE_SUCCESS}" != "" ]; then
    cat <<EEE

${FIND_MOUNT}

count list: ${COUNT}

EEE
        exit 0
    else
    cat <<EEE

diff: $(diff --color=always var/playwright-docker-defaults.test <(FORCE_SUCCESS=1 /bin/bash playwright-docker-defaults.sh --test))
${ERROR}
EEE
        exit 1
    fi
fi

if [ "$(find . \
    -path ./docs -prune -o \
    -path ./var -prune -o \
    -type d -name node_modules -prune -print | wc -l)" -ne 1 ]; then
    cat >&2 <<EEE
${0} error: Expected exactly one node_modules directory
hint: node_modules directories found:

$(find . -type d -name node_modules -prune -print)

    fetched with :
        find . -type d -name node_modules -prune -print

EEE

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
--env CI=true

EOF

