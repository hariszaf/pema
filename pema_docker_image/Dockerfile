FROM hariszaf/pemabase:v.2.0.1
MAINTAINER Haris Zafeiropoulos haris-zaf@hcmr.gr

# Copy and paste the manually written scripts that PEMA needs
WORKDIR /home/scripts
COPY /scripts/ ./

# Copy and paste the PEMA script!
WORKDIR /home
COPY pema_latest.bds .

# make a source of the .bashrc file
WORKDIR /root

RUN ["/bin/bash", "-c", "-l",  "source /root/.bashrc"]

RUN export PATH=$PATH:/home/tools/BDS/.bds
ENV PATH=$PATH:/home/tools/BDS/.bds




RUN pip3 uninstall -y cutadapt
#RUN apt install python3-cutadapt



# Updating Ubuntu packages
RUN apt-get update && yes|apt-get upgrade

# Adding wget and bzip2
RUN apt-get install -y wget bzip2

# Anaconda installing
RUN wget https://repo.continuum.io/archive/Anaconda3-5.0.1-Linux-x86_64.sh
RUN bash Anaconda3-5.0.1-Linux-x86_64.sh -b
RUN rm Anaconda3-5.0.1-Linux-x86_64.sh

# Set path to conda
ENV PATH /root/anaconda3/bin:$PATH

# Updating Anaconda packages
RUN conda update conda
#RUN conda update anaconda
#RUN conda update --all


# FROM STACKOVERFLOW
RUN conda install --force-reinstall anaconda
RUN conda update --all


# Get cutadapt
RUN conda install -c bioconda cutadapt





# Set "home" as my working directory when a container starts
WORKDIR /home
