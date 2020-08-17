FROM hariszaf/pemabase:noscripts
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

# Set "home" as my working directory when a container starts
WORKDIR /home
