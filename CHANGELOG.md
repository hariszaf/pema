# Changelog

## v3.0.0

PEMA is rewritten in [Nextflow](https://www.nextflow.io/). Every step runs in its own container (Docker, Podman, Singularity or
Apptainer), which Nextflow pulls automatically: there is no PEMA image to install anymore, and the same command runs PEMA on a laptop,
a server or an HPC cluster (with the `slurm` profile, or any Nextflow executor). The BigDataScript-based PEMA v2.x is available with
the `v.2.1.5` and `v2.2.0` tags.

### Running PEMA

- One parameters file, [`pema.yaml`](pema.yaml) (YAML), replaces `parameters.tsv`; every option of every tool can be set in it.
- Input: any folder of paired-end fastq files (`.fastq`, `.fq`, gzipped or not); the read pairs are recognised by their names
  (`_1`/`_2`, `_R1`/`_R2`, Illumina names, ...), and PEMA lists every problem with the input before running anything.
- `-resume` replaces the checkpoints: only the steps whose input or parameters changed are run again.
- `-profile reports` writes Nextflow's report of the run (time, CPU and memory of every step).

### Steps

- Quality control and merging of the read pairs with fastp (replacing Trimmomatic, BayesHammer and PANDAseq / SPAdes merging).
- ITS: primers removed with cutadapt on the raw read pairs, before fastp (IUPAC codes allowed in the primers).
- ASV inference with **Swarm** or **DADA2** (new: DADA2 denoises the forward and reverse reads separately and merges them afterwards),
  or OTU clustering with **VSEARCH** (with de novo chimera removal).
- Taxonomy assignment with **crest4** (replacing CREST) or **RDPClassifier**:
  - crest4's built-in databases (SILVA/PR2, MIDORI, MitoFish, SSUome);
  - PEMA's databases, downloaded from [Zenodo](https://zenodo.org/records/23298141) on first use: `unite2025` (crest4, ITS),
    `12S_v200`, `midori_1` and `midori_2` (RDPClassifier);
  - your own databases: PEMA trains RDPClassifier or builds a crest4 database from a taxonomy and a sequence file.
- Mapping to NCBI Taxonomy with the NCBI Datasets tool (replacing ncbi-taxonomist): NCBI lineage, taxids, and the NCBI taxid of each
  taxon; names matching several taxids are resolved from the assigned lineage; within the NCBI rate limits, with or without an API key.

### Not (yet) in v3

- The phylogeny-based taxonomy assignment (EPA-ng) and the phyloseq analysis of PEMA v2.x.
- OTU clustering with CROP.

### Development

- A sanity check (`sanity_check/run_sanity_check.sh`) runs PEMA on a test dataset for each marker gene, clustering algorithm and
  classifier; CI (GitHub Actions) lints the pipeline and runs part of it on every push and pull request.
- The documentation is now in `docs/`, and published to https://hariszaf.github.io/pema_documentation by GitHub Actions.
