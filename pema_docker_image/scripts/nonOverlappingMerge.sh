#!/bin/bash 

export LC_ALL=C

forwardFile=${1}
reverseFile=${2}
correctFile=${3}


# convert the fastq files into fasta, as in our merging method, the qualities play no part
cat $forwardFile | paste - - - - | sed 's/^@/>/g'| cut -f1-2 | tr '\t' '\n' > $forwardFile.fasta
cat $reverseFile  | paste - - - - | sed 's/^@/>/g'| cut -f1-2 | tr '\t' '\n' > $reverseFile.fasta



# make the reverse complement of the reverse file!
cat $reverseFile.fasta |\
while read L ; \
do \
	echo $L;\
	read L; echo $L | /usr/bin/rev | /usr/bin/tr "ATCG" "TAGC" ;  
done > reverse_complement_$reverseFile.fasta


## here i ll have to add something in order to take all the parts of reverse complement and create the complete file.

# here it justs glues the files in the order they have to
paste -d "" $forwardFile.fasta reverse_complement_$reverseFile.fasta > double_$correctFile.merged.fasta
sed 's/>[^>]*//2g' double_$correctFile.merged.fasta > $correctFile.merged.fastq








#sed 's/ .*//' $forwardFile.fasta > noCordinates_$forwardFile.fasta
#sed 's/ .*//' reverse_complement_$reverseFile.fasta > noCordinates_$reverseFile.fasta

#paste -d "" noCordinates_$forwardFile.fasta noCordinates_$reverseFile.fasta > double_$correctFile.merged.fasta
#rm  $forwardFile.fasta $reverseFile.fasta reverse_complement_$reverseFile.fasta  noCordinates_$forwardFile.fasta  noCordinates_$reverseFile.fasta double_$correctFile.merged.fasta
