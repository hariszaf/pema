---
layout: page
title: Training the RDPClassifier
---

RDPClassifier can be trained on your own reference sequences, and PEMA does the training for you.
This is a two-step procedure:

1. **you** prepare a taxonomy file and a sequence file, in the formats below;
2. **PEMA** checks them, trains RDPClassifier, saves the trained database, and uses it for your analysis.


## Step 1 - the files you prepare

There is no way to do this step automatically, as it depends on the format of your reference database. You need two files.

**A taxonomy file**: tab-separated, with a header line; an id column, then one column per rank:

```
Seq_ID      Kingdom    Phylum     Class       Order     Family     Genus    Species
SEQ1179093  Eukaryota  Annelida   Polychaeta  Eunicida  Eunicidae  Eunice   Eunice_vittata
SEQ1180266  Eukaryota  Annelida   Polychaeta  Phyllodocida  Nereididae  Alitta  Alitta_succinea
```

As [John Quensen highlights](https://john-quensen.com/tutorials/training-the-rdp-classifier/), there are two requirements:

* there must be an entry for **every rank** on every line (a `-` placeholder is allowed, but not recommended);
* **"convergent evolution"** is not allowed: the same name cannot appear at the same rank under different parents,
  e.g. a genus in two different families.

**A sequence file**: fasta, the first word of each header being the id used in the taxonomy file. Anything after the first space is ignored.

```
>SEQ1179093
ATCTTCTCCCTACACTTAGCAGGAGTTTCATCAATTTTAGGCTCCATTAATTTTATTACT...
```

The [PEMA repository](https://github.com/hariszaf/pema/tree/master/sanity_check/custom_rdp/custom_ref_db) includes a small example of both files.


### An example: MIDORI 2

As an example of the worst case, here is how we prepared the MIDORI 2 database (`MIDORI_UNIQ_GB240_CO1_RDP.fasta`, 1,332,086 sequences
from 185,617 unique taxonomies) to train RDPClassifier.
Its headers carry both an accession and a taxonomy:

```
>MG559732.1.<1.>690	root_1;Eukaryota_2759;Discosea_555280;Flabellinia_1485085;order_Vannellidae_95227;Vannellidae_95227;Clydonella_218657;Clydonella sawyeri_2201168
```

To get the **sequence file**, we renamed the sequences with ids of ours:

```
awk '/>.* /{$0 = ">MIDSEQ" ++seq}1' MIDORI_UNIQ_GB240_CO1_RDP.fasta > MIDORI_UNIQ_GB240_CO1_RDP_unique_ids.fasta
```

To get the **taxonomy file**, we kept these ids, and the taxonomies of the headers without the NCBI taxids and the rank words:

```
grep ">" MIDORI_UNIQ_GB240_CO1_RDP_unique_ids.fasta | sed 's/>//g' > unique_ids.tsv
grep ">" MIDORI_UNIQ_GB240_CO1_RDP.fasta | awk -F "\t" '{print $2}' > taxonomies_initial.tsv
sed 's/root_1;//g ; s/_[0-9]*//g ; s/order//g ; s/class//g ; s/phylum//g ; s/family//g ; s/ /_/g' taxonomies_initial.tsv > taxonomies_clear.tsv
```

We checked that every taxonomy has the same number of ranks (6 `;` on every line):

```
awk '{print gsub(/;/,"")}' taxonomies_clear.tsv | sort | uniq -c
```

and joined the ids and the taxonomies, with a header line:

```
( printf 'Seq_ID\tKingdom\tPhylum\tClass\tOrder\tFamily\tGenus\tSpecies\n'
  paste -d ";" unique_ids.tsv taxonomies_clear.tsv | sed 's/;/\t/g' ) > taxonomy.tsv
```

MIDORI does have "convergent evolution": more than 90 genus names appear in different taxonomies, e.g. the genus *Thalia*, both a
tunicate (Chordata; Thaliacea) and a plant (Streptophyta; Marantaceae). PEMA finds these for you (see below).


## Step 2 - what PEMA does

In the `rdp` section of the parameters file, set the two files, `databases_dir` (where the trained database is saved), and
`database` (the name of the new database):

```
classifier: rdp

rdp:
  database: midori_custom
  databases_dir: /path/to/rdp_databases
  train:
    taxonomy: /path/to/taxonomy.tsv
    sequences: /path/to/MIDORI_UNIQ_GB240_CO1_RDP_unique_ids.fasta
    rename_duplicates: false
    memory: 64 GB
```

If `databases_dir` does not have that database yet, PEMA:

1. checks the two files, and stops with a list of all the problems: missing ranks, ids without a taxonomy, and names that appear
   at the same rank under different parents (**convergent evolution**). With `rename_duplicates: true`, PEMA renames those instead,
   to `<name>_1`, `<name>_2`, ... (e.g. `Thalia_1` and `Thalia_2`);
2. converts them to the training files of RDPClassifier (as the `lineage2taxTrain.py` and `addFullLineage.py` scripts of the
   [GLBRC Team Microbiome](https://github.com/GLBRC-TeamMicrobiome/python_scripts) did);
3. trains RDPClassifier (`rdp_classifier train`) and adds its `rRNAClassifier.properties` file;
4. saves the trained database in `databases_dir/<database>`, and assigns the taxonomy of your samples with it.

The next runs find the trained database in `databases_dir` and use it without training again.
To train it again, delete its folder.

Training large databases needs a lot of memory (`train.memory`): MIDORI 2 needed more than 50 GB.
See [Running on HPC]({{ '/3.running_on_HPC/' | relative_url }}).


## Using a trained database

A trained database is a folder with an `rRNAClassifier.properties` file and the files it lists:

```
my_database/
├── bergeyTrainingTree.xml
├── genus_wordConditionalProbList.txt
├── logWordPrior.txt
├── rRNAClassifier.properties
└── wordConditionalProbIndexArr.txt
```

To use one you already have, without the `train` part, set `database` to its folder name and `databases_dir` to the folder that contains it,
or `database` to the full path of the folder.
