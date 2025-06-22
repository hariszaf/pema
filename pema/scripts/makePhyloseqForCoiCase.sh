awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < rdpClassifierInput.fasta > rdpClassifierInputOneLine.fasta

sed -i '1d' rdpClassifierInputOneLine.fasta

sed 's/$/\n/g' taxonomies.txt > taxonomies_2.txt

sed -i 's/;size=[0-9]*//g' rdpClassifierInputOneLine.fasta

paste rdpClassifierInputOneLine.fasta taxonomies_2.txt > Aligned_assignments.fasta

rm rdpClassifierInputOneLine.fasta taxonomies_2.txt

sed -i 's/\t/ /g' Aligned_assignments.fasta
