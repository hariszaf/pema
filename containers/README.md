# PEMA containers

Every step of the Nextflow pipeline runs in its own container. The images are set with the `container`
directive of each process in [`modules/`](../modules) and are pulled automatically on the first run.

| Image | Used by | Built from |
|-------|---------|------------|
| `hariszaf/pema-nf:0.2.2` | hashing, contingency tables, oligoton removal, VSEARCH map-back, taxonomy tables, NCBI merging | [`Dockerfile.pema_nf`](Dockerfile.pema_nf) |
| `hariszaf/crest4:4.4.5` | `CREST_TAXONOMY_ASSIGNMENT`, `TRAIN_CREST_DB` | [`Dockerfile.crest4`](Dockerfile.crest4) |
| `quay.io/biocontainers/rdp_classifier:2.13--hdfd78af_1` | `RDP_CLASSIFY` | BioContainers |
| `quay.io/biocontainers/cutadapt:5.2--py312hfabe715_2` | `CUTADAPT` (ITS) | BioContainers |
| `quay.io/biocontainers/fastp:1.0.1--heae3180_0` | `FASTP` | BioContainers |
| `quay.io/biocontainers/vsearch:2.30.4--hd6d6fdc_0` | `VSEARCH_DEREP`, and the VSEARCH OTU clustering steps | BioContainers |
| `quay.io/biocontainers/swarm:3.1.6--h9948957_0` | `SWARM` | BioContainers |
| `quay.io/biocontainers/bioconductor-dada2:1.38.0--r45ha27e39d_0` | `DADA2` | BioContainers |
| `staphb/ncbi-datasets:18.36.0` | `NCBI_TAXONOMY_QUERY` | StaPH-B |


## `pema-nf`

The `pema-nf` image holds PEMA's [`scripts/`](../scripts) (under `/opt/pema/scripts`) and what they need:
Python 3 with pandas and numpy, `gawk`, and `procps` (`ps` is needed by Nextflow to collect task metrics).

The scripts are copied into the image, so **any change in `scripts/` needs a new image**:
build it, push it with a new tag, and update the tag in the modules.

> **ATTENTION!**
>
> You need to run the `docker build` command from the root folder of the repo!

```bash
docker build -f containers/Dockerfile.pema_nf -t hariszaf/pema-nf:<tag> .
docker push hariszaf/pema-nf:<tag>
```


## Other Dockerfiles

* [`Dockerfile.dada2`](Dockerfile.dada2) builds [DADA2](https://benjjneb.github.io/dada2/) (1.40.0) from Bioconductor 3.23 / R 4.6.1,
  on the official Bioconductor image (7.6 GB); the pipeline uses the smaller BioContainers image instead.
* [`Dockerfile.rdpclassifier`](Dockerfile.rdpclassifier) builds RDPClassifier 2.13 with the PEMA-trained databases inside.
  The pipeline uses the BioContainers image instead, with the databases given in the parameters file.

The Docker and Singularity images of PEMA v2.x (BigDataScript) are described on the
[`master`](https://github.com/hariszaf/pema/tree/master) branch.



Besides DockerHub, another repo for images is the [Quay](https://quay.io/)