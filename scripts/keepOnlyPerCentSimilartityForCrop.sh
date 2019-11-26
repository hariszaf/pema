#!/bin/bash
#
#path2=$(pwd)
#echo $path2
#source parameters.tsv
#
#percentage=$(awk '$1 == "percentageOfSimilarity" {print $2} ' parameters.tsv)

## just like the awk_3.sh but this time for the CROP output
awk '{if($NF >= 90) {print $0}}' taxonomy_from_rdpclassifer_COI_CROP.txt > assignment_90.txt
awk '{print $(NF-3)" "$(NF-2)}' assignment_90.txt | sort | uniq | sort > unique_species_list.txt

rm assignment_90.txt
