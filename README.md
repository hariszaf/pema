<p align="center">
  <img src="https://i.paste.pics/870189fadf668a958c8aac83f38e799c.png"  width="300" align="left" >
</p>

<br/><br/>
# PEMA: 
## a flexible Pipeline for Environmental DNA Metabarcoding Analysis of the 16S/18S rRNA, ITS and COI marker genes 
*PEMA is reposited in* [*Docker Hub*](https://hub.docker.com/r/hariszaf/pema) *as well as in* [*Singularity Hub*](https://singularity-hub.org/collections/2295)

#### A PEMA tutorial can be found [**here**]( https://docs.google.com/presentation/d/1lVH23DPa2NDNBhVvOTRoip8mraw8zfw8VQwbK4vkB1U/edit?fbclid=IwAR14PpWfPtxB8lLBBnoxs7UbG3IJfkArrJBS5f2kRA__kvGDUb8wiJ2Cy_s#slide=id.g57f092f54d_1_21).




<!---
```diff
[//]---------  **This is still a BETA version!**    ---------
```
-->

Table of Contents
=================

   * [PEMA: biodiversity in all its different levels](#pema-biodiversity-in-all-its-different-levels)
   * [ A container-based tool](#a-container-based-tool)
   * [How to run PEMA](#how-to-run-pema)
   * [Parameters' file](#parameters-file)
   * [PEMA on HPC](#pema-on-hpc)
      * [Prerequisites](#prerequisites-1)
      * [Installing](#installing-1)
      * [Running PEMA](#running-pema-1)
        * [Example](#example)
   * [PEMA on a simple PC](#pema-on-a-simple-pc)
      * [Prerequisites](#prerequisites)
      * [Installing](#installing)
      * [Running PEMA](#running-pema)
         * [Step 1 - Build a Docker container](#step-1---build-a-docker-container)
         * [Step 2 - Run PEMA](#step-2---run-pema)
   * [phyloseq - for a downstream ecological analysis](#the-phyloseq-r-package)
   * [Acknowledgments](#acknowledgments)
   * [Citation](#citation)


```diff
+ PEMA now supports 2 extra marker genes, 18S rRNA and ITS. 
+ PEMA is now available for macOS!
for anything feel free to contact me at: haris-zaf@hcmr.gr
```

<!---  ################   FIRST CHAPTER     ########################          -->



# PEMA: biodiversity in all its different levels

PEMA supports the metabarcoding analysis of four marker genes, **16S rRNA** (Bacteria), **ITS** (Fungi) as well as **COI** and **18S rRNA** (metazoa). As input, PEMA accepts .fastq.gz files as returned by Illumina sequencing platforms.

PEMA processes the reads from each sample and **returns an OTU- or an ASV-table with the taxonomies** of the taxa found and their abundances in each sample. It also returns statistics and a FASTQC diagram about the quality of the reads for each sample. Finally, PEMA supports **downstream ecological analysis** of the profiles retrieved, facilitated by the [phyloseq](http://joey711.github.io/phyloseq/index.html) R package.

PEMA supports both OTU clustering (thanks to VSEARCH and CROP algorithms) and ASV inference (via SWARM) for all four marker genes.

For the case of the 16S rRNA marker gene, PEMA includes two separate approaches for taxonomy assignment: alignment-based and phylogenetic-based. For the latter, a reference tree of 1000 taxa was created using SILVA_132_SSURef, EPA-ng and RaxML-ng.

PEMA has been implemented in [BigDataScript](https://pcingola.github.io/BigDataScript/) programming language. BDS’s ad hoc task parallelism and task synchronization, supports heavyweight computation. Thus, PEMA inherits such features and it also supports roll-back checkpoints and on-demand partial pipeline execution. In addition, PEMA takes advantage of all the computational power available on a specific machine; for example, if PEMA is executed on a personal laptop with 4 cores, it is going to use all four of them. 

Finally, container-based technologies such as Docker and Singularity, make PEMA easy accessible for all operating systems.
As you can see in the [PEMA_tutorial.pdf](https://github.com/hariszaf/pema/blob/master/help_files/GitHub%20tutorial.pdf), once you have either Docker or Singularity on your computational environment (see below which suits your case better), running PEMA is cakewalk. You can also find the [**PEMA tutorial**](https://docs.google.com/presentation/d/1lVH23DPa2NDNBhVvOTRoip8mraw8zfw8VQwbK4vkB1U/edit?usp=sharing) as a Google Slides file.


<!---  ################   NEXT CHAPTER     ########################          -->


# A container-based tool

PEMA can run either on a HPC environment (server, cluster etc) or on a simple PC. However, we definitely suggest to run it on an HPC environment to exploit the full potential of PEMA. Running on a powerful server or a cluster can be time-saving since it would require significantly less computational time than in a common PC. However, for analyses with a small number of samples, a common PC can suffice.

There is one **major difference** between running PEMA on a common PC than running it on a HPC environment. In the first case, PEMA runs through [**Docker**](https://www.docker.com/), while in the latter one, it runs through [**Singularity**](https://sylabs.io/singularity/).

On the following chapters, you can find how to install PEMA both in Docker and Singlularity including examples.

Running PEMA is exactly **the same** procedure in both of those cases. 



<!---  ################   NEXT CHAPTER     ########################          -->



# How to run PEMA

Assuming you have either Docker or Singularity on your system (see below how to get them). 
You need to create a directory where you will have everything PEMA needs - we will call it ***analysis directory***.

In this directory, you need to add the following **mandatory** files:
* the [***parameters.tsv***](https://github.com/hariszaf/pema/blob/master/analysis_directory/parameters.tsv) file (you can download it from this repository and then **complete it** according to the needs of your analysis) 
* a subdirectory called ***mydata*** where your .fastq.gz files will be located <br />

If your need to perform phyloseq, in the analysis directory you also need to add the following **optionally** files:
* the [***phyloseq_in_PEMA.R***](https://github.com/hariszaf/pema/blob/master/analysis_directory/phyloseq_in_PEMA.R) which you can also download from this repository and set it the way you want (that is an R script which we have implemented and has some main features that need to stay always the same in order to be executed as part of PEMA and some parts where the user can set what exactly needs to get from the phyloseq package)
* the [***metadata.csv***](https://raw.githubusercontent.com/hariszaf/pema/master/analysis_directory/metadata.csv) file which has to be in a **comma separated** format (you can find an example of this file on PEMA's GitHub repository).

**Attention!**  <br />
PEMA will **fail** unless you name the aforementioned files and directories **exactly** as described above.
<br />

Here is an example of how your *analysis directory* should be in case you do want a phyloseq analysis:

```
user@home-PC:~/Desktop/analysis_directory$ ls
mydata  parameters.tsv  phyloseq_in_PEMA.R  metadata.csv
```

and in case you do not:
```
user@home-PC:~/Desktop/analysis_directory$ ls
mydata  parameters.tsv 
```

[**Here**](https://github.com/hariszaf/pema/tree/master/analysis_directory) you can find an example of an *analysis directory*.

After you have prepared this *analysis directory* you are ready to run PEMA (see below).

**An extended list with PEMA's ouput can be found [**here**](https://github.com/hariszaf/pema/blob/master/help_files/PEMA's%20output%20files.md).**





<!---  ################   NEXT CHAPTER     ########################          -->




# Parameters' file
The most crucial component in running PEMA is the parameters file. This file must be located **in** the *analysis directory* and the user needs to fill it **every time** PEMA is about to be called. If you need more than one analyses to run, then you need to make copies of the parameters' file and have one of those in eah of the analysis directrories you create.

So, here is the [***parameters.tsv***](https://github.com/hariszaf/pema/blob/master/analysis_directory/parameters.tsv) file as it looks like, in a study case of our own. 



<!---  ################   NEXT CHAPTER     ########################          -->




# PEMA on HPC

PEMA is best to run on HPC (server, cluster, cloud). Usually environmental data are quite large and the whole process has huge computational demands. To get PEMA running on your HPC you (actually your system administrator) need to install Singularity as described below. 

## Prerequisites

**[Singularity]( https://www.sylabs.io/guides/3.0/user-guide/quick_start.html#quick-installation-steps )**  is a free, cross-platform and open-source computer program that performs operating-system-level virtualization also known as containerization. One of the main uses of Singularity is to bring containers and reproducibility to scientific computing and the high-performance computing (HPC) world.

Singularity needs a Linux/Unix system to run.

## Installing

After you install Singularity in your environment and open it, you need to download PEMA's image from Singularity Hub, by running the command:

```
 singularity pull shub://hariszaf/pema:v1
```

Now you have PEMA on your environment. But there is still one really **important** thing that you need to do! Please **download** the [*parameters.tsv*](https://github.com/hariszaf/pema/blob/master/analysis_directory/parameters.tsv) file and move it or copy it to the same directory with your raw data.

Now you are ready to go! 


## Running PEMA
Singularity permits the use of a job scheduler that allocates computional resources on clusters and at the same time, works as a queuing system, as **[Slurm](https://slurm.schedmd.com/overview.html)**. This way you are able to create a job as you usually do in your system and after editing the parameters file as needed, run PEMA as a job on your cluster.


### Example

```
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --mem=
# Memory per node specification is in MB. It is optional.
# The default limit is 3000MB per core.
#SBATCH --job-name="testPema"
#SBATCH --output=PEMA.output
#SBATCH --mail-user=haris-zafr@hcmr.gr
#SBATCH --mail-type=ALL
#SBATCH --requeue


singularity run -B /<path>/<of>/<input>/<directory>/:/mnt/analysis /<path>/<of>/<PEMA_Image>

```

In the above example, we set the cluster "Zorba", to run PEMA in 1 node, with 20 cores.

For further information, you can always check [PEMA's tutorial](https://docs.google.com/presentation/d/1lVH23DPa2NDNBhVvOTRoip8mraw8zfw8VQwbK4vkB1U/edit?fbclid=IwAR14PpWfPtxB8lLBBnoxs7UbG3IJfkArrJBS5f2kRA__kvGDUb8wiJ2Cy_s#slide=id.g57f092f54d_1_21).




<!---  ################   NEXT CHAPTER     ########################          -->




# PEMA on a simple PC

## Prerequisites

To run PEMA in a simple PC on your own environment, you first need to install [Docker]( https://docs.docker.com/install/ ), in case you do not already have it.

You should check your software version. A version of Docker is avalable for all Windows, Mac and Linux. If you have Windows 10 Pro or your Mac's hardware in after 2010, then you can insall Docker straightforward. Otherwise, you need to install the [Docker toolbox]( https://docs.docker.com/toolbox/) instead. You can check if your System Requirements are according to the ones mentioned below in order to be sure what you need to do.

**System Requirements**

```
**__Windows 10 64bit__**:
Pro, Enterprise or Education (1607 Anniversary Update, Build 14393 or later).
Virtualization is enabled in BIOS. Typically, virtualization is enabled by default.
This is different from having Hyper-V enabled. For more detail see Virtualization must be enabled in Troubleshooting.
CPU SLAT-capable feature.
At least 4GB of RAM.

**__Mac__**
Mac hardware must be a 2010 or newer model, with Intel’s hardware support for memory management unit (MMU)
virtualization, including Extended Page Tables (EPT) and Unrestricted Mode. You can check to see if your machine
has this support by running the following command in a terminal:
sysctl kern.hv_support macOS El Capitan 10.11 and newer macOS releases are supported.
We recommend upgrading to the latest version of macOS.
At least 4GB of RAM
VirtualBox prior to version 4.3.30 must NOT be installed (it is incompatible with Docker for Mac).
If you have a newer version of VirtualBox installed, it’s fine.
```


## Installing

After you install Docker in your environment and run it, the only thing you need to do, is to download PEMA's image, by running the command:

```
docker pull hariszaf/pema
```

The PEMA image file is a quite large (~3Gb), so it will take a while until it is downloaded in your computer system.


## Running PEMA

Running PEMA has two discrete steps.

### Step 1 - Build a Docker container

At first, you need to let Docker have access in your dataset. To provide access you need to run the following command and specifying the path to where your data is stored, i.e. changing the <path_to_analysis_directory> accordingly:

```
docker run -it -v /<path_to_analysis_directory>/:/mnt/analysis hariszaf/pema
```

After you run the command above, you have now built a Docker container, in which you can run PEMA!


### Step 2 - Run PEMA

Now, being inside the PEMA container, the only thing remaining to do, is to run PEMA

```
./PEMA_docker_version.bds
```

PEMA is now running. The runtime of PEMA depends on the computational features of your environment, on the size of your data, as well as the parameters you chose.

Please, keep in mind that when you need to copy a whole directory, then you always have to put "/" in the end of the path that describes where the directory is located.

Finally, you will find the PEMA output in the analysis directory on your computer. <br />
As the output directory is mounted into the built Docker container, you can copy its contents wherever you want. However, in case you want to remove it permanently, you need to do this as a sudo user. 



<!---  ################   NEXT CHAPTER     ########################          -->





# The "phyloseq" R package 
**for a downstream ecological analysis of OTUs/ASVs retrieved**

PEMA performs all the basic functions of the "phyloseq" R package. In addition, it performs certain functions of the [***vegan***](https://cran.r-project.org/web/packages/vegan/index.html) R package. 

When the user asks for a downstream analysis using the "phyloseq" R package, then an extra input file called [***"phyloseq_script.R"***](https://github.com/hariszaf/pema/blob/master/analysis_directory/phyloseq_in_PEMA.R) needs to be imported in the "analysis_directory". In PEMA's main repository, you can find a template of this file; this file needs to be as it would run on your own computer, as you would run *phyloseq* in any case. PEMA will create the *"phyloseq object"* automatically and then it will perform the analysis as asked. The output will be placed in an extra subfolder in the main output directory of PEMA called *phyloseq_analysis*. 

In addition, the ***metadata.tsv*** file is also required when the phyloseq option has been selected. An example of this file you can find [here](https://raw.githubusercontent.com/hariszaf/pema/master/analysis_directory/metadata.csv).


# Acknowledgments
PEMA uses a series of tools, datasets as well as Big Data Script language. We thank all the groups that developed them.
The tools & databases that PEMA uses are: 
* BigDataScript programming language - https://pcingola.github.io/BigDataScript/
* FASTQC - https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
* Τrimmomatic - http://www.usadellab.org/cms/?page=trimmomatic
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
* "phat" algorithm, from the "gappa" package - https://github.com/lczech/gappa/wiki/Subcommand:-phat
* MAFFT - https://mafft.cbrc.jp/alignment/software/
* RAxML -ng - https://github.com/amkozlov/raxml-ng
* PaPaRa - https://cme.h-its.org/exelixis/web/software/papara/index.html
* EPA-ng - https://github.com/Pbdas/epa-ng
* phyloseq R package - http://joey711.github.io/phyloseq/index.html
* vegan R package - https://cran.r-project.org/web/packages/vegan/index.html 

And definitely, we also need to thank the container-based technologies that allow PEMA to run in such an easy and efficient way:
* Docker - https://www.docker.com/
* Singularity - https://sylabs.io/singularity/

# Citation
PEMA: from the raw .fastq files of 16S rRNA and COI marker genes to the (M)OTU-table, a thorough metabarcoding analysis
Haris Zafeiropoulos, Ha Quoc Viet, Katerina Vasileiadou, Antonis Potirakis, Christos Arvanitidis, Pantelis Topalis, Christina Pavloudi, Evangelos Pafilis
bioRxiv 709113; doi: https://doi.org/10.1101/709113
