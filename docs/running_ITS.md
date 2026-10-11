---
layout: page
title: ITS analysis
---

ITS needs an extra step: removing the primers with [cutadapt](https://cutadapt.readthedocs.io/en/stable/).


## Primer removal

ITS amplicons vary a lot in length; when an amplicon is shorter than the reads, the reads run into the opposite primer.
So, with `marker_gene: ITS`, PEMA runs cutadapt on the raw read pairs, **before** fastp trims and merges them:

* from read 1, the forward primer and the reverse complement of the reverse primer;
* from read 2, the reverse primer and the reverse complement of the forward primer;

as in the [DADA2 ITS workflow](https://benjjneb.github.io/dada2/ITS_workflow.html).

Set the primers you used in the `cutadapt` section of the parameters file (5'→3'; IUPAC ambiguity codes are allowed), e.g.

```
marker_gene: ITS

cutadapt:
  forward_primer: GATGAAGAACGYAGYRAA
  reverse_primer: CTBTTVCCKCTTCACTCG
```

Any other cutadapt option can be added to the section, without the leading `--`, e.g. `minimum-length: 50`.
The cutadapt report of each sample, with the number of reads in which each primer was found, is in `cutadapt/` in the output folder.


## ASVs or OTUs

Set `clustering_algo` to `swarm` (ASVs) or `vsearch` (OTUs); see [16/18S analysis]({{ '/running_16_18S/' | relative_url }}).


## Taxonomy assignment

crest4 has no built-in ITS database; PEMA provides one built from [UNITE](https://unite.ut.ee/) (2025): set `database: unite2025` and
`mount_crest_dbs` to a folder of yours (in the `crest` section), and PEMA downloads it from [Zenodo](https://zenodo.org/records/23266088)
the first time it is used. You can also use another crest4 database (put it in `mount_crest_dbs` and set `database` to its name),
or build one from the UNITE sequences yourself; see
[Training the CREST classifier]({{ '/training_crest_classifier/' | relative_url }}).
