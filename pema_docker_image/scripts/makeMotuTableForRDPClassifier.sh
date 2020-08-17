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

rm final_motu_table.tsv SWARM_OTU_table.tsv.first SWARM_OTU_table.tsv.first_sorted true_Swarm_otu_table.tsv assigned out redi almost

mv a final_table.tsv





#/////////////////////////////////////////////////////////////////////////////////////////


### error! 

###################################################################
## 1st step:  find and remove the chimeras from the Swarm output
###################################################################
#
## to do so, first find the Swarm ASVs
#sed '/^>/!d; s/;size=[0-9]*//g ; s/>//g' SWARM_final_OTU_representative.fasta > asvs
#
## then find the ASVs left after the chimera removal 
#sed '/^>/!d; s/;size=[0-9]*//g ; s/>//g' SWARM_otu_no_chimera.fasta > asvsNoChimera
#
## keep the removed ASVs to a file 
#diff asvs asvsNoChimera > differences
#sed -i 's/[0-9]*[a-z][0-9]*//g ; s/< //g; /^$/d' differences
#
## make a copy of the initial Swarm output
#cp SWARM.stats SWARM.stats.arxiko
#
## remove from the Swarm output the chimera entries
#while read p; do   sed -i "/$p/d" SWARM.stats ; done < differences
#
#
## 2nd step:  remove the singletons from the Swarm output
#
#awk '{if($1!=1 && $2!=1) print $0}' SWARM.stats > new.stats
#a=$(awk '{if($1!=1 && $2!=1) print $0}' SWARM.stats | wc -l)
#a=$(awk '{if($1!=1 && $2!=1) print $0}' SWARM.stats | wc -l) |  head -$a SWARM.swarms > new.swarms
#
#awk '{ print $NF,$0 }' SWARM_OTU_table.tsv | sort -k1,1 -n -r | cut -d " " -f 2-   >  redi
#
## keep the first line of the MOTU table
#tail -n 1 redi >> mpli
#
## remove last line - used to be the title
#sed -i '$ d' redi
#
#head -$a redi > new_table.tsv
#
#
#
#sed 's/[A-Z]*.*;size=[0-9]*//g ; s/superkingdom//g ; s/phylum//g ; s/class//g ; s/order//g ; s/family//g ; s/genus//g ; s/species//g' tax_assign_swarm_COI.txt > almost
#sed 's/\t//g ; s/[0-9]\.[0-9]*/;/g ; s/.$//' almost > taxonomies.txt
#
#
#
#cut -f 2- new_table.tsv | rev | cut -f 2- | rev > temp.otu_table
#
#awk '{print $2}' new_table.tsv > from_new_table
#awk '{print $1}' tax_assign_swarm_COI.txt | sed 's/;size=[0-9]*//g' > from_taxonomy
#
#
#sort  from_taxonomy  > from_taxonomy_sorted
#sort  from_new_table > from_new_table_sorted
#
#diff from_new_table_sorted from_taxonomy_sorted > differences2
#sed -i 's/[0-9]*[a-z][0-9]*//g ; s/< //g; /^$/d' differences2
#
#while read p; do   sed -i "/$p/d" temp.otu_table ; done < differences2
#
#paste temp.otu_table taxonomies.txt > almost_done
#
#sed -i 's/amplicon\t// ; s/total/classification/' mpli
#(cat mpli && cat almost_done ) > filename1 && mv filename1 final_otu_table.txt
#
##rm mpli redi new_table.tsv from_new_table* from_taxonomy* almost_done differences almost

