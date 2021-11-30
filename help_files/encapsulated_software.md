# List of dependencies, software and their versions in PEMA 

System dependecies, building an image based on Ubuntu 16.04


## Dependencies

| Dependency                 | Version / notes |
|----------------------------|-----------------|
| bds                        | 0.99999p (build 2018-01-03 10:35) |
| ant                        |         |
| software-properties-common |        |
| openjdk-8-jdk              |        |
| openjdk-11-jdk             | 11.0.11+9 |
| wget                       | 1.17.1 |
| bzip2                      | 1.0.6  |
| libbz2-dev                 |        |
| liblzma-dev                |        |
| libcurl4-openssl-dev       |        |
| ca-certificates            |        |
| libglib2.0-0               |        |
| libxext6                   |        |
| libsm6                     |        |
| libxrender1                |        |
| mono-mcs                   |        |
| git                        | 2.7.4  |
| mercurial                  |        |
| subversion                 |        |
| unzip                      | 6.00   |
| autoconf                   | 2.69   |
| autogen                    | 5.18.7 |
| libtool                    |        |
| gcc                        | 5.4.0  |
| zlib1g-dev                 |        |
| ca-certificates-java       |        |
| libjpeg-dev                |        |
| pip                        | 21.1.3 |
| R                          | 3.6.0  |
| xorg-dev                   |        |
| build-essential            |        |
| gfortran                   | 5.4.0  |
| fort77                     |        |
| libblas-dev                |        |
| gcc-multilib               |        |
| gobjc++                    |        |
| aptitude                   | 0.7.4  |
| libreadline-dev            |        |
| cmake                      | 3.5.1  |
| curl                       | 7.47.0 |      





## Software versions

| Software       | Version | Url                                                                                            |
|----------------|---------|------------------------------------------------------------------------------------------------|
| EPA-ng         | v0.3.8  | https://github.com/Pbdas/epa-ng/releases/tag/v0.3.8                                            |
| Swarm          | 3.1.0   | https://github.com/torognes/swarm/releases/tag/v3.1.0                                          |
| PaPaRa         | 2.5     | https://sco.h-its.org/exelixis/resource/download/software/papara_nt-2.5-static_x86_64.tar.gz   |
| SPAdes         | 3.13.0  | http://cab.spbu.ru/files/release3.13.0/SPAdes-3.13.0-Linux.tar.gz                              |
| pandaseq       | 2.11    | https://github.com/neufeld/pandaseq/releases/tag/v2.11                                         |
| Trimmomatic    | 0.38    | http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.38.zip            |
| vsearch        | v2.9.1  | https://github.com/torognes/vsearch/releases/download/v2.9.1/vsearch-2.9.1-linux-x86_64.tar.gz |
| FastQC         | v0.11.8 | https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip                   |
| cutadapt3      | 1.9.1   | https://cutadapt.readthedocs.io/en/stable/                                                     |
| MAFFT          | v7.427  |                                                                                                |
| OBITools       | 1.2.13  |                                                                                                |
| ncbi-taxonomist| 1.2.1   |                                                                                                | 
| CREST          | 3.0     |                                                                                                |
| RDPTools       |         |                                                                                                |

 
## R packages

| package      |
|--------------|
| vegan        |
| dplyr        |
| tidyr        |
| BiocManager  |
| RColorBrewer |
| phyloseq     |
| ShortRead    |



## Databases 

To facilitate updating reference databases, a Zenodo repository has been 
created to version RDPTools and CREST classifiers, along with their training 
files. 

You may find this repo [here]().

Currently, RDPTools support: 
    - Midori 1
    - Midori 2

CREST supports: 
    - Silva 128
    - Silva 132
    - [Silva 138](https://www.arb-silva.de/no_cache/download/archive/release_138_1/Exports/) [Integrated in 2021 Dec]: 119,525 unique taxa out of 510,508 (SSURef_NR99_tax_silva_full_align_trunc.fasta.gz)
    - [PR2 v.4.14.0](https://github.com/pr2database/pr2database/releases/tag/v4.14.0) [Integrated in 2021 Dec]: 

> IMPORTANT NOTE! In case you would be intrested in contributing to the PEMA 
    project, you need to download and unzip these tarballs in your PEMA repository
    as described in the [pemabase Dockerfile](https://zenodo.org/record/5734317#.YaTg4HvP1hE).

