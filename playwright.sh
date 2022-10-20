
# current shell name reliably
_SHELL="$(ps "${$}" | grep "${$} " | grep -v grep | sed -rn "s/.*[-\/]+(bash|z?sh) .*/\1/p")"; # bash || sh || zsh
case ${_SHELL} in
  zsh)
    _DIR="$( cd "$( dirname "${(%):-%N}" )" && pwd -P )"
    _0="$( basename "${(%):-%N}" )"
    _SCRIPT="${(%):-%N}"
    _BINARY="/bin/zsh"
    _PWD="$(pwd)"
    ;;
  sh)
    _DIR="$( cd "$( dirname "${0}" )" && pwd -P )"
    _0="$( basename "${0}" )"
    _SCRIPT="${0}"
    _BINARY="/bin/sh"
    _PWD="$(pwd)"
    ;;
  *)
    _DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
    _0="$( basename "${BASH_SOURCE[0]}" )"
    _SCRIPT="${BASH_SOURCE[0]}"
    _BINARY="/bin/bash"
    _PWD="$(pwd)"
    ;;
esac

cd "${_DIR}"

function quote {
  echo "$1" | sed -E 's/\"/\\"/g'
}

_TARGET="local";
_HELP="0";
_HEADLESS="--headed"
_ALLOWONLY="--forbid-only"
_PROJECT="--project=chromium"

PARAMS=""
_EVAL=""
while (( "$#" )); do
  case "$1" in
    -h|--help)
      _HELP="1";
      shift;
      ;;
    --headless)
      _HEADLESS="";
      shift;
      ;;
    --allow-only)
      _ALLOWONLY="";
      shift;
      ;;
    -p|--project)
      if [ "$2" = "all" ]; then                       
        _PROJECT="";
      else                                
        _PROJECT="--project=$2";                                          
      fi                              
      _PROJECT="";
      shift 2;
      ;;
    -t|--target)
      if [ "$2" = "" ]; then                           
        echo "$0 error: --target value can't be empty" >&2 
        exit 1;                                          
      fi                              
      _TARGET="$2";
      shift 2;
      ;;
    --) # end argument parsing
      shift;
      while (( "$#" )); do          # optional
        if [ "$1" = "&&" ]; then
          PARAMS="$PARAMS \&\&"
          _EVAL="$_EVAL &&"
        else
          if [ "$PARAMS" = "" ]; then
            PARAMS="\"$(quote "$1")\""
            _EVAL="\"$(quote "$1")\""
          else
            PARAMS="$PARAMS \"$(quote "$1")\""
            _EVAL="$_EVAL \"$(quote "$1")\""
          fi
        fi
        shift;                     
      done                          
      break;
      ;;
    -*|--*=) # unsupported flags
      echo "$0 error: Unsupported flag $1" >&2
      exit 1;
      ;;
    *) # preserve positional arguments
      if [ "$1" = "&&" ]; then
          PARAMS="$PARAMS \&\&"
          _EVAL="$_EVAL &&"
      else
        if [ "$PARAMS" = "" ]; then
            PARAMS="\"$(quote "$1")\""
            _EVAL="\"$(quote "$1")\""
        else
          PARAMS="$PARAMS \"$(quote "$1")\""
            _EVAL="$_EVAL \"$(quote "$1")\""
        fi
      fi
      shift;
      ;;
  esac
done

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

PARAMS="$(trim "$PARAMS")"
_EVAL="$(trim "$_EVAL")"

if [ "${_HELP}" = "1" ]; then

cat <<EOF

/bin/bash playwright.sh --target local -- ... rest of params for playwright  
    # by default
/bin/bash playwright.sh --target docker -- ... rest of params for playwright  

/bin/bash playwright.sh --headless -- ... rest of params for playwright
    # it's here because --headed is added by default
    # WARNING: be aware that this is params only handled/consumed by this script only 

/bin/bash playwright.sh --allow-only -- ... rest of params for playwright
    # it's here because --forbid-only is added by default
    # WARNING: be aware that this is params only handled/consumed by this script only 

/bin/bash playwright.sh -- --workers=5
    # this will override hardcoded --workers=1 (which is added by default)

/bin/bash playwright.sh --project=firefox -- ... rest of params for playwright
    or
/bin/bash playwright.sh --project=all -- ... rest of params for playwright
    # it's here because --project=chromium is added by default
    # --project=firefox   - this will change browser to firefox
    # --project=all       - this will launch against all registered browsers
    # WARNING: be aware that this is params only handled/consumed by this script only 
        # there is one edge case
            /bin/bash playwright.sh --project=all -- --project=firefox ... rest of params for playwright
                this is the same as 
            /bin/bash playwright.sh --project=firefox -- ... rest of params for playwright

EOF

exit 0

fi

eval set -- "$PARAMS"

if [ "${_TARGET}" = "local" ]; then

    set -e

    if [ ! -f "node_modules/.bin/playwright" ]; then

        echo "${0} error: node_modules/.bin/playwright doesn't exist"

        exit 1
    fi

    node node_modules/.bin/playwright test ${_HEADLESS} ${_ALLOWONLY} ${_PROJECT} --workers=1 $@

    exit 0
fi

if [ "${_TARGET}" = "docker" ]; then

    set -e

    if [[ "$OSTYPE" == "darwin"* ]]; then
        _HOSTHANDLER="--env HOST=host.docker.internal"
    else
        _HOSTHANDLER="--net host"
    fi

    docker run \
        -i \
        --rm \
        --ipc host \
        --cap-add SYS_ADMIN \
        -w "/code" \
        -v "$(pwd)/tests:/code/tests" \
        -v "$(pwd)/node_modules:/code/node_modules" \
        -v "$(pwd)/playwright-async.config.js:/code/playwright-async.config.js" \
        -v "$(pwd)/playwright.config.js:/code/playwright.config.js" \
        -v "$(pwd)/.env:/code/.env" \
        ${_HOSTHANDLER} \
        mcr.microsoft.com/playwright:v1.27.1-focal \
        node /ms-playwright-agent/node_modules/.bin/playwright test ${_ALLOWONLY} ${_PROJECT} --workers=1 $@
    
    exit 0
fi


echo "${0} error: unhandled --target '${_TARGET}'"

exit 1

