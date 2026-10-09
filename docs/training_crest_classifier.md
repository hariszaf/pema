---
layout: page
title: Training the CREST classifier
---

PEMA can build a [crest4](https://github.com/xapple/crest4) database from your own reference sequences, and use it for the taxonomy assignment.
This is a two-step procedure:

1. **you** prepare a taxonomy file and a sequence file, in the formats below;
2. **PEMA** checks them, builds the database, saves it, and uses it for your analysis.

> crest4 works differently from the CREST version of PEMA v2.x: it searches your sequences against the database with BLAST or VSEARCH,
> so the reference sequences **do not need to be aligned** anymore.


## Step 1 - the files you prepare

There is no way to do this step automatically, as it depends on the format of your reference database. You need two files.

**A taxonomy file**: tab-separated, without a header, one line per sequence: the accession, the lineage, and optionally a name.
The lineage can be separated by `/`, as crest4 expects (e.g. as exported from [ARB](http://www.arb-home.de/)):

```
OQ071219	Main genome/Eukaryota/Amorphea/Metazoa/Mollusca/Scaphopoda/Dentaliida/Dentaliidae/Antalis/Antalis occidentalis	Antalis occidentalis
```

or by `;`, as in the `.nds` files of the previous CREST versions:

```
SSEQ_1	Bacteria;Firmicutes;Bacilli;Bacillales;Bacillaceae;Bacillus;Bacillus_vallismortis	SSEQ_1
```

A good practice is to use accessions without dots.

**A sequence file**: fasta, the first word of each header being the accession. An alignment works too: the gaps are removed.

You can rename the sequences and the accessions consistently, e.g. to `SSEQ_1`, `SSEQ_2`, ..., with

```
awk '/^>/{print ">SSEQ_" ++i; next}1' sequences.fasta.temp > sequences.fasta
cut -f 2- taxonomy.nds.temp | nl | sed 's/^ */SSEQ_/' > taxonomy.nds
```

(the sequences and the lines of the taxonomy file must be in the same order).

The [PEMA repository](https://github.com/hariszaf/pema/tree/master/sanity_check/custom_crest/custom_ref_db) includes a small example of both files.


## Step 2 - what PEMA does

In the `crest` section of the parameters file, set the two files, `mount_crest_dbs` (the folder with your crest4 databases, where the new one
is saved), and `database` (the name of the new database):

```
classifier: crest

crest:
  database: my_crest_db
  mount_crest_dbs: /path/to/crest4_databases
  train:
    taxonomy: /path/to/taxonomy.nds
    sequences: /path/to/sequences.fasta
```

If `mount_crest_dbs` does not have that database yet, PEMA:

1. checks the two files, and stops with a list of the problems: lines without a lineage, repeated accessions, sequences without a taxonomy;
2. builds the database for crest4: the `.map`, `.names` and `.tre` files, with
   [`make_new_crest_db.py`](https://github.com/hariszaf/pema/blob/master/scripts/make_new_crest_db.py) by Lucas Sinclair;
3. builds the search index (BLAST or VSEARCH, according to `search_algo`);
4. saves the database in `mount_crest_dbs/<database>`, and assigns the taxonomy of your samples with it.

The next runs find the database in `mount_crest_dbs` and use it without building it again. To build it again, delete its folder.

Each rank gets a minimum similarity for a sequence to be assigned to it: 0.99 for the deepest rank (e.g. species), then 0.02 less per rank up
(0.97 genus, 0.95 family, ...), and none for the first two ranks (in ARB lineages, `Main genome` and the domain).


## Using a database

A crest4 database is a folder with the same name as its files:

```
my_crest_db/
├── my_crest_db.fasta
├── my_crest_db.map
├── my_crest_db.names
└── my_crest_db.tre
```

To use one you already have (e.g. a UNITE database for ITS), without the `train` part, put it in `mount_crest_dbs` and set `database` to its name.
