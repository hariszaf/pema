#!/bin/bash

# Go to the RDPTools directory
cd /home/tools/RDPTools

# Keep the taxonomy and the sequence files provided by the user as variables
taxonomy_file="/mnt/analysis/custom_ref_db/"${1}
sequence_file="/mnt/analysis/custom_ref_db/"${2}
name_of_custom_db=${3}

# Train the classifier

# This step could take hours; for example for training the Midori2 database took more than 12hours.
python /home/scripts/lineage2taxTrain.py $taxonomy_file > ready4train_taxonomy.txt 

python /home/scripts/addFullLineage.py $taxonomy_file $sequence_file > ready4train_seqs.fasta

java -Xmx10g -jar /home/tools/RDPTools/classifier.jar train -o TRAIN/$name_of_custom_db -s ready4train_seqs.fasta -t ready4train_taxonomy.txt

# Once the training step is completed, we just copy a last file of the RDPTools environment on our new ref db
cp /home/tools/RDPTools/classifier/samplefiles/rRNAClassifier.properties TRAIN/$name_of_custom_db

