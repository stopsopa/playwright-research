

# docker hub repository

https://hub.docker.com/repository/docker/monstersmart/playwright/general

# copy of description for repository above

[DOCKER-HUB-DESCRIPTION.md](DOCKER-HUB-DESCRIPTION.md)

# steps

found info how to build https://github.com/microsoft/playwright/issues/5154#issuecomment-767410926

>
> [!CAUTION]
> Do below on the modified [PR](https://github.com/stopsopa/playwright/pull/1) prepared for particular build
>


```sh

mkdir xxx
cd xxx
git clone git@github.com:stopsopa/playwright.git .
node -v
# make sure to be on node -v -> v20.15.0 for old focal
# make sure to be on node -v -> v24.14.1 for old noble
npm ci
npm run build
# /bin/bash ./utils/docker/build.sh --arm64 focal monstersmart/playwright:v1.45.0-focal-just-chromium   --- this is for old image
/bin/bash ./utils/docker/build.sh --arm64 noble monstersmart/playwright:v1.59.1-noble-just-chromium
  # where --arm64 argument is really not used but it is provided here to just follow previous argument order

# then push
   docker push monstersmart/playwright:v1.45.0-focal-just-chromium

```
