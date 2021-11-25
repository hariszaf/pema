#!/bin/bash

# This sanity checks allows to have an overview of the PEMA modules
# what works well and what does not.
# Can be used to test whether a new feture causes any issues or not.
# Should be always run before a new version is to be released.

CWD=$(pwd)

## Run example case for 16S using vsearch
rm -rf 16S/test_16S*
cp 16S/parameters_vsearch.tsv 16S/parameters.tsv
docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
rm 16S/parameters.tsv

# ## Run example case for 16S using Swarm
# cp 16S/parameters_swarm.tsv 16S/parameters.tsv
# docker run --rm -v $CWD/16S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
# rm 16S/parameters.tsv

# #----------------------------

# ##  Run example case for 18S using vsearch and Silva db
# rm -rf test_18S*
# cp 18S/parameters_vsearch.tsv 18S/parameters.tsv
# docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:v.2.1.3 ./pema_latest.bds
# rm 18S/parameters.tsv

# ## Run example case for 18S using Swarm and Silva db
# cp 18S/parameters_swarm.tsv 18S/parameters.tsv
# docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
# rm 18S/parameters.tsv

# ## Run example case for 18S using vsearcg and PR2 db
# cp 18S/parameters_vsearch_pr2.tsv 18S/parameters.tsv
# docker run --rm -v $CWD/18S/:/mnt/analysis/ hariszaf/pema:v.2.1.4 ./pema_latest.bds
# rm 18S/parameters.tsv


# #----------------------------

# ## Run example case for COI using Swarm and Midori-1
# rm -rf test_COI*
# cp COI/parameters_swarm.tsv 18S/parameters.tsv
# docker run --rm -v $CWD/COI/:/mnt/analysis/ hariszaf/pema:v.2.1.3 ./pema_latest.bds
# rm COI/parameters.tsv


# ## Run example case for COI using Swarm and a custom db (Amvrakikos)




# #----------------------------

# ## Run example case for ITS using Swarm and Unite
# docker run --rm -v $CWD/ITS/:/mnt/analysis/ hariszaf/pema:v.2.1.3 ./pema_latest.bds







