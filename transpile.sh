#
# Transpiles generator.ts -> generator.js (native ESM, loaded directly by generator.html)
# with full typechecking along the way. No bundler involved - one file in, one file out.
#
# Requires typescript in devDependencies (npm install).
#
# /bin/bash transpile.sh
#     # typecheck + emit generator.js next to generator.ts
#     # on type error: prints errors, doesn't touch generator.js, exits with non zero code
#
# /bin/bash transpile.sh --watch
#     # the same but stays running and re-transpiles on every change of generator.ts
#     # type errors are printed but process keeps running, stop with Ctrl+C
#     # previous output is not cleared between rebuilds (--preserveWatchOutput)
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TSC="${DIR}/node_modules/.bin/tsc"

WATCH="0"

# parse arguments - only --watch is supported
for ARG in "${@}"; do

  if [[ "${ARG}" == "--watch" ]]; then

    WATCH="1"
  else

    echo "${0} error: unknown argument ARG=>${ARG}<, supported: --watch" >&2

    exit 1
  fi
done

if [[ ! -f "${TSC}" ]]; then

  echo "${0} error: typescript is not installed, TSC=>${TSC}< doesn't exist, run: npm install" >&2

  exit 1
fi

cd "${DIR}" || exit 1

TSC_ARGS=(
  generator.ts
  --target es2022
  --module es2022
  --lib es2022,dom,dom.iterable
  --strict
  --noEmitOnError
  --skipLibCheck
)

# watch mode - hand over the process to tsc, it runs until Ctrl+C
if [[ "${WATCH}" == "1" ]]; then

  echo "${0}: watching generator.ts for changes (Ctrl+C to stop)"

  exec "${TSC}" "${TSC_ARGS[@]}" --watch --preserveWatchOutput
fi

"${TSC}" "${TSC_ARGS[@]}"

CODE="${?}"

if [[ "${CODE}" != "0" ]]; then

  echo "${0} error: transpilation of generator.ts failed, exit code CODE=>${CODE}<" >&2

  exit "${CODE}"
fi

echo "${0}: generator.ts -> generator.js done"
