#!/bin/bash

awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < no_singletons.fasta > no_singletons_2.fasta

rm no_singletons.fasta nospace_swarm.fasta

mv no_singletons_2.fasta SWARM_otu_no_chimera.fasta
