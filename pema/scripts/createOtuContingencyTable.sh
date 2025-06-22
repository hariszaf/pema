#!/bin/bash

# Aim: The "stats" table obtained once Swarm v2 was complteted
#      gives for each ASV:
#        1. the total abundance, 
#        2. the number of unique amplicons in the OTU, 
#        3. the name and the abundance of the most abundant amplicon in the OTU (i.e. the seed), and 
#        4. the number of low abundant amplicons (abundance = 1) in the ASV.

#       The sorted ASVs, can be used along with the amplicon
#       contingency table to produce a new ASV contingency table.
#       That table will indicate for each ASV the number of time
#       elements of that ASV (i.e. amplicons) have been seen in 
#       each sample (columns).
#
# Usage: PEMA invokes this script every time Swarm v2 has been asked for by the user,
#        once Swarm has been completed, in the clusteringSwarm function of the clustering module.
# 
# Authors: Frédéric Mahé, edited by Haris Zafeiropoulos
#           initial script available at: 
#           https://github.com/torognes/swarm/wiki/Working-with-several-samples#produce-a-contingency-table-for-otus

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



