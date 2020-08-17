#!/bin/bash

awk \
'BEGIN {FS = "[>_]"  }    
## Parse the sample files
/^>/ {contingency[$2][FILENAME] = $3
    amplicons[$2] += $3
    if (FNR == 1) {
        samples[++i] = FILENAME
    }
}
END {
# Create table header
printf "amplicon"
s = length(samples)
for (i = 1; i <= s; i++) {
    printf "\t%s", samples[i]
}
printf "\t%s\n", "total"
# Sort amplicons by decreasing total abundance use a coprocess
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
}}'  linearized.dereplicate*  >  amplicon_contingency_table_temp.csv