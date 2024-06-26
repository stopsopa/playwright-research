

# docker hub repository

https://hub.docker.com/repository/docker/monstersmart/playwright/general

# copy of description for repository above

[DOCKER-HUB-DESCRIPTION.md](DOCKER-HUB-DESCRIPTION.md)

# steps

found info how to build https://github.com/microsoft/playwright/issues/5154#issuecomment-767410926

Do below on the modified [PR](https://github.com/stopsopa/playwright/pull/1) prepared for particular build

```

mkdir xxx
cd xxx
git clone git@github.com:stopsopa/playwright.git .
node -v
# make sure to be on node -v -> v20.15.0
npm ci
npm run build
docker build . -t monstersmart/playwright:v1.45.0-focal

# inspect if all is right
#   docker run -it monstersmart/playwright:v1.45.0-focal bash
# and run inside the container
#   node /ms-playwright-agent/node_modules/.bin/playwright-core --help
# 
# then push
#   docker push monstersmart/playwright:v1.45.0-focal
# 

```