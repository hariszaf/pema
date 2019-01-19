<p align="center">
  <img src="https://i.paste.pics/870189fadf668a958c8aac83f38e799c.png"  width="300" align="left" >
</p>

<br/><br/>
# P.E.M.A.: 
# a Pipeline for Environmental DNA Metabarcoding Analysis for the 16S and COI marker genes 
*P.E.M.A. is reposited in* [*DockerHub*](https://hub.docker.com/r/hariszaf/pema)
<br/><br/><br/><br/>


Table of Contents
=================

   * [Getting Started](#getting-started)
   * [P.E.M.A on HPC](#pema-on-hpc)
      * [Prerequisites](#prerequisites)
      * [Installing](#installing)
      * [Running P.E.M.A.](#running-pema)
         * [Example](#example)
   * [P.E.M.A on a simple PC](#pema-on-a-simple-pc)
      * [Prerequisites](#prerequisites-1)
      * [Installing](#installing-1)
      * [Running P.E.M.A.](#running-pema-1)
         * [Step 1 - Build a Docker container](#step-1---build-a-docker-container)
         * [Step 2 - Run P.E.M.A.](#step-2---run-pema)
   * [Parameters' file](#parameters-file)
   * [P.E.M.A.'s output files](#pemas-output-files)
      * [1.quality_control](#1quality_control)
      * [Pre-processing steps](#pre-processing-steps)
      * [6.linearized_files](#6linearized_files)
      * [7.gene_dependent](#7gene_dependent)
         * [gene_16S](#gene_16s)
         * [gene_COI](#gene_coi)
   * [Acknowledgments](#acknowledgments)


P.E.M.A. is a pipeline for two marker genes, **16S rRNA** (microbes) and **COI** (Eukaryotes). As input, P.E.M.A. accepts .fastq files as returned by Illumina sequencing platforms. P.E.M.A. processes the reads from each sample and **returns an OTU-table with the taxonomies** of the taxa found and their abundances in each sample. It also returns statistics and a FASTQC diagram about the quality of the reads for each sample. Finally, in the case of 16S, P.E.M.A. returns **alpha and beta diversities**, and make correlations between samples. The last step is facilitated by Rhea, a set of R scripts for downstream 16S amplicon analysis of microbial profiles.

In the COI case, two clustering algorithms can be performed by P.E.M.A. (CROP and SWARM), while in the 16S, two approaches for taxonomy assignment are supported: alignment- and phylogenetic-based. For the latter, a reference tree with 1000 taxa was created using SILVA_132_SSURef, EPA-ng and RaxML-ng.


# Getting Started

P.E.M.A. is able to run either on a HPC environment (server, cluster etc) or on a simple PC of your own. However, we definitely suggest to run it on an HPC environment. A powerful server or a cluster, even better, is necessary, as  P.E.M.A. would take ages in a common PC.

There is one **major difference** between running P.E.M.A. on your own PC than running it on a HPC environment. In the first case, P.E.M.A. runs through **Docker**, while in the latter one, it runs through **Singularity**.

On the next chapters, you can find how to install P.E.M.A. in each case as well as an example of running it.

Running P.E.M.A. is exactly **the same** procedure in both oh these cases.


# P.E.M.A on HPC

P.E.M.A. is best to run on HPC (server, cluster, cloud). Usually Environmental data are quite large and the whole process has huge computational demands. To get P.E.M.A. running on your HPC you need just to do the followings.

## Prerequisites

**[Singularity]( https://www.sylabs.io/guides/3.0/user-guide/quick_start.html#quick-installation-steps )**  is a free, cross-platform and open-source computer program that performs operating-system-level virtualization also known as containerization. One of the main uses of Singularity is to bring containers and reproducibility to scientific computing and the high-performance computing (HPC) world

Singularity, needs a Linux system to run .

## Installing

After you install Singularity in your environment and open it, you need to download P.E.M.A.'s image from Docker Hub, by running the command:

```
singularity pull docker://hariszaf/pema
```

Now you have P.E.M.A. on your environment and the only thing that is left to do, is to fulfill the **parapeters.tsv**  file (see below, on "Parameters' file" section) and run P.E.M.A.


## Running P.E.M.A.
Singularity allows to use a  job scheduler that allocates compute resources on clusters and at the same time, works as a queuing system, as **[Slurm](https://slurm.schedmd.com/overview.html)**. This way you are able to create a job as you useally do in your system and after setting the parameters' file as you want to, run P.E.M.A. as a job on your cluster.




sudo singularity shell --overlay my_overlay/ pema_on_singularity.sif




### Example

```
#SBATCH --partition=batch
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=20
#SBATCH --mem=
# Memory per node specification is in MB. It is optional.
# The default limit is 3000MB per core.
#SBATCH --job-name="testPema"
#SBATCH --output=PEMA.output
#SBATCH --mail-user=haris-zafr@hcmr.gr
#SBATCH --mail-type=ALL
#SBATCH --requeue

singularity exec ~/ubuntu.img echo "Hey, I'm running ubuntu"

```

In the above job, we set HCMR's  cluster "Zorba", to run P.E.M.A. in 2 nodes, with 20 cores in each of those.











# P.E.M.A on a simple PC


## Prerequisites

To run P.E.M.A. in a simple PC on your own environment, you first need to install Docker ( https://docs.docker.com/install/ ), in case you do not already have it.

You should check your software version. Docker is avalable for all Windows, Mac and Linux.  
However, in case of Windows and Mac, you might need to install Docker toolbox instead ( https://docs.docker.com/toolbox/ ), if your System Requirements are not the ones mentioned below.

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

After you install Docker in your environment and open it, the only thing you need to do, is to download P.E.M.A.'s image, by running the command:

```
docker pull hariszaf/pema
```

P.E.M.A. is a quite large image (~2Gb) so it will take a while until it is downloaded in your computer system.


## Running P.E.M.A.

Running P.E.M.A. has two discrete steps.

### Step 1 - Build a Docker container

At first, you need to let Docker have access in your dataset. For this you need to run this command, specifying the path to where your data is stored, i.e. changing the path_to_my_data accordingly:

```
docker run -it vol -v /<path_to_my_data>:/vol_myData pema
```

After you run the command above, you have now built a Docker container, in which you can work with P.E.M.A.


P.E.M.A. gives you the opportunity, among others, to BLAST your data, in case you want to.

In this and only in this case, you need to tell P.E.M.A. where to find your BLAST database. So, in this case, you skip the previous command, and execute the commands below,specifying the path to where your data and the BLAST database are stored, i.e. changing the path_to_my_data and the path_to_BLAST_Database accordingly:

```

docker run -it --name vol -v /<path_to_my_data>:/vol_myData -v /<path_to_BLAST_Database>:/vol_myDataBase PEMA_image

docker run -it --rm --name foo --volumes-from=vol

```


### Step 2 - Run P.E.M.A.

To run P.E.M.A. you first need to set all parameters the way they should be, depending on your dataset and your experiment.

To do so, run the command below and set the parameters in it:

```
nano parameters.csv
```

For more details about the #parameters.csv#, please check on the [manual for the parapeter's file](https://www.google.com).
Αpparently, you can use any text-editor. The "Nano" editor that is mentioned, is just an example.

Finally, when all the above are set, the only thing remaining to do, is to run P.E.M.A.

```
./PEMA_docker_version.bds
```

P.E.M.A. is now running and it depends on your computer (or server or cluster), on the size of your data, as well as on the parameters you chose, how long it will take.

When

In order to get the output file in your computer, you just need to copy it from the Docker container you are working on. To do so, you just need to see the **id** of your container, simply by typing:

```
docker ps -a
```

and then, copying anything you want to, from a single file to the whole folder, with a command like this:

```
docker cp <contaier_ID>:/path/to/what/you/need/to/copy/ /path/to/the/directory/you/want/to/copy/it/to/
```

Please, keep in mind that when you want to copy a whole directory, then you always have to put "/" in the end of the path that describes where the folder is located.




# Parameters' file
The most crucial component in running P.E.M.A. is the parameters' file. This is located in the same directory as P.E.M.A. does and the user needs to fill it **every time** P.E.M.A. is about to be called.

So, here is the [**parameters.tsv**](https://github.com/hariszaf/pema/blob/master/parameters_docker.tsv) file as it looks like, in a study case of our own. The user has to set it the way it fits to his own data.  



# P.E.M.A.'s output files
Each of the next paragraphs stands for a subfolder in the output folder that P.E.M.A. creates after each run.

## 1.quality_control

The first folder in the output folder contains the results of FastQC; the quality control results. In this folder, there is a folder for each sample, as well as a .html file and a .zip file which contain all the information included in the folder with the sample’s output. The sequences of each sample, could get either a “pass”, “warn” or “fail” to each of FASTQC’s tests. 

## Pre-processing steps
In folders *2.trimmomatic_output*, *3.correct_by_BayesHammer*, *4.merged_by_SPAdes*, *5.dereplicate_by_obiuniq* and *6.linearized_files* the output of each of the tools used for the pre-processing of the reads, are placed. 

## 6.linearized_files

The folder called “6.linearized_files” contains the sequences that remained after they were treated properly to form a single .fasta (“teliko_all_samples.fasta”). That is the file P.E.M.A. will use from this point onwards for the clustering and taxonomy assignment steps.

## 7.gene_dependent

In this folder, all output from clustering and taxonomy assignment steps are placed. Depending on the marker gene, another folder is created on it. 


* ### gene_16S

The sequences that were defined as OTUs (Operational Taxonomic Unit) can be found in the “16S_all_samples.otus.fa” file. 

The OTU-table that includes the OTUs found and the number of the copies observed in each sample, lies in the file “16S_otutab.txt”.

The OTU-table that includes the OTUs found and the number of the copies observed in each sample, lies in the file “16S_otutab.txt”. Obviously, in this OTU-table there are no taxonomies.

Finally, there is also a folder called **16S_taxon_assign** where the output of the alignmet-based taxonomy assignment step is placed.

The *“Relative_Abundance.tsv”* file contains relative abundance data across the dataset, which are normalised to the total number of assigned reads.

The number of assignments at each taxonomic rank are provided in *“All_Assignments.tsv”*. Assignments to the taxon node itself are counted only and not to child taxa at lower ranks. For each taxon, the full taxonomic path from root to the taxon itself is also provided.

In *“All_Cumulative.tsv”* file, cumulative counts for the number of assignments at each taxonomic rank are listed. Contrary to *“All_Assignments.tsv”*, here assignments to child taxa are counted too.

Total count of OTUs for each taxon as well as their number can be found in *“Richness.tsv”*. 

Finally, ***“16S_otutab.txt”*** is the OTU-table that P.E.M.A. ends up with. The OTU-table contains all information about how OTUs are distributed, and hence it contains the taxonomic composition across each sample of the dataset.



In case that the phylogeny-based taxonomy approach has also been performed, another folder called **16S_taxon_assign_phylogeny_assignment** has been created;  two output files are included in this folder: the “epa_info.log” which includes all parameters as they were set in EPA-ng and the “epa_result.jplace” file which is the final output of this approach and can be used as an input to a series of different tools (e.g. iTOL) in order to visualize the assignments of the OTUs found to the reference tree of 1000 taxa. . 






**Attention!**
<br/>
For the phylogeny-based taxonomy assignemnt, an MSA is supposed to be made with both the reference sequences and the queries; the final file is supposed to contain only the alignment of the query sequences as it ensued. The reference sequences are removed automatically from the final MSA by P.E.M.A. which subsequently executes the “convertPhylipToFasta.sh” (which is located in the folder *scripts* of P.E.M.A.) manually written program, to convert this final MSA from phylip (.phy) to Fasta (.fasta) format. 

Finally, EPA-ng is performed using the MSA file (“papara_alignment.fasta”, located in the *gene_16S* folder) along with the reference MSA (“raxml_easy_right_refmsa.raxml.reduced.phy.fasta”) and the reference tree (“raxml_easy_right_refmsa.raxml.bestTree”). The last two files, can be found here: *PEMA/tools/silva_132/for_placement/createTreeTheEasyWay*


* ### gene_COI

The file “SWARM_otu_no_chimera.fasta” contains all the MOTUs found.

As SWARM does the clustering and then the chimera removal takes place, in this file only the true MOTU sequences are included. Contrary, MOTU representatives are included in the “SWARM_final_OTU_representative.fasta” .

SWARM also produces two files “.stats” and “.swarms”. The first one is a tab-separated table with one MOTU per row and 8 columns of information, while  the MOTUs are written in the “.swarms” file. In fact, each line of this file, contains as much MOTUs as it is mentioned in the first column of the “.stats” file.







# Acknowledgments
P.E.M.A. uses a series of tools, datasets as well as Big Data Script language. We have to thank all of these groups.
The tools & databases that PEMA uses are :
* FASTQC - https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
* Τrimmomatic - http://www.usadellab.org/cms/?page=trimmomatic
* SPAdes - http://cab.spbu.ru/software/spades/
* BayesHammer - included in SPAdes
* OBITools - https://pythonhosted.org/OBITools/welcome.html
* USEARCH - https://www.drive5.com/usearch/
* BLAST- https://blast.ncbi.nlm.nih.gov/Blast.cgiCMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download
* CREST - https://github.com/lanzen/CREST
* SILVA db - https://www.arb-silva.de/no_cache/download/archive/current/Exports/
* RAxML - https://sco.h-its.org/exelixis/web/software/raxml/index.html
* RAxML -ng - https://github.com/amkozlov/raxml-ng
* EPA-ng - https://github.com/Pbdas/epa-ng
* SWARM - https://github.com/torognes/swarm
* CROP - https://github.com/tingchenlab/CROP
* VSEARCH-2.7.1 - https://github.com/torognes/vsearch/releases/tag/v2.7.1
* RDPClassifier - https://github.com/rdpstaff/classifier
(RPDtools are required in order to execute RDPClassifier)
