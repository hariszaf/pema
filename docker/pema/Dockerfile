FROM hariszaf/pemabase:published
MAINTAINER Haris Zafeiropoulos haris-zaf@hcmr.gr

# Copy and paste the PEMA script!
WORKDIR /home
COPY PEMA_v1.bds .

# make a source of the .bashrc file
WORKDIR /root
RUN ["/bin/bash", "-c", "-l",  "source /root/.bashrc"]

# Set "home" as my working directory when a container starts
WORKDIR /home
