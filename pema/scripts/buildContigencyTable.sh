#!/bin/bash

# Aim:     Keep track of the number of occurrences of each amplicon in each sample
#          Amplicons (rows) and their occurrences in the different samples (columns).
# 
# Usage:   This script is invoked every time the user selects Swarm, as part of the
#          PEMA preprocessing module, in the swarmDereplicate() function
# 



# Dereplication at the study level
echo -e "\n\n * Dereplication at the study level *"


# Step 1: Dereplicate at the study level; dereplicate sequences and keep their sum across all samples
echo -e "==> Build all_samples.fasta file."

export LC_ALL=C

cat *.derep.fa | \
    awk 'BEGIN {RS = ">" ; FS = "[_\n]"}
        {if (NR != 1) {abundances[$1] += $2 ; sequences[$1] = $3}}
        END {for (amplicon in sequences) {
            print ">" amplicon "_" abundances[amplicon] "_" sequences[amplicon]}}' | \
    sort --temporary-directory=$(pwd) -t "_" -k2,2nr -k1.2,1d | \
    sed -e 's/\_/\n/2' > ../all_samples.fasta

# Build a matrix where the hash is the raw name and 
# the abundance of the corresponding amplicon the value at eash sample (column)
echo -e "==> Build amplicon contigency table .."

awk 'BEGIN {FS = "[>_]"}

     # Parse the sample files
     /^>/ {contingency[$2][FILENAME] = $3
           amplicons[$2] += $3
           if (FNR == 1) {
               samples[++i] = FILENAME
           }
          }

     END {# Create table header
          printf "amplicon"
          s = length(samples)
          for (i = 1; i <= s; i++) {
              printf "\t%s", samples[i]
          }
          printf "\t%s\n", "total"

          # Sort amplicons by decreasing total abundance (use a coprocess)
          command = "LC_ALL=C sort -k1,1nr -k2,2d"
          for (amplicon in amplicons) {
               printf "%d\t%s\n", amplicons[amplicon], amplicon |& command
          }
          close(command, "to")
          FS = "\t"
          while ((command |& getline) > 0) {
              amplicons_sorted[++j] = $2
          }
          close(command)

          # Print the amplicon occurrences in the different samples
          n = length(amplicons_sorted)
          for (i = 1; i <= n; i++) {
               amplicon = amplicons_sorted[i]
               printf "%s", amplicon
               for (j = 1; j <= s; j++) {
                   printf "\t%d", contingency[amplicon][samples[j]]
               }
               printf "\t%d\n", amplicons[amplicon]
          }}' *.derep.fa > ../amplicon_contingency_table.tsv
