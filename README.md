
# P.E.M.A.
# a Pipeline for Environmental DNA Metabarcoding Analysis for the 16S and COI marker genes

P.E.M.A. is a pipeline for two marker genes, 16S rRNA (microbes) and COI (eukaryotes). As input, P.E.M.A. accepts fastq files as returned by Illumina sequencing platforms. P.E.M.A. processes the reads from each sample and returns an OTU-table with the taxonomies of the organisms found and their abundances in each sample. It also returns statistics and a FASTQC diagram about the quality of the reads for each sample. Finally, in the case of 16S, P.E.M.A. returns alpha and beta diversities, and make correlations between samples. The last step is facilitated by Rhea, a set of R scripts for downstream 16S amplicon analysis of microbial profiles.

In the COI case, two clustering algorithms can be performed by P.E.M.A. (CROP and SWARM), while in the 16S, two approaches for taxonomy assignment are supported: alignment- and phylogenetic-based. For the latter, a reference tree with 1000 taxa was created using SILVA_132_SSURef, EPA-ng and RaxML-ng.


## Getting Started


### Prerequisites

In order to get P.E.M.A. running to your environment, you first need to install Docker ( https://docs.docker.com/install/ ), in case you do not already have it.

You should check your software version. Docker is avalable for all Windows, Mac and Linux.  
However, in case of Windows and Mac, you might need to install Docker toolbox instead ( https://docs.docker.com/toolbox/ ), if your System Requirements are not the ones mentioned below.

**System Requirements**

```
**__Windows 10 64bit__**: 
Pro, Enterprise or Education (1607 Anniversary Update, Build 14393 or later).
Virtualization is enabled in BIOS. Typically, virtualization is enabled by default. This is different from having Hyper-V enabled. For more detail see Virtualization must be enabled in Troubleshooting.
CPU SLAT-capable feature.
At least 4GB of RAM.

**__Mac__** 
Mac hardware must be a 2010 or newer model, with Intel’s hardware support for memory management unit (MMU) virtualization, including Extended Page Tables (EPT) and Unrestricted Mode. You can check to see if your machine has this support by running the following command in a terminal: sysctl kern.hv_support macOS El Capitan 10.11 and newer macOS releases are supported. We recommend upgrading to the latest version of macOS.
At least 4GB of RAM
VirtualBox prior to version 4.3.30 must NOT be installed (it is incompatible with Docker for Mac). If you have a newer version of VirtualBox installed, it’s fine.
```


### Installing

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

For more details about the #parameters.csv#, please check on the [manual for the parapeter's file](https://www.google.com)

In order to get the output file in your computer, you just need to copy it from the Docker container you are working on. To do so, you just need to see the **id** of your container, simply by typing:

```
docker ps -a
```

and then, copying anything you want to, from a single file to the whole folder, with a command like this: 

```
docker cp <contaier_ID>:/path/to/what/you/need/to/copy/ /path/to/the/directory/you/want/to/copy/it/to/
```

Please, keep in mind that when you want to copy a whole directory, then you always have to put "/" in the end of the path that describes where the folder is located. 

\## Authors

* **Haris Zafeiropoulos** - *Initial work* - 

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* 
