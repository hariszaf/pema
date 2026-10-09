<p align="center">
  <img src="https://hariszaf.github.io/pema_documentation/public/pema_logo.png"  width="300" align="left" >
</p>


# PEMA:
### a flexible Pipeline for Environmental DNA Metabarcoding Analysis of the 16S/18S rRNA, ITS and COI marker genes
#### PEMA website along with *how to* documentation can be found [**here**](https://hariszaf.github.io/pema_documentation/).

#### For any troubles you may have when running PEMA or for any potential improvevments you would like to suggest, please share on the [PEMA Gitter community](https://gitter.im/pema-helpdesk/community).

[![Gitter](https://badges.gitter.im/pema-helpdesk/community.svg)](https://gitter.im/pema-helpdesk/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


> **This is the Nextflow version of PEMA, under development.**
> The BigDataScript-based PEMA (v2.x), with its Docker and Singularity images and its `parameters.tsv` file,
> is available on the [`master`](https://github.com/hariszaf/pema/tree/master) branch.


Table of Contents
=================

   * [PEMA: biodiversity in all its different levels](#pema-biodiversity-in-all-its-different-levels)
   * [What the Nextflow pipeline does](#what-the-nextflow-pipeline-does)
   * [How to run PEMA](#how-to-run-pema)
      * [Requirements](#requirements)
      * [Input data](#input-data)
      * [Run](#run)
      * [Resume a run](#resume-a-run)
   * [The parameters file](#the-parameters-file)
   * [Output](#output)
   * [Running single modules](#running-single-modules)
   * [Acknowledgments](#acknowledgments)
   * [License](#license)
   * [Citation](#citation)



## PEMA: biodiversity in all its different levels

PEMA supports the metabarcoding analysis of four marker genes, **16S rRNA** (Bacteria), **ITS** (Fungi) as well as **COI** and **18S rRNA** (metazoa). As input, PEMA accepts .fastq.gz files as returned by Illumina sequencing platforms.

Since the `v.2.1.4` release, PEMA supports also the analysis of the 12S rRNA marker gene!

PEMA processes the reads from each sample and **returns an OTU- or an ASV-table with the taxonomies** of the taxa found and their abundances in each sample, along with quality reports for the reads of each sample.

PEMA is now being rewritten in [Nextflow](https://www.nextflow.io/). Every step runs in its own container, so the only requirements are Nextflow and a container engine (Docker, Podman, Singularity or Apptainer).



## What the Nextflow pipeline does

| Step | Tool | Container |
|------|------|-----------|
| Quality control and merging of paired-end reads | [fastp](https://github.com/OpenGene/fastp) | `quay.io/biocontainers/fastp` |
| Dereplication per sample | [VSEARCH](https://github.com/torognes/vsearch) | `quay.io/biocontainers/vsearch` |
| Hashing of the unique sequences and contingency table across samples | PEMA scripts | `hariszaf/pema-nf` |
| ASV inference, or | [Swarm v3](https://github.com/torognes/swarm) | `quay.io/biocontainers/swarm` |
| OTU clustering, with de novo chimera removal | [VSEARCH](https://github.com/torognes/vsearch) | `quay.io/biocontainers/vsearch` |
| Removal of oligotons (low-abundance ASVs or amplicons) and ASV/OTU tables | PEMA scripts | `hariszaf/pema-nf` |
| Taxonomy assignment | [crest4](https://github.com/xapple/crest4) or [RDPClassifier](https://github.com/rdpstaff/classifier) | `hariszaf/crest4`, `quay.io/biocontainers/rdp_classifier` |
| Mapping to NCBI Taxonomy (optional) | [NCBI Datasets CLI](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/command-line-tools/download-and-install/) | `staphb/ncbi-datasets`, `hariszaf/pema-nf` |

Supported: `clustering_algo: swarm` (ASVs) or `clustering_algo: vsearch` (OTUs), and `classifier: crest` or `classifier: rdp`, in any combination.



## How to run PEMA

### Requirements

* [Nextflow](https://www.nextflow.io/docs/latest/install.html) **25.04 or later** (tested with 26.04)
* One of: Docker (default), Podman, Singularity or Apptainer

All container images are pulled automatically on the first run.


### Input data

A folder (`raw_reads`) with paired-end fastq files (`.fastq`, `.fq`, `.fastq.gz` or `.fq.gz`).
Other files in the folder are ignored.

The two files of a pair are recognised by a `1`/`2` (or `R1`/`R2`, any case) between separators (`_`, `.` or `-`) in their names;
the last such marker in the name is used, and the part before it becomes the sample name. For example:

| Read 1 | Read 2 | Sample |
|--------|--------|--------|
| `S1_1.fastq.gz` | `S1_2.fastq.gz` | `S1` |
| `S1_R1.fq.gz` | `S1_R2.fq.gz` | `S1` |
| `S1.R1.fastq` | `S1.R2.fastq` | `S1` |
| `S1_S1_L001_R1_001.fastq.gz` | `S1_S1_L001_R2_001.fastq.gz` | `S1_S1_L001` |
| `site_1_1.fastq.gz` | `site_1_2.fastq.gz` | `site_1` |

PEMA stops before running anything, and lists all the problems found, if:

* the folder does not exist or contains no fastq files;
* a file has no `1`/`2` marker, or no sample name before it;
* a file has no mate, or two files claim to be the same read of a sample;
* two pairs end up with the same sample name (e.g. `S1_R1_001` and `S1_R1_002`).

Sample names may not contain whitespace.
Samples sequenced on several lanes (`_L001`, `_L002`, ...) are treated as separate samples.


### Run

Copy [`config_files/pema.yaml`](config_files/pema.yaml), set `raw_reads` and `outdir`, adjust the parameters (see [below](#the-parameters-file)), and run from the root folder of this repository:

```bash
nextflow run pema.nf --params-file config_files/pema.yaml
```

To use another container engine, add a profile:

```bash
nextflow run pema.nf --params-file config_files/pema.yaml -profile singularity
```

Available profiles: `docker` (default), `podman`, `singularity`, `apptainer`.
Adding the `reports` profile (e.g. `-profile docker,reports`) writes a Nextflow timeline, report and trace in `pipeline_info/`.
This needs `ps` in every container, which the `hariszaf/crest4` image does not provide yet.

> **Note:** the parameters are given with `--params-file` (two dashes), which PEMA reads itself.
> Nextflow's own `-params-file` (single dash) is a different option.


### Resume a run

Add `-resume` to re-run only the steps whose input or code changed:

```bash
nextflow run pema.nf --params-file config_files/pema.yaml -resume
```

This is especially useful if the NCBI Taxonomy step is interrupted (for example by "too many requests" errors).



## The parameters file

All parameters live in one YAML file; [`config_files/pema.yaml`](config_files/pema.yaml) documents each of them.
Parameters left empty are not passed to the tool, so the tool's own default applies.

| Section / key | Description | Default |
|---------------|-------------|---------|
| `raw_reads` | Folder with the paired-end fastq files (see [Input data](#input-data)) | **required** |
| `outdir` | Output folder | `results` |
| `threads` | Threads for fastp, Swarm and crest4 | `3` |
| `clustering_algo` | `swarm` or `vsearch` | `swarm` |
| `classifier` | `crest` or `rdp` | `crest` |
| `min_oligotons` | Abundance below which ASVs (Swarm) or amplicons (VSEARCH) are removed; `0` keeps all | `5` |
| `fastp` | Any [fastp option](https://github.com/OpenGene/fastp#all-options), without the leading `--` | **required** |
| `swarm` | Any [Swarm option](https://github.com/torognes/swarm), e.g. `differences`, `fastidious` | required for Swarm |
| `vsearch` | `threshold`: identity threshold for the OTU clustering | `0.97` |
| `crest` | `database`, `mount_crest_dbs`, `search_algo`, `min_score`, `min_smlrty`, `score_drop`, `threads` | see the YAML file |
| `rdp` | `database`, `databases_dir`, `confidence`, `memory` | see the YAML file |
| `ncbi_taxonomy` | `get_ncbi_taxonomy`, `ncbi_api_key`, `max_parallel`, `sleep` | off when missing |

PEMA adjusts some values to keep the tools consistent:

* With Swarm, fastp's `n_base_limit` is set to `0` (Swarm does not accept `N`s).
* Swarm's fastidious options (`fastidious`, `boundary`, `ceiling`, `bloom-bits`) are only used when `differences` is `1`,
  and the pairwise alignment options (`match-reward`, `mismatch-penalty`, `gap-opening-penalty`, `gap-extension-penalty`) only when it is larger than `1`.

**Oligotons.** With Swarm, `min_oligotons` applies to whole ASVs, after clustering.
With VSEARCH it applies to individual amplicons (unique sequences) before clustering, as in PEMA v2.x and the
[VSEARCH pipeline](https://github.com/torognes/vsearch/wiki/VSEARCH-pipeline), so it removes many more reads:
with VSEARCH, a low value (e.g. `2`) is usually preferable.

**CREST databases.** `database` is one of crest4's built-in databases (`ssuome`, `silvamod138pr2`, `mitofish`, `midori253darn`)
or the name of a folder with a custom database. For a custom database, `mount_crest_dbs` must point to the folder that contains it, for example:

```
~/.crest4/
├── silvamod138pr2/
└── unite_19_02_2025/
    ├── unite_19_02_2025.fasta
    ├── unite_19_02_2025.map
    ├── unite_19_02_2025.names
    ├── unite_19_02_2025.tre
    └── unite_19_02_2025.tsv
```

Setting `mount_crest_dbs` is also recommended for the built-in databases, so they are downloaded only once.

**RDPClassifier databases.** RDPClassifier needs an RDP-trained database: a folder with an `rRNAClassifier.properties` file
and the files it lists, for example:

```
rdp_databases/
└── 12S_v2.0.0/
    ├── bergeyTrainingTree.xml
    ├── genus_wordConditionalProbList.txt
    ├── logWordPrior.txt
    ├── rRNAClassifier.properties
    └── wordConditionalProbIndexArr.txt
```

Set `database` to the folder name and `databases_dir` to the folder that contains it (here `rdp_databases`), or `database` to the full path.
The PEMA-trained databases (e.g. 12S, and MIDORI for COI) are available on [Zenodo](https://zenodo.org/records/16876159) (`rdp_dbs_v220.tar.gz`).
Ranks are kept from the top down while RDPClassifier's confidence is at least `confidence` (default 0.8; for short amplicons a lower value such as 0.5 is common).
Rank prefixes such as `g__` and placeholder ranks such as `k__undef_Eukaryota` are removed from the taxonomy.

**NCBI Taxonomy.** With `get_ncbi_taxonomy: true`, the lowest taxon of each assignment is looked up in NCBI Taxonomy
and the NCBI lineage and taxids are added to the final table.
Without an API key, queries run one at a time (NCBI allows about 3 requests per second); with a key, `max_parallel` queries can run at once.
[Get an API key](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/api/api-keys/) and preferably provide it through an environment variable,
to keep it out of your configuration files:

```bash
export NCBI_API_KEY=<your key>
```



## Output

See [output_descr.md](output_descr.md) for a description of every output file.
The main result is `crest_assignment/tax_assigned_table.tsv` or `rdp_assignment/tax_assigned_table.tsv` (ASV abundances per sample with their taxonomy),
or `ncbi_taxonomy/tax_assigned_with_ncbi.tsv` when the NCBI Taxonomy step is enabled.



## Running single modules

Each module in [`modules/`](modules) can also be run on its own, for example to test a step:

```bash
nextflow run modules/swarm.nf --params-file config_files/swarm.yaml -c nextflow.config
```

Add `-c nextflow.config`: when a module is run directly, Nextflow does not load the root `nextflow.config`, so containers would be disabled.
See [modules/README.md](modules/README.md) for notes on developing the pipeline.



## Acknowledgments

PEMA invokes a series of tools and makes use of several databases.

Tools used by the Nextflow pipeline:

* fastp - https://github.com/OpenGene/fastp
* VSEARCH - https://github.com/torognes/vsearch
* SWARM - https://github.com/torognes/swarm
* crest4 - https://github.com/xapple/crest4
* NCBI Datasets - https://www.ncbi.nlm.nih.gov/datasets/
* Nextflow - https://www.nextflow.io/

Tools used by PEMA v2.x:

* FASTQC - https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
* Trimmomatic - http://www.usadellab.org/cms/?page=trimmomatic
* Cutadapt - https://cutadapt.readthedocs.io/en/stable/
* BayesHammer - included in SPAdes - http://cab.spbu.ru/software/spades/
* PANDAseq - https://github.com/neufeld/pandaseq
* OBITools4 - https://obitools4.metabarcoding.org/
* BLAST Command Line Applications - https://www.ncbi.nlm.nih.gov/books/NBK52640/
* CROP - https://github.com/tingchenlab/CROP
* RDPClassifier - https://github.com/rdpstaff/classifier
(RPDtools are required in order to execute RDPClassifier)
* "phat" algorithm, from the "gappa" package - https://github.com/lczech/gappa/wiki/Subcommand:-phat
* MAFFT - https://mafft.cbrc.jp/alignment/software/
* RAxML -ng - https://github.com/amkozlov/raxml-ng
* PaPaRa - https://cme.h-its.org/exelixis/web/software/papara/index.html
* EPA-ng - https://github.com/Pbdas/epa-ng
* phyloseq R package - http://joey711.github.io/phyloseq/index.html
* vegan R package - https://cran.r-project.org/web/packages/vegan/index.html
* ncbi-taxonomist - https://ncbi-taxonomist.readthedocs.io/en/latest/
* Big Data Script (BDS) - https://pcingola.github.io/BigDataScript/

Databases

* SILVA db - https://www.arb-silva.de/no_cache/download/archive/current/Exports/
* MIDORI db - http://reference-midori.info/index.html
* PR2 db - https://pr2-database.org/
* Unite db -- https://unite.ut.ee/

And of course the container-based technologies:

* Docker - https://www.docker.com/
* Singularity - https://sylabs.io/singularity/


## License
PEMA is under the GNU GPLv3 license (for 3rd party components separate licenses apply).

## Citation
Haris Zafeiropoulos, Ha Quoc Viet, Katerina Vasileiadou, Antonis Potirakis, Christos Arvanitidis, Pantelis Topalis, Christina Pavloudi, Evangelos Pafilis, PEMA: a flexible Pipeline for Environmental DNA Metabarcoding Analysis of the 16S/18S ribosomal RNA, ITS, and COI marker genes, GigaScience, Volume 9, Issue 3, March 2020, giaa022, https://doi.org/10.1093/gigascience/giaa022
