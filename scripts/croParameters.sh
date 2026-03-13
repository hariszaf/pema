#!/bin/bash

path=$(pwd)
echo $path

## calculation of parameteres for  CROP
number_of_seqs=$(cat no_chim_COI_CROP_all_samples.fasta | grep ">" | wc -l)

# beta parameter
beta=$(($number_of_seqs/50))
echo "beta equals to " $beta

# zeta parameter
cat no_chim_COI_CROP_all_samples.fasta | grep "^[^>]" > just_seqs.txt
cat just_seqs.txt | tr -d " \t\n\r" > just_bases.txt
total_bases=$(cat just_bases.txt)
total_length=${#total_bases}
echo "total length equals to: " $total_length
zeta="$(( (total_length - number_of_seqs) / number_of_seqs ))"
echo "zeta equals to " $zeta

# epsilon parameter
epsilon=$((10 * $zeta))
echo "epsilon equals to " $epsilon

# keep estimated parameter values in a .tsv file
echo "zeta:$zeta" | tr : '\t' >>cropParameters.tsv
echo "beta:$beta" | tr : '\t' >>cropParameters.tsv
echo "epsilon:$epsilon" | tr : '\t' >>cropParameters.tsv

# remove temporar files for the calculation of zeta parameter
rm just_seqs.txt just_bases.txt

## get the path for the PEMA tools
#toolsPath="/home/tools/"
#echo "toolsPath is: " $toolsPath

## run the CROP algorithm 
#cd $cropPath
#$toolsPath/CROP/CROP/CROPLinux -i no_chim_COI_CROP_all_samples.fasta -o CROP_output -z $zeta -b $beta -e $epsilon || true
