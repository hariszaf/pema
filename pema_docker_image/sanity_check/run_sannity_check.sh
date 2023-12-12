#!/bin/bash

# Aim:  This sanity checks allows to have an overview of the PEMA modules
#       what works well and what does not. Can be used to test whether 
#       a new feture causes any issues or not.
#       Should be always run before a new version is to be released.
#
# Usage: ./run_sannity_check.sh
# 
# Author: Haris Zafeiropoulos

CWD=$(pwd)
TAG=v.2.1.5

cp 16S/parameters.tsv 16S/parameters.tsv.bck

## Run example case for 16S ENA data using vsearch
echo "PEMA for 16S in ENA format and using original setup for preprocessing, vsearch and Silva db is about to start"
docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:$TAG rm -rf /mnt/analysis/test_16S_original_vsearch

start_time=$(date +%s.%N)

docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:$TAG bds /home/pema_latest.bds

end_time=$(date +%s.%N)
elapsed_time=$(echo "$end_time - $start_time" | bc)
elapsed_minutes=$(echo "$elapsed_time / 60" | bc)

echo "PEMA for 16S using vsearch and Silva db has been completed in ${elapsed_minutes} minutes"


## Run example case for 16S using Swarm
echo "PEMA for 16S in ENA format using using original setup for preprocessing, Swarm and Silva db is about to start"

sed -i 's/outputFolderName\ttest_16S_original_vsearch/outputFolderName\ttest_16S_original_swarm/' 16S/parameters.tsv
sed -i 's/clusteringAlgo\talgo_vsearch/clusteringAlgo\talgo_Swarm/' 16S/parameters.tsv

docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:$TAG rm -rf /mnt/analysis/test_16S_original_swarm/

start_time=$(date +%s.%N)

docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:$TAG bds /home/pema_latest.bds

end_time=$(date +%s.%N)
elapsed_time=$(echo "$end_time - $start_time" | bc)
elapsed_minutes=$(echo "$elapsed_time / 60" | bc)

echo "PEMA for 16S using original setup for preprocessing, Swarm and Silva db has been completed in ${elapsed_minutes} minutes"


## Run example case for 16S using fastp and Swarm
echo "PEMA for 16S in ENA format using fastp for preprocessing, Swarm and Silva db is about to start"

sed -i 's/outputFolderName\ttest_16S_original_swarm/outputFolderName\ttest_16S_fastp_swarm/' 16S/parameters.tsv
sed -i 's/preprocess\toriginal/preprocess\tfastp/' 16S/parameters.tsv

docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:$TAG rm -rf /mnt/analysis/test_16S_fastp_swarm/

start_time=$(date +%s.%N)

docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:$TAG bds /home/pema_latest.bds

end_time=$(date +%s.%N)
elapsed_time=$(echo "$end_time - $start_time" | bc)
elapsed_minutes=$(echo "$elapsed_time / 60" | bc)


echo "PEMA for 16S using fastp for preprocessing, Swarm and Silva db has been completed in ${elapsed_minutes} minutes"


## Run example case for 16S using fastp and vsearch
echo "PEMA for 16S in ENA format using fastp for preprocessing, Swarm and Silva db is about to start"

sed -i 's/outputFolderName\ttest_16S_fastp_swarm/outputFolderName\ttest_16S_fastp_vsearch/' 16S/parameters.tsv
sed -i 's/clusteringAlgo\talgo_Swarm/clusteringAlgo\talgo_vsearch/' 16S/parameters.tsv

docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:$TAG rm -rf /mnt/analysis/test_16S_fastp_vsearch/

start_time=$(date +%s.%N)

docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:$TAG bds /home/pema_latest.bds

end_time=$(date +%s.%N)
elapsed_time=$(echo "$end_time - $start_time" | bc)
elapsed_minutes=$(echo "$elapsed_time / 60" | bc)

echo "PEMA for 16S using fastp for preprocessing, vsearch and Silva db has been completed in ${elapsed_minutes} minutes"


mv parameters.tsv.bck parameters.tsv
exit



# #----------------------------

#  Run example case for 18S using vsearch and Silva db
cp 18S/parameters.tsv 18S/parameters.tsv.bck

echo "PEMA for 18S using original preprocessing setup, vsearch and Silva db is about to start"

docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:$TAG rm -rf /mnt/analysis/test_18S_original_vsearch/
docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:$TAG bds /home/pema_latest.bds


echo "PEMA for 18S using vsearch and Silva db has been completed"

## Run example case for 18S using Swarm and Silva db
echo "PEMA for 18S using Swarm and Silva db is about to start"
cp 18S/parameters_swarm.tsv 18S/parameters.tsv
docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:$TAG rm -rf /mnt/analysis/test_18S_original_swarm/
docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:$TAG ./pema_latest.bds
rm 18S/parameters.tsv
echo "PEMA for 18S using Swarm and Silva db has been completed"

## Run example case for 18S using vsearcg and PR2 db - when feature available
## Not available for now! 
            # echo "PEMA for 18S using vsearch and PR2 is about to start"
            # cp 18S/parameters_vsearch_pr2.tsv 18S/parameters.tsv
            # docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:$TAG ./pema_latest.bds
            # rm 18S/parameters.tsv
            # echo "PEMA for 18S using vsearch and PR2 db is about to start"

# #----------------------------

## Run example case for COI using Swarm and Midori-1
echo "PEMA for COI using Swarm and Midori-1 db is about to start"
cp COI/parameters_midori_1.tsv COI/parameters.tsv
docker run --rm -v $CWD/COI/:/mnt/analysis/ hariszaf/pema:$TAG rm -rf /mnt/analysis/test_COI_midori1/
docker run --rm -v $CWD/COI/:/mnt/analysis/ hariszaf/pema:$TAG ./pema_latest.bds
rm COI/parameters.tsv
echo "PEMA for COI using Swarm and Midori-1 db has been completed"

# ## Run example case for COI using Swarm and a custom db (Amvrakikos)
echo "PEMA for COI data using Swarm and a custom db to train the RDPClassifier"
docker run --rm -v $CWD/custom_rdp/:/mnt/analysis hariszaf/pema:$TAG rm -rf /mnt/analysis/custom_db_rdp_coi/
docker run --rm -v $CWD/custom_rdp/:/mnt/analysis hariszaf/pema:$TAG ./pema_latest.bds
echo "PEMA using custom db and RDPClassifier has been completed"

## Run example case for 16S using vsearch and a custom db (Amvrakikos)
echo "PEMA for 16S data using vsearch and a custom dv to train the CREST algorithm" 
docker run --rm -v $CWD/custom_crest/:/mnt/analysis hariszaf/pema:$TAG rm -rm /mnt/analysis/custom_db_crest_16S
docker run --rm -v $CWD/custom_crest/:/mnt/analysis hariszaf/pema:$TAG ./pema_latest.bds
echo "PEMA using custom db and CREST algorithm has been compleleted"


# #----------------------------

# ## Run example case for ITS using Swarm and Unite
echo "PEMA for ITS is about to start"
docker run --rm -v $CWD/ITS/:/mnt/analysis/ hariszaf/pema:$TAG rm -rf /mnt/analysis/    test_*
docker run --rm -v $CWD/ITS/:/mnt/analysis/ hariszaf/pema:$TAG ./pema_latest.bds
echo "PEMA for ITS has been completed"






