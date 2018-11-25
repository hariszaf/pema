
## P.E.M.A.: a Pipeline for Environmental DNA Metabarcoding Analysis for the 16S and COI marker genes

P.E.M.A. is a pipeline for two marker genes, 16S rRNA (microbes) and COI (eukaryotes). As input, P.E.M.A. accepts fastq files as returned by Illumina sequencing platforms. P.E.M.A. processes the reads from each sample and returns an OTU-table with the taxonomies of the organisms found and their abundances in each sample. It also returns statistics and a FASTQC diagram about the quality of the reads for each sample. Finally, in the case of 16S, P.E.M.A. returns alpha and beta diversities, and make correlations between samples. The last step is facilitated by Rhea, a set of R scripts for downstream 16S amplicon analysis of microbial profiles.

In the COI case, two clustering algorithms can be performed by P.E.M.A. (CROP and SWARM), while in the 16S, two approaches for taxonomy assignment are supported: alignment- and phylogenetic-based. For the latter, a reference tree with 1000 taxa was created using SILVA_132_SSURef, EPA-ng and RaxML-ng.


## Getting Started


### Prerequisites

In order to get P.E.M.A. running to your environment, you first need to install Docker ( https://docs.docker.com/install/ ), in case you do not already have it.

You should check your software version. Docker is avalable for all Windows, Mac and Linux.  
However, in case of Windows and Mac, you might need to install Docker toolbox instead ( https://docs.docker.com/toolbox/ ), if your System Requirements are not the ones mentioned below.

**System Requirements**
'''
**Windows 10 64bit**: Pro, Enterprise or Education (1607 Anniversary Update, Build 14393 or later).
Virtualization is enabled in BIOS. Typically, virtualization is enabled by default. This is different from having Hyper-V enabled. For more detail see Virtualization must be enabled in Troubleshooting.
CPU SLAT-capable feature.
At least 4GB of RAM.

**Mac** hardware must be a 2010 or newer model, with Intel’s hardware support for memory management unit (MMU) virtualization, including Extended Page Tables (EPT) and Unrestricted Mode. You can check to see if your machine has this support by running the following command in a terminal: sysctl kern.hv_support macOS El Capitan 10.11 and newer macOS releases are supported. We recommend upgrading to the latest version of macOS.
At least 4GB of RAM
VirtualBox prior to version 4.3.30 must NOT be installed (it is incompatible with Docker for Mac). If you have a newer version of VirtualBox installed, it’s fine.
'''


### Installing

A step by step series of examples that tell you how to get a development env running

Say what the step will be

```
Give the example
```

And repeat

```
until finished
```

End with an example of getting some data out of the system or using it for a little demo

## Running the tests

Explain how to run the automated tests for this system


## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds


\## Authors

* **Haris Zafeiropoulos** - *Initial work* - 

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* 
