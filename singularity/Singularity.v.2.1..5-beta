# Build Singularity container based on the PEMA Docker image

# Set base image
Bootstrap: docker
From: hariszaf/pema:v.2.1.5-beta

# Set Singularity environment
%post
export WORKDIR="/home"
echo "export WORKDIR=$WORKDIR" >> $SINGULARITY_ENVIRONMENT
mkdir -p $WORKDIR

#pip install ncbi-taxonomist
#echo "export PATH=${PATH}:$HOME/.local/bin" >> ~/.bashrc 

# Exports needed
echo "export PATH=/usr/lib/jvm/java-8-openjdk-amd64/bin:/usr/lib/jvm/java-11-openjdk-amd64/bin:/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/tools/BDS/.bds:/bin/gzip:/root/miniconda3/bin/ncbi-taxonomist" >> $SINGULARITY_ENVIRONMENT 
#echo "export PATH=$PATH:/bin/gzip" >> ~/.bashrc 


# Set basecommnad; run PEMA analysis
%runscript
/home/tools/BDS/.bds/bds /home/pema_latest.bds
