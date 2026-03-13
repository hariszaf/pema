#!/bin/bash

# Aim:   When ASVs are built using the Swarm v2 algorithm, 
#        this script builds the 
#        asvs_representatives_all_samples.fasta file
#        where the abundance of each ASV is merged to its id 
#        e.g. 
#        >218a968dfc3034ee2071c2f017aac9b38596ba5f_1286
#        CCAAGGATGAACTGTTTACCCC....
#
# Usage: This script is called in the clustering.bds file 
#        from the clusteringSwarm() function 
#
# Author: Haris Zafeiropoulos



awk -F'\t' '
BEGIN { OFS = "\t" }
NR == 1 {
  for (i = 1; i <= NF; i++) gsub(/\.derep\.fa/, "", $i)
}
NR == 1 || NF > 1 {
  $2 = ""                     # remove 2nd column (Seed)
  sub(/\t\t/, "\t")           # collapse the empty column
  print
}
' asvs_contingency_hash.tsv > asvs_contingency_table.tsv 



awk -F'\t' '
  FNR == NR {
    if (FNR == 1) next                    # skip header of table
    hash_to_asv[$2] = $1                  # map hash to ASV ID
    next
  }
  /^>/ {
    if (match($0, /^>([^;]+);size=([0-9]+)/, arr)) {
      hash = arr[1]
      size = arr[2]
      if (hash in hash_to_asv)
        print ">" hash_to_asv[hash] ";size=" size
      else
        print $0                          # leave unchanged if not found
    } else {
      print $0                            # malformed header? print as-is
    }
    next
  }
  { print }                               # sequence lines
' asvs_contingency_hash.tsv asvs_representatives_hash.fa > asvs_representatives.fa
