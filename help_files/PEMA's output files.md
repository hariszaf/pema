# PEMA's output files
Each of the next paragraphs stands for a subdirectory in the output folder that PEMA creates after each run.

## qualityReports

The first folder in the output folder contains the reports of sample sequence quality of FastQC or fastp. 

### FastQC
In this folder, there is a folder for each sample, as well as an .html file and a .zip file which contain all the information included in the folder with the sample’s output. The sequences of each sample, could get either a “pass”, “warn” or “fail” to each of FASTQC’s tests. 

### fastp
In this folder thera are file reports in .json and .html formats for each sample.

## Pre-processing steps
In folders *trimmedSequences*, *mergedSequences* and *dereplicateSamples* the output of each of tool used for the pre-processing steps are placed. When the original approach is selected for the preprocessing an additional folder is created called *adjustedSequences*.

## linearizedSequences

The folder called “linearizedSequences” contains sample files (.fasta) only with the sequences that remained after the quality control and the pre-processing steps. These files are used to form a single .fasta (“final_all_samples.fasta”). That is the file PEMA will use from this point onwards for the clustering and taxonomy assignment steps.

## mainOutput

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
