#!/bin/bash


#cat SWARM_final_OTU_representative.fasta | grep ">" > temp_SWARM_OTU_to_create_table.txt
cat SWARM_otu_no_chimera.fasta | grep ">" > temp_SWARM_OTU_to_create_table.txt

sed 's/>//g; s/:/\t/g; s/;/\t/g; s/:/\t/g; s/;/\t/g; s/size=//g' temp_SWARM_OTU_to_create_table.txt > SWARM_OTU_to_create_table_temp.tsv

cat SWARM_OTU_to_create_table_temp.tsv | sort -n -r -k3 > sorted_SWARM_OTU_to_create_table_temp.tsv


awk '
{kolpo[$1,$2]=$3; samples[$1];otus[$2];}

END{

for(sample in samples)   #print header
  printf("\t%s",sample);
  printf("\n");

for(i in otus) {                                             #each row
   
   printf("%s\t",i);
   
   for(j in samples)                                            #each column
        printf("\t%d", kolpo[j,i]);				#changed on 04/10/2019 it used to be "%d\t"
        printf("\n");
 }   
}' SUBSEP="\t"  sorted_SWARM_OTU_to_create_table_temp.tsv >  SWARM_OTU_table.tsv

rm temp_SWARM_OTU_to_create_table.txt SWARM_OTU_to_create_table_temp.tsv  sorted_SWARM_OTU_to_create_table_temp.tsv
