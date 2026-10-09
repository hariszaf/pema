---
layout: page
title: COI analysis
---


## OTUs or ASVs

PEMA includes the [CROP algorithm](https://code.google.com/archive/p/crop-tingchenlab/) for OTU clustering for the case of COI data and the [Swarm algorithm](https://github.com/torognes/swarm) for ASVs inference. 

The user may select between the two by setting the `clusteringAlgoForCOI_ITS` parameter of the `parameters.tsv` file either as `algo_CROP` or `algo_SWARM` correspondingly. 

> We are strongly suggest to use the Swarm option, especially in large datasets, as the computational time CROP might need can be 


> **Hint** <br />
The Swarm algorithm asks you to set the value of the essential parameter *d*. It [has been shown](https://www.biorxiv.org/content/10.1101/717355v3.full.pdf) that for COI data the *d* parameter can take rather high values, i.e 10 < *d* < 25. 


## Midori versions

Since `v.2.0.1` PEMA supports both [MIDORI versions](http://www.reference-midori.info/). MIDORI reference 2 includes not only metazoans but also eukaryota sequences.  

By setting the `midori_version` parameter of the `parameters.tsv` file as `v_1` or `v_2` the user may choose which of the two versions preferes to use.

MIDORI 2 may include about 100.000 unique species more, however the computational time needed to run an analysis using that increases **significantly**! 

To run an analysis using MIDORI 2 you need to have access on a HPC or cloud environment as a personal computer is quite sure that will not be able to support that. 

## Using a custom reference db

Since `v.2.0.1` PEMA supports that option for the COI data too. 
To do so, the user needs to support PEMA with two specific files so PEMA can train the RDPClassifier according to your database. 

You may have a look on how the format of these input files need to be like [here](https://github.com/hariszaf/pema/tree/local_ref_db/analysis_directory/custom_ref_db/rdpclassifier_example) and for further information on how to train the RDPClassifier, you can also check the documentation tab [Training the RDPClassifier](https://hariszaf.github.io/pema_documentation/training_rdpclassifier/).


