FROM ubuntu:16.04 
MAINTAINER Haris Zafeiropoulos haris-zaf@hcmr.gr


#### Now I am about to build the PEMA base image. 
#### When you are about to build the final image containing the PEMA.bds script, 
#### just comment in the line 280 of this Dockerfile.

## Here is all JAVA 11 !

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


##### testing fixing "core dump"

RUN ulimit -c unlimited

#############################   This is where JAVA installation is completed!!   ######################################


## Some extras just in case
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

#####################################################################
#####################################################################

#  Now I start build on the PEMA part

# Create a folder where all PEMA tools are gonna be
RUN mkdir tools
WORKDIR /home/tools


### Downloading and installing all tools necessary

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
RUN wget http://cab.spbu.ru/files/release3.13.0/SPAdes-3.13.0-Linux.tar.gz && tar -zxvf SPAdes-3.13.0-Linux.tar.gz && rm SPAdes-3.13.0-Linux.tar.gz

# Download and install PANDAseq
WORKDIR /home/tools
RUN mkdir PANDAseq
WORKDIR /home/tools/PANDAseq
RUN git clone http://github.com/neufeld/pandaseq.git && cd pandaseq && ./autogen.sh && ./configure --prefix="/home/tools/PANDAseq"&& make && make install
RUN chmod -R +777 /home/tools/PANDAseq/pandaseq/.libs/ 

# Install OBITools
WORKDIR /home/tools
RUN apt-get update && apt-get install -y apt-transport-https
RUN apt-get install -y cython3
RUN apt-get install -y python-pip

#RUN wget https://pythonhosted.org/OBITools/_downloads/get-obitools.py

RUN wget https://git.metabarcoding.org/obitools/obitools/raw/master/get_obitools/get-obitools.py
RUN python get-obitools.py && rm get-obitools.py
RUN rm obitools


# Download and install NCBI
WORKDIR /home/tools
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.8.1/ncbi-blast-2.8.1+-x64-linux.tar.gz && \
        tar -zxvf ncbi-blast-2.8.1+-x64-linux.tar.gz && rm ncbi-blast-2.8.1+-x64-linux.tar.gz

# Download and install CREST & LCAClassifier
# To do that, we first need to make through with "setuptools" Python package. We need a version until 33.1.1.
WORKDIR /home/tools/CREST
RUN apt-get remove -y --purge python-setuptools
RUN pip install setuptools==33.1.1
## there is a crucial issue with the CREST web-server. we make that work another way.
## the true download commands are in the end of that script commented out. 

# The true download commands for CREST:
#RUN git clone https://github.com/lanzen/CREST.git 
#RUN cd CREST/LCAClassifier && bash install.sh
### Here what's happening: the SURVER of CREST has an issue and does not allow us to download silvadatabase!   For that... we will do it on our own! :P   In case they fix it, the upper connands should be executed instead of the following COPY, in order to get the latest versions of both the classifier and the databases!!
COPY /tools/CREST/ ./																


# Download and install PaPaRa software
WORKDIR /home/tools
WORKDIR /home/tools/PaPaRa
RUN wget https://sco.h-its.org/exelixis/resource/download/software/papara_nt-2.5-static_x86_64.tar.gz
RUN tar -zxvf papara_nt-2.5-static_x86_64.tar.gz && rm papara_nt-2.5-static_x86_64.tar.gz

# Download and install EPA-ng
WORKDIR /home/tools
WORKDIR /home/tools/EPA-ng
RUN git clone --recursive https://github.com/Pbdas/epa.git 
RUN apt-get install --"yes" autotools-dev libtool flex bison cmake automake autoconf
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

## if i have R on my image already, i need to remove everything of it, so:
RUN apt-get remove -y r-base-core

## if i do NOT have any R version, i can skip the previous command
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


# some packages mendatory for phyloseq 
RUN Rscript -e 'install.packages("vegan", repos="https://cran.rstudio.com")'
#RUN Rscript -e 'install.packages("biom", repos="https://cran.rstudio.com")'


# install R packages for PEMA to run all its features 
RUN Rscript -e 'install.packages("dplyr", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("tidyr", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("BiocManager", repos="https://cran.rstudio.com")'
RUN Rscript -e 'install.packages("RColorBrewer", repos="https://cran.rstudio.com")'

# download and install phyloseq
#RUN Rscript -e "source('http://bioconductor.org/biocLite.R');biocLite('phyloseq')"
RUN Rscript -e 'library(BiocManager); BiocManager::install("phyloseq")'

# Install cutadapt (for the ITS marker gene case)
# First I need to install pip3
RUN apt update
RUN apt install -y python3-pip
RUN pip3 install cutadapt

# Install R package required for cutadapt R script
RUN apt-get install -y libjpeg-dev
RUN Rscript -e 'library(BiocManager); BiocManager::install("ShortRead")'


# Copy and paste the manually written scripts that PEMA needs
WORKDIR /home/scripts 
COPY /scripts/ ./

## Copy and paste the PEMA script!
#WORKDIR /home
#COPY PEMA_v1.bds .

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

# Copy and paste the Midori database
WORKDIR /home/tools/midori
COPY /tools/midori/ ./

# Copy and install RDPTools
WORKDIR /home/tools/RDPTools
COPY /tools/RDPTools/ ./

# Download and install RDPClassifier
#WORKDIR /home/tools
#RUN git clone https://github.com/rdpstaff/RDPTools.git && cd RDPTools/ && git submodule init && git submodule update && make


##############################################			 TRULY IMPORTANT COMMAND !!!!!			#######################################################
#  Change the root password by nothing at all.
RUN echo "root:Docker!" | chpasswd
#######################################################################################################################################################


# Download and install Big Data Script language (BDS) - in this Dockerfile, BDS 0.9999 is called, so JAVA 11 is NOT necessary
WORKDIR /home/tools/BDS
COPY /tools/bds_Linux.tgz ./
RUN tar -xvzf bds_*.tgz 
RUN echo "export PATH=$PATH:/home/tools/BDS/.bds" >> /root/.bashrc
RUN rm bds_Linux.tgz

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


# make all needed for R
WORKDIR /home
RUN touch .Renviron
RUN echo "export R_LIBS=/home/R_libs/" >> .Renviron
COPY /R_libs/ .

# we need MAFFT to align our OTUs
WORKDIR /home/tools
RUN wget https://mafft.cbrc.jp/alignment/software/mafft_7.427-1_amd64.deb
RUN dpkg -i mafft_7.427-1_amd64.deb


##  fixing java
RUN  apt-get install -y libhsdis0-fcml

# make a source of the .bashrc file
WORKDIR /root
RUN ["/bin/bash", "-c", "-l",  "source /root/.bashrc"]


# Set "home" as my working directory when a container starts
WORKDIR /home



##########################################################################################################
#													 													 #	
#					the Dockerfile ends here!					 										 #
#													 													 #
##########################################################################################################
