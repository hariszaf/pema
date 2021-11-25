#!/bin/bash

# This sanity checks allows to have an overview of the PEMA modules
# what works well and what does not.
# Can be used to test whether a new feture causes any issues or not.
# Should be always run before a new version is to be released.

CWD=$(pwd)

# ## Run example case for 16S ENA data using vsearch
# echo "PEMA for 16S in ENA format and using vsearch and Silva db is about to start"
# cp 16S/parameters_vsearch.tsv 16S/parameters.tsv
# mv 16S/ena_data/ERR* 16S/mydata/
# docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 rm -rf /mnt/analysis/test_16S*
# docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
# rm 16S/parameters.tsv
# mv 16S/mydata/ERR* 16S/ena_data
# echo "PEMA for 16S using vsearch and Silva db has been completed"

# ## Run example case for 16S non ENA data using vsearch
# echo "PEMA for 16S in non ENA format using vsearch and Silva db is about to start"
# cp 16S/parameters_vsearch_noENA_data.tsv 16S/parameters.tsv
# mv 16S/noEna_data/We1* 16S/mydata/
# docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 rm -rf /mnt/analysis/test_16S*
# docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
# rm 16S/parameters.tsv
# mv 16S/initial_data/We1* 16S/noEna_data/
# rm 16S/mydata/ERR*
# echo "PEMA for 16S using vsearch and Silva db has been completed"

# ## Run example case for 16S using Swarm
# echo "PEMA for 16S using Swarm and Silva db is about to start"
# cp 16S/parameters_swarm.tsv 16S/parameters.tsv
# docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 rm -rf /mnt/analysis/test_16S*
# docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
# rm 16S/parameters.tsv
# echo "PEMA for 18S using Swarm and Silva db has been completed"

# # #----------------------------

#  Run example case for 18S using vsearch and Silva db
echo "PEMA for 18S using vsearch and Silva db is about to start"
cp 18S/parameters_vsearch.tsv 18S/parameters.tsv
docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 rm -rf /mnt/analysis/test_18S_vsearch/
docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
rm 18S/parameters.tsv
echo "PEMA for 18S using vsearch and Silva db has been completed"

# ## Run example case for 18S using Swarm and Silva db
# echo "PEMA for 18S using Swarm and Silva db is about to start"
# cp 18S/parameters_swarm.tsv 18S/parameters.tsv
# docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 rm -rf /mnt/analysis/test_18S*
# docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
# rm 18S/parameters.tsv
# echo "PEMA for 18S using Swarm and Silva db has been completed"

# ## Run example case for 18S using vsearcg and PR2 db - when feature available
# cp 18S/parameters_vsearch_pr2.tsv 18S/parameters.tsv
# docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
# rm 18S/parameters.tsv


# #----------------------------

# ## Run example case for COI using Swarm and Midori-1
# echo "PEMA for COI using Swarm and Midori-1 db is about to start"
# cp COI/parameters_midori_1.tsv COI/parameters.tsv
# docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 rm -rf /mnt/analysis/test_COI*
# docker run --rm -v $CWD/COI/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
# rm COI/parameters.tsv
# echo "PEMA for COI using Swarm and Midori-1 db has been completed"

# ## Run example case for COI using Swarm and a custom db (Amvrakikos)





# #----------------------------

# ## Run example case for ITS using Swarm and Unite
# docker run --rm -v $CWD/ITS/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds







