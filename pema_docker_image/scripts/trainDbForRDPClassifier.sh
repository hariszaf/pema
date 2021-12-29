#!/bin/bash

# Aim:    Train the RDPClassifier using the required files, based on a custom db
# 
# Usage:  PEMA invokes this script every time that the RDPClassifier has been selected
#         and the custom_ref_db parameter has beeen set as "Yes". It is called as part 
#         of the `initialize` module of PEMA 
# 
# Authors: Haris Zafeiropoulos

# Go to the RDPTools directory
cd /home/tools/RDPTools

# Keep the taxonomy and the sequence files provided by the user as variables
taxonomy_file=${1}
sequence_file=${2}
name_of_custom_db=${3}

# Train the classifier
mkdir TRAIN/$name_of_custom_db

# This step could take hours; for example for training the Midori2 database took more than 12hours.
python /home/scripts/lineage2taxTrain.py $taxonomy_file > ready4train_taxonomy.txt 

python /home/scripts/addFullLineage.py $taxonomy_file $sequence_file > ready4train_seqs.fasta

java -Xmx10g -jar /home/tools/RDPTools/classifier.jar train -o TRAIN/$name_of_custom_db/ -s ready4train_seqs.fasta -t ready4train_taxonomy.txt

# Once the training step is completed, we just copy a last file of the RDPTools environment on our new ref db
cp /home/tools/RDPTools/classifier/samplefiles/rRNAClassifier.properties TRAIN/$name_of_custom_db/

