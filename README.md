<p align="center">
  <img src="https://i.paste.pics/870189fadf668a958c8aac83f38e799c.png"  width="300" align="left" >
</p>

<br/><br/>
# PEMA: 
# a flexible Pipeline for Environmental DNA Metabarcoding Analysis of the 16S/18S rRNA, ITS and COI marker genes 
*PEMA is reposited in* [*Docker Hub*](https://hub.docker.com/r/hariszaf/pema) *as well as in* [*Singularity Hub*](https://singularity-hub.org/collections/2295)
<br/><br/>

<!---
```diff
[//]---------  **This is still a BETA version!**    ---------
```
-->

Table of Contents
=================

   * [Intro](#intro)
   * [Getting Started](#getting-started)
   * [First things first](#first-things-first)
   * [Parameters' file](#parameters-file)
   * [PEMA on a simple PC](#pema-on-a-simple-pc)
      * [Prerequisites](#prerequisites)
      * [Installing](#installing)
      * [Running PEMA](#running-pema)
         * [Step 1 - Build a Docker container](#step-1---build-a-docker-container)
         * [Step 2 - Run PEMA](#step-2---run-pema)
  * [PEMA on HPC](#pema-on-hpc)
      * [Prerequisites](#prerequisites-1)
      * [Installing](#installing-1)
      * [Running PEMA](#running-pema-1)
        * [Example](#example)
   * [PEMA's output files](#pemas-output-files)
      * [1.quality_control](#1quality_control)
      * [Pre-processing steps](#pre-processing-steps)
      * [6.linearized_files](#6linearized_files)
      * [7.gene_dependent](#7gene_dependent)
         * [gene_16S](#gene_16s)
         * [gene_COI](#gene_coi)
      * [phyloseq - for the analysis of microbial profiles](#rhea---for-the-analysis-of-microbial-profiles)
   * [Acknowledgments](#acknowledgments)
   * [Citation](#citation)


```diff
+ PEMA is now available for macOS!
for anything feel free to contact me at: haris-zaf@hcmr.gr
```

# Intro 

PEMA supports the metabarcoding analysis of two marker genes, **16S rRNA** (microbes) and **COI** (eukaryotes). As input, PEMA accepts .fastq.gz files as returned by Illumina sequencing platforms

. PEMA processes the reads from each sample and **returns an OTU-table with the taxonomies** of the taxa found and their abundances in each sample. It also returns statistics and a FASTQC diagram about the quality of the reads for each sample. Finally, for the case of the 16S marker gene, PEMA returns **alpha and beta diversity values**, as well as other **multivariate analyses between samples**, facilitated by the [phyloseq](http://joey711.github.io/phyloseq/index.html) R package, which allows the downstream analysis of microbial profiles.

In the case of the COI marker gene, PEMA can perform clustering with two different algorithms (CROP and SWARM), while in the case of 16S rRNA marker gene, PEMA includes two separate approaches for taxonomy assignment: alignment-based and phylogenetic-based. For the latter, a reference tree of 1000 taxa was created using SILVA_132_SSURef, EPA-ng and RaxML-ng.

PEMA has been implemented in [BigDataScript](https://pcingola.github.io/BigDataScript/) programming language. BDS’s ad hoc task parallelism and task synchronization, supports heavyweight computation. Thus, PEMA inherits such features and it also supports roll-back checkpoints and on-demand partial pipeline execution. In addition, PEMA takes advantage of all the computational power available on a specific machine; for example, if PEMA is executed on a personal laptop with 4 cores, it is going to use all four of them. 

Finally, container-based technologies such as Docker and Singularity, make PEMA easy accessible for all operating systems.
As you can see in the [PEMA_tutorial.pdf](https://github.com/hariszaf/pema/blob/master/GitHub%20tutorial.pdf), once you have either Docker or Singularity on your computational environment (see below which suits your case better), running PEMA is cakewalk. You can also find the [**PEMA tutorial**](https://docs.google.com/presentation/d/1lVH23DPa2NDNBhVvOTRoip8mraw8zfw8VQwbK4vkB1U/edit?usp=sharing) as a Google Slides file.


# A container-based tool

PEMA can run either on a HPC environment (server, cluster etc) or on a simple PC. However, we definitely suggest to run it on an HPC environment to exploit the full potential of PEMA. Running on a powerful server or a cluster can be time-saving since it would require significantly less computational time than in a common PC. However, for analyses with a small number of samples, a common PC can suffice.

There is one **major difference** between running PEMA on a common PC than running it on a HPC environment. In the first case, PEMA runs through [**Docker**](https://www.docker.com/), while in the latter one, it runs through [**Singularity**](https://sylabs.io/singularity/).

On the following chapters, you can find how to install PEMA both in Docker and Singlularity including examples.

Running PEMA is exactly **the same** procedure in both of those cases. 

# First things first

In the begining, on **your computational environment** you need to create a directory where you will have everything PEMA needs to run - in this README file, we will call it ***analysis folder***.

In this directory, you need to add (**mandatory**):
* the [***parameters.tsv***](https://github.com/hariszaf/pema/blob/master/parameters.tsv) file (you can download it from this repository and then **complete it** according to the needs of your analysis) 
* a subdirectory called ***mydata*** where your .fastq.gz files will be located <br />

If your marker gene is 16S and you need to perform phyloseq, in the analysis folder you also need to add (**optionally**):
* the [***phyloseq_in_PEMA.R***](https://github.com/hariszaf/pema/blob/master/phyloseq_in_PEMA.R) which you can also download from this repository and set it the way you want (that is an R script which we have implemented and has some main features that need to stay always the same in order to be executed as part of PEMA and some parts where the user can set what exactly needs to get from the phyloseq package)
* and finally, your ***metadata.csv*** file which has to be in a **comma separated** format.

**Attention!**  <br />
PEMA will **fail** unless you name the aforementioned files and directories exactly as described above.
<br />

Here is an example of how your *analysis folder* should be:

```
user@home-PC:~/Desktop/analysis_folder$ ls
mydata  parameters.tsv  phyloseq_in_PEMA.R  metadata.csv
```

# Parameters' file
The most crucial component in running PEMA is the parameters file. This file must be located **in** the *analysis folder* and the user needs to fill it **every time** PEMA is about to be called. If you need more than one analyses to run, then you need to make copies of the parameters' file and have one of those in eah of the analysis folders you create.

So, here is the [***parameters.tsv***](https://github.com/hariszaf/pema/blob/master/parameters.tsv) file as it looks like, in a study case of our own. 


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

At first, you need to let Docker have access in your dataset. To provide access you need to run the following command and specifying the path to where your data is stored, i.e. changing the <path_to_analysis_folder> accordingly:

```
docker run -it -v /<path_to_analysis_folder>/:/mnt/analysis hariszaf/pema
```

After you run the command above, you have now built a Docker container, in which you can run PEMA!


### Step 2 - Run PEMA

Now, being inside the PEMA container, the only thing remaining to do, is to run PEMA

```
./PEMA_docker_version.bds
```

PEMA is now running. The runtime of PEMA depends on the computational features of your environment, on the size of your data, as well as the parameters you chose.

Please, keep in mind that when you need to copy a whole directory, then you always have to put "/" in the end of the path that describes where the folder is located.

Finally, you will find the PEMA output in the analysis folder on your computer. <br />
As the output folder is mounted into the built Docker container, you can copy its contents wherever you want. However, in case you want to remove it permanently, you need to do this as a sudo user. 


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

Now you have PEMA on your environment. But there is still one really **important** thing that you need to do! Please **download** the [*parameters.tsv*](https://github.com/hariszaf/pema/blob/master/parameters.tsv) file and move it or copy it to the same folder with your raw data.

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


singularity run -B /<path>/<of>/<input>/<folder>/:/mnt/analysis /<path>/<of>/<PEMA_Image>

```

In the above example, we set the cluster "Zorba", to run PEMA in 1 node, with 20 cores.

For further information, you can always check [PEMA's tutorial](https://docs.google.com/presentation/d/1lVH23DPa2NDNBhVvOTRoip8mraw8zfw8VQwbK4vkB1U/edit?fbclid=IwAR14PpWfPtxB8lLBBnoxs7UbG3IJfkArrJBS5f2kRA__kvGDUb8wiJ2Cy_s#slide=id.g57f092f54d_1_21).

# PEMA's output files
Each of the next paragraphs stands for a subdirectory in the output folder that PEMA creates after each run.

## 1.quality_control

The first folder in the output folder contains the results of FastQC; the quality control results. In this folder, there is a folder for each sample, as well as an .html file and a .zip file which contain all the information included in the folder with the sample’s output. The sequences of each sample, could get either a “pass”, “warn” or “fail” to each of FASTQC’s tests. 

## Pre-processing steps
In folders *2.trimmomatic_output*, *3.correct_by_BayesHammer*, *4.merged_by_SPAdes* and *5.dereplicate_by_obiuniq* the output of each of tool used for the pre-processing steps are placed. 

## 6.linearized_files

The folder called “6.linearized_files” contains sample files (.fasta) only with the sequences that remained after the quality control and the pre-processing steps. These files are used to form a single .fasta (“final_all_samples.fasta”). That is the file PEMA will use from this point onwards for the clustering and taxonomy assignment steps.

## 7.gene_dependent

In this folder, all output from clustering and taxonomy assignment steps is placed. Depending on the marker gene, another folder is created (called "gene_16S" or "gene_COI" correspondingly). 


* ### gene_16S

The OTUs (Operational Taxonomic Unit) defined by the VSEARCH clustering algorithm, can be found in the “16S_all_samples.otus.fa” file. 

The file “16S_otutab.txt” is the OTU-table that includes the OTUs found and the number of the copies observed in each sample. No taxonomic information is included yet.

Τhere is also a folder called **16S_taxon_assign** (this name is the by default name of that folder, the user can change it in case of repeated runs) where the output of the **alignment-based taxonomy assignment** step is placed.

The *“Relative_Abundance.tsv”* file contains relative abundance values across the dataset, that are normalised to the total number of assigned reads.

The number of assignments at each taxonomic rank is provided in *“All_Assignments.tsv”*. Assignments to the taxon node itself are counted only. For each taxon, the full taxonomic path is provided.

In *“All_Cumulative.tsv”* file, cumulative counts for each taxonomic rank are listed. Here, assignments to child taxa are counted too.

The total counts of OTUs for each taxon can be found in *“Richness.tsv”*. 

Finally, ***“16S_otutab.txt”*** is the OTU-table that PEMA ends up with. The OTU-table contains all information about how OTUs are distributed, and hence it contains the taxonomic composition across each sample of the dataset.


If **phylogeny-based taxonomy approach** has also been performed, another folder called **16S_taxon_assign_phylogeny_assignment** has been created;  two output files are included in this folder: the “epa_info.log” which includes all parameters as they were set in EPA-ng and the “epa_result.jplace” file which is the final output of this approach and can be used as an input to a series of different tools (e.g. iTOL) in order to visualize the assignments of the OTUs found to the reference tree of 1000 taxa.



**Attention!**
<br/>
For the phylogeny-based taxonomy assignment, an MSA will be made with both the reference sequences and the query sequences; the final file will contain only the alignment of the query sequences as it ensued. The reference sequences are removed automatically from the final MSA by PEMA which subsequently executes the “convertPhylipToFasta.sh” (which is located in the folder *scripts* of PEMA) manually written program, to convert this final MSA from phylip (.phy) to Fasta (.fasta) format. 

Finally, EPA-ng is performed using the MSA file (“papara_alignment.fasta”, located in the *gene_16S* folder) along with the reference MSA (“raxml_easy_right_refmsa.raxml.reduced.phy.fasta”) and the reference tree (“raxml_easy_right_refmsa.raxml.bestTree”). The last two files, can be found here: *PEMA/tools/silva_132/for_placement/createTreeTheEasyWay*


* ### gene_COI

For the COI marker gene, there are two clustering algorithms provided by PEMA but only one taxonomy assignment method. Depending on the chosen clustering algorithm, a subfolder is created in it. Let us assume that the clustering method chosen by the user, was the Swarm clustering algorithm. Then a subfolder in the *7.gene_dependent* folder is created called as the clustering algorithm chosen; in our case *"SWARM"**. 

The file “SWARM_otu_no_chimera.fasta” contains all the MOTUs found.

As SWARM does the clustering and then the chimera removal takes place, in this file only the true MOTU sequences are included. Contrary, MOTU representatives are included in the “SWARM_final_OTU_representative.fasta” .

SWARM also produces two files “.stats” and “.swarms”. The first one is a tab-separated table with one MOTU per row and 8 columns of information, while  the MOTUs are written in the “.swarms” file. In fact, each line of this file, contains as much MOTUs as it is mentioned in the first column of the “.stats” file.

Finally, for the alignment-based taxonomy assignment that is used in the case of the COI marker gene, CREST - LCAClassifier and the MIDORI database, are used and you can find the output of each of the tools used for the pre-processing of the reads.

In the ***tax_assign_swarm_COI.txt*** file, the user can find the final MOTU-table. All MOTUs, are assigned to the species level; each MOTU has a taxonomy assigned and next to each taxon level, the confidence estimate that the MOTU belongs to that taxon is reported. However, the final MOTU-table for the case of the COI marker gene, is not made by the *“tax_assign_swarm_COI.txt”* file, but after a pre-process on that, during which only the assignments that have more than 97% confidence estimate to the MIDORI taxa, are kept. The final MOTU-table is the ***OTU_table_for_significantly_assigned.tsv*** file, where the user can see the taxonomies found with certainty and the samples in which they were recorded.



## "phyloseq" R package - for the analysis of microbial profiles

For the analysis of the microbial profiles using the 16S marker gene, PEMA performs all the basic functions of the "phyloseq" R package. In addition, it performs certain functions of the [***vegan***](https://cran.r-project.org/web/packages/vegan/index.html) R package. 

When the user asks for a downstream analysis using the "phyloseq" R package, then an extra input file called [***"phyloseq_script.R"***](https://github.com/hariszaf/pema/blob/master/phyloseq_in_PEMA.R) needs to be imported in the "analysis_folder". In PEMA's main repository, you can find a template of this file; this file needs to be as it would run on your own computer, as you would run *phyloseq* in any case. PEMA will create the *"phyloseq object"* automatically and then it will perform the analysis as asked. The output will be placed in an extra subfolder in the main output folder of PEMA called *phyloseq_analysis*. 


# Acknowledgments
PEMA uses a series of tools, datasets as well as Big Data Script language. We thank all the groups that developed them.
The tools & databases that PEMA uses are: 
* BigDataScript programming language - https://pcingola.github.io/BigDataScript/
* FASTQC - https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
* Τrimmomatic - http://www.usadellab.org/cms/?page=trimmomatic
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
