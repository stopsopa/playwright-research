Inside that directory, you can run several commands:

npx playwright test
Runs the end-to-end tests.

npx playwright test --project=chromium
Runs the tests only on Desktop Chrome.

npx playwright test example.spec.js
Runs the tests in the specific file.

npx playwright test --debug
Runs the tests in debug mode.

We suggest that you begin by typing:

    npx playwright test

And check out the following files:
- ./example.spec.js - Example end-to-end test
- ./playwright.config.js - Playwright Test configuration

Visit https://playwright.dev/docs/intro for more information. ✨

Happy hacking! 🎭