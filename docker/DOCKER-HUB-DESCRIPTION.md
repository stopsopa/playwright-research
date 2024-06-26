


version (currently latest v1.45.0 - as of 26-06-2024).

The difference from original is that I've added **/ms-playwright-agent** directory which is no longer provided inside image.


---



To see the difference go to these two Dockerfiles:
 
https://github.com/microsoft/playwright/blob/v1.37.1/utils/docker/Dockerfile.focal

/ms-playwright-agent exist in old image
    
https://github.com/microsoft/playwright/blob/v1.45.0/utils/docker/Dockerfile.focal

/ms-playwright-agent doesn't exist in latest image


---


can be also inspected simply by running command like:
```
docker run -it mcr.microsoft.com/playwright:v1.45.0-focal bash

docker run -it mcr.microsoft.com/playwright:v1.37.1-focal bash
```


---



more about: 

https://mcr.microsoft.com/en-us/product/playwright/about

https://playwright.dev/docs/docker#image-tags


---

How to regenerate the image

https://github.com/stopsopa/playwright-research




---


```


```