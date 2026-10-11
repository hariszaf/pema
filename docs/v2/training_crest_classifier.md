---
layout: page
title: Training the CREST classifier
---


We will consider this  task as a *two-step* procedure.

The first one, is the one **you** need do on your own; this is the step of preparing the taxonomy and the sequence file in the necessary formats.

This step is **not the same for all cases** as it is **strongly dependent** on the format of your sequence database.

Its output though **must be** as described in the following chapters in order to use it in the PEMA framework.

Once you complete this, you may provide PEMA with its outcome and PEMA will run the second one; where the actual training of the classifier occurs.




As an example, we will use a subset of Silva sequences coming from Bacteria genus found in Greece according to the [BacDive](https://bacdive.dsmz.de/isolation-sources?filters_origin[country][0]=GRC) platform.



## Step 1 - the one you'll need to do on your own


Aim of this step is to end up with two files:
* a **sequence alignment file** (with a `.fasta` extension)
* a **taxonomy file** (with a `.nds` extension)

in the format required.

>Unfortunately, there is no way for step 1 to be implemented in a completely automatic way, so it could be part of the PEMA code.
The user needs to provide PEMA with the aforementioned files, otherwise an error will occur.

You may find the example files on PEMA GitHub repo. 


Here are some things you might find useful to build the files as they need to be. 



### With respect to the `taxononomy.nds` file


This file needs to be a tab seperated file with **exactly** three columns. 

Here is an example of how this file could be like.

```
SSEQ_1  Bacteria;Firmicutes;Bacilli;Bacillales;Bacillaceae;Bacillus;Bacillus_vallismortis   SSEQ_1
```

As it is rather grumpy task, a good practice is to have a sequence id without dots and have the same id both on column 1 and 3. 

On column 2 you need to provide the taxonomy that corresponds to each sequence. 



### With respect to the `sequence_alignment.fasta` file

In the alignment file, it is good to have **only** the sequnce id as title with no taxonomy next to that.

Besides that, this file is just an ordinary alignment. The [mafft](https://mafft.cbrc.jp/alignment/software/) algorithm could be used to this end.

----------------------------

Here are some nice bash commands to get your files.

You can replace the titles of the sequences 
```
awk '{for(x=1;x<=NF;x++) if($x~/>.*/){ sub(/>.*/,">SSEQ_"++i) }}1' sequence_alignment_file.fasta.temp > sequence_alignment_file.fasta
```

To replace first ids with a `SSEQ_n` pattern:

```
cut -f 2- taxonomy_file.nds.temp | nl |sed 's/^ */SSEQ/' > taxonomy_file.nds
```


## Step 2 - running in a PEMA container

PEMA makes use of the CREST scripts and automatically trains the CREST algorithm with your custom db sequences. 

