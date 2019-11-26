#!/bin/bash

sed 's/;size=.*//g' tax_assign_swarm_COI.txt > assigned

cp SWARM_OTU_table.tsv SWARM_OTU_table.tsv.first

while read p; do   sed -i "/$p/d" SWARM_OTU_table.tsv ; done < assigned


sort SWARM_OTU_table.tsv > SWARM_OTU_table.tsv_sorted
sort SWARM_OTU_table.tsv.first > SWARM_OTU_table.tsv.first_sorted

comm -3 SWARM_OTU_table.tsv_sorted SWARM_OTU_table.tsv.first_sorted >  true_Swarm_otu_table.tsv

awk '{print $NF $0}' true_Swarm_otu_table.tsv | sort -k3,3 | sort -s -k1,1 -n -r | cut -f 3-  >  redi

awk 'NF{NF--};1' < redi > out
sed -i 's/ /\t/g' out


sed 's/[A-Z]*.*;size=[0-9]*//g ; s/superkingdom//g ; s/phylum//g ; s/class//g ; s/order//g ; s/family//g ; s/genus//g ; s/species//g' tax_assign_swarm_COI.txt > almost
sed 's/\t//g ; s/[0-9]\.[0-9]*/;/g ; s/.$//' almost > taxonomies.txt

paste out taxonomies.txt > final_motu_table.tsv

head -1 SWARM_OTU_table.tsv.first  | sed 's/amplicon\t//g; s/total/classification/g' > a | cat final_motu_table.tsv >> a

rm final_motu_table.tsv

mv a final_table.tsv
