# PEMA's output files
Each of the next paragraphs stands for a subdirectory in the output folder that PEMA creates after each run.



### fastp
In this folder thera are file reports in .json and .html formats for each sample.



### Difference between clustering algorithms

* ### Swarm
 
***"all_samples.fasta"*** contains all the sequences found in all samples and their respective unique identifiers based on abundances and sequences. This is the main input file for all clustering algorithms.

***"all.denovo.nonchimeras.fasta"*** contains the sequences, their abundances and identifiers after chimera removal

***"all_sequences_grouped.fasta"*** contains the sequences, their abundances and identifiers after chimera removal and clustering

***"amplicon_contingency_table.tsv"*** contains the abundance of each unique sequence (amplicon) across different samples, and the total, after dereplication.

***"asvs_contingency_table.tsv"*** contains the abundance of each ASV across different samples, and the total.

***"asvs_representatives_all_samples.fasta"*** contains the abundance of each ASV, merged to its id (e.g. >218a968dfc3034ee2071c2f017aac9b38596ba5f_1286), and its built using "asvs_contingency_table.tsv".

***"asvs_repr_with_singletons"*** contains the same information as the above, with similar structure, but still contains oligotons

SWARM also produces two files ***“.stats”*** and ***“.swarms”***. The first one is a tab-separated table with one MOTU per row and 8 columns of information, while  the MOTUs are written in the “.swarms” file. In fact, each line of this file, contains as much MOTUs as it is mentioned in the first column of the “.stats” file.

- .stats

1. number of unique amplicons in the cluster,
2. total abundance of amplicons in the cluster,
3. label of the initial seed (header without abundance annotations),
4. abundance of the initial seed,
5. number of amplicons with an abundance of 1 in the cluster,
6. maximum number of iterations before the cluster reached its natural limit,
7. cummulated number of steps along the path joining the seed and the furthermost
amplicon in the cluster. Please note that the actual number of differences between
the seed and the furthermost amplicon is usually much smaller. When using the
option --fastidious (-f), grafted amplicons are not taken into account.


=> when I sum column 1, I get the number of entries in the all_samples.fasta
=> when I sum column 2, I get the number of entries of the total merged files (`/mergedSequences/`)

16S sanity check:
total merged reads:  67872
after chimera removal, total abundance : 60860

- .swarms (`-o` argument)

a list of clusters, one cluster per line. 
A cluster is a list of amplicon headers separated by spaces. Default is to write to standard output.





* ### vsearch

***"all_samples.fasta"*** is also present in "vsearch", but it has been reformatted to comply with the algorithm's requirements: underscores are replaced with ";size=", hence the presence of two files with the same name (the initial one outside "mainOutput" and the reformatted one inside "vsearch" folder)

***"all.derep.fasta"*** contains the sequences and their abundances in each samples after dereplication

***"all.preclustered.fasta"*** contains the sequences and their abundances in each samples after dereplication and first clustering step

***"all.denovo.nonchimeras.fasta"*** contains the sequences and their abundances in each samples after dereplication,first clustering step and chimera removal

***"all.ref.nonchimeras.fasta"*** is a copy of "all.denovo.nonchimeras.fasta" with a new name

***"all.nonchimeras.derep.fasta"*** is generated using "all.derep.fasta", "all.preclustered.uc" and "all.ref.nonchimeras.fasta" to perform the second clustering step

***"all.nonchimeras.fasta"*** contains all clustered sequences, and is generated using "all_samples.fasta", "all.derep.uc" and "all.nonchimeras.derep.fasta" during the second clustering step

***"all.otus.fasta"*** contains centroid sequences of the clusters (still contains oligotons)

***"all.otutab.txt"*** is an OTU table containing cluster abundance information (still contains oligotons)

***"no-singl-allSquences.fa"*** contains all the sequences clustered by vsearch (OTUs) and after oligotons removal

***"no-singl-allTab.tsv"*** contains the counts of these remaining OTUs

***"allTab_my_taxon_assign.tsv"*** is a copy of "no-singl-allTab.tsv"

***"all_sequences_grouped"*** is a copy of "no-singl-allSquences.fa"


### Difference between classifiers

The chosen classifier algorithm for the taxonomy assignment step is also going to influence the outputs. Remember, if you have 16S, 18S or ITS you should choose CREST, if you have COI or 12S you should choose RDPClassifier. 

* ### RDPClassifier

In ***"tax_assigned_table.tsv"*** file, the user can find the final MOTU-table. The first column is the ASV identifier, the following columns contain the counts of each ASVs in each sample, and the last column contains the taxonomy.

***"extenedFinalTable.tsv"*** contains the same information with an additional column which is the NCBI ID of the identified taxa.

***"taxonomies.txt"*** is a table coming from RDPClassifier, with one line per ASV, containing their unique identifier followed by the taxonomic ranks from Kingdom to Species.

***"tax_assignments.tsv"*** combines the ASV identifiers, with their identified taxonomic ranks and their respective confidence levels.


* ### CREST

For 18S, 16S and ITS, there will be a folder called **my_taxon_assign** (this name is the by default name of that folder, the user can change it in case of repeated runs) where the output of the **alignment-based taxonomy assignment** step is placed.

***"Aligned_Assignments.fasta"*** contains two lines per ASV/OTU, the first is the identifier followed by the taxonomy, the second is the sequence.

The number of assignments at each taxonomic rank is provided in ***“All_Assignments.tsv”***. Assignments to the taxon node itself are counted only. For each taxon, the full taxonomic path is provided.

In ***“All_Cumulative.tsv”*** file, cumulative counts for each taxonomic rank are listed. Here, assignments to child taxa are counted too.

The ***“Relative_Abundance.tsv”*** file contains relative abundance values across the dataset, that are normalised to the total number of assigned reads.

The total counts of OTUs for each taxon can be found in ***“Richness.tsv”***. 

`assignments.txt`

`search.hits`

`tax_assigned_table.tsv`



Finally, ***“tax_assigned_table.tsv"*** is the OTU-table that PEMA ends up with. The OTU-table contains all information about how OTUs are distributed, and hence it contains the taxonomic composition across each sample of the dataset.


If **phylogeny-based taxonomy approach** has also been performed, another folder called **my_taxon_assign_phylogeny_assignment** has been created;  two output files are included in this folder: the “epa_info.log” which includes all parameters as they were set in EPA-ng and the “epa_result.jplace” file which is the final output of this approach and can be used as an input to a series of different tools (e.g. iTOL) in order to visualize the assignments of the OTUs found to the reference tree of 1000 taxa.



**Attention!**
<br/>
For the phylogeny-based taxonomy assignment, an MSA will be made with both the reference sequences and the query sequences; the final file will contain only the alignment of the query sequences as it ensued. The reference sequences are removed automatically from the final MSA by PEMA which subsequently executes the “convertPhylipToFasta.sh” (which is located in the folder *scripts* of PEMA) manually written program, to convert this final MSA from phylip (.phy) to Fasta (.fasta) format. 

Finally, EPA-ng is performed using the MSA file (“papara_alignment.fasta”, located in the *gene_16S* folder) along with the reference MSA (“raxml_easy_right_refmsa.raxml.reduced.phy.fasta”) and the reference tree (“raxml_easy_right_refmsa.raxml.bestTree”). The last two files, can be found here: *PEMA/tools/silva_132/for_placement/createTreeTheEasyWay*
