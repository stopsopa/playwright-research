# docker hub repository

https://hub.docker.com/repository/docker/monstersmart/playwright/general

# copy of description for repository above

[DOCKER-HUB-DESCRIPTION.md](DOCKER-HUB-DESCRIPTION.md)

# steps

found info how to build https://github.com/microsoft/playwright/issues/5154#issuecomment-767410926

> [!CAUTION]
> See final changes for each consecutive build https://github.com/stopsopa/playwright/pulls

First determine node version from the target image:

```

podman run -it mcr.microsoft.com/playwright:v1.60.0-noble node --version
docker run -it mcr.microsoft.com/playwright:v1.59.1-noble node --version

```

Then sync upstream main to our fork

```sh
# pull https://github.com/stopsopa/playwright using /Users/xxxx/Workspace/pull.sh
git remote add upstream https://github.com/microsoft/playwright.git
git fetch upstream
git checkout main
git merge upstream/main
git push origin main

```

Then create local branch from latests tag

```

export LATEST_TAG="v1.60.0"

git checkout -b "${LATEST_TAG}" "tags/${LATEST_TAG}"

git push -u origin "refs/heads/${LATEST_TAG}"

git checkout -b "${LATEST_TAG}-only-chrome-with-core"

git push -u origin "${LATEST_TAG}-only-chrome-with-core"

# create branch
echo "" >> README.md
git add README.md
git commit -m "add branch for ${LATEST_TAG}"
git push
# and visit
cat <<EEE

  Name pull request:
  
    Building custom ${LATEST_TAG} docker image with just chrome and with /ms-playwright-agent

   https://github.com/stopsopa/playwright/compare/${LATEST_TAG}...stopsopa:playwright:${LATEST_TAG}-only-chrome-with-core

EEE

```

and create pull request from branch "${LATEST_TAG}-only-chrome-with-core" to "${LATEST_TAG}"

then

look for images https://mcr.microsoft.com/en-us/artifact/mar/playwright/tags

that will be needed to setup asdf node.js version for the branch we will create

Create new PR based on some combination of changes done in latests pr from the file [CUSTOM_BUILD.md](https://github.com/stopsopa/playwright/pull/2/changes#diff-bbb64ab4bd6463c3339113b403525b158daf1e3484dfdf3f1aa1babed37a81aa)

Once you create new PR for the new image then execute these commands:

```sh

mkdir xxx
cd xxx
git clone git@github.com:stopsopa/playwright.git .
switch to just created branch
node -v
# make sure to be on node -v -> v20.15.0 for old focal
# make sure to be on node -v -> v24.14.1 for old noble
docker login
npm ci
npm run build
# /bin/bash ./utils/docker/build.sh --arm64 focal monstersmart/playwright:v1.45.0-focal-just-chromium   --- this is for old image
/bin/bash ./utils/docker/build.sh --arm64 noble monstersmart/playwright:v1.59.1-noble-just-chromium
  # where --arm64 argument is really not used but it is provided here to just follow previous argument order

# then push
   docker push monstersmart/playwright:v1.45.0-focal-just-chromium

```

Further testing starts from here:

https://github.com/stopsopa/playwright/pull/2/changes#diff-bbb64ab4bd6463c3339113b403525b158daf1e3484dfdf3f1aa1babed37a81aaR47
