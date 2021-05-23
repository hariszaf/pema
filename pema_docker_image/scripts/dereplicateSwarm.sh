#!/bin/bash

# This script is based on blocks of code from F.Mahe - developer of Swarm 
# You may find more about that on the following GitHub Wiki page:
#  https://github.com/torognes/swarm/wiki/




for file in $(ls); 
do 
   awk 'NR==1 {print ; next} {printf /^>/ ? "\n"$0"\n" : $1} END {printf "\n"}' $file \
   > ../../6.linearizedSequences/$file.linearized.fasta ; 
done


cd ../../6.linearizedSequences/


# Dereplication at the sample level

for file in $(ls | grep linearized.fasta); 
do  
   grep -v "^>" $file | \
   grep -v [^ACGTacgt] | sort -d | uniq -c | \
   while read abundance sequence ; 
   do     
      hash=$(printf "${sequence}" | sha1sum); \
      hash=${hash:0:40}; \
      printf ">%s_%d_%s\n" "${hash}" "${abundance}" "${sequence}"; 
   done | \
   sort -t "_" -k2,2nr -k1.2,1d | sed -e 's/\_/\n/2' > ../5.dereplicateSamples/$file._dereplicated.fasta ; 
done


cd ../5.dereplicateSamples/


rename.ul .linearized.fasta._dereplicated.fasta "" *_dereplicated.fasta


for f in * ; do mv -- "$f" "linearized.dereplicate_$f" ; done


# Dereplication at the study level
export LC_ALL=C
cat linearized.dereplicate* | \
awk 'BEGIN {RS = ">" ; FS = "[_\n]"}
     {if (NR != 1) {abundances[$1] += $2 ; sequences[$1] = $3}}
     END {for (amplicon in sequences) {
         print ">" amplicon "_" abundances[amplicon] "_" sequences[amplicon]}}' | \
sort --temporary-directory=$(pwd) -t "_" -k2,2nr -k1.2,1d | \
sed -e 's/\_/\n/2' > ../all_samples.fasta




# HOPEFULLY WE WON'T NEED THIS - IF WE DO WE NEED TO REMOVE SEQS FROM FILES TOO
# SO THEY WON'T BE IN THE AMPLICONS CONTINGENCY TABLE
# task awk '/N/{n=2}; n {n--; next}; 1' < $globalVars{'outputFilePath'}/all_samples.fasta  > $globalVars{'outputFilePath'}/final_all_samples.fasta


# Build contingency table 
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
          }}' linearized.dereplicate* > ../amplicon_contingency_table.tsv








