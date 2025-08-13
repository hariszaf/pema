# PEMA as a Docker-based container 


# From v2.2.0

PEMA is now available in a containerized version only optionally. 
You can install it locally as explain in the main [README](../../README.md) of this repo.

However, it is also available as a container and from now on, it is independent of the ```pemabase``` image.


> **ATTENTION!**
>
> You need to run the `docker build` command, from the root folder of the repo ! 

```
docker build -t pema:v220 -f containers/docker/Dockerfile.v220 .
```



## Up to v1.1.4

PEMA used to be solely a container-based pipeline, and there were 
two Dockerfiles that were used to build the PEMA image. 

The Dockerfile shown here is the one to build the ```pema``` Docker image. 
It builds on the ```pemabase``` image and adds the actual PEMA code.

In the ```pemabase``` subdirectory, you may find the Dockerfile that builds the ```pemabase``` Docker image.
This is the software base of PEMA, setting all the dependencies, tools and databases needed. 


