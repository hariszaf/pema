<p align="center">
  <img src="https://hariszaf.github.io/pema_documentation/public/pema_logo.png"  width="300" align="left" >
</p>


# PEMA:
*a flexible Pipeline for Environmental DNA Metabarcoding Analysis of the 16S/18S rRNA, ITS and COI marker genes*


<!-- TOC -->

- [PEMA:](#pema)
   - [PEMA: biodiversity in all its different levels](#pema-biodiversity-in-all-its-different-levels)
   - [What the Nextflow pipeline does](#what-the-nextflow-pipeline-does)
   - [How to run PEMA](#how-to-run-pema)
      - [Requirements](#requirements)
      - [Input data](#input-data)
      - [Run](#run)
      - [Resume a run](#resume-a-run)
   - [The parameters file](#the-parameters-file)
   - [Output](#output)
   - [Running single modules](#running-single-modules)
   - [Running the tests](#running-the-tests)
      - [Running the sanity check locally](#running-the-sanity-check-locally)
      - [Running the CI workflow locally](#running-the-ci-workflow-locally)
   - [PEMA website along with how to documentation can be found here.](#pema-website-along-with-how-to-documentation-can-be-found-here)
   - [Contact](#contact)
   - [License](#license)
   - [Citation](#citation)

<!-- /TOC -->


## PEMA: biodiversity in all its different levels

PEMA supports the metabarcoding analysis of four marker genes, **16S rRNA** (Bacteria), **ITS** (Fungi) as well as **COI** and **18S rRNA** (metazoa). As input, PEMA accepts .fastq.gz files as returned by Illumina sequencing platforms.

Since the `v.2.1.4` release, PEMA supports also the analysis of the 12S rRNA marker gene!

PEMA processes the reads from each sample and **returns an OTU- or an ASV-table with the taxonomies** of the taxa found and their abundances in each sample, along with quality reports for the reads of each sample.

PEMA is now being rewritten in [Nextflow](https://www.nextflow.io/). Every step runs in its own container, so the only requirements are Nextflow and a container engine (Docker, Podman, Singularity or Apptainer).



## What the Nextflow pipeline does

| Step | Tool | Container |
|------|------|-----------|
| Primer removal (ITS only) | [cutadapt](https://cutadapt.readthedocs.io) | `quay.io/biocontainers/cutadapt` |
| Quality control and merging of paired-end reads | [fastp](https://github.com/OpenGene/fastp) | `quay.io/biocontainers/fastp` |
| Dereplication per sample | [VSEARCH](https://github.com/torognes/vsearch) | `quay.io/biocontainers/vsearch` |
| Hashing of the unique sequences and contingency table across samples | PEMA scripts | `hariszaf/pema-nf` |
| ASV inference, or | [Swarm v3](https://github.com/torognes/swarm) | `quay.io/biocontainers/swarm` |
| ASV inference (on the read pairs, merged after denoising), or | [DADA2](https://benjjneb.github.io/dada2/) | `quay.io/biocontainers/bioconductor-dada2` |
| OTU clustering, with de novo chimera removal | [VSEARCH](https://github.com/torognes/vsearch) | `quay.io/biocontainers/vsearch` |
| Removal of oligotons (low-abundance ASVs or amplicons) and ASV/OTU tables | PEMA scripts | `hariszaf/pema-nf` |
| Taxonomy assignment | [crest4](https://github.com/xapple/crest4) or [RDPClassifier](https://github.com/rdpstaff/classifier) | `hariszaf/crest4`, `quay.io/biocontainers/rdp_classifier` |
| Mapping to NCBI Taxonomy (optional) | [NCBI Datasets CLI](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/command-line-tools/download-and-install/) | `staphb/ncbi-datasets`, `hariszaf/pema-nf` |

Supported: `clustering_algo: swarm` (ASVs), `clustering_algo: dada2` (ASVs) or `clustering_algo: vsearch` (OTUs), and `classifier: crest` or `classifier: rdp`, in any combination.



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
| `marker_gene` | `16S`, `18S`, `12S`, `COI` or `ITS` | **required** |
| `outdir` | Output folder | `results` |
| `threads` | Threads for fastp, Swarm and crest4 | `3` |
| `clustering_algo` | `swarm`, `dada2` or `vsearch` | `swarm` |
| `classifier` | `crest` or `rdp` | `crest` |
| `min_oligotons` | Abundance below which ASVs (Swarm) or amplicons (VSEARCH) are removed; `0` keeps all | `5` |
| `cutadapt` | `forward_primer`, `reverse_primer` and any other [cutadapt option](https://cutadapt.readthedocs.io/en/stable/reference.html) | required for ITS |
| `fastp` | Any [fastp option](https://github.com/OpenGene/fastp#all-options), without the leading `--` | **required** |
| `swarm` | Any [Swarm option](https://github.com/torognes/swarm), e.g. `differences`, `fastidious` | required for Swarm |
| `vsearch` | `threshold`: identity threshold for the OTU clustering; `min_oligotons` for VSEARCH only | `0.97`; the global `min_oligotons` |
| `dada2` | `trunc_len_forward`, `trunc_len_reverse`, `pool`, `min_overlap`, `max_mismatch`, `chimera_method`, `nbases` | see the YAML file |
| `crest` | `database`, `mount_crest_dbs`, `search_algo`, `min_score`, `min_smlrty`, `score_drop`, `threads`, and `train` for a custom database | see the YAML file |
| `rdp` | `database`, `databases_dir`, `confidence`, `memory`, and `train` for a custom database | see the YAML file |
| `ncbi_taxonomy` | `get_ncbi_taxonomy`, `ncbi_api_key`, `max_parallel`, `sleep` | off when missing |

**ITS.** With `marker_gene: ITS`, the primers are removed with cutadapt from the raw read pairs, before fastp. ITS amplicons vary in length,
so reads often run into the opposite primer: read 1 is trimmed of the forward primer and of the reverse complement of the reverse primer, and
read 2 of the reverse primer and of the reverse complement of the forward primer (as in the DADA2 ITS workflow). This has to happen while the
reads are still pairs, before fastp trims and merges them. IUPAC ambiguity codes are allowed in the primers.

PEMA adjusts some values to keep the tools consistent:

* With Swarm, fastp's `n_base_limit` is set to `0` (Swarm does not accept `N`s).
* Swarm's fastidious options (`fastidious`, `boundary`, `ceiling`, `bloom-bits`) are only used when `differences` is `1`,
  and the pairwise alignment options (`match-reward`, `mismatch-penalty`, `gap-opening-penalty`, `gap-extension-penalty`) only when it is larger than `1`.

**DADA2.** With `clustering_algo: dada2`, the ASVs are inferred with [DADA2](https://benjjneb.github.io/dada2/), as in its
[tutorial](https://benjjneb.github.io/dada2/tutorial.html): fastp filters the read pairs **without merging them**, DADA2 learns the
error rates and denoises the forward and the reverse reads separately (on all samples together), merges the denoised pairs
(`mergePairs`) and removes the chimeras. Merging before denoising would change the quality scores DADA2's error model relies on.
`min_oligotons` then removes the ASVs with a lower total abundance. The options are in the `dada2` section (`pool`, `min_overlap`,
`max_mismatch`, `chimera_method`, `nbases`); to truncate the reads to fixed lengths, as DADA2 recommends, set `trunc_len_forward` and `trunc_len_reverse` (applied by fastp, only for DADA2).

**Oligotons.** With Swarm, `min_oligotons` applies to whole ASVs, after clustering.
With VSEARCH it applies to individual amplicons (unique sequences) before clustering, as in PEMA v2.x and the
[VSEARCH pipeline](https://github.com/torognes/vsearch/wiki/VSEARCH-pipeline), so it removes many more reads:
with VSEARCH, a low value (e.g. `2`) is usually preferable; set it in the `vsearch` section, so it applies to VSEARCH only.

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

PEMA's own crest4 databases, currently `unite2025` (UNITE, for ITS), are downloaded from [Zenodo](https://zenodo.org/records/23298141)
into `mount_crest_dbs` the first time they are used (`DOWNLOAD_CREST_DB`, from `<download_url>/<database>.tar.gz`), and reused afterwards.
Their files are renamed after the database folder, as crest4 requires.

**Building a custom CREST database.** Set `crest.train.taxonomy` and `crest.train.sequences`, `mount_crest_dbs`, and `database` to the name of the new database.
If that database is not yet in `mount_crest_dbs`, PEMA builds it there (`PREPARE_CREST_TRAINING`, `TRAIN_CREST_DB`) and then uses it; later runs reuse it.
The database is built for crest4 with `scripts/make_new_crest_db.py` (the `.map`, `.names` and `.tre` files) and its search index is built too.
The two files are:

* a **taxonomy** file: tab-separated, no header, one line per sequence: accession, lineage, and optionally a name.
  The lineage is separated by `/` (crest4; e.g. exported from ARB, starting with `Main genome/`) or by `;` (the `.nds` files of the
  [previous CREST versions](https://hariszaf.github.io/pema_documentation/training_crest_classifier/)):
  ```
  SSEQ_1   Bacteria;Firmicutes;Bacilli;Bacillales;Bacillaceae;Bacillus;Bacillus_vallismortis   SSEQ_1
  ```
* a **sequence** file: fasta, the first word of each header being the accession. Unlike older CREST versions, crest4 does not need an alignment
  (gaps are removed if there are any).

Each rank gets a minimum similarity for an assignment to it: 0.99 for the deepest rank (e.g. species), then 0.02 less per rank up
(0.97 genus, 0.95 family, ...), and none for the first two ranks below the root (in ARB lineages, `Main genome` and the domain).
`sanity_check/custom_crest/custom_ref_db/` contains a small example.

**RDPClassifier databases.** RDPClassifier needs an RDP-trained database: a folder with an `rRNAClassifier.properties` file
and the files it lists, for example:

```
rdp_databases/
└── 12S_v200/
    ├── bergeyTrainingTree.xml
    ├── genus_wordConditionalProbList.txt
    ├── logWordPrior.txt
    ├── rRNAClassifier.properties
    └── wordConditionalProbIndexArr.txt
```

Set `database` to the folder name and `databases_dir` to the folder that contains it (here `rdp_databases`), or `database` to the full path.
The PEMA-trained databases `12S_v200` (12S; `12S_v2.0.0` also works), `midori_1` and `midori_2` (COI) are downloaded from [Zenodo](https://zenodo.org/records/23298141)
into `databases_dir` the first time they are used (`DOWNLOAD_RDP_DB`), and reused afterwards.
They are fetched as `<download_url>/<database>.tar.gz` (`download_url` in the `rdp` section).
Ranks are kept from the top down while RDPClassifier's confidence is at least `confidence` (default 0.8; for short amplicons a lower value such as 0.5 is common).
Rank prefixes such as `g__` and placeholder ranks such as `k__undef_Eukaryota` are removed from the taxonomy.

**Training RDPClassifier on a custom database.** Set `rdp.train.taxonomy` and `rdp.train.sequences`, `databases_dir`, and `database` to the name of the new database.
If that database is not yet in `databases_dir`, PEMA trains it there (`PREPARE_RDP_TRAINING`, `TRAIN_RDP_DB`) and then uses it; later runs reuse it.
The two files are prepared as described in the [PEMA documentation](https://hariszaf.github.io/pema_documentation/training_rdpclassifier/):

* a **taxonomy** file: tab-separated, with a header line; an id column, then one column per rank, with an entry for every rank on every line
  ```
  Seq_ID      Kingdom    Phylum     Class       Order     Family     Genus    Species
  SEQ1179093  Eukaryota  Annelida   Polychaeta  Eunicida  Eunicidae  Eunice   Eunice_vittata
  ```
* a **sequence** file: fasta, the first word of each header being the id used in the taxonomy file.

PEMA checks both files before training and lists any problem: missing ranks, sequences without a taxonomy, and taxon names that appear
at the same rank under different parent lineages (e.g. the genus *Thalia*, both an animal and a plant), which RDPClassifier does not allow.
Set `rename_duplicates: true` to rename those to `<name>_1`, `<name>_2`, ... instead.
Training large databases needs a lot of memory (`train.memory`; MIDORI needed more than 50 GB).
`sanity_check/custom_rdp/custom_ref_db/` contains a small example.

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

Some modules in [`modules/`](modules) can also be run on their own, to test a step on small data:
fastp, Swarm and crest4 (CREST taxonomy assignment). Their parameters files are in [`tests/configs/`](tests/configs) and their
input data in [`tests/data/`](tests/data) (see [tests/README.md](tests/README.md)). From the root folder of this repository:

```bash
nextflow run modules/fastp.nf --params-file tests/configs/fastp.yaml -c nextflow.config
nextflow run modules/swarm.nf --params-file tests/configs/swarm.yaml -c nextflow.config
nextflow run modules/crest.nf --params-file tests/configs/crest.yaml -c nextflow.config
```

The outputs are written in `tests/results/` (git-ignored). Add `-c nextflow.config`: when a module is run directly, Nextflow does not
load the root `nextflow.config`, so containers would be disabled. The crest4 test classifies ITS sequences with the `unite2025`
database: set `mount_crest_dbs` in `tests/configs/crest.yaml` to the folder that has it.
See [modules/README.md](modules/README.md) for notes on developing the pipeline.



## Running the tests

On every push and pull request, GitHub Actions ([`.github/workflows/tests.yml`](.github/workflows/tests.yml)) lints the pipeline
and runs two tests of the sanity check, `COI-rdp-custom` and `COI-crest-custom`, which need no external database.
Other tests can be run from the Actions tab ("Run workflow"), with the list of tests to run.

Both can also be run on your computer: the sanity check itself, or the whole CI workflow.


### Running the sanity check locally

[`sanity_check/run_sanity_check.sh`](sanity_check/run_sanity_check.sh) runs PEMA on a small dataset for each marker gene, with
different clustering algorithms and classifiers, and reports which cases work. Run it before a release, or to check that a change
breaks nothing. You need Nextflow and Docker (or another container engine, see `--profile`).

For each test, the script:

1. downloads and extracts the sanity dataset into `sanity_check/` (~280 MB), if it is not there yet;
2. writes a parameters file from [`config_files/pema.yaml`](config_files/pema.yaml), with the reads, marker gene, clustering
   algorithm, classifier and database of the test (so the tests always use the current parameters file);
3. runs `pema.nf` in `sanity_check/<marker>/`;
4. checks that the final table (`tax_assigned_table.tsv`) exists and has ASVs/OTUs, and counts how many have a taxonomy.

It ends with a summary, one line per test (`OK`, `FAILED` or `SKIPPED`, the time, and the number of ASVs/OTUs), and exits with an
error if a test failed. The files of a test are in `sanity_check/<marker>/`:

| File | Content |
|------|---------|
| `TEST_<marker>_FASTP_<clustering>_<classifier>/` | the output of PEMA (see [output_descr.md](output_descr.md)) |
| `TEST_<...>.yaml` | the parameters file of the test |
| `TEST_<...>.log` | the Nextflow log of the run: look here when a test fails |
| `work/` | Nextflow's intermediate files (can be deleted) |

The tests:

| Test | Marker | Clustering | Classifier and database | Needs |
|------|--------|------------|-------------------------|-------|
| `16S` | 16S | Swarm | crest4, `silvamod138pr2` | the crest4 SILVA database (~4 GB, downloaded on first use) |
| `18S` | 18S | Swarm | crest4, `silvamod138pr2` | as `16S` |
| `12S` | 12S | Swarm | crest4, `mitofish` | the crest4 MitoFish database (downloaded on first use) |
| `COI` | COI | Swarm | crest4, `midori253darn` | the crest4 MIDORI database (~3 GB, downloaded on first use) |
| `ITS` | ITS | cutadapt, Swarm | crest4, `unite2025` | PEMA's UNITE database (12 MB, downloaded on first use) |
| `16S-vsearch` | 16S | VSEARCH | crest4, `silvamod138pr2` | as `16S` |
| `18S-vsearch` | 18S | VSEARCH | crest4, `silvamod138pr2` | as `16S` |
| `16S-dada2` | 16S | DADA2 | crest4, `silvamod138pr2` | as `16S`; the slowest test (~12 min) |
| `12S-rdp` | 12S | Swarm | RDPClassifier, `12S_v200` | PEMA's 12S database (30 MB, downloaded on first use) |
| `COI-rdp` | COI | Swarm | RDPClassifier, MIDORI | `RDP_COI_DB=midori_1` or `midori_2` (downloaded on first use; >= 20 GB of memory); skipped otherwise |
| `COI-rdp-custom` | COI | Swarm | RDPClassifier, trained on `sanity_check/custom_rdp/custom_ref_db/` | nothing: trains its own database (also run by CI) |
| `COI-crest-custom` | COI | Swarm | crest4, built from `sanity_check/custom_crest/custom_ref_db/` | nothing: builds its own database (also run by CI) |

**Running specific tests.** From the root folder of this repository, give the tests to run; without tests, all of them run:

```bash
# one test
sanity_check/run_sanity_check.sh 16S

# several tests
sanity_check/run_sanity_check.sh 16S 16S-vsearch 16S-dada2

# the tests that need no external database (as CI)
sanity_check/run_sanity_check.sh COI-rdp-custom COI-crest-custom

# all the tests
sanity_check/run_sanity_check.sh
```

Options, given before the tests:

```bash
# also test the mapping to NCBI Taxonomy (set NCBI_API_KEY to go faster)
sanity_check/run_sanity_check.sh --ncbi 18S-vsearch

# with Singularity (or podman, apptainer) instead of Docker
sanity_check/run_sanity_check.sh --profile singularity 16S

# resume the previous runs of these tests, e.g. after a failure (only what changed is run again)
sanity_check/run_sanity_check.sh --resume 16S-dada2
```

Environment variables choose where the databases are and which ones some tests use:

| Variable | Default | |
|----------|---------|---|
| `CREST_DBS` | `~/.crest4` | folder of the crest4 databases; they are downloaded there once |
| `ITS_CREST_DB` | `unite2025` | crest4 database of the `ITS` test, in `CREST_DBS` |
| `RDP_DBS` | `sanity_check/rdp_dbs` | folder of the RDPClassifier databases; the PEMA-trained ones are downloaded there once |
| `RDP_12S_DB` | `12S_v200` | RDPClassifier database of the `12S-rdp` test |
| `RDP_COI_DB` | (none) | RDPClassifier database of the `COI-rdp` test, e.g. `midori_1`; without it, `COI-rdp` is skipped |

for example:

```bash
# COI with RDPClassifier and MIDORI 1
RDP_COI_DB=midori_1 sanity_check/run_sanity_check.sh COI-rdp

# ITS with a crest4 database of your own, in /data/crest4/my_unite
CREST_DBS=/data/crest4 ITS_CREST_DB=my_unite sanity_check/run_sanity_check.sh ITS

# the crest4 databases somewhere else than ~/.crest4
CREST_DBS=/scratch/crest4 sanity_check/run_sanity_check.sh 16S 18S
```

`sanity_check/run_sanity_check.sh --help` lists all this too.

**Testing your version of the code, as CI does.** The scripts of `scripts/` run in the `pema-nf` image; to test your changes to them,
build the image from your copy of the repository, with the tag the modules use (otherwise it is pulled from Docker Hub), and lint the
pipeline:

```bash
for tag in $(grep -rhoE 'hariszaf/pema-nf:[0-9.]+' modules/ | sort -u); do
    docker build -f containers/Dockerfile.pema_nf -t "$tag" .
done
nextflow lint pema.nf modules/ nextflow.config
```


### Running the CI workflow locally

To check the CI workflow itself (e.g. after changing `.github/workflows/tests.yml`), run it with [act](https://github.com/nektos/act),
which runs GitHub Actions workflows on your computer. You need Docker (usable without `sudo`), Java 17 or later, and act.

1. Get act, once. It is a single file, no installation or `sudo` needed; e.g. in `~/bin`:
   ```bash
   mkdir -p ~/bin && curl -sL https://github.com/nektos/act/releases/latest/download/act_Linux_x86_64.tar.gz | tar xz -C ~/bin act
   ~/bin/act --version
   ```
   (for macOS or Windows, see the [act releases](https://github.com/nektos/act/releases)).
2. Run the workflow, **from the root folder of this repository** (act takes the folder it is run from as the repository):
   ```bash
   ~/bin/act push -W .github/workflows/tests.yml -P ubuntu-latest=-self-hosted
   ```
   This runs what GitHub runs on a push: the lint job, then the two sanity tests (about 10 minutes). It worked if every job ends with
   `🏁  Job succeeded`, and act exits without an error. The first time, act may ask which default image to use; any answer works.
3. To run other tests, as with "Run workflow" on the Actions tab:
   ```bash
   ~/bin/act workflow_dispatch --input tests="16S 18S-vsearch" -W .github/workflows/tests.yml -P ubuntu-latest=-self-hosted
   ```
   These download the crest4 databases they need on first use (SILVA is ~4 GB).
4. Clean up: act keeps a folder for each job it ran in `~/.cache/act/<id>/` (a copy of the repository with the test outputs,
   a few GB each); delete those when you are done. Keep `~/.cache/act/actions-*`, `~/.cache/act/tool_cache` and `~/.cache/actcache`
   (the GitHub actions, Java and the caches), which act reuses.

Notes:

* `-P ubuntu-latest=-self-hosted` runs the steps directly on your computer instead of in a container: the tests start Docker containers
  themselves, which does not work from inside act's own containers. The steps need no `sudo`.
* act runs your working copy, including changes you have not committed.
* Do not use `-n` (dry run) with `-self-hosted`: in this mode the steps run anyway.
* The `actions/setup-java` step writes Maven settings in `~/.m2/` (`settings.xml`, `toolchains.xml`).
* The `punycode` deprecation messages come from the Node.js that act uses to run the GitHub actions, and can be ignored.



## PEMA website along with *how to* documentation can be found [**here**](https://hariszaf.github.io/pema_documentation/).

Its sources are in [`docs/`](docs) (a Jekyll site); changes merged into `master` are published there automatically
by the [docs workflow](.github/workflows/docs.yml), through [hariszaf/pema_documentation](https://github.com/hariszaf/pema_documentation).

To build and preview them on your computer, use Jekyll with Ruby (option 1), or Docker (option 2).

**Option 1: Jekyll.** The site uses the same Jekyll version and plugins as GitHub Pages (the `github-pages` gem, listed in
[`docs/Gemfile`](docs/Gemfile)), which need **Ruby 3.3**, as GitHub Pages uses (Ruby 4 does not work with them).

1. Install Ruby 3.3 with its development files and a C compiler, which some gems need to build.
 If your system's Ruby is another version (e.g. Fedora 44 ships Ruby 4), install 3.3 with a version manager such as [rbenv](https://github.com/rbenv/rbenv):
   ```bash
   # the compiler and libraries to build Ruby, e.g. on Fedora:
   sudo dnf install gcc make openssl-devel libyaml-devel readline-devel zlib-devel libffi-devel
   # or on Debian/Ubuntu:
   sudo apt install build-essential libssl-dev libyaml-dev libreadline-dev zlib1g-dev libffi-dev

   rbenv install 3.3.6
   cd docs && rbenv local 3.3.6      # use Ruby 3.3 in docs/ only
   ```
   On macOS, `brew install rbenv ruby-build` gives you rbenv.

2. Install the gems, in `docs/vendor/` (git-ignored):
   ```bash
   cd docs
   gem install bundler
   bundle config set --local path vendor/bundle
   bundle install
   ```
3. Build and serve the site:
   ```bash
   bundle exec jekyll serve
   ```
   and open http://localhost:4000/pema_documentation/; the pages are rebuilt as you edit them (Ctrl+C to stop).
   `bundle exec jekyll build` only builds it, in `docs/_site/`.

**Option 2: Docker.** Without installing Ruby, from the root folder of this repository:

```bash
docker run --rm -it -p 4000:4000 -u $(id -u):$(id -g) -v "$PWD/docs":/srv/jekyll jekyll/jekyll:pages jekyll serve --host 0.0.0.0
```

and open http://localhost:4000/pema_documentation/.

The documentation of the Nextflow-based PEMA is in `docs/`, and that of PEMA v2.x in `docs/v2/`.

## Contact

For any troubles you may have when running PEMA or for any potential improvevments you would like to suggest, please share on the [PEMA Gitter community](https://gitter.im/pema-helpdesk/community).

[![Gitter](https://badges.gitter.im/pema-helpdesk/community.svg)](https://gitter.im/pema-helpdesk/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


> **This is the Nextflow version of PEMA, under development.**
> The BigDataScript-based PEMA (v1.x and v2.x), with its Docker and Singularity images and its `parameters.tsv` file,
> is available on the [`master`](https://github.com/hariszaf/pema/tree/master) branch.

## License
PEMA is under the GNU GPLv3 license (for 3rd party components separate licenses apply).

## Citation
Haris Zafeiropoulos, Ha Quoc Viet, Katerina Vasileiadou, Antonis Potirakis, Christos Arvanitidis, Pantelis Topalis, Christina Pavloudi, Evangelos Pafilis, PEMA: a flexible Pipeline for Environmental DNA Metabarcoding Analysis of the 16S/18S ribosomal RNA, ITS, and COI marker genes, GigaScience, Volume 9, Issue 3, March 2020, giaa022, https://doi.org/10.1093/gigascience/giaa022
