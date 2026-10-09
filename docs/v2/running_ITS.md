---
layout: page
title: ITS analysis
---



ITS has a rather peculiar behavior in terms of removing the primers from the corresponding sequencing data.

To this end, PEMA implements an **extra step** in this case, by making use of the [`cutadapt`](https://cutadapt.readthedocs.io/en/stable/) tool. 


When you are about to run PEMA for ITS data these are the parameters you need to make sure you have ther right: 

* `gene`	   `gene_ITS`

> The next parameters are needed for the `cutadat` tool. \n You need to set the primers you used there to allow `cutadapt` to perform

* `forwardITSPrimer`	   `GATGAAGAACGYAGYRAA` 


  `reverseITSPrimer`	   `CTBTTVCCKCTTCACTCG`
 

Regarding the algorithm for ASVs inference or OTU clustering, 
you are able to select between the `Swarm` and the `CROP` algorithms.

We strongly suggest to use the `Swarm` option as it scales better and takes less time. 


