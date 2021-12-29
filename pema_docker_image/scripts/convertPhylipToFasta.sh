#!/bin/bash

# Aim: This script takes as input a Phylim alignment file and 
#      converts it into a fasta file
#
# Usage: That is required in case phylogeny based taxonomy
#        assignment has been asked (16S data). In the 
#        phylogenyAssign() function once PaPaRa has been completed
#        its papara_alignment.phy output needs to be converted to fasta
# 
# Author: Haris Zafeiropoulos


awk '{print ">"$1}' papara_alignment*.phy > only_ids.txt
awk '{print $2}' papara_alignment*.phy  > only_seqs.phy
sed -e "s/.\{80\}/&\n/g" < only_seqs.phy > only_seqs_in.fasta
filename='only_ids.txt'
filelines=`cat $filename`
counter=1

for line in $filelines  
do
sed "${counter}i${line}" only_seqs_in.fasta > temp.fasta ;
mv temp.fasta only_seqs_in.fasta ;
counter=$((counter + 30)) ;
done

rm only_ids.txt only_seqs.phy
mv only_seqs_in.fasta papara_alignment.fasta


echo "we have converted your .phy to .fasta file for you!"
