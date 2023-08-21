# just shortcut to run app as an local instance
local_app_instance:
	node node_modules/.bin/nodemon server.js

# run app and playwright test suites as a one command locally
# we don't necesarily care about running tests agains all browser
local_app_and_tests:
	node node_modules/.bin/playwright test --headed --forbid-only
	
local_app_and_tests_chromium:
	node node_modules/.bin/playwright test --headed --forbid-only --project=chromium --workers=1

# https://playwright.dev/docs/inspector#open-playwright-inspector
# https://playwright.dev/docs/inspector#stepping-through-the-playwright-script
# https://playwright.dev/docs/debug#playwright-inspector
inspect:
	PWDEBUG=1 node node_modules/.bin/playwright test --headed --forbid-only --project=chromium --workers=1
#	PWDEBUG=console		read more: https://playwright.dev/docs/debug#run-in-debug-mode
#	DEBUG=pw:api  		read more: https://playwright.dev/docs/debug#verbose-api-logs

# from: https://github.com/microsoft/playwright/issues/7035
watch:
	node node_modules/.bin/chokidar 'tests/**/*.e2e.js' --initial -c 'node node_modules/.bin/playwright test --headed --forbid-only --project=chromium --workers=1 --retries=0 tests/001loading.e2e.js'

codegen:
	node node_modules/.bin/playwright codegen wikipedia.org

# proof that playwright can be used as a library
asalib:
	node as-a-lib.js

