# List of dependencies, software and their versions in PEMA 

System dependecies, building an image based on Ubuntu 16.04


## Dependencies

For an overview of the PEMA Docker image dependencies, since version `v.2.1.4`,  
you may initiate a PEMA container, for example by running 
```
docker run --rm -it hariszaf/pema:v.2.1.4
```
and have a look at the `pema_environment.tsv` file that you will find unde the `/home` folder. 

Here are the first lines of that file:
```bash
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                                Version                               Architecture Description
+++-===================================-=====================================-============-===============================================================================
ii  adduser                             3.113+nmu3ubuntu4                     all          add and remove users and groups
ii  ant                                 1.9.6-1ubuntu1.1                      all          Java based build tool like make
ii  ant-optional                        1.9.6-1ubuntu1.1                      all          Java based build tool like make - optional libraries
ii  apt           
```

For any previous versions, you may run:
```bash
dpkg --list
```

and you will get the same info. 

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
| MAFFT          | v7.427  | https://mafft.cbrc.jp/alignment/software/                                                      |
| OBITools*      | 1.2.13  | https://pythonhosted.org/OBITools/welcome.html                                                 |
| ncbi-taxonomist| 1.2.1   | https://ncbi-taxonomist.readthedocs.io/en/latest/index.html                                    | 
| CREST**        | 3.0     | https://github.com/lanzen/CREST                                                                |
| RDPTools**     | v 2.5   | https://github.com/rdpstaff/RDPTools                                                           |
| raxml-ng       | v. 1.1.0| https://github.com/amkozlov/raxml-ng                                                           |

* OBITools are now in version 3. It seems like all previous versions are hard to get. PEMA has kept this `1.2.13` version 
precompiled in a [zenodo repo](https://zenodo.org/record/5745272#.YaefgnvP0UE).

** CREST and RDPTools classifiers have been also precompiled and can be found in the PEMA [zenodo repo](https://zenodo.org/record/5745272#.YaefgnvP0UE).
   In case that new databases are about to be added in PEMA image, these will be integrated in the relative directories. 


## R packages

PEMA currently uses `R-3.6.0`

| Package        | Version |
|----------------|---------|
| `vegan`        |  2.5-7  |
| `dplyr`        |  1.0.7  |
| `tidyr`        |  1.1.4  |
| `BiocManager`  | 1.30.16 |
| `RColorBrewer` | 1.1.2   |
| `phyloseq`     | 1.30.0  |
| `ShortRead`    | 1.44.3  |


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
    <!-- - [Silva 138](https://www.arb-silva.de/no_cache/download/archive/release_138_1/Exports/) [Integrated in 2021 Dec]: 119,525 unique taxa out of 510,508 (SSURef_NR99_tax_silva_full_align_trunc.fasta.gz)
    - [PR2 v.4.14.0](https://github.com/pr2database/pr2database/releases/tag/v4.14.0) [Integrated in 2021 Dec]:  -->

> IMPORTANT NOTE! In case you would be intrested in contributing to the PEMA 
    project, you need to download and unzip these tarballs in your PEMA repository
    as described in the [pemabase Dockerfile](https://zenodo.org/record/5734317#.YaTg4HvP1hE).

