#!/bin/bash

STATS="asvs.stats"
SWARMS="asvs.swarms"
AMPLICON_TABLE="amplicon_contingency_table.tsv"
ASV_TABLE="asvs_contingency_table.tsv"

# Header
echo -e "ASV\t$(head -n 1 "${AMPLICON_TABLE}")" > "${ASV_TABLE}"

# Compute "per sample abundance" for each ASV
awk -v SWARM="${SWARMS}" \
   -v TABLE="${AMPLICON_TABLE}" \
   'BEGIN {FS = " "
           while ((getline < SWARM) > 0) {
               swarms[$1] = $0
           }
           FS = "\t"
           while ((getline < TABLE) > 0) {
               table[$1] = $0
           }
          }

    {# Parse the stat file (ASVs sorted by decreasing abundance)
     seed = $3"_"$4      
     n = split(swarms[seed], ASV, "[ _]");

     for (i = 1; i < n; i = i + 2) {
         sample_ASV = ASV[i]
         #gsub(/:0:0:0:/, "", sample_ASV )
         #gsub(/:::/, ":", sample_ASV )
   
         s = split(table[ sample_ASV ], abundances, "\t")
         for (j = 1; j < s; j++) {
             samples[j] += abundances[j+1]
         } 
     }
     printf "%s\t%s", NR, $3
     for (j = 1; j < s; j++) {
         printf "\t%s", samples[j]
     }
    printf "\n"
    delete samples
    }' "${STATS}" >> "${ASV_TABLE}"



