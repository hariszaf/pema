#!/bin/bash


path=$(pwd)
#suffix="/scripts"
#real_path=${path%"$suffix"}
#cd $real_path
#echo "actual main path is: " $real_path
#output_folder=$(/usr/bin/awk '{ if ($1 == "outputFile") {print $2}}' parameters.tsv)
#echo "the output folder is called: " $output_folder
#cd $real_path/$output_folder/7.gene_dependent/gene_COI/CROP


echo $path

## calculation of parameteres for  CROP
number_of_seqs=$(cat no_chim_COI_CROP_all_samples.fasta | grep ">" | wc -l)
beta=$(($number_of_seqs/50))

echo "beta equals to " $beta

cat no_chim_COI_CROP_all_samples.fasta | grep "^[^>]" > just_seqs.txt
cat just_seqs.txt | tr -d " \t\n\r" > just_bases.txt
total_bases=$(cat just_bases.txt)
total_length=${#total_bases}
echo "total length equals to: " $total_length
zeta="$(( (total_length - number_of_seqs) / number_of_seqs ))"
echo "zeta equals to " $zeta

epsilon=$((10 * $zeta))

echo "zeta:$zeta" | tr : '\t' >>cropParameters.tsv
echo "beta:$beta" | tr : '\t' >>cropParameters.tsv
echo "epsilon:$epsilon" | tr : '\t' >>cropParameters.tsv


rm just_seqs.txt just_bases.txt


cropPath=$(pwd)
echo "cropPath is: " $cropPath 

cd ../../../..
cd tools/

toolsPath=$(pwd)

echo "toolsPath is: " $toolsPath

cd $cropPath

$toolsPath/CROP/CROPLinux -i no_chim_COI_CROP_all_samples.fasta -o CROP_output -z $zeta -b $beta -e $epsilon || true
