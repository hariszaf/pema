Bootstrap: docker
From: hariszaf/pema2



%post
export WORKDIR="/home"
echo "export WORKDIR=$WORKDIR" >> $SINGULARITY_ENVIRONMENT
mkdir -p $WORKDIR

echo "export PATH=/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/tools/BDS/.bds" >> $SINGULARITY_ENVIRONMENT 




%runscript
/home/tools/BDS/.bds/bds /home/PEMA.bds
