#!/bin/bash


awk '{$1=""; print $0}' SWARM_OTU_table.tsv >  temp_SWARM_otu_table.tsv
rm SWARM_OTU_table.tsv
cat temp_SWARM_otu_table.tsv | rev | cut  -f2- | rev > SWARM_OTU_table.tsv
sed -i 's/amplicon/#OTU_ID/; s/ /\t/g' SWARM_OTU_table.tsv



cut -f 2- SWARM_OTU_table.tsv > mple
awk 'NF{NF-=1};1' < mple >out
rm SWARM_OTU_table.tsv
mv out SWARM_OTU_table.tsv
sed -i 's/ /\t/g' SWARM_OTU_table.tsv