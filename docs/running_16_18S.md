---
layout: page
title: 16/18S analysis
---

Set `marker_gene: 16S` or `marker_gene: 18S` in the parameters file.


## ASVs or OTUs

PEMA supports both ASV inference and OTU clustering; set `clustering_algo` in the parameters file:

* `swarm`: [Swarm](https://github.com/torognes/swarm) infers **ASVs**. Its options are in the `swarm` section; the usual setting is
  `differences: 1` with `fastidious: true`. Higher values of `differences` merge more sequences into each ASV.
* `dada2`: [DADA2](https://benjjneb.github.io/dada2/) infers **ASVs** from the read pairs, as in its [tutorial](https://benjjneb.github.io/dada2/tutorial.html):
  fastp filters the pairs without merging them; DADA2 learns the error rates and denoises the forward and the reverse reads separately,
  merges the denoised pairs and removes the chimeras. Its options are in the `dada2` section (e.g. `pool`, `min_overlap`); to truncate the reads to a
  fixed length, as DADA2 recommends, use fastp's `max_len1` and `max_len2`. The read counts after each step are in `dada2/dada2_read_tracking.tsv`.
* `vsearch`: [VSEARCH](https://github.com/torognes/vsearch) clusters **OTUs**, at the identity `threshold` of the `vsearch` section
  (e.g. `0.97`), after removing chimeras de novo, as in the [VSEARCH pipeline](https://github.com/torognes/vsearch/wiki/VSEARCH-pipeline).

`min_oligotons` removes ASVs with a low total abundance after Swarm or DADA2. With VSEARCH, it removes unique sequences with a low total
abundance *before* clustering (as in PEMA v2.x), which removes many more reads: use a low value, e.g. `2`.


## Taxonomy assignment

With `classifier: crest`, PEMA assigns the taxonomy with [crest4](https://github.com/xapple/crest4), an LCA-based classifier,
against one of its databases (`database` in the `crest` section):

* `silvamod138pr2`: SILVA 138 with PR2, for 16S and 18S;
* `ssuome`: the crest4 SSU database, for 16S and 18S.

crest4 downloads the database the first time it is used; set `mount_crest_dbs` to a folder of yours (e.g. `~/.crest4`) to keep it there,
so it is downloaded only once. The search uses BLAST or VSEARCH (`search_algo`); `min_score`, `score_drop` and `min_smlrty` set how strict the
assignment is (see the `crest` section of the parameters file).

You can also use your own reference database; see [Training the CREST classifier]({{ '/training_crest_classifier/' | relative_url }}).

The phylogeny-based taxonomy assignment (EPA-ng) and the `phyloseq` analysis of PEMA v2.x are not part of the Nextflow-based PEMA;
the final ASV/OTU table (`tax_assigned_table.tsv`) can be loaded in phyloseq, or any other R or Python package, directly.
