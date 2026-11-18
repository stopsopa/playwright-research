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
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TSC="${DIR}/node_modules/.bin/tsc"

if [[ ! -f "${TSC}" ]]; then

  echo "${0} error: typescript is not installed, TSC=>${TSC}< doesn't exist, run: npm install" >&2

  exit 1
fi

cd "${DIR}" || exit 1

"${TSC}" generator.ts \
  --target es2022 \
  --module es2022 \
  --lib es2022,dom,dom.iterable \
  --strict \
  --noEmitOnError \
  --skipLibCheck \
  "${@}"

CODE="${?}"

if [[ "${CODE}" != "0" ]]; then

  echo "${0} error: transpilation of generator.ts failed, exit code CODE=>${CODE}<" >&2

  exit "${CODE}"
fi

echo "${0}: generator.ts -> generator.js done"
