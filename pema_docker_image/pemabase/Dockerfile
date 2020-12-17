# This is the Dockerfile for building the base image for the PEMA workflow

# To build the actual PEMA image, you may use this as a source, i.e FROM hariszaf/pemabase

# You won't be able to run PEMA using this image by itself


# Kernel and maintainer 
FROM ubuntu:16.04 
MAINTAINER Haris Zafeiropoulos \
           haris-zaf@hcmr.gr

# Set the environment

# Get JAVA versions 8 and 11 

RUN rm -rf /var/lib/apt/lists/* && apt-get clean && apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update
RUN apt-get install -y software-properties-common
RUN apt-get update

RUN  add-apt-repository ppa:openjdk-r/ppa
RUN  apt-get update -q

RUN apt-get install -y openjdk-8-jdk
RUN  apt-get install -y openjdk-11-jdk

ENV JAVA_HOME /usr/lib/jvm/java-11-oracle 
ENV PATH="/opt/java/openjdk/bin:$PATH"

ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport"
RUN export JAVA_HOME

RUN ulimit -c unlimited             # testing fixing "core dump"


# Some extras just in case
RUN apt-get update && apt-get install -y ant && apt-get clean;
RUN apt-get update && apt-get install ca-certificates-java && apt-get clean && update-ca-certificates -f;

# Install all necessary labs and programs to set up our Docker Image
WORKDIR /home
RUN apt-get update --fix-missing && apt-get install -y wget bzip2 libbz2-dev liblzma-dev libcurl4-openssl-dev \
    ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial subversion unzip autoconf autogen libtool zlib1g-dev

# Download GNU
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install gcc mono-mcs && \
    rm -rf /var/lib/apt/lists/*

# Let "git" do as it wants for 15 times
RUN git config --global credential.helper cache

# Some necessary programs
RUN apt-get update -y 
RUN apt-get install --"yes" autotools-dev libtool flex bison cmake automake autoconf

#------------------------------------------------------------

#  Building the PEMA-related part

# Create a folder where all PEMA tools are gonna be
RUN mkdir tools
WORKDIR /home/tools

# Download and install FastQC
RUN mkdir fastqc
WORKDIR /home/tools/fastqc
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip && unzip fastqc_v0.11.8.zip && rm fastqc_v0.11.8.zip \
        && cd FastQC/ && chmod 755 fastqc

# Download and install VSEARCH
WORKDIR /home/tools
RUN mkdir VSEARCH
WORKDIR /home/tools/VSEARCH
RUN wget https://github.com/torognes/vsearch/releases/download/v2.9.1/vsearch-2.9.1-linux-x86_64.tar.gz \
        && tar -zxvf vsearch-2.9.1-linux-x86_64.tar.gz && rm vsearch-2.9.1-linux-x86_64.tar.gz 

# Download and install Trimmomatic
WORKDIR /home/tools
RUN mkdir Trimmomatic
WORKDIR /home/tools/Trimmomatic
RUN wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.38.zip && unzip Trimmomatic-0.38.zip \
        && rm Trimmomatic-0.38.zip

# Download and install SPAdes
WORKDIR /home/tools
RUN mkdir SPAdes
WORKDIR /home/tools/SPAdes
#RUN wget http://cab.spbu.ru/files/release3.13.0/SPAdes-3.13.0-Linux.tar.gz && tar -zxvf SPAdes-3.13.0-Linux.tar.gz && rm SPAdes-3.13.0-Linux.tar.gz
# 2020.12.14 Upgrade to SPAdes 3.14.0 and install from source code
RUN wget http://cab.spbu.ru/files/release3.14.0/SPAdes-3.14.0.tar.gz  && tar -xzf SPAdes-3.14.0.tar.gz && cd SPAdes-3.14.0 && ./spades_compile.sh


# Download and install PANDAseq
WORKDIR /home/tools
RUN mkdir PANDAseq
WORKDIR /home/tools/PANDAseq
RUN git clone http://github.com/neufeld/pandaseq.git && cd pandaseq && ./autogen.sh && ./configure --prefix="/home/tools/PANDAseq"&& make && make install
RUN chmod -R +777 /home/tools/PANDAseq/pandaseq/.libs/ 

# Install OBITools // following the instructions described here: https://www.biostars.org/p/235898/
WORKDIR /home/tools
RUN apt-get update -y
RUN apt-get install -y python-virtualenv
RUN mkdir OBI && cd OBI && virtualenv OBI-env
# Get and extract the source
RUN wget 'https://git.metabarcoding.org/obitools/obitools/repository/archive.tar.gz?ref=master'
RUN tar -zxvf "archive.tar.gz?ref=master"
# Activate the virtual env
WORKDIR /home/tools/OBI
RUN /bin/bash -c "source OBI-env/bin/activate ; \
 pip install sphinx==1.4.8 ; \
 cd obitools-master-* ; \
 python setup.py build ; \
 python setup.py install ; \
 deactivate"

# At this point the software should be installed within the OBI directory, just add the bin directory in your PATH
# Add this line in your .bashrc to enable the OBITools
RUN export PATH=${PATH}:"~/OBI/OBI-env/bin"

# Download and install NCBI
WORKDIR /home/tools
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.8.1/ncbi-blast-2.8.1+-x64-linux.tar.gz && \
        tar -zxvf ncbi-blast-2.8.1+-x64-linux.tar.gz && rm ncbi-blast-2.8.1+-x64-linux.tar.gz

# Download and install PaPaRa software
WORKDIR /home/tools
WORKDIR /home/tools/PaPaRa
RUN wget https://sco.h-its.org/exelixis/resource/download/software/papara_nt-2.5-static_x86_64.tar.gz
RUN tar -zxvf papara_nt-2.5-static_x86_64.tar.gz && rm papara_nt-2.5-static_x86_64.tar.gz

# Download and install EPA-ng
WORKDIR /home/tools
WORKDIR /home/tools/EPA-ng
RUN git clone --recursive https://github.com/Pbdas/epa.git 
#RUN apt-get install --"yes" autotools-dev libtool flex bison cmake automake autoconf
RUN cd epa && make

# Download and install SWARM clustering algoritm
WORKDIR /home/tools/swarm
RUN git clone https://github.com/torognes/swarm.git && cd swarm/src/ && make && cd ../bin/

# Download and install CROP and all necessary for that
WORKDIR /home/tools/CROP
RUN apt-get install -y libgsl-dev
RUN git clone https://github.com/tingchenlab/CROP.git &&  cd CROP && make 

# Install of "locate" program that allows to find where is what on your container
RUN apt-get install mlocate && updatedb
RUN apt update
RUN apt install -y python3-pip

# Install cutadapt (for the ITS marker gene case)
RUN pip3 install cutadapt
RUN apt-get install -y libjpeg-dev

# Get the "setuptools" Python package. We need a version until 33.1.1.
WORKDIR /app
ADD . /app
RUN set -xe \
    && apt-get update \
    && apt-get install -y python-pip

RUN pip install --upgrade pip
RUN apt-get remove -y --purge python-setuptools
RUN pip install setuptools==33.1.1



###############                  RDPTools - CLASSIFIER                  ##############

# We have already trained the RDPClassifier with the MIDORI database (version: MIDORI_LONGEST_1.1)
# So we copy our local version of RDPTools on the image:
WORKDIR /home/tools/RDPTools
COPY /tools/RDPTools/ ./

## If you need the PEMAbase container without this training, you shall mute the 2 previous commands.
## and run the following block of commands instead, i.e lines 181-195 (now muted).
## For the following, check also on this tutorial: https://john-quensen.com/tutorials/tutorial-1/

## Get the dependencies, set the environment, download and install RDPClassifier
#RUN apt-get install hmmer
#
#ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64 
#ENV PATH="PATH=${JAVA_HOME}/bin:${PATH}"
#RUN export JAVA_HOME
#RUN export PATH
#
## Now go for getting the RDPClassifier
#WORKDIR /usr/local
#RUN git clone https://github.com/rdpstaff/RDPTools.git 
#WORKDIR RDPTools
#RUN git submodule init 
#RUN git submodule update
#RUN make

##############                  RDPTools - CLASSIFIER                  ##############


################                  CREST  CLASSIFIER                  ################

## On 2020.12.14 the CREST team fixed a crucial issue with the CREST web-server they used to have.
## However, we copy the CREST we have locally to add the trainings we have already done on it on the PEMAbase image.
WORKDIR /home/tools/CREST
COPY /tools/CREST/ ./

## If you need the PEMAbase container without these trainings, you shall run the 2 next commands (muted now) and mute the 2 previous ones.
#RUN git clone https://github.com/lanzen/CREST.git 
#RUN cd CREST/LCAClassifier && bash install.sh

################                  CREST  CLASSIFIER                  ################



# Copy and paste the manually the Easy Trees that PEMA needs for the phylogenetic taxonomy assignment
WORKDIR /home/tools/createTreeTheEasyWay
COPY /createTreeTheEasyWay/ ./

# Make an extra folder to keep any database from the user
WORKDIR /mnt/
RUN mkdir analysis
RUN mkdir databases

# We need to be sure that in the directory to mount, all permissions are set properly.
RUN chmod 777 /mnt/analysis
RUN chmod g+s /mnt/analysis

# Download and install "nano" editor.
RUN apt-get update 
RUN apt-get install -y apt-transport-https
#RUN apt-get update
WORKDIR /home
RUN apt-get install -y nano --fix-missing

# In order to compile, BDS needs the "go" program. Here, we download and install "go".
WORKDIR /usr/local
RUN wget https://dl.google.com/go/go1.11.2.linux-amd64.tar.gz
RUN tar -xzf go1.11.2.linux-amd64.tar.gz && rm go1.11.2.linux-amd64.tar.gz && export PATH=$PATH:/usr/local/go/bin

# Download and install GAWK 4
WORKDIR /home/tools
RUN wget https://ftp.gnu.org/gnu/gawk/gawk-4.2.1.tar.gz && tar -xvpzf gawk-4.2.1.tar.gz
RUN rm gawk-4.2.1.tar.gz && cd gawk-4.2.1/ && ./configure && make && make install  


# Remove everything R-related:
RUN apt-get remove -y r-base-core

# Set the R environment
RUN apt-get install -y gfortran
RUN apt-get install -y build-essential
RUN apt-get install -y fort77
RUN apt-get install -y xorg-dev
RUN apt-get install -y liblzma-dev libblas-dev gfortran
RUN apt-get install -y gcc-multilib
RUN apt-get install -y gobjc++
RUN apt-get install -y aptitude
RUN aptitude install -y libreadline-dev
RUN apt-get install libbz2-dev

RUN export CC=/usr/bin/gcc
RUN export CXX=/usr/bin/g++
RUN export FC=/usr/bin/gfortran
RUN export PERL=/usr/bin/perl

RUN apt-get install -y libpcre3-dev libpcre2-dev libpcre-ocaml-dev libghc-regex-pcre-dev

# At last, get R!
WORKDIR /home
RUN apt-get install -y xorg-dev
RUN wget https://ftp.cc.uoc.gr/mirrors/CRAN/src/base/R-3/R-3.6.0.tar.gz
RUN tar -xf R-3.6.0.tar.gz
WORKDIR /home/R-3.6.0
RUN ./configure 
RUN make
RUN make install


# Packages mendatory for Phyloseq 
RUN Rscript -e 'install.packages("vegan", repos="https://cran.rstudio.com")'

# Install R packages for PEMA to run all its features 
RUN Rscript -e 'install.packages("dplyr", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("tidyr", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("BiocManager", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("RColorBrewer", repos="https://cran.rstudio.com")'

# Download and install phyloseq
#RUN Rscript -e "source('http://bioconductor.org/biocLite.R');biocLite('phyloseq')"
RUN Rscript -e 'library(BiocManager); BiocManager::install("phyloseq")'

# Install R package required for cutadapt R script
RUN Rscript -e 'library(BiocManager); BiocManager::install("ShortRead")'


##############################################			 TRULY IMPORTANT COMMAND !!!!!			#######################################################
#  Change the root password by nothing at all.
RUN echo "root:Docker!" | chpasswd
#######################################################################################################################################################


# Download and install Big Data Script language (BDS) - in this Dockerfile, BDS 0.9999 is called, so JAVA 11 is NOT necessary
WORKDIR /home/tools/BDS
RUN wget https://github.com/pcingola/BigDataScript/blob/master/distro/bds_Linux.tgz?raw=true
RUN tar -xvzf bds_Linux*
RUN echo "export PATH=$PATH:/home/tools/BDS/.bds" >> /root/.bashrc

# Download and install RAxML-ng
WORKDIR /
RUN apt-get install cmake
RUN apt-get install -y libgmp3-dev

WORKDIR /home/tools/raxml-ng
RUN git clone --recursive https://github.com/amkozlov/raxml-ng
RUN cd raxml-ng
RUN mkdir build && cd build
WORKDIR /home/tools/raxml-ng/raxml-ng/build
RUN cmake -DUSE_MPI=ON ..
RUN make


# R necessary modifs
WORKDIR /home
RUN touch .Renviron
RUN echo "export R_LIBS=/home/R_libs/" >> .Renviron
COPY /R_libs/ .

# Get Mafft for alignment related tasks
WORKDIR /home/tools
RUN wget https://mafft.cbrc.jp/alignment/software/mafft_7.427-1_amd64.deb
RUN dpkg -i mafft_7.427-1_amd64.deb


# Fixing java
RUN  apt-get install -y libhsdis0-fcml

# Make a source of the .bashrc file
WORKDIR /root
RUN ["/bin/bash", "-c", "-l",  "source /root/.bashrc"]


# Set "home" as my working directory when a container starts
WORKDIR /home


###################################################################
#													 			  #	
#					the Dockerfile ends here!					  #
#  	     	 													  #
###################################################################