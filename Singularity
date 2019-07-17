### Unmute the 2 following lines, to put on the Singularity image
Bootstrap: docker
From: hariszaf/pema:v1


%post
export WORKDIR="/home"
echo "export WORKDIR=$WORKDIR" >> $SINGULARITY_ENVIRONMENT
mkdir -p $WORKDIR

echo "export PATH=/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/tools/BDS/.bds" >> $SINGULARITY_ENVIRONMENT 
echo "export PATH=$PATH:/bin/gzip" >> ~/.bashrc 


%runscript

/home/tools/BDS/.bds/bds /home/PEMA_v1.bds
