<p align="center">
  <img src="https://i.paste.pics/870189fadf668a958c8aac83f38e799c.png"  width="300" align="left" >
</p>

<br/><br/>
# PEMA: 
# a Pipeline for Environmental DNA Metabarcoding Analysis for the 16S and COI marker genes 
*PEMA is reposited in* [*Docker Hub*](https://hub.docker.com/r/hariszaf/pema) *as well as in* [*Singularity Hub*](https://singularity-hub.org/collections/2295)
<br/><br/><br/><br/>



```diff
---------  **This is still a BETA version!**    ---------
```

PEMA is a pipeline for two marker genes, **16S rRNA** (microbes) and **COI** (Eukaryotes). As input, PEMA accepts .fastq.gz files as returned by Illumina sequencing platforms. PEMA processes the reads from each sample and **returns an OTU-table with the taxonomies** of the taxa found and their abundances in each sample. It also returns statistics and a FASTQC diagram about the quality of the reads for each sample. Finally, in the case of 16S, PEMA returns **alpha and beta diversities**, and make correlations between samples. The last step is facilitated by the "phyloseq" R package for downstream 16S amplicon analysis of microbial profiles.

In the COI case, two clustering algorithms can be performed by PEMA (CROP and SWARM), while in the 16S, two approaches for taxonomy assignment are supported: alignment- and phylogenetic-based. For the latter, a reference tree with 1000 taxa was created using SILVA_132_SSURef, EPA-ng and RaxML-ng.


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




# Intro 

PEMA is a pipeline for two marker genes, 16S rRNA (microbes) and COI (eukaryotes). As input, PEMA accepts fastq files as returned by Illumina sequencing platforms. PEMA processes the reads from each sample and returns an OTU-table with the taxonomies of the organisms found and their abundances in each sample. It also returns statistics and a FASTQC diagram about the quality of the reads for each sample. Finally, in the case of 16S, PEMA returns alpha and beta diversities, and make correlations between samples. The last step is facilitated by Rhea, a set of R scripts for downstream 16S amplicon analysis of microbial profiles.

In the COI case, two clustering algorithms can be performed by PEMA (CROP and SWARM), while in the 16S, two approaches for taxonomy assignment are supported: alignment- and phylogenetic-based. For the latter, a reference tree with 1000 taxa was created using SILVA_132_SSURef, EPA-ng and RaxML-ng.


# Getting Started

PEMA is able to run either on a HPC environment (server, cluster etc) or on a simple PC of your own. However, we definitely suggest to run it on an HPC environment. A powerful server or a cluster, even better, is necessary, as  PEMA would take ages in a common PC.

There is one **major difference** between running PEMA on your own PC than running it on a HPC environment. In the first case, PEMA runs through **Docker**, while in the latter one, it runs through **Singularity**.

On the next chapters, you can find how to install PEMA in each case as well as an example of running it.

Running PEMA is exactly **the same** procedure in both oh these cases.

# First things first

Hence, you need to create on **your computational environment** a folder where you will have everything PEMA needs to run - in the framework of this README file, we will call it ***analysis folder***.

In this folder, you need to add:
* the ***parameters.tsv*** file which you can download from this repository and **you need to complete** according to the needs of your analysis - mandatory 
* a subfolder called ***mydata*** where your .fastq.gz files will be located - mandatory 
and in case that your marker gene is the 16S and you need phyloseq to perform, in the analysis folder you also need to add:
* the ***phyloseq_in_PEMA.R** which you can also download from this repository and set it the way you want - optioanally
* and finaly your ***metadata.csv*** file which has to be comma separated - optionally

**Attention!**  <br />
You need to call these files exactly as it is described above and the ***mydata*** subfolder as well. <br />
If you don't PEMA will fail. 

Here is an example of how your *analysis folder* should be:

```
haris@haris-XPS-13-9343:~/Desktop/analysis_folder$ ls
mydata  parameters.tsv  phyloseq_in_PEMA.R  metadata.csv
```

# Parameters' file
The most crucial component in running PEMA is the parameters file. This is located in the same directory as PEMA does and the user needs to fill it **every time** PEMA is about to be called.

So, here is the [***parameters.tsv***](https://github.com/hariszaf/pema/blob/master/parameters.tsv) file as it looks like, in a study case of our own. The user has to set it the way it fits to his own data.  



# PEMA on a simple PC

## Prerequisites

To run PEMA in a simple PC on your own environment, you first need to install [Docker]( https://docs.docker.com/install/ ), in case you do not already have it.

You should check your software version. Docker is avalable for all Windows, Mac and Linux.  
However, in case of Windows and Mac, you might need to install [Docker toolbox]( https://docs.docker.com/toolbox/) instead, if your System Requirements are not the ones mentioned below.

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

After you install Docker in your environment and open it, the only thing you need to do, is to download PEMA's image, by running the command:

```
docker pull hariszaf/pema
```

PEMA is a quite large image (~2Gb) so it will take a while until it is downloaded in your computer system.


## Running PEMA

Running PEMA has two discrete steps.

### Step 1 - Build a Docker container

At first, you need to let Docker have access in your dataset. For this you need to run this command, specifying the path to where your data is stored, i.e. changing the path_to_my_data accordingly:

```
docker run -it vol -v /<path_to_analysis_folder>/:/mnt/analysis pema
```

After you run the command above, you have now built a Docker container, in which you can run PEMA!


### Step 2 - Run PEMA

Now, being inside the PEMA contaienr, the only thing remaining to do, is to run PEMA

```
./PEMA_docker_version.bds
```

PEMA is now running and it depends on the computational feautres of your environment, on the size of your data, as well as on the parameters you chose, how long it will take.

Please, keep in mind that when you want to copy a whole directory, then you always have to put "/" in the end of the path that describes where the folder is located.

Finally, you will find the PEMA output in the analysis folder on your computer. <br />
As the output folder is mounted into the Docker container we built, you can copy its contents wherever you want to as you would do regularly, however, in case you want to remove it permanently, you need to do this as a sudo user. 


# PEMA on HPC

PEMA is best to run on HPC (server, cluster, cloud). Usually Environmental data are quite large and the whole process has huge computational demands. To get PEMA running on your HPC you need just to do the followings.

## Prerequisites

**[Singularity]( https://www.sylabs.io/guides/3.0/user-guide/quick_start.html#quick-installation-steps )**  is a free, cross-platform and open-source computer program that performs operating-system-level virtualization also known as containerization. One of the main uses of Singularity is to bring containers and reproducibility to scientific computing and the high-performance computing (HPC) world

Singularity, needs a Linux system to run .

## Installing

After you install Singularity in your environment and open it, you need to download PEMA's image from Docker Hub, by running the command:

```
 singularity pull pema shub://hariszaf/pema
```

Now you have PEMA on your environment. But there is still one thing that you need to do! And it is an **important** one!
Please **download** the [*parameters.tsv*](https://github.com/hariszaf/pema/blob/master/parameters.tsv) and move it or copy it to the same folder with your raw data.

Now you are ready to go! 


## Running PEMA
Singularity allows to use a  job scheduler that allocates compute resources on clusters and at the same time, works as a queuing system, as **[Slurm](https://slurm.schedmd.com/overview.html)**. This way you are able to create a job as you useally do in your system and after setting the parameters' file as you want to, run PEMA as a job on your cluster.




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


singularity run -B /<path>/<of>/<input>/<folder>/:/mnt /<path>/<of>/<PEMA_Image>

```

In the above job, we set HCMR's  cluster "Zorba", to run PEMA in 1 node, with 20 cores.






# PEMA's output files
Each of the next paragraphs stands for a subfolder in the output folder that PEMA creates after each run.

## 1.quality_control

The first folder in the output folder contains the results of FastQC; the quality control results. In this folder, there is a folder for each sample, as well as a .html file and a .zip file which contain all the information included in the folder with the sample’s output. The sequences of each sample, could get either a “pass”, “warn” or “fail” to each of FASTQC’s tests. 

## Pre-processing steps
In folders *2.trimmomatic_output*, *3.correct_by_BayesHammer*, *4.merged_by_SPAdes*, *5.dereplicate_by_obiuniq* and *6.linearized_files* the output of each of the tools used for the pre-processing of the reads, are placed. 

## 6.linearized_files

The folder called “6.linearized_files” contains the sequences that remained after they were treated properly to form a single .fasta (“teliko_all_samples.fasta”). That is the file PEMA will use from this point onwards for the clustering and taxonomy assignment steps.

## 7.gene_dependent

In this folder, all output from clustering and taxonomy assignment steps are placed. Depending on the marker gene, another folder is created on it. 


* ### gene_16S

The sequences that were defined as OTUs (Operational Taxonomic Unit) by the USEARCH/UPARSE clustering algorithm, can be found in the “16S_all_samples.otus.fa” file. 

The OTU-table that includes the OTUs found and the number of the copies observed in each sample, lies in the file “16S_otutab.txt”.

The OTU-table that includes the OTUs found and the number of the copies observed in each sample, lies in the file “16S_otutab.txt”. Obviously, in this OTU-table there are no taxonomies.

Finally, there is also a folder called **16S_taxon_assign** where the output of the **alignmet-based taxonomy assignment** step is placed.

The *“Relative_Abundance.tsv”* file contains relative abundance data across the dataset, which are normalised to the total number of assigned reads.

The number of assignments at each taxonomic rank are provided in *“All_Assignments.tsv”*. Assignments to the taxon node itself are counted only and not to child taxa at lower ranks. For each taxon, the full taxonomic path from root to the taxon itself is also provided.

In *“All_Cumulative.tsv”* file, cumulative counts for the number of assignments at each taxonomic rank are listed. Contrary to *“All_Assignments.tsv”*, here assignments to child taxa are counted too.

Total count of OTUs for each taxon as well as their number can be found in *“Richness.tsv”*. 

Finally, ***“16S_otutab.txt”*** is the OTU-table that PEMA ends up with. The OTU-table contains all information about how OTUs are distributed, and hence it contains the taxonomic composition across each sample of the dataset.


In case that the **phylogeny-based taxonomy approach** has also been performed, another folder called **16S_taxon_assign_phylogeny_assignment** has been created;  two output files are included in this folder: the “epa_info.log” which includes all parameters as they were set in EPA-ng and the “epa_result.jplace” file which is the final output of this approach and can be used as an input to a series of different tools (e.g. iTOL) in order to visualize the assignments of the OTUs found to the reference tree of 1000 taxa. . 



**Attention!**
<br/>
For the phylogeny-based taxonomy assignemnt, an MSA is supposed to be made with both the reference sequences and the queries; the final file is supposed to contain only the alignment of the query sequences as it ensued. The reference sequences are removed automatically from the final MSA by PEMA which subsequently executes the “convertPhylipToFasta.sh” (which is located in the folder *scripts* of PEMA) manually written program, to convert this final MSA from phylip (.phy) to Fasta (.fasta) format. 

Finally, EPA-ng is performed using the MSA file (“papara_alignment.fasta”, located in the *gene_16S* folder) along with the reference MSA (“raxml_easy_right_refmsa.raxml.reduced.phy.fasta”) and the reference tree (“raxml_easy_right_refmsa.raxml.bestTree”). The last two files, can be found here: *PEMA/tools/silva_132/for_placement/createTreeTheEasyWay*


* ### gene_COI

For the COI marker gene, there are two clustering algorithms provided by PEMA but only one taxonomy assignment methond. Depending on the chosen clustering algorithm, a subfolder in the  Let us assume that the clustering method chosen by the user, was the Swarm clustering algorithm. Then a subfolder in the *7.gene_dependent* folder is created called as the clustering algorithm chosen; in our case *"SWARM"**. 

The file “SWARM_otu_no_chimera.fasta” contains all the MOTUs found.

As SWARM does the clustering and then the chimera removal takes place, in this file only the true MOTU sequences are included. Contrary, MOTU representatives are included in the “SWARM_final_OTU_representative.fasta” .

SWARM also produces two files “.stats” and “.swarms”. The first one is a tab-separated table with one MOTU per row and 8 columns of information, while  the MOTUs are written in the “.swarms” file. In fact, each line of this file, contains as much MOTUs as it is mentioned in the first column of the “.stats” file.

Finally, for the alignment-based taxonomy assignment that is used in the case of the COI marker gene, CREST - LCAClassifier and the MIDORI database, are used and their results are placed in the same folder as the clustering step's output. 

In the ***tax_assign_swarm_COI.txt*** file, the user can find the final MOTU-table. All MOTUs found, are assigned to species level; each of them has a taxonomy and next to each taxon level, the percentage of similarity that the MOTU belongs to that taxon is reported. However, the final MOTU-table for the case of the COI marker gene, is not made by the *“tax_assign_swarm_COI.txt”* file, but after a pre-process on that, during which only the assignments that have more than 97% similarity to the MIDORI taxa, are kept. The final MOTU-table is the ***OTU_table_for_significantly_assigned.tsv*** file, where the user can see the taxonomies found with certainty and the samples in which they were recorded.



## "phyloseq" R package - for the of microbial profiles

In the case of 16S marker gene and for the analysis of the microbial profiles, PEMA. performs all that the "phyloseq" R package provides. 

When the user asks for a downstream analysis using the "phyloseq" R package, then an extra input file called *"phyloseq_script.R"* needs to be imported in the "analysis_folder". In PEMA's main repository, you can find a template of this file; this file needs to be as it would run on your own computer, as you would run *phyloseq* in any case. PEMA will create the *"pgyloseq object"* automatically and then it will perform the analysis as asked. The output will be placed in an extra subfolder in the main output folder of PEMA called *phyloseq_analysis*. 


# Acknowledgments
PEMA uses a series of tools, datasets as well as Big Data Script language. We need to thank all of these groups.
The tools & databases that PEMA uses are :
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

And definitely, we also need to thank the container-based technologies that allow PEMA to run in such an easy and efficient way:
* Docker - https://www.docker.com/
* Singularity - https://sylabs.io/singularity/

# Citation
