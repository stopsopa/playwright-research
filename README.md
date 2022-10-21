
# What is purpose of this repository?

The idea behind this repository is to create single point of execution to run playwright tests in most portable way possible across different scenarios:
1) run tests locally against your local server to have all test "blink" in front of your eyes
2) run tests locally against your local server in headles mode
3) run tests locally in docker against remote server and have them "blink" in front of your eyes
4) run tests locally in docker against remote server in headles mode
5) run all tests locally in docker against your local server
6) run all tests locally in docker remote server
7) and so on

Additionally
8) all above should be done by executing single line of code
9) command should return proper exit code
10) filtering tests to run single directory or single test.spec file
11) injecting env vars one by one or via injecting different .env file
12) it should have place to configure what should be mounted for tests to "docker run -v ..." if executed in docker mode
13) if tests executed in docker, version of docker image should be determined by extracting version of "[playwright](https://www.npmjs.com/package/playwright)" library from local package.json
14) if tests executed in docker command should return the final docker run command executed
15) it should provide way to control all arguments of "docker run" command
16) it should provide way to control all arguments of "playwrite run" command
17) it should run tests in headless mode by default if executed in docker
18) it should run tests in headed mode by default if executed on local machine
19) command also should be usable in pipelines

To achieve all above there is few "things" needed:
- playwright.sh file
- playwright-docker-defaults.sh file (can be generated with defaults by playwright.sh)
- playwright.sh will require [playwright browser intalled globally](https://playwright.dev/docs/intro#installing-playwright) for local executing
- playwright.sh will require to have "[playwright](https://www.npmjs.com/package/playwright)" and "[@playwright/test](https://www.npmjs.com/package/@playwright/test)" installed in local package.json dependencies (both in the same version)
- you need to have some tests (by default in "tests" directory)
- you also have to have playwright.config.js (obviously)

Here are examples how to achieve each point from 


# doc

- [Expect](https://jestjs.io/docs/expect) also [Assertions doc page](https://playwright.dev/docs/test-assertions) and [Playwright test doc page](https://playwright.dev/docs/api/class-test)
- [Debugging selector](https://playwright.dev/docs/inspector#debugging-selectors)
- [Trace on retry](https://playwright.dev/docs/trace-viewer#recording-a-trace)
- [Record session an reuse it](https://playwright.dev/docs/codegen#preserve-authenticated-state) Also for [API testing](https://playwright.dev/docs/test-api-testing#reusing-authentication-state). See also [Intercepting with Route](https://playwright.dev/docs/api/class-route)
- [Codegen](https://playwright.dev/docs/codegen) [Non standard context](https://playwright.dev/docs/codegen#record-using-custom-setup)
- [Skip test - conditions](https://playwright.dev/docs/test-annotations#conditionally-skip-a-group-of-tests)
- [Emulate geolocation](https://playwright.dev/docs/codegen#emulate-geolocation-language-and-timezone)
- [slowMo](https://playwright.dev/docs/debug#run-in-headed-mode)
- [as a lib](as-a-lib.js) -> [from](https://playwright.dev/docs/api/class-page#page-event-request-failed) also [Playwright Library doc page](https://playwright.dev/docs/api/class-playwright)

# cmd
- https://playwright.dev/docs/intro#command-line

# watch mode
https://github.com/microsoft/playwright/issues/7035

# some extra doc pages
- [Listening to console](https://playwright.dev/docs/api/class-consolemessage) and native PW [logger](https://playwright.dev/docs/api/class-logger)
- File [Download](https://playwright.dev/docs/api/class-download) and [Upload](https://playwright.dev/docs/api/class-filechooser)
- [Interacting with element](https://playwright.dev/docs/api/class-elementhandle)
- [Keyboard](https://playwright.dev/docs/api/class-keyboard)

# last read doc page
https://playwright.dev/docs/intro

# todo
- [x] integrate with GH Actions
- [x] build some example tests
- [x] make docker image version package.json '@playwright/test' driven
