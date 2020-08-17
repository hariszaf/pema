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



############################################################################

#
#cat SWARM.stats | sort -n -r -k4 > sorted_SWARM.stats
#
#STATS="sorted_SWARM.stats"
#SWARMS="SWARM.swarms"
#AMPLICON_TABLE="amplicon_contingency_table_temp.csv"
#OTU_TABLE="SWARM_OTU_table_2.tsv"
#
## Header
#echo -e "OTU\t$(head -n 1 "${AMPLICON_TABLE}")" > "${OTU_TABLE}"
#
## Compute "per sample abundance" for each OTU
#awk -v SWARM="${SWARMS}" \
#    -v TABLE="${AMPLICON_TABLE}" \
#    'BEGIN {FS = " "
#            while ((getline < SWARM) > 0) {
#                swarms[$1] = $0
#            }
#            FS = "\t"
#            while ((getline < TABLE) > 0) {
#                table[$1] = $0
#            }
#           }
#
#     {# Parse the stat file (OTUs sorted by decreasing abundance)
#      seed = $3"_"$4      
#      n = split(swarms[seed], OTU, "[ _]");
#
#      for (i = 1; i < n; i = i + 2) {
#          sample_otu = OTU[i]
#          #gsub(/:0:0:0:/, "", sample_otu )
#          #gsub(/:::/, ":", sample_otu )
#    
#          s = split(table[ sample_otu  ], abundances, "\t")
#          for (j = 1; j < s; j++) {
#              samples[j] += abundances[j+1]
#          } 
#      }
#      printf "%s\t%s", NR, $3
#      for (j = 1; j < s; j++) {
#          printf "\t%s", samples[j]
#      }
#     printf "\n"
#     delete samples
#     }' "${STATS}" >> "${OTU_TABLE}"
#
