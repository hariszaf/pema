#!/bin/bash



awk -F "\t" 'BEGIN {OFS = "\t"} { $2=""; $NF=""; print }' asvs_contingency_table.tsv | \
sed 's/linearized.dereplicate_//g ; s/.merged.fastq//g ; s/OTU/#OTU_ID/g; s/^\([0-9].*\)/Otu\1/g ; s/\t\t/\t/g ; s/_/ /g'  > tmp

awk -F '\t' '{print $1}' asvs_contingency_table.tsv | sed 's/^\([0-9].*\)/Otu\1/g ; s/OTU/#OTU_ID/g' > firstCol

head -1 asvs_contingency_table.tsv | awk 'BEGIN {OFS = "\t"}{for(i=3;i<=NF-1;++i) printf $i"\t"}' |  sed 's/linearized.dereplicate_//g ; s/.merged.fastq//g' > header 

while read line; do grep -v OTU |  awk -v b=2 'BEGIN{FS=OFS="\t"} {for (i=b;i<=NF;i++) printf "%d%s", $i, (i<NF ? OFS : ORS)}' > OUTPUT_t ;done < tmp

awk 'BEGIN {OFS="\t"} NF{NF-=1};1' OUTPUT_t > OUTPUT

awk '1' header OUTPUT > samples

paste -d "\t" firstCol samples  > allTab.tsv

rm tmp firstCol header samples OUTPUT


# Map Swarm ids to Otu numbers

sed '1i\\' asvs_representatives_all_samples.fasta > tml 
mv tml asvs_representatives_all_samples.fasta

while read line; do grep ">" |  sed 's/>//g ; s/_.*//g' | xargs -I {} grep {} asvs_contingency_table.tsv | awk 'BEGIN {OFS="\t"} {print $1 "\t" $2}'; done < asvs_representatives_all_samples.fasta  > pairs

tail -n +2 asvs_representatives_all_samples.fasta > tml
mv tml asvs_representatives_all_samples.fasta


awk -F "\t" {'print ">Otu"$1'} pairs > otus
cat asvs_representatives_all_samples.fasta | grep -v ">" > seqs

paste -d \\n otus seqs  > asvs_representatives_all_samples.fasta

rm pairs otus seqs 

