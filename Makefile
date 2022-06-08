# just shortcut to run app as an local instance
local_app_instance:
	node node_modules/.bin/nodemon server.js
# run app and playwright test suites as a one command locally
local_app_and_tests:
	npx playwright test --headed --forbid-only
local_app_and_tests_chromium:
	npx playwright test --headed --forbid-only --project=chromium --workers=1
# https://playwright.dev/docs/inspector#open-playwright-inspector
inspect:
	PWDEBUG=1 npx playwright test --headed --forbid-only --project=chromium --workers=1


