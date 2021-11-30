# PEMA: a flexible Pipeline for Environmental DNA Metabarcoding Analysis 
# of the 16S/18S ribosomal RNA, ITS, and COI marker genes. GigaScience. 2020 Mar;9(3):giaa022.
# 
# Aim:   Build the base of the PEMA environment 
#        This base image will be used for the FROM statement  
#        when building the actual PEMA docker image
# 
# Usage: docker build -t hariszaf/pemabase:<tag> .

FROM ubuntu:16.04 
MAINTAINER Haris Zafeiropoulos haris-zaf@hcmr.gr

## Set Java envs

RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends curl ca-certificates && \ 
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-get update

RUN  add-apt-repository ppa:openjdk-r/ppa && \
    apt-get update -q

RUN apt-get install -y openjdk-8-jdk
RUN apt-get install -y openjdk-11-jdk

ENV JAVA_HOME /usr/lib/jvm/java-11-oracle 
ENV PATH="/opt/java/openjdk/bin:$PATH"

ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport"
RUN export JAVA_HOME


## Fixing "core dump"

RUN ulimit -c unlimited

#-------   This is where JAVA installation is completed!!   ---------

## Some extras 
RUN apt-get update && apt-get install -y ant && \
    apt-get clean
RUN apt-get update && apt-get install ca-certificates-java && \
    apt-get clean && \
    update-ca-certificates -f

# Install all necessary labs and programs to set up our Docker Image
WORKDIR /home
RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 libbz2-dev liblzma-dev libcurl4-openssl-dev \
                            libglib2.0-0 libxext6 libsm6 libxrender1 git mercurial \
                            subversion unzip autoconf autogen libtool zlib1g-dev
# Download GNU
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install gcc mono-mcs && \
    rm -rf /var/lib/apt/lists/*

# Let "git" do as it wants for 15 times
RUN git config --global credential.helper cache

#####################################################################
#####################################################################

#  Now I start build on the PEMA part
# Create a folder where all PEMA tools are gonna be
RUN mkdir tools
WORKDIR /home/tools

# ------------------------------   FastQC  --------------------------------

# Download and install FastQC
RUN mkdir fastqc
WORKDIR /home/tools/fastqc
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip && unzip fastqc_v0.11.8.zip && rm fastqc_v0.11.8.zip \
        && cd FastQC/ && chmod 755 fastqc

# ------------------------------   VSEARCH  --------------------------------

# Download and install VSEARCH
WORKDIR /home/tools
RUN mkdir VSEARCH
WORKDIR /home/tools/VSEARCH
RUN wget https://github.com/torognes/vsearch/releases/download/v2.9.1/vsearch-2.9.1-linux-x86_64.tar.gz \
        && tar -zxvf vsearch-2.9.1-linux-x86_64.tar.gz && rm vsearch-2.9.1-linux-x86_64.tar.gz 

# ------------------------------   Trimmomatic  --------------------------------

# Download and install Trimmomatic
WORKDIR /home/tools
RUN mkdir Trimmomatic
WORKDIR /home/tools/Trimmomatic
RUN wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.38.zip && unzip Trimmomatic-0.38.zip \
        && rm Trimmomatic-0.38.zip

# ------------------------------   SPAdes  --------------------------------

# Download and install SPAdes
WORKDIR /home/tools
RUN mkdir SPAdes
WORKDIR /home/tools/SPAdes
RUN wget http://cab.spbu.ru/files/release3.13.0/SPAdes-3.13.0-Linux.tar.gz && tar -zxvf SPAdes-3.13.0-Linux.tar.gz && rm SPAdes-3.13.0-Linux.tar.gz

# ------------------------------   PANDAseq  --------------------------------

# Download and install PANDAseq
WORKDIR /home/tools
RUN mkdir PANDAseq
WORKDIR /home/tools/PANDAseq
RUN git clone http://github.com/neufeld/pandaseq.git && cd pandaseq && ./autogen.sh && ./configure --prefix="/home/tools/PANDAseq"&& make && make install
RUN chmod -R +777 /home/tools/PANDAseq/pandaseq/.libs/ 


# ------------------------------   OBITools  [START]  --------------------------------

WORKDIR /home/tools
RUN apt-get update && apt-get install -y apt-transport-https && \
    apt-get install -y cython3 && \
    apt-get install -y python-pip

# Install Miniconda 
WORKDIR /home
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && bash Miniconda3-latest-Linux-x86_64.sh -b
ENV PATH=/root/miniconda3/bin:${PATH} 

# Get venv
RUN apt-get install -y python3-dev
RUN pip install virtualenv && \
    apt install -y python3-venv

# Get cmake
RUN apt update &&\
    apt purge --auto-remove cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.21.4/cmake-3.21.4.tar.gz &&\
    tar -xzvf cmake-3.21.4.tar.gz

# Get an OpenSSl
RUN apt-get install -y libssl-dev 

# Install cmake
WORKDIR /home/cmake-3.21.4
RUN /bin/bash bootstrap
RUN make -j$(nproc) 
RUN make install

# Install OBITools3
# Based on https://git.metabarcoding.org/obitools/obitools3/wikis/Installing-the-OBITools3
WORKDIR /home
RUN	python3 -m venv obi3-env
RUN /bin/bash -c "source obi3-env/bin/activate && pip3 install --upgrade pip setuptools wheel Cython &&  pip3 install --pre --upgrade OBITools3"

# --------------------------------   OBITools [END]    --------------------------------


# ------------------------------   NCBI tools   --------------------------------

# Download and install NCBI tools
WORKDIR /home/tools
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.8.1/ncbi-blast-2.8.1+-x64-linux.tar.gz && \
    tar -zxvf ncbi-blast-2.8.1+-x64-linux.tar.gz && rm ncbi-blast-2.8.1+-x64-linux.tar.gz

# ------------------------------   PaPaRa   --------------------------------

# Download and install PaPaRa software
WORKDIR /home/tools
WORKDIR /home/tools/PaPaRa
RUN wget https://sco.h-its.org/exelixis/resource/download/software/papara_nt-2.5-static_x86_64.tar.gz && \
    tar -zxvf papara_nt-2.5-static_x86_64.tar.gz && rm papara_nt-2.5-static_x86_64.tar.gz

# ------------------------------   EPA-ng   --------------------------------

# Download and install EPA-ng
WORKDIR /home/tools
WORKDIR /home/tools/EPA-ng
RUN git clone --recursive https://github.com/Pbdas/epa.git && \
    apt-get install --"yes" autotools-dev flex bison automake && \
    cd epa && \
    make

# ------------------------------   RAxML-ng   --------------------------------

## Download and install RAxML-ng
WORKDIR /
RUN apt-get install -y libgmp3-dev

WORKDIR /home/tools/raxml-ng
RUN git clone --recursive https://github.com/amkozlov/raxml-ng
RUN cd raxml-ng && \
    mkdir build && \
    cd build
WORKDIR /home/tools/raxml-ng/raxml-ng/build
RUN cmake -DUSE_MPI=ON .. && \
    make

# --------------------------------   SWARM   --------------------------------

# Download and install SWARM clustering algoritm
WORKDIR /home/tools/swarm
RUN git clone https://github.com/torognes/swarm.git && cd swarm/src/ && make && cd ../bin/

# --------------------------------   MAFFT   --------------------------------
# Install MAFFT to align our OTUs
WORKDIR /home/tools
RUN wget https://mafft.cbrc.jp/alignment/software/mafft_7.427-1_amd64.deb
RUN dpkg -i mafft_7.427-1_amd64.deb

# ------------------------------   Cutadapt   -------------------------------

# Install cutadapt (for the ITS marker gene case)
# First I need to install pip3
RUN apt update && \
    apt install -y python3-pip && \
    apt install python3-cutadapt


# -------------------------------   CREST   ---------------------------------

WORKDIR /home/tools
RUN wget https://zenodo.org/record/5734317/files/crest.tar.gz && \
    tar -zxvf crest.tar.gz && \
    rm crest.tar.gz

# Alternative: new CREST now available
# RUN conda install -c bioconda -c conda-forge -c xapple crest4


# --------------------------------  RPDTools  --------------------------------
# # Copy and install RDPTools
# WORKDIR /home/tools/RDPTools
# COPY /tools/RDPTools/ ./

WORKDIR /home/tools
RUN wget https://zenodo.org/record/5734317/files/rdptools.tar.gz && \
    tar -zxvf rdptools.tar.gz && \
    rm rdptools.tar.gz


# -------------------  ENABLE EDITING AND RUNNING A CONTAINER ----------------
# Download and install "nano" editor.
RUN apt-get update 
RUN apt-get install -y apt-transport-https

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


# -----------------------   SET R ENV     --------------------------------

# Install of "locate" program that allows to find where is what on your container
RUN apt-get install mlocate && updatedb

## if i have R on my image already, i need to remove everything of it, so:
RUN apt-get remove -y r-base-core

## if i do NOT have any R version, i can skip the previous command
RUN apt-get install -y gfortran && \
    apt-get install -y build-essential && \
    apt-get install -y fort77 && \
    apt-get install -y xorg-dev && \
    apt-get install -y libblas-dev 

RUN apt-get install -y gcc-multilib && \
    apt-get install -y gobjc++ && \
    apt-get install -y aptitude && \
    aptitude install -y libreadline-dev

RUN export CC=/usr/bin/gcc && \
    export CXX=/usr/bin/g++ && \
    export FC=/usr/bin/gfortran && \
    export PERL=/usr/bin/perl

RUN apt-get install -y libpcre3-dev libpcre2-dev libpcre-ocaml-dev libghc-regex-pcre-dev


# At last, get R!
WORKDIR /home
# RUN apt-get install -y xorg-dev
RUN wget https://ftp.cc.uoc.gr/mirrors/CRAN/src/base/R-3/R-3.6.0.tar.gz
RUN tar -xf R-3.6.0.tar.gz
WORKDIR /home/R-3.6.0
RUN ./configure 
RUN make
RUN make install


# Some packages mendatory for phyloseq 
#RUN Rscript -e 'install.packages("biom", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("vegan", repos="https://cran.rstudio.com")'

# Install R packages for PEMA to run all its features 
RUN Rscript -e 'install.packages("dplyr", repos="https://cran.rstudio.com")' && \
    Rscript -e 'install.packages("tidyr", repos="https://cran.rstudio.com")' && \
    Rscript -e 'install.packages("BiocManager", repos="https://cran.rstudio.com")' && \
    Rscript -e 'install.packages("igraph", repos="https://cran.rstudio.com")' && \
    Rscript -e 'install.packages("RColorBrewer", repos="https://cran.rstudio.com")'


# Download and install phyloseq
#RUN Rscript -e "source('http://bioconductor.org/biocLite.R');biocLite('phyloseq')"
RUN Rscript -e 'library(BiocManager); BiocManager::install("phyloseq")'


# Install R package required for cutadapt R script
RUN apt-get install -y libjpeg-dev
RUN Rscript -e 'library(BiocManager); BiocManager::install("ShortRead")'


# ---------------    COPY AND PASTE SCRIPTS AND DBs  -------------------

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


# ###############			 TRULY IMPORTANT COMMAND !!!!!			#########################
#  Change the root password by nothing at all.
RUN echo "root:Docker!" | chpasswd
############################################################################################

# Download and install Big Data Script language (BDS) - in this Dockerfile, BDS 0.9999 is called, so JAVA 11 is NOT necessary
WORKDIR /home/tools/BDS
COPY /tools/bds_Linux.tgz ./
RUN tar -xvzf bds_*.tgz 
RUN echo "export PATH=$PATH:/home/tools/BDS/.bds" >> /root/.bashrc
RUN rm bds_Linux.tgz

# Make all needed for R
WORKDIR /home
RUN touch .Renviron
RUN echo "export R_LIBS=/home/R_libs/" >> .Renviron
COPY /R_libs/ .

# Fixing java
RUN  apt-get install -y libhsdis0-fcml


# Install ncbi-taxonomist Python software
RUN pip install ncbi-taxonomist && \
    echo "export PATH=${PATH}:$HOME/.local/bin" >> ~/.bashrc

# Install super conveninet jq library to handle json output of ncbi-taxonomist
# For more about this library, you may see here: https://stedolan.github.io/jq/
RUN apt-get install -y jq

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
