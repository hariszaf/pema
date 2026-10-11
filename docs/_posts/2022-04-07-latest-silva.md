---
layout: post
title: Train the CREST classifier using any Silva version
---

In this post we present how to train the CREST classifier using any [Silva database](https://www.arb-silva.de/) version 
of your choice. 
We will use Silva v.138 as an example. 

From Silva's [archive](https://www.arb-silva.de/download/archive/) and from the "Exports" tab, 
you may download the following files: 

    - SILVA_<version>_SSURef_NR99_tax_silva_full_align_trunc.fasta.gz
    - SILVA_<version>_SSURef_NR99_tax_silva_trunc.fasta.gz

and `gunzip` them. 

Let's break down the name of these files:
    - **SSU**: is for the 16S/18S rRNA marker genes.
    - **Ref**: RefNR to the non-redundant SILVA Reference datase
    - **NR**: stands for the non-redundant SILVA Reference dataset
    - **trunc**: Sequences in these files haven been truncated. This means that all nucleotides that have not been aligned were removed from the sequence.
    - **align**: Multi FASTA files of the SSU/LSU databases including the SILVA taxonomy for Bacteria, Archaea and Eukaryotes in the header (including the FULL alignment).

As described in the [*Training the CREST classifier*](https://hariszaf.github.io/pema_documentation/training_crest_classifier/) tab, 
you need to have: 
    1. a 3-column file (`.nds` taxonomy file)
    2. an alignment file of your sequences 


## The `.nds` file

### Get the taxonomies 

```bash
grep ">" SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' > taxonomies
```

### Get the accession numbers 

It has been noticed that is better 
for the `.nds` file not to have special characters.
So we remove the dots `.` from the accession numbers. 

Remove the taxonomy from the headers of the sequences.
```bash
sed 's/ .*//g' SILVA_138.1_SSURef_NR99_tax_silva_trunc.fasta  > SILVA_138.1_SSURef_NR99_tax_silva_trunc_no_taxonomy.fasta
```
and remove the dots `.` from the accesion ids. 
```
sed '/^>/s/\.//g' SILVA_138.1_SSURef_NR99_tax_silva_trunc_no_taxonomy.fasta > SILVA_138.1_SSURef_NR99_tax_silva_trunc_no_taxonomy_no_points.fasta
```
Now, you can keep just the *ids* of the sequences (accessions numbers without the dots).
```bash
more SILVA_138.1_SSURef_NR99_tax_silva_trunc_no_taxonomy_no_points.fasta | grep ">"  > ids
```

### Build the `.nds` file
 
We use the `ids` and the `taxonomies` files we built to get the `.nds` file: 
```bash
paste -d "\t" ids taxonomies ids > silva138.nds
```

## The alignment sequence file 

This is the reason you downloaded the `SILVA_<version>_SSURef_NR99_tax_silva_full_align_trunc.fasta.gz` too. 

> This is the alignment that was made out of the initial sequences of your Silva version . The `*SSURef_NR99_tax_silva_trunc.fasta*`we used in the previous step contains the sequences of this alignment, meaning that all nucleotides that have not been aligned were removed from the sequence.

So, the only thing you need to do before using it is to make sure that you keep as a header only the new `id` 
(the accession number without the dots `.`).

```bash
sed 's/ .*//g' SILVA_138.1_SSURef_NR99_tax_silva_full_align_trunc.fasta > SILVA_138.1_SSURef_NR99_tax_silva_full_align_trunc_no_taxonomy.fasta
sed '/^>/s/\.//g' SILVA_138.1_SSURef_NR99_tax_silva_full_align_trunc_no_taxonomy.fasta > SILVA_138.1_SSURef_NR99_tax_silva_full_align_trunc_no_taxonomy_no_points.fasta
```

## Train CREST with your Silva version

Now, you may train the CREST classifier by running 

```
~/CREST/LCAClassifier/bin/nds2CREST -o silva138 -i SILVA_138.1_SSURef_NR99_tax_silva_full_align_trunc_no_taxonomy_no_points.fasta silva138.nds
```
where the `nds2CREST` is available through the [CREST GitHub repo](https://github.com/lanzen/CREST)
or you may just run a pema container and do it there. 

> REMEMBER! In case you are using a container, everything you are doing there is gone once you exit the container. So you have to mount a local directory onto the container and save your work there. This way you will get the output of anything running on the container in your machine. 

You have now a `silva138.map` and a `silva138.tre` file. 

## Last but not least

To actually use CREST though you also need a blast batabase with the sequences you used. 
To this end, you may use the `SILVA_138.1_SSURef_NR99_tax_silva_trunc_no_taxonomy_no_points.fasta`.
**Attention!**
This is the non-aligned sequencing file! 

```bash
/ncbi-blast-2.8.1+/bin/makeblastdb \
	-in SILVA_138.1_SSURef_NR99_tax_silva_trunc_no_taxonomy_no_points.fasta \
	-title silva138 \
	-dbtype nucl \
	-out <a-directory-of-your-choice>
```

This will return 3 files:
`silva138.nsq` ,`silva138.nin`, `silva138.nhr`

You can now add the new Silva version on yor CREST instance by moving all these 3 files along with the
`*.map` and the `*.tree` file under a new directory at 
`~/CREST/LCAClassifier/parts/flatdb`
and add it to the `lcaclassifier.conf` file that is located at
`~/CREST/LCAClassifier/parts/etc` by running something like: 

```
echo "silva138 = /home/tools/CREST/LCAClassifier/parts/flatdb/silva138" >> /home/tools/CREST/LCAClassifier/parts/etc/lcaclassifier.conf
```

You are all set! 

