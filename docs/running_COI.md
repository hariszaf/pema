---
layout: page
title: COI analysis
---

Set `marker_gene: COI` in the parameters file.


## ASVs or OTUs

Set `clustering_algo` to `swarm` (ASVs) or `vsearch` (OTUs); see [16/18S analysis]({{ '/running_16_18S/' | relative_url }}) for both.

> **Hint** <br />
The `differences` (*d*) parameter of Swarm can take rather high values for COI data: [it has been shown](https://www.biorxiv.org/content/10.1101/717355v3.full.pdf)
that 10 < *d* < 25 can work well. Fastidious mode only applies to *d* = 1, so PEMA turns it off otherwise.


## Taxonomy assignment

### RDPClassifier with MIDORI

With `classifier: rdp`, PEMA assigns the taxonomy with [RDPClassifier](https://github.com/rdpstaff/classifier), trained on
[MIDORI](http://www.reference-midori.info/):

* `midori_1`: MIDORI 1, metazoans;
* `midori_2`: MIDORI 2, all eukaryotes; about 100,000 more species, but considerably slower and needing more memory.

Set `database` to one of them and `databases_dir` to a folder of yours (in the `rdp` section): PEMA downloads the database from
[Zenodo](https://zenodo.org/records/23298141) the first time it is used, and reuses it afterwards.
Set `memory` to at least `20 GB`; with MIDORI 2 you will most likely need an HPC system or a server
(see [Running on HPC]({{ '/3.running_on_HPC/' | relative_url }})).

RDPClassifier gives a confidence to every rank; PEMA keeps the ranks from the top down while their confidence is at least `confidence`
(default `0.8`; for short amplicons a lower value, such as `0.5`, is common).


### crest4 with MIDORI

Alternatively, with `classifier: crest` and `database: midori253darn`, the crest4 MIDORI database is used
(see [16/18S analysis]({{ '/running_16_18S/' | relative_url }}) for crest4).


## Your own reference database

Both classifiers can be trained on your own reference sequences; see [Training the RDPClassifier]({{ '/training_rdpclassifier/' | relative_url }})
and [Training the CREST classifier]({{ '/training_crest_classifier/' | relative_url }}).
