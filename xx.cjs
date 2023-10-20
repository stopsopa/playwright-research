// https://stopsopa.github.io/viewer.html?file=%2Fpages%2Fbash%2Fxx%2Fxx-template.cjs
// edit: https://github.com/stopsopa/stopsopa.github.io/blob/master/pages/bash/xx/xx-template.cjs

// https://stopsopa.github.io/viewer.html?file=xx.cjs
// edit: https://github.com/stopsopa/stopsopa.github.io/blob/master/xx.cjs
// 🚀 -
// ✅ -
// ⚙️  -
// 🗑️  -
// 🛑 -

module.exports = (setup) => {
  return {
    help: {
      command: `
set -e  

source .env
       
cat <<EEE

  GitHub: $(git ls-remote --get-url origin | awk '{\$1=\$1};1' | tr -d '\\n' | sed -E 's/git@github\\.com:([^/]+)\\/([^\\.]+)\\.git/https:\\/\\/github.com\\/\\1\\/\\2/g')  

  app:
    \${NODE_API_PROTOCOL}://\${NODE_API_HOST}:\${NODE_API_PORT}

  run all in chromium:
    node node_modules/.bin/playwright test --headed --forbid-only --project=chromium --workers=1  

  playwright run all registered browsers:
    node node_modules/.bin/playwright test --headed --forbid-only 
    
  inspect mode:  
    # https://playwright.dev/docs/inspector#open-playwright-inspector
    # https://playwright.dev/docs/inspector#stepping-through-the-playwright-script
    # https://playwright.dev/docs/debug#playwright-inspector
    #	PWDEBUG=console		read more: https://playwright.dev/docs/debug#run-in-debug-mode
    #	DEBUG=pw:api  		read more: https://playwright.dev/docs/debug#verbose-api-logs
      PWDEBUG=1 node node_modules/.bin/playwright test --headed --forbid-only --project=chromium --workers=1
    
  watch mode:
    # from: https://github.com/microsoft/playwright/issues/7035
      node node_modules/.bin/chokidar 'tests/**/*.e2e.js' --initial -c 'node node_modules/.bin/playwright test --headed --forbid-only --project=chromium --workers=1 --retries=0 tests/001loading.e2e.js'
    
  codegen:
    node node_modules/.bin/playwright codegen wikipedia.org

  as a library mode:
    node as-a-lib.js

EEE

      `,
      description: "Status of all things",
      confirm: false,
    },
    [`run app`]: {
      command: `
set -e
node node_modules/.bin/nodemon server.js
`,
      description: `run local app which we are about to test`,
      confirm: false,
    },
    ...setup,
  };
};
