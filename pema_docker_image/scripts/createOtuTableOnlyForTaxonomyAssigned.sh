#!/bin/bash

# Aim: This has the same scope as the createOtuContingencyTable.sh
# 
# Usage: PROBABLY NOT NEEDED
# 
# Authors: Haris Zafeiropoulos, Evangelos Pafilis

cp finalTriplesFromSwarmClustering.txt finalTriplesFromSwarmClustering.tsv 

sed -e "s/\s\{3,\}/\t/g" finalTriplesFromSwarmClustering.tsv > temporaryOTU.tsv
rm finalTriplesFromSwarmClustering.tsv finalTriplesFromSwarmClustering.txt
sed 's/ /_/g'  temporaryOTU.tsv >  finalTriplesFromSwarmClustering.tsv


awk '
{kolpo[$1,$3]=$2; samples[$1];otus[$3];}

END{

for(sample in samples)   #print header
  printf("\t%s",sample);
  printf("\n");

for(i in otus) {                                             #each row
   
   printf("%s\t",i);
   
   for(j in samples)                                            #each column
        printf("%d\t", kolpo[j,i]);
        printf("\n");
 }   
}' SUBSEP="\t" finalTriplesFromSwarmClustering.tsv  >  OTU_table_for_significantly_assigned.tsv


rm temporaryOTU.tsv
