#!/bin/bash

# Install pema's dependencies 

# emojis -- hehe! :)
# ------
       SMILE="\U0001F60A"
        TADA="\U0001F389"
      ROCKET="\U0001F680"
  GREEN_TICK="\U00002705"
   RED_CROSS="\U0000274C"
  RED_CIRCLE="\U0001F534"
   HOURGLASS="\u23F3"
WHITE_CIRCLE="\u26AA"

# Default values
VERSION_ARG=false
   HELP_ARG=false
  KOFAM_ARG=false
 SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Parse options using getopt
PARSED=$(getopt --options kh --long kofam,help -- "$@")
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to parse options." >&2
  exit 1
fi

# Reorder arguments so they can be processed
eval set -- "$PARSED"

# Loop through options
while true; do
  case "$1" in
    # -k|--kofam)
    #   KOFAM_ARG=true
    #   shift
    #   ;;
    -h|--help)
      HELP_ARG=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unexpected option: $1" >&2
      exit 1
      ;;
  esac
done

# 
echo -e "\n Building conda environment and installing required dependencies to enable pema ${ROCKET} \n\n"

if $HELP_ARG; then
  echo "Usage: bash setup_env.sh [options]"
  echo "  -h, --help     Show this help message"
  echo ""
  echo -e "${RED_CIRCLE} Either conda or miniconda is considered to be available. If not, setup_environment.sh will fail."
  echo -e "${RED_CIRCLE} Make sure you run the script from the root folder of the pema repository."
  exit 0
fi



SETUP_WD=$(pwd)


# ====================================
# Step 1: Set up base Conda environment
# ====================================

# Exit immediately if a command exits with a non-zero status
set -e

# Check if conda is installed
if ! command -v conda &> /dev/null; then
    echo -e "Error: Conda is not installed or not in the PATH. $RED_CROSS"
    exit 1
fi

# Ensure Conda is initialized for the current shell
eval "$(conda shell.bash hook)"
echo -e "$WHITE_CIRCLE conda is available and ready to go!"


# Create and activate the phendb environment
ENV_NAME="pema"

# Check if the environment already exists
if conda info --envs | grep -q "$ENV_NAME"; then
    echo -e "$GREEN_TICK Environment '$ENV_NAME' already exists. Skipping creation."
else
    # NOTE: SPAdes has compatibility issues with Python -- we need to use Python < 3.10 as long as we stinck with SPAdes 3.14.0
    conda create -n $ENV_NAME python=3.9 -y
    echo -e "$GREEN_TICK A conda environment, called $ENV_NAME, has been built."
fi

# Build a hidden folder for pema-related software
INSTALL_DIR=$HOME/.pema/
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# --------------
# Install BDS
# --------------
BDS_DIR="$INSTALL_DIR/.bds"
BDS_TGZ="$INSTALL_DIR/bds_Linux.tgz"

if [[ -x "$BDS_DIR/bds" ]]; then
  echo -e "$GREEN_TICK bds is already installed at $BDS_DIR"
else
  echo -e "$HOURGLASS Installing bds to $BDS_DIR..."
  cp $SETUP_WD/pema_docker_image/pemabase/tools/bds_Linux.tgz "$BDS_TGZ"
  tar -xvzf bds_*.tgz
  rm -f "$BDS_TGZ"
  echo -e "$GREEN_TICK bds installed to $BDS_DIR"
fi

# Add ~/.pema/.bds to PATH if not already included
if [[ ":$PATH:" != *":$HOME/.pema/.bds:"* ]]; then
  echo 'export PATH="$HOME/.pema/.bds:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.pema/.bds:$PATH"
  echo -e "$GREEN_TICK Added ~/.pema/.bds to PATH. Restart your terminal or run: source ~/.bashrc"
fi


# --------------
# INSTALL SOFTWARE 
# --------------

# # Versions
# FASTP=
# FASTQC=
# TRIMMOMATIC=
# VSEARCH=
SPADES=3.14.0


# --------------
# Install fastp
# --------------
if [[ -x ~/.pema/fastp ]]; then
  echo -e "$GREEN_TICK fastp already exists at ~/.pema/fastp"
else
  echo -e "$HOURGLASS fastp not found in ~/.pema/. Downloading..."
  wget http://opengene.org/fastp/fastp -O ~/.pema/fastp && \
  chmod a+x ~/.pema/fastp && \
  echo -e "$GREEN_TICK fastp downloaded to ~/.pema/fastp"
fi


# --------------
# Install fastQC
# --------------
if [[ -x ~/.pema/FastQC ]]; then
  echo -e "$GREEN_TICK fasQC already exists at ~/.pema/FastQC"
else
  wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip 
  unzip fastqc_v0.11.8.zip
  rm fastqc_v0.11.8.zip 
  cd FastQC 
  chmod 755 fastqc
fi

# Add ~/.pema/FastQC/fastqc to PATH if not already included
if [[ ":$PATH:" != *":$HOME/.pema/FastQC:"* ]]; then
  echo 'export PATH="$HOME/.pema/FastQC:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.pema/FastQC:$PATH"
  echo -e "$GREEN_TICK Added ~/.pema/FastQC to PATH. Restart your terminal or run: source ~/.bashrc"
fi


# --------------
# Install VSEARCH
# --------------
if [[ -x ~/.pema/vsearch ]]; then
  echo -e "$GREEN_TICK VSEARCH already exists at ~/.pema/vsearch"
else
  echo -e "$HOURGLASS Installing VSEARCH.."
  wget https://github.com/torognes/vsearch/releases/download/v2.9.1/vsearch-2.9.1-linux-x86_64.tar.gz
  tar -zxvf vsearch-2.9.1-linux-x86_64.tar.gz 
  rm vsearch-2.9.1-linux-x86_64.tar.gz 
  mv vsearch-2.9.1-linux-x86_64 vsearch
fi

# Add ~/.pema/vsearch to PATH if not already included
if [[ ":$PATH:" != *":$HOME/.pema/vsearch:"* ]]; then
  echo 'export PATH="$HOME/.pema/vsearch:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.pema/vsearch:$PATH"
  echo -e "$GREEN_TICK Added ~/.pema/vsearch to PATH. Restart your terminal or run: source ~/.bashrc"
fi


# --------------
# Install Trimmomatic
# --------------
if [[ -x ~/.pema/Trimmomatic-0.38 ]]; then
  echo -e "$GREEN_TICK Trimmomatic already exists at ~/.pema/fastp"
else
  echo -e "$HOURGLASS Installing Trimmomatic.."
  wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.38.zip
  unzip Trimmomatic-0.38.zip
  rm Trimmomatic-0.38.zip
fi

# --------------
# Install SPAdes
# --------------
if [[ -x ~/.pema/SPAdes-$SPADES-Linux ]]; then
  echo -e "$GREEN_TICK SPAdes already exists at ~/.pema/SPAdes-$SPADES-Linux"
else
  echo -e "$HOURGLASS Getting SPAdes binary.."
  wget https://github.com/ablab/spades/releases/download/v$SPADES/SPAdes-$SPADES-Linux.tar.gz
  tar -xzf SPAdes-$SPADES-Linux.tar.gz
  rm SPAdes-$SPADES-Linux.tar.gz 
  echo -e "$GREEN_TICK SPAdes is now installed."
fi

# Add ~/.pema/SPAdes to PATH if not already included
if [[ ":$PATH:" != *":$HOME/.pema/SPAdes-$SPADES-Linux/bin:"* ]]; then
  echo "export PATH="$HOME/.pema/SPAdes-$SPADES-Linux/bin:$PATH"" >> ~/.bashrc
  export PATH="$HOME/.pema/SPAdes-$SPADES-Linux/bin:$PATH"
  echo -e "$GREEN_TICK Added ~/.pema/SPAdes-$SPADES-Linux/bin to PATH. Restart your terminal or run: source ~/.bashrc"
fi




# --------------
# Install PANDASEQ
# --------------
if [[ -x ~/.pema/pandaseq ]]; then
  echo -e "$GREEN_TICK PANDAseq already exists at ~/.pema/pandaseq"
else
  echo -e "$HOURGLASS Installing PANDAseq..."
  git clone http://github.com/neufeld/pandaseq.git
  cd pandaseq && ./autogen.sh
  ./configure --prefix=$INSTALL_DIR"/PANDAseq"
  make
  make install
  chmod -R +777 /home/tools/PANDAseq/pandaseq/.libs/
  cd ..
  echo -e "$GREEN_TICK PANDAseq was installed"
fi

# Add ~/.pema/PANDAseq to PATH if not already included
if [[ ":$PATH:" != *":$HOME/.pema/PANDAseq/bin:"* ]]; then
  echo "export PATH="$HOME/.pema/PANDAseq/bin:$PATH"" >> ~/.bashrc
  export PATH="$HOME/.pema/PANDAseq/bin:$PATH"
  echo -e "$GREEN_TICK Added ~/.pema/PANDAseq/bin to PATH. Restart your terminal or run: source ~/.bashrc"
fi






# Add ~/.pema to PATH if not already included
if [[ ":$PATH:" != *":$HOME/.pema:"* ]]; then
  echo 'export PATH="$HOME/.pema:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.pema:$PATH"
  echo -e "$GREEN_TICK Added ~/.pema to PATH. Restart your terminal or run: source ~/.bashrc"
fi
# Move back to the setup directory
cd $SETUP_WD



source $HOME/.bashrc
