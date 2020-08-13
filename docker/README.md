We have built a Docker image called ***[pemabase](https://hub.docker.com/r/hariszaf/pemabase)*** with all the dependencies PEMA requires. 
This Dockerfile **will not build an image for you** as it includes some parts that have to be pre installed locally. 

After getting the base image, we can build another Docker image called ***[pema](https://hub.docker.com/r/hariszaf/pema)*** based on the *pemabase*. 

If you would like to add anything on PEMA, you may use the *pemabase* image in the same way we do. 

You **do not need to build** any of these as they are publicly available. 

You shall use it only for any further development. 
