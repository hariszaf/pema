---
layout: page
title: Training the RDPClassifier
---


> **Attention!**<br/>
This feature is compatible with `Singularity 3.7.1`! 
Previous versions of Singularity may not support for this.


In case you are using Singularity, to enable this feauture you need to **get** PEMA in another way than discussed before. 


```
singularity build --fix-perms pema_fixperms shub://hariszaf/pema:v.2.0.3
```

Then, once you prepare your `analysis_directory` as described in the following sections, to **run** PEMA you also need to 
run an alternative command: 

```
singularity run --fakeroot --writable -B /home/haris/Documents/coding/local_only/test_beds/pema/analysis_directory:/mnt/analysis pema_fixperms
```






We will consider this  task as a *two-step* procedure.

The first one, is the one **you** need do on your own; this is the step of preparing the taxonomy andn the sequence file in the necessary formats.

This step is not the same for all cases as it is **strongly dependent** on the format of your sequence database.

Its output though **must be** as described in the following chapters in order to use it in the PEMA framework

Once you complete this, you may provide PEMA with its outcome and PEMA will run the second one; where the actual training of the classifier occurs.

As an example, we will show you how we handled the [Midori2](http://www.reference-midori.info/download.php#) database to train
the RDPClassifier.

> You may have a look on how your final input files need to look like over [here](https://github.com/hariszaf/pema/tree/local_ref_db/analysis_directory/custom_ref_db/rdpclassifier_example)


## Step 1 - the one you'll need to do on your own*

Aim of this step is to end up with two files:
* a **sequence file** (with a `.fasta` extension)
* a **taxonomy file** (with a `.tsv` extension)

in the format required.

>Unfortunately, there is no way for step 1 to be implemented in a completely automatic way, so it could be part of the PEMA code.
The user needs to provide PEMA with the aforementioned files, otherwise an error will occur.


Here is how we trained RDPClassifier with Midori 2 reference database. 

 <span style="color:green">This is an **extreme case** so you should not panic with the following commands! </span>

 <span style="color:green">Most cases will be **considerably easier** to get an appropriate *taxonomy file*! </span>

 <span style="color:green">We chose to use this as an example as a worst case scanerio</span>


We downloaded the MIDORI_UNIQ_GB240_CO1_RDP fasta file of Midori2 which includes 1.332.086 sequences coming from 185.617 unique taxonomies.

### Building the *sequence file*

To get the `.fasta` file in the required format in terms of training the RDPClassfier, we run:

```bash
awk '/>.* /{$0 = ">MIDSEQ" ++seq}1' MIDORI_UNIQ_GB240_CO1_RDP.fasta > MIDORI_UNIQ_GB240_CO1_RDP_unique_ids.fasta
```

This way we renamed all the sequence titles with an Id of ours. So, the sequnce titles that used to be something like this:

```bash
>MG559732.1.<1.>690	root_1;Eukaryota_2759;Discosea_555280;Flabellinia_1485085;order_Vannellidae_95227;Vannellidae_95227;Clydonella_218657;Clydonella sawyeri_2201168
```
now they are like this:

```bash
>MIDSEQ1
```

>**Anything after the first white space is ignored**, so we do not really mind if any **taxonomy** information is included on the titles or not.


### Building the *taxonomy file*

As John Quensen highlights, there are two requirements for this file:
> a. There must be an entry for every rank in every line. Hyphen placeholders are allowed but are not recommended.
b. “Convergent evolution” is not allowed. For example, the same genus cannot appear in two different families.


So first, we may keep the unique ids we made in a separate file:

```bash 
more MIDORI_UNIQ_GB240_CO1_RDP_unique_ids.fasta | grep ">" | sed 's/>//g' > unique_ids.tsv
```

To get only the taxonomies included there, we ran:

```bash
more MIDORI_UNIQ_GB240_CO1_RDP.fasta | grep ">" | awk -F "\t" '{print $2}' > taxonomies_initial.tsv
```

And then, to remove unecessary words from them, such as *class*, *family* etc. that could lead to problems later on, we ran:

```bash
sed 's/root_1;//g ; s/_[0-9]*//g ; s/order//g ; s/class//g ; s/phylum//g ; s/family//g ; s/ /_/g' taxonomies_initial.tsv > taxonomies_clear.tsv
```

**Attention!** We need to make sure that all taxonomies include an entry for every rank in every line!

A good practice is to count the ";" in each taxonomy

```bash
awk '{print gsub(/;/,"")}' taxonomies_clear.tsv > count_leves_per_taxonomy.tsv
```

On the output file, we see that we get 6 counts in all the taxonomies included! That's good news!!

Now, we can concatenate the ids with the taxonomies to a single file.

```bash
paste unique_ids.tsv taxonomies_clear.tsv -d ";" > taxonomy.tsv
```

Finally, we need to substitute all the ";" with tabs

```bash
sed -i 's/;/\t/g' taxonomy_file.tsv
```


By now, we should be ok. However, as we found out the hard way, Midori does allow “Convergent evolution”.
So there are genus names that are part of different taxonomies.
For example, the genus *Thalia* has two different taxonomies:

```bash
root_1;Eukaryota_2759;Chordata_7711;Thaliacea_30304;Salpida_30307;Salpidae_34759;Thalia_34760;Thalia longicauda_1408229
```

and

```bash
root_1;Eukaryota_2759;Streptophyta_35493;Magnoliopsida_3398;Zingiberales_4618;Marantaceae_4619;Thalia_96513;Thalia geniculata_96515
```
This is a major issue for RDPClassifier and we need to avoid it. As the Midori2 version we are trying to use for training has more 1.332.086 sequences and we had more than 90  taxa names with this issue, we had to develop a script to deal with this issue.

```python
#!/usr/bin/python3.5
import sys, re
doubles = [
	# add all the taxa names with this issue
]

taxa_file = open("taxonomies_clear.tsv", "r")
set_of_repeats = set ()

for line in taxa_file:
	taxa_levels = line.split(";")
	for level in taxa_levels:
		if level not in doubles:
			continue
		else:
			taxonomy_index = taxa_levels.index(level)
			taxonomy_repeat = taxa_levels[:taxonomy_index + 1]
			taxonomy_repeat =  ";".join(taxonomy_repeat)
			set_of_repeats.add(taxonomy_repeat)
			break
new_taxonomies = {}
for double in doubles:
	counter = 1
	for entry in set_of_repeats:
		if re.search(double, entry):
			new_taxonomies[entry] = entry + "_" + str(counter)
			counter += 1

taxa_file = open("taxonomies_clear.tsv", "r")
new_taxa_file = open("taxonomy.tsv", "w+")
for line in taxa_file:
	taxa_levels = line.split(";")
	check = True
	for level in taxa_levels:
		if level in doubles:
			taxonomy_index = taxa_levels.index(level)
			taxonomy_repeat = taxa_levels[:taxonomy_index + 1]
			taxonomy_repeat =  ";".join(taxonomy_repeat)

			replace_prefix = new_taxonomies[taxonomy_repeat]
			replace_suffix = ";".join(taxa_levels[taxonomy_index + 1 :])
			replace = replace_prefix + ";" + replace_suffix
			new_taxa_file.write(replace)
			check = False
			break
	if check:
		new_taxa_file.write(line)

```



So, now PEMA can take it from here! ;)

\* For this step, you may also check the instructions of [John Quensen](https://john-quensen.com/tutorials/training-the-rdp-classifier/) as well.

## Step 2 - running in a PEMA container

 <span style="color:green">This step is implemented by PEMA so you do not need to do anything! </span>
 <span style="color:green">It's here to present you an overview of the steps needed to train the RDPClassifier. </span>
 <span style="color:green">If you are interested in that you may move forward on the [how to run step](#howtorun)</span>


PEMA makes use of the two scripts the [GLBRC Microbiome Team](https://github.com/GLBRC-TeamMicrobiome/python_scripts) has developed to support this task; the ```lineage2taxTrain.py``` and the ```addFullLineage.py```; both are on Python2.

```bash
./lineage2taxTrain.py taxonomy_file.tsv > ready4train_taxonomy.txt     
```
 this will take some hour!

Meanwhile, PEMA will also run the following
```bash
./addFullLineage.py taxonomy_file.tsv MIDORI_UNIQ_GB240_CO1_RDP_unique_ids.fasta > ready4train_seqs.fasta
```

Once both these scripts are done, the actual training step is about to start!

```bash
java -Xmx10g -jar /usr/local/RDPTools/classifier.jar train -o midori_training_files -s ready4train_seqs.fasta -t ready4train_taxonomy.txt
```

Just to give you an order of magnitude of the computational costs we have up to now, the `lineage2taxTrain.py` took approximately 20 hours to complete, while the building of the `training_files` (see last command) required more than 50Gb of RAM.

However, we finally did it!

Now, we only have to copy the `rRNAClassifier.properties` included in the RDPClassifier directory, to the `midori_training_files` where is the final output of our two steps and we are ready to use the classifier against the new Midori2.

Midori2 has been included on the `v.2.0` of PEMA.

>We expect to have great results using this new Midori2 version, however, an essential computational cost comes with that.
The time PEMA will now need to implement this step will be increased to a great extent.



## How to run PEMA when you're using a custom db

PEMA as already mentioned, is a container - based software. 

You can think of a container as a box that includes everything you need to run your code on it (you may see more about containers [here]()).

Apparently, when you are about to use your custom database, PEMA somehow needs to add this on the corresponding container. 

To do this you need to get PEMA as a **`sandbox`**. 

So you need to download PEMA like this:

```bash
singularity build --sandbox pema_sandbox shub://hariszaf/pema:v.2.0.3
```

Once you have added the corresponding files of your database for the training of the RDPClassifier, you may run:

```bash
singularity run --writable -B /path_to_your/analysis_directory/:/mnt/analysis pema_sandbox/
```

The `--writable` parameter allows PEMA to make add the files returned from the training and finally, use them for the taxonomy assignment step. 




