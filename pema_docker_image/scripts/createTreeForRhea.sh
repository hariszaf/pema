#!/bin/bash


###  MIN DIAGRAFSEIS TIN APO KATO GRAMMI ME TIPOTA!!!!
####/usr/bin/raxmlHPC -f a -p 12345 -s aligned_otus.fasta -x 54321 -# 100 -m GTRGAMMA -n TEST

pathScripts=$(pwd)
cd ..
pathPema=$(pwd)
echo $pathPema

### $pathPema/tools/raxml-ng/raxml-ng/bin/raxml-ng --all --msa aligned_otus.fasta --model GTR --tree pars{10} --bs-trees 200

/home1/haris/metabar_pipeline/PEMA/tools/raxml-ng/raxml-ng/bin/raxml-ng --all --msa aligned_otus.fasta --model GTR --tree pars{10} --bs-trees 200

## --threads
