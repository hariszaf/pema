---
layout: page
title: Get PEMA 
---


To run PEMA you need either [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/docs/) on your computer environment. 

**Singularity** is the best choice especially when you are running on a HPC or a cloud environment. 

For more details on how to set Docker or/and Singularity, please check on the [Running on HPC](https://hariszaf.github.io/pema_documentation/running_on_HPC/) and [Running on a personal computer]() according to your machine. 

Once you have a virtualization environment set, you need to build the input directory for PEMA. Once this is ready, you will need to *mount* this directory from you local, physical machine into the container environment to allow PEMA to run. 

Here are the steps to do so! 



## Get PEMA on your computer environment

Being containerized, PEMA is extremely easy to be ready-to-go on your machine. 

You just need a single command according to the virtualization platform you are using: 




## [Singularity](https://sylabs.io/guides/3.0/user-guide/installation.html)

Singularity has exactly the same notion on how to **pull** a container. 

So, in this case, the command you will have to run is

```
singularity pull shub://hariszaf/pema:<tag>
```

You should **always specify** the PEMA version you are about to download by replacing `<tag>` with that

For example, to download the `v.2.0.3` PEMA version, you would run:

```
singularity pull shub://hariszaf/pema:v.2.0.3
```




## [Docker](https://docs.docker.com/get-docker/) 
You just need to **pull** the PEMA image of the version (this will be the `<tag>` on the following commands) you want. 

```
docker pull hariszaf/pema:<tag>
```
If you leave `<tag>` blank, then you will automatically download the latest PEMA version. 

In case, you would like to get a specific PEMA version, let's say `v.1.3.2` for example, you just replace `<tag>` with the version

```
docker pull hariszaf/pema:v.1.3.1
```

As PEMA is a rather large image, this will take some minutes, depending on your internet connection. 


Once the download is complete, you are ready to go!






