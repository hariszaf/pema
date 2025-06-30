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

# 1. Cleaned OTU IDs
cut -f1 asvs_contingency_table.tsv | sed 's/^\([0-9].*\)/Otu\1/g; s/OTU/#OTU_ID/g' > firstCol

# 2. Cleaned header (samples: from col 3 to N−1)
head -1 asvs_contingency_table.tsv | \
  awk 'BEGIN{OFS="\t"}{for(i=3;i<=NF-1;++i) printf "%s%s", $i, (i<NF-1 ? OFS : ORS)}' | \
  sed 's/linearized.dereplicate_//g; s/.merged.fastq//g' > header

# 3. Main matrix (remove 2nd and last cols, clean sample/OTU names)
awk -F"\t" 'BEGIN{OFS="\t"} NR>1 { $2=""; $NF=""; print }' asvs_contingency_table.tsv | \
  sed 's/\t\t/\t/g' | \
  awk -F"\t" 'BEGIN{OFS="\t"} {for(i=2;i<NF;i++) printf "%d%s", $i, (i<NF-1 ? OFS : ORS)}' > OUTPUT

# 4. Add header
cat header OUTPUT > samples

# 5. Add OTU IDs back
paste -d "\t" firstCol samples > allTab.tsv

# 6. Cleanup
rm firstCol header samples OUTPUT



# awk -F "\t" 'BEGIN {OFS = "\t"} { $2=""; $NF=""; print }' asvs_contingency_table.tsv | \
# sed 's/linearized.dereplicate_//g ; s/.merged.fastq//g ; s/OTU/#OTU_ID/g; s/^\([0-9].*\)/Otu\1/g ; s/\t\t/\t/g ; s/_/ /g'  > tmp

# awk -F '\t' '{print $1}' asvs_contingency_table.tsv | sed 's/^\([0-9].*\)/Otu\1/g ; s/OTU/#OTU_ID/g' > firstCol

# head -1 asvs_contingency_table.tsv | awk 'BEGIN {OFS = "\t"}{for(i=3;i<=NF-1;++i) printf $i"\t"}' |  sed 's/linearized.dereplicate_//g ; s/.merged.fastq//g' > header 

# sed -i 's/\t$//' header

# while read line; do grep -v OTU |  awk -v b=2 'BEGIN{FS=OFS="\t"}{OFMT = "%.0f"} {for (i=b;i<=NF;i++) printf "%d%s", $i, (i<NF ? OFS : ORS)}' > OUTPUT_t ;done < tmp

# awk 'BEGIN {OFS="\t"} NF{NF-=1};1' OUTPUT_t > OUTPUT

# awk '1' header OUTPUT > samples

# paste -d "\t" firstCol samples  > allTab.tsv

# rm tmp firstCol header samples OUTPUT OUTPUT_t



# --------------------------------------


# Map Swarm ids to Otu numbers

# Extract ASV headers and their corresponding sequences
grep "^>" asvs_representatives_all_samples.fasta | sed 's/^>//' > asv_ids.txt
grep -v "^>" asvs_representatives_all_samples.fasta > seqs.txt

# Extract ASV to sample mapping (assumes ASV IDs are in first column of TSV)
# awk -F"\t" 'NR==FNR{a[$1]; next} $1 in a {print $1, $2}' asv_ids.txt asvs_contingency_table.tsv > pairs.txt
awk -F"\t" 'NR==FNR{a[$1]; next} $2 in a {print $1, $2}' asv_ids.txt asvs_contingency_table.tsv > pairs.txt

# Create new headers like >OtuASV_001
awk '{print ">Otu"$1}' pairs.txt > headers.txt

# Paste headers and sequences back together into FASTA
paste -d "\n" headers.txt seqs.txt > tmp
awk 'NF==0 {exit} {print}' tmp > asvs_representatives_all_samples.fasta

# Cleanup
rm asv_ids.txt seqs.txt headers.txt pairs.txt tmp


# sed '1i\\' asvs_representatives_all_samples.fasta > tml 
# mv tml asvs_representatives_all_samples.fasta

# while read line; do grep ">" |  \
#    sed 's/>//g ; s/_.*//g' | \
#    xargs -I {} grep {} asvs_contingency_table.tsv | \
#    awk 'BEGIN {OFS="\t"} {print $1 "\t" $2}'; \
# done < asvs_representatives_all_samples.fasta  > pairs

# tail -n +2 asvs_representatives_all_samples.fasta > tml
# mv tml asvs_representatives_all_samples.fasta


# awk -F "\t" {'print ">Otu"$1'} pairs > otus
# cat asvs_representatives_all_samples.fasta | grep -v ">" > seqs

# paste -d \\n otus seqs  > asvs_representatives_all_samples.fasta

# rm otus seqs pairs

