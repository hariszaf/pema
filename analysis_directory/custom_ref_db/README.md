You only need this directory, in case you need to use your own reference database.

If that is the case, you need to keep the name of this directory exactly as it is ```custom_ref_db```


# Custom reference database on PEMA

We will consider this  task as a *two-step* procedure. 

The first one, is the one **you** will have to do on your own; this is the step of preparing the taxonomy andn the sequence file in the necessary formats. 
Once you complete this, you may provide PEMA with its outcome and PEMA will run the second one; where the actual training of the classifier occurs. 

------------------------------------

## Step 1 - the one you'll need to do on your own

### In case of the COI marker gene - Training RDPClassifier

We will following the steps of [John Quensen](https://john-quensen.com/tutorials/training-the-rdp-classifier/).

We will use the [Midori2](http://www.reference-midori.info/download.php#) database as an example for the first step, more specifically the MIDORI_UNIQ_GB240_CO1_RDP fasta file. 
This Midori version includes 1.332.086 sequences coming from 185.617 unique taxonomies. 


To get the `.fasta` file as needed to train the RDPClassfier:

```
awk '/>.* /{$0 = ">MIDSEQ" ++seq}1' MIDORI_UNIQ_GB240_CO1_RDP.fasta > MIDORI_UNIQ_GB240_CO1_RDP_unique_ids.fasta
```

Now, we may keep the unique ids we made in a file:

```
more MIDORI_UNIQ_GB240_CO1_RDP_unique_ids.fasta | grep ">" | sed 's/>//g' > unique_ids.tsv
```

To get the taxonomies file as needed:
```
sed 's/root_1;//g ; s/_[0-9]*//g ; s/order//g ; s/class//g ; s/phylum//g ; s/family//g ; s/ /_/g' taxonomies_initial.tsv > taxonomies_clear.tsv
```

**Attention!**
This is a rather important thing to remember! You may get some advise from [Dr John Quensen](https://john-quensen.com/tutorials/training-the-rdp-classifier/).
We need to make sure that all taxonomies include an entry for every rank in every line! 

We can do that by counting the ";" in each taxonomy

```
awk '{print gsub(/;/,"")}' taxonomies_clear.tsv > count_leves_per_taxonomy.tsv
```

On the output file, we see that we get 6 counts in all the taxonomies included! That's good news!! 

Now, we can concatenate the ids with the taxonomies to a single file. 
 
```
paste unique_ids.tsv taxonomies_clear.tsv -d ";" > semicolomn_taxonomy_file.tsv
```

Finally, we need to substitute all the ";" with tabs

```
sed -i 's/;/\t/g' taxonomy_file.tsv
```

and now we can run the scripts to get the taxonomy in the format needed for the training. PEMA can take it from here! ;)


>Unfortunately, there is no way for step 1 to be implemented in a completely automatic way, so it could be part of the PEMA code. 
The user needs to provide PEMA with the aforementioned files, otherwise an error will occur. 



### In case of 16S/18S and ITS

Sequences of the reference marker genes in the alignment, in FASTA format (sequences.fasta in the example below). It is important that the sequences are cropped so that stretches of unaligned sequence is not included. Such sequences may bias the alignments during classification. In ARB, this can be done by using a positional filter when exporting sequences.





------------------------------------


## Step 2 - now PEMA makes the rest

We are using two of the scripts the [GLBRC Microbiome Team](https://github.com/GLBRC-TeamMicrobiome/python_scripts) has developed to support this task; the ```lineage2taxTrain.py``` and the ```addFullLineage.py```; both are on Python2.



```
./lineage2taxTrain.py taxonomy_file.tsv > ready4train_taxonomy.txt     
```
 this will take some hour! 

Meanwhile, PEMA will also run the following 
```
./addFullLineage.py ../semicolomn_taxonomy_file.tsv ../MIDORI_UNIQ_GB240_CO1_RDP_unique_ids.fasta > ready4train_seqs.fasta
```

Once both these scripts are done, the actual training step is about to start! 

```
java -Xmx10g -jar /usr/local/RDPTools/classifier.jar train -o training_files -s ready4train_seqs.fasta -t ready4train_taxonomy.txt
```


