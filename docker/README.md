

# docker hub repository

https://hub.docker.com/repository/docker/monstersmart/playwright/general

# copy of description for repository above

[DOCKER-HUB-DESCRIPTION.md](DOCKER-HUB-DESCRIPTION.md)

# steps

found info how to build https://github.com/microsoft/playwright/issues/5154#issuecomment-767410926

>
> [!CAUTION]
> See final changes for each consecutive build https://github.com/stopsopa/playwright/pulls

First determine node version from the target image:
```

docker run -it mcr.microsoft.com/playwright:v1.59.1-noble node --version

```

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
