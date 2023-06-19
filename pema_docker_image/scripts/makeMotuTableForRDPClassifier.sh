#!/bin/bash

# Aim: Script to process the output of the RDPClassifier and
# build an ASVs table
# 
# Usage : This script is invoked when the RDPClassifier 
#         has been selected by the user, as part of the
#         rdpBuildingTable() function of the taxAssinment module of PEMA
# 
# Author: Haris Zafeiropoulos

sed 's/[A-Z]*.*;size=[0-9]*//g ; s/superkingdom//g ; s/phylum//g ; s/class//g ; s/order//g ; s/family//g ; s/genus//g ; s/species//g' tax_assignments.tsv > almost
sed 's/\t//g ; s/[0-9]\.[0-9]*/;/g ; s/.$// ; s/_[0-9]*/\t/' almost > taxonomies.txt


while read line; do awk -F "\t" '{print $2}' | \
        xargs -I {} grep {} taxonomies.txt | \
        awk -F "\t" {'print $2'} ; \
done < asvs_contingency_table.tsv > taxonomies_sorted.txt 

sed -i '1 i\Classification' taxonomies_sorted.txt


awk 'BEGIN {OFS="\t"} {for(i=3;i<=NF;i++){printf "%s ", $i}; printf "\n"}' asvs_contingency_table.tsv > tml
awk 'BEGIN {FS=" "}{OFS="\t"} NF{NF-=1};1' tml > tnl
sed 's/linearized.dereplicate_//g ; s/.merged.fastq//g' tnl > TMP

rm tml tnl

awk -F "\t" '{print "ASV_"$1 ":" $2}' asvs_contingency_table.tsv | sed -e 's/ASV_ASV/ASV_number/' > asvs

sed -i 's/\(.*\)_/\1 /' taxonomies_sorted.txt

paste -d "\t" asvs TMP taxonomies_sorted.txt > finalTable.tsv

rm asvs TMP taxonomies_sorted.txt almost




