#!/bin/bash


#Aim:    Script to extract a single column from the finalTable.tsv file 
#         in cases that the RDPClassifier has been used, to build per sample profiles.

# Usage:  script needs a sample name as an argument and it needs to be run from 
#         the same directory where the finalTable.tsv file is 

# Author: Haris Zafeiropoulos


# Keep sample in a var
sample=${1}
echo "From the matrix, sammple: " $sample

# Get the index of the column of the sample in the finalTable.tsv file
index=$(head -1 finalTable.tsv | tr "\t" "\n" | grep -nx "$sample" |  cut -d":" -f1) 
echo "From the matrix, index: " $index

# Make a file of that column
awk -F"\t" -v "col=${index}" '{print $1 "\t" $col "\t" $NF}' finalTable.tsv > profile_$sample.tsv.tmp

awk -F"\t" '$2 != 0' profile_$sample.tsv.tmp > profile_$sample.tsv

rm profile_$sample.tsv.tmp

