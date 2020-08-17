#!/bin/bash


read fileToConvert
phy_file=$(cat $fileToConvert)


awk '{print ">"$1}' $phy_file > only_ids.txt
awk '{print $2}' $phy_file  > only_seqs.phy
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
mv only_seqs_in.fasta $phy_file.fasta


echo "we have converted your .phy to .fasta file for you!"
