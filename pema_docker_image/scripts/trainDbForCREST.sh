#!/bin/bash

# Go to the RDPTools directory
cd /home/tools/CREST/LCAClassifier/src/LCAClassifier

# Keep the taxonomy and the sequence files provided by the user as variables
taxonomy_file="/mnt/analysis/custom_ref_db/"${1}
sequence_file="/mnt/analysis/custom_ref_db/"${2}
name_of_custom_db=${3}

# Train the classifier
/home/tools/CREST/LCAClassifier/bin/nds2CREST -o $name_of_custom_db -i $sequence_file $taxonomy_file

# Set the trained algorithm available for use
mkdir /home/tools/CREST/LCAClassifier/parts/flatdb/$name_of_custom_db
cp $name_of_custom_db.* /home/tools/CREST/LCAClassifier/parts/flatdb/$name_of_custom_db
cd /home/tools/CREST/LCAClassifier/parts/flatdb/$name_of_custom_db

echo "$name_of_custom_db = /home/tools/CREST/LCAClassifier/parts/flatdb/$name_of_custom_db" >> /home/tools/CREST/LCAClassifier/parts/etc/lcaclassifier.conf

# 2. classifiy -d database-name env_custom.xml

sed 's/\.//g ; s/-//g' $sequence_file |  tr "\t" "\n" | fold -w 80 > alignment_sequences_to_makeblastdb.fasta
/home/tools/ncbi-blast-2.8.1+/bin/makeblastdb -in alignment_sequences_to_makeblastdb.fasta -title $name_of_custom_db -dbtype nucl -out /home/$name_of_custom_db
rm alignment_sequences_to_makeblastdb.fasta