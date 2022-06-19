# just shortcut to run app as an local instance
local_app_instance:
	node node_modules/.bin/nodemon server.js
# run app and playwright test suites as a one command locally
local_app_and_tests:
	npx playwright test --headed --forbid-only
local_app_and_tests_chromium:
	npx playwright test --headed --forbid-only --project=chromium --workers=1

# https://playwright.dev/docs/inspector#open-playwright-inspector
# https://playwright.dev/docs/inspector#stepping-through-the-playwright-script
# https://playwright.dev/docs/debug#playwright-inspector
inspect:
	PWDEBUG=1 npx playwright test --headed --forbid-only --project=chromium --workers=1
#	PWDEBUG=console		read more: https://playwright.dev/docs/debug#run-in-debug-mode
#	DEBUG=pw:api  		read more: https://playwright.dev/docs/debug#verbose-api-logs

# from: https://github.com/microsoft/playwright/issues/7035
watch:
	node node_modules/.bin/chokidar 'tests/**/*.spec.js' --initial -c 'npx playwright test --headed --forbid-only --project=chromium --workers=1 --retries=0 tests/001request.spec.js'

codegen:
	npx playwright codegen wikipedia.org


