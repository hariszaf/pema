#!/bin/bash


### I remove all  new lines and make each sequence an one ana only line kai kano oli tin allilouxia mia grammi
awk 'NR==1 {print ; next} {printf /^>/ ? "\n"$0"\n" : $1} END {printf "\n"}' SWARM_otu_no_chimera.fasta > nospace_swarm.fasta

### I remove all singletons
#sed '/\<size=1\>/,+1 d' nospace_swarm.fasta > no_singletons.fasta
sed '/\<size=[1,2]\>/,+1 d' nospace_swarm.fasta > no_singletons.fasta


