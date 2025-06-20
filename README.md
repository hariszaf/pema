<p align="center">
  <img src="https://i.paste.pics/870189fadf668a958c8aac83f38e799c.png"  width="300" align="left" >
</p>


# PEMA: 
### a flexible Pipeline for Environmental DNA Metabarcoding Analysis of the 16S/18S rRNA, ITS and COI marker genes 
*PEMA is reposited in* [*Docker Hub*](https://hub.docker.com/r/hariszaf/pema) 
#### PEMA website along with *how to* documentation can be found [**here**](https://hariszaf.github.io/pema_documentation/).

#### For any troubles you may have when running PEMA or for any potential improvevments you would like to suggest, please share on the [PEMA Gitter community](https://gitter.im/pema-helpdesk/community).

[![Gitter](https://badges.gitter.im/pema-helpdesk/community.svg)](https://gitter.im/pema-helpdesk/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


Table of Contents
=================

   * [PEMA: biodiversity in all its different levels](#pema-biodiversity-in-all-its-different-levels)
   * [A container-based tool](#a-container-based-tool)
   * [How to run PEMA](#get-set-go-pema)
      * [Get](#get)
      * [Set](#set)
      * [Go](#go)
   * [The Parameters' file](#parameters-file)
   * [Downstream ecological analysis](#downstream-ecological-analysis)
   * [Acknowledgments](#acknowledgments)
   * [License](#license)
   * [Citation](#citation)

<!--   * [PEMA on HPC](#pema-on-hpc)
      * [Prerequisites](#prerequisites-1)
      * [Installing](#installing-1)
      * [Running PEMA](#running-pema-1)
        * [Example](#example)
   * [PEMA on a simple PC](#pema-on-a-simple-pc)
      * [Prerequisites](#prerequisites)
      * [Installing](#installing)
      * [Running PEMA](#running-pema)
         * [Step 1 - Build a Docker container](#step-1---build-a-docker-container)
         * [Step 2 - Run PEMA](#step-2---run-pema) -->


<!-- ![Anurag's GitHub stats](https://github-readme-stats.vercel.app/api?username=hariszaf&show_icons=true&theme=onedark) -->
<!-- [![Readme Card](https://github-readme-stats.vercel.app/api/pin/?username=hariszaf&repo=pema)](https://github.com/hariszaf/pema) -->


<!---  ################   FIRST CHAPTER     ########################          -->



## PEMA: biodiversity in all its different levels

PEMA supports the metabarcoding analysis of four marker genes, **16S rRNA** (Bacteria), **ITS** (Fungi) as well as **COI** and **18S rRNA** (metazoa). As input, PEMA accepts .fastq.gz files as returned by Illumina sequencing platforms.

Since the `v.2.1.4` release, PEMA supports also the analysis of the 12S rRNA marker gene!

PEMA processes the reads from each sample and **returns an OTU- or an ASV-table with the taxonomies** of the taxa found and their abundances in each sample. It also returns statistics and a FASTQC diagram about the quality of the reads for each sample. Finally, PEMA supports **downstream ecological analysis** of the profiles retrieved, facilitated by the [phyloseq](http://joey711.github.io/phyloseq/index.html) R package.

PEMA supports both OTU clustering (VSEARCH) and ASV inference (Swarm).

More specifically: 
<!-- &#9744; unchecked -->
<!-- &#9745; checked -->
| Marker gene | OTUs /VSEARCH    | ASVs / Swarm   | 
|-------------|------------------|----------------|
| 16S rRNA    |    &#9745;       |    &#9745;     |
| 18S rRNA    |    &#9745;       |    &#9745;     |
| 12S rRNA    |    &#9744;       |    &#9745;     |
| ITS         |    &#9745;       |    &#9745;     |
| COI         |    &#9744;       |    &#9745;     |


For the case of the 16S rRNA marker gene, PEMA includes two separate approaches for taxonomy assignment: alignment-based and phylogenetic-based. 
For the latter, a reference tree of 1000 taxa was created using SILVA_132_SSURef, EPA-ng and RaxML-ng.

PEMA has been implemented in [BigDataScript](https://pcingola.github.io/BigDataScript/) programming language. BDS’s ad hoc task parallelism and task synchronization, supports heavyweight computation. Thus, PEMA inherits such features and it also supports roll-back checkpoints and on-demand partial pipeline execution. In addition, PEMA takes advantage of all the computational power available on a specific machine; for example, if PEMA is executed on a personal laptop with 4 cores, it is going to use all four of them. 

Finally, container-based technologies such as Docker and Singularity, make PEMA easy accessible for all operating systems.
As you can see in the [PEMA documentation](https://hariszaf.github.io/pema_documentation/2.running_general/), once you have either Docker or Singularity on your computational environment (see below which suits your case better), running PEMA is cakewalk. You can also find the [**PEMA tutorial**](https://docs.google.com/presentation/d/1lVH23DPa2NDNBhVvOTRoip8mraw8zfw8VQwbK4vkB1U/edit?usp=sharing) as a Google Slides file.

## A container-based tool

PEMA can run either on a HPC environment (server, cluster etc) or on a simple PC. 
However, we definitely suggest to run it on an HPC environment to exploit the full potential of PEMA. Running on a powerful server or a cluster can be time-saving since it would require significantly 
less computational time than in a common PC. 
However, in some cases, for analyses with a small number of samples, a common PC can suffice.
For COI, a minimum of 20 GB of RAM for the taxonomy assignment step is required. 

PEMA runs either as a [**Docker**](https://www.docker.com/) or as a [**Singularity**](https://sylabs.io/singularity/) image. On the following chapters, you can find how to install PEMA both in Docker and Singlularity including examples.



<!---  ################   NEXT CHAPTER     ########################          -->


## Get-set-go PEMA! 

### Get

To get PEMA running you first need to make sure you either have **[Singularity]( https://www.sylabs.io/guides/3.0/user-guide/quick_start.html#quick-installation-steps )** , 
or Docker on your computing environment. 

In case you are working on Singularity, you may run the following command to get the PEMA Singularity image:

```
 singularity pull pema_v.2.1.5.sif https://gitlab.com/microbactions/pema-singularity-images-v.2.1.5/-/raw/main/pema_v.2.1.5.sif 
```

This will take some time but once it's downloaded you have PEMA ready to go!


Similarly, in case you are working on Docker you need to run: 
```bash=
docker pull hariszaf/pema:v.2.1.5
```
instead.

A version of Docker is avalable for all Windows, Mac and Linux. 
If you have Windows 10 Pro or your Mac's hardware in after 2010, then you can insall Docker straightforward. 
Otherwise, you need to install the [Docker toolbox](https://docs.docker.com/toolbox/) instead. 
You can check if your System Requirements are according to the ones mentioned below in order to be sure what you need to do.


You are now ready to set up your analysis PEMA run! 



###  Set 

In the step, you need to create a directory where you will have everything PEMA needs to 
perform an analysis. We will call this the ***analysis directory***.

In the *analysis directory*, you need to add the following **mandatory** files:

   * the [***parameters.tsv***](https://github.com/hariszaf/pema/blob/master/analysis_directory/parameters.tsv) file 
   (you can download it from this repository and then **complete it** according to the needs of your analysis) 
   > **ATTENTION!** You always need to check that you have the corresponding version of the parameters file with the pema version you are about to use! For example, if you are about to use `pema:v.2.1.5` then, your parameters file needs to be the [`v.2.1.5`](https://github.com/hariszaf/pema/blob/ARMS/analysis_directory/parameters.tsv) 

   * a subdirectory called ***mydata*** where your .fastq.gz files will be located <br />

If your need to perform phyloseq, in the analysis directory you also need to add the following **optionally** files:

   * the [***phyloseq_in_PEMA.R***](https://github.com/hariszaf/pema/blob/master/analysis_directory/phyloseq_in_PEMA.R) which you can also download from this repository and set it the way you want (that is an R script which we have implemented and has some main features that need to stay always the same in order to be executed as part of PEMA and some parts where the user can set what exactly needs to get from the phyloseq package)

   * the [***metadata.csv***](https://raw.githubusercontent.com/hariszaf/pema/master/analysis_directory/metadata.csv) file which has to be in a **comma separated** format (you can find an example of this file on PEMA's GitHub repository).


> **Attention!**  <br />
PEMA will **fail** unless you name the aforementioned files and directories **exactly** as described above.
<br />

Here is an example of how your *analysis directory* should be in case you do want a phyloseq analysis:

```bash
user@home-PC:~/Desktop/analysis_directory$ ls
mydata  parameters.tsv  phyloseq_in_PEMA.R  metadata.csv
```

and in case you do not:

```bash
user@home-PC:~/Desktop/analysis_directory$ ls
mydata  parameters.tsv 
```

[**Here**](https://github.com/hariszaf/pema/tree/master/analysis_directory) you can find an example of an *analysis directory*.

**An extended list with PEMA's ouput can be found [**here**](https://github.com/hariszaf/pema/blob/master/help_files/PEMA's%20output%20files.md).**


Now you are ready to run!




###  Go

Either you are working on Docker or in Singularity, running PEMA has two discrete steps: 

   1. A container needs to be initiated having your analysis directory mounted under a certain directory
   2. Run pema



#### Docker 
To do so using Docker, you will first run:

```bash
docker run -it -v /<path_to_analysis_directory>/:/mnt/analysis hariszaf/pema
```

The `-v` flag allows to the container you built, have access to everything included under your `<path_to_analysis_directory>`. 
All PEMA's outuput will be there too


From the inside of the PEMA container, the only thing remaining to do now, is to run PEMA:

```bash
./pema_latest.bds
```

PEMA is now running!

The runtime of PEMA depends on the computational features of your environment, on the size of your data, as well as the parameters you chose.


#### Singularity 

In case you are working on Singularity, you may implement both these steps with a single command 
by running:

```bash
singularity run -B /<path_to_analysis_directory>/:/mnt/analysis /<path_to>/pema_v.2.1.5.sif
```

The `pema_v.2.1.5.sif` may be called differently according to the pema version you 're using.



> For further information, you can always check on [PEMA's website](https://hariszaf.github.io/pema_documentation/2.running_general/).



<!---  ################   NEXT CHAPTER     ########################          -->

## Parameters' file
The most crucial component in running PEMA is the parameters file. 
This file must be located **in** the *analysis directory* and the user needs to fill it **every time** PEMA is about to be called. 
If you need more than one analyses to run, then you need to make copies of the parameters' file and have one of those in eah of the analysis directrories you create.

So, here is the [***parameters.tsv***](https://github.com/hariszaf/pema/blob/master/analysis_directory/parameters.tsv) file as it looks like, in a study case of our own. 

**Always remember** to have the same version of the parameters file with the pema version you are about to use!



<!---  ################   NEXT CHAPTER     ########################          -->



## Downstream ecological analysis

PEMA performs all the basic functions of the "phyloseq" R package. In addition, it performs certain functions of the [***vegan***](https://cran.r-project.org/web/packages/vegan/index.html) R package. 

When the user asks for a downstream analysis using the "phyloseq" R package, then an extra input file called [***"phyloseq_script.R"***](https://github.com/hariszaf/pema/blob/master/analysis_directory/phyloseq_in_PEMA.R) needs to be imported in the "analysis_directory". In PEMA's main repository, you can find a template of this file; this file needs to be as it would run on your own computer, as you would run *phyloseq* in any case. PEMA will create the *"phyloseq object"* automatically and then it will perform the analysis as asked. The output will be placed in an extra subfolder in the main output directory of PEMA called *phyloseq_analysis*. 

In addition, the ***metadata.tsv*** file is also required when the phyloseq option has been selected. An example of this file you can find [here](https://raw.githubusercontent.com/hariszaf/pema/master/analysis_directory/metadata.csv).


## Acknowledgments
PEMA uses a series of tools, datasets as well as Big Data Script language. We thank all the groups that developed them.
The tools & databases that PEMA uses are: 
* BigDataScript programming language - https://pcingola.github.io/BigDataScript/
* FASTQC - https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
* Trimmomatic - http://www.usadellab.org/cms/?page=trimmomatic
* fastp - https://github.com/OpenGene/fastp
* Cutadapt - https://cutadapt.readthedocs.io/en/stable/
* BayesHammer - included in SPAdes - http://cab.spbu.ru/software/spades/
* PANDAseq - https://github.com/neufeld/pandaseq
* OBITools - https://pythonhosted.org/OBITools/welcome.html
* BLAST Command Line Applications - https://www.ncbi.nlm.nih.gov/books/NBK52640/
* VSEARCH-2.9.1 - https://github.com/torognes/vsearch/releases/tag/v2.9.1
* SWARM - https://github.com/torognes/swarm
* CROP - https://github.com/tingchenlab/CROP
* CREST - https://github.com/lanzen/CREST
* RDPClassifier - https://github.com/rdpstaff/classifier
(RPDtools are required in order to execute RDPClassifier)
* SILVA db - https://www.arb-silva.de/no_cache/download/archive/current/Exports/
* MIDORI db - http://reference-midori.info/index.html
* PR2 db - https://pr2-database.org/
* "phat" algorithm, from the "gappa" package - https://github.com/lczech/gappa/wiki/Subcommand:-phat
* MAFFT - https://mafft.cbrc.jp/alignment/software/
* RAxML -ng - https://github.com/amkozlov/raxml-ng
* PaPaRa - https://cme.h-its.org/exelixis/web/software/papara/index.html
* EPA-ng - https://github.com/Pbdas/epa-ng
* phyloseq R package - http://joey711.github.io/phyloseq/index.html
* vegan R package - https://cran.r-project.org/web/packages/vegan/index.html 
* ncbi-taxonomist - https://ncbi-taxonomist.readthedocs.io/en/latest/

And of course the container-based technologies:
* Docker - https://www.docker.com/
* Singularity - https://sylabs.io/singularity/


## License
PEMA is under the GNU GPLv3 license (for 3rd party components separate licenses apply).

## Citation
Haris Zafeiropoulos, Ha Quoc Viet, Katerina Vasileiadou, Antonis Potirakis, Christos Arvanitidis, Pantelis Topalis, Christina Pavloudi, Evangelos Pafilis, PEMA: a flexible Pipeline for Environmental DNA Metabarcoding Analysis of the 16S/18S ribosomal RNA, ITS, and COI marker genes, GigaScience, Volume 9, Issue 3, March 2020, giaa022, https://doi.org/10.1093/gigascience/giaa022
