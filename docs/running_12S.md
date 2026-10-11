---
layout: page
title: 12S analysis
---

Set `marker_gene: 12S` in the parameters file; 12S is mostly used for fish and other vertebrates.

For the clustering, set `clustering_algo` to `swarm` (ASVs) or `vsearch` (OTUs); see [16/18S analysis]({{ '/running_16_18S/' | relative_url }}).


## Taxonomy assignment

* **RDPClassifier** (`classifier: rdp`) with the PEMA-trained 12S database: set `database: 12S_v200` and `databases_dir` to a folder of yours
  in the `rdp` section; PEMA downloads the database from [Zenodo](https://zenodo.org/records/23298141) the first time it is used.
  12S amplicons are short, so a `confidence` lower than the default `0.8`, such as `0.5`, usually gives more assignments to genus and species.
* **crest4** (`classifier: crest`) with `database: mitofish`, the crest4 database built from [MitoFish](http://mitofish.aori.u-tokyo.ac.jp/).

You can also use your own reference database; see [Training the RDPClassifier]({{ '/training_rdpclassifier/' | relative_url }})
and [Training the CREST classifier]({{ '/training_crest_classifier/' | relative_url }}).
