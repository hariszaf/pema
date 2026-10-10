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
| `marker_gene` | `16S`, `18S`, `12S`, `COI` or `ITS` | **required** |
| `outdir` | Output folder | `results` |
| `threads` | Threads for fastp, Swarm and crest4 | `3` |
| `clustering_algo` | `swarm` or `vsearch` | `swarm` |
| `classifier` | `crest` or `rdp` | `crest` |
| `min_oligotons` | Abundance below which ASVs (Swarm) or amplicons (VSEARCH) are removed; `0` keeps all | `5` |
| `cutadapt` | `forward_primer`, `reverse_primer` and any other [cutadapt option](https://cutadapt.readthedocs.io/en/stable/reference.html) | required for ITS |
| `fastp` | Any [fastp option](https://github.com/OpenGene/fastp#all-options), without the leading `--` | **required** |
| `swarm` | Any [Swarm option](https://github.com/torognes/swarm), e.g. `differences`, `fastidious` | required for Swarm |
| `vsearch` | `threshold`: identity threshold for the OTU clustering | `0.97` |
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
└── 12S_v2.0.0/
    ├── bergeyTrainingTree.xml
    ├── genus_wordConditionalProbList.txt
    ├── logWordPrior.txt
    ├── rRNAClassifier.properties
    └── wordConditionalProbIndexArr.txt
```

Set `database` to the folder name and `databases_dir` to the folder that contains it (here `rdp_databases`), or `database` to the full path.
The PEMA-trained databases `12S_v2.0.0` (12S), `midori_1` and `midori_2` (COI) are downloaded from [Zenodo](https://zenodo.org/records/16876159)
into `databases_dir` the first time they are used (`DOWNLOAD_RDP_DB`), and reused afterwards.
They are fetched as `<download_url>/<database>.tar.gz`, or, if that file is not there, from the archive with all of them (`rdp_dbs_v220.tar.gz`, ~1.2 GB).
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

Each module in [`modules/`](modules) can also be run on its own, for example to test a step:

```bash
nextflow run modules/swarm.nf --params-file config_files/swarm.yaml -c nextflow.config
```

Add `-c nextflow.config`: when a module is run directly, Nextflow does not load the root `nextflow.config`, so containers would be disabled.
See [modules/README.md](modules/README.md) for notes on developing the pipeline.



## Running the tests

On every push and pull request, GitHub Actions ([`.github/workflows/tests.yml`](.github/workflows/tests.yml)) lints the pipeline
and runs two tests of the sanity check, `COI-rdp-custom` and `COI-crest-custom`, which need no external database.
Other tests can be run from the Actions tab ("Run workflow"), with the list of tests to run.

Both can also be run on your computer: the sanity check itself, or the whole CI workflow.


### Running the sanity check locally

With Nextflow and Docker, from the root folder of this repository:

1. Lint the pipeline:
   ```bash
   nextflow lint pema.nf modules/ nextflow.config
   ```
2. Build the `pema-nf` image from your copy of the repository, with the tag the modules use, so the tests run your version of `scripts/`
   (otherwise the image is pulled from Docker Hub):
   ```bash
   for tag in $(grep -rhoE 'hariszaf/pema-nf:[0-9.]+' modules/ | sort -u); do
       docker build -f containers/Dockerfile.pema_nf -t "$tag" .
   done
   ```
3. Run the sanity check tests:
   ```bash
   sanity_check/run_sanity_check.sh COI-rdp-custom COI-crest-custom
   ```
   The first time, this downloads the sanity dataset (~280 MB) into `sanity_check/`.
   Each test prints whether it passed, and its log is `sanity_check/<marker>/TEST_<...>.log`;
   the script exits with an error if a test failed.

`sanity_check/run_sanity_check.sh` without tests runs all of them (16S, 18S, 12S, COI and ITS, with Swarm or VSEARCH, crest4 or RDPClassifier);
some need databases that are downloaded on first use (the crest4 SILVA database is ~4 GB) or that you provide.
`sanity_check/run_sanity_check.sh --help` lists the tests and their options, e.g. `--ncbi` to also test the NCBI Taxonomy step,
or `--profile singularity` to use Singularity instead of Docker.


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
