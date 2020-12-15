#!/bin/bash

# Go to the RDPTools directory
cd /home/tools/CREST/LCAClassifier/src/LCAClassifier

# Keep the taxonomy and the sequence files provided by the user as variables
taxonomy_file="/mnt/analysis/custom_ref_db"${1}
sequence_file="/mnt/analysis/custom_ref_db"${2}
name_of_custom_db=${3}

# Train the classifier
python nds2CREST.py -o $name_of_custom_db -i $sequence_file $taxonomy_file

# Set the trained algorithm available for use
mkdir /home/tools/CREST/LCAClassifier/parts/flatdb/$name_of_custom_db
cp $name_of_custom_db.* /home/tools/CREST/LCAClassifier/parts/flatdb/$name_of_custom_db
cd /home/tools/CREST/LCAClassifier/parts/flatdb/$name_of_custom_db

echo "$name_of_custom_db = /home/tools/CREST/LCAClassifier/parts/flatdb/$name_of_custom_db" >> /home/tools/CREST/LCAClassifier/parts/etc/lcaclassifier.conf




# to use it
# 1. megablast -i env.fa -d ~/LCAClassifier/parts/flatdb/database-name/database-name.fasta -b100 -v100 -m7 -o env_custom.xml
# 2. classifiy -d database-name env_custom.xml