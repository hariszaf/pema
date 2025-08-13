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
# PARSED=$(getopt --options eh --long env,help -- "$@")
PARSED=$(getopt --options eh --long env:,help -- "$@")
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to parse options." >&2
  exit 1
fi

# Reorder arguments so they can be processed
eval set -- "$PARSED"

# Loop through options
# Parse options
while true; do
  case "$1" in
    -h|--help)
      HELP_ARG=true
      shift
      ;;
    -e|--env)
      RUN_ENV="$2"
      shift 2
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

# Validate ENV value and that --env value is provided
if ! $HELP_ARG && [[ -z "$RUN_ENV" ]]; then
  echo -e "$RED_CROSS Error: --env is required; it can take either 'local' or 'container' value."
  exit 1
fi

if [[ -n "$RUN_ENV" && "$RUN_ENV" != "local" && "$RUN_ENV" != "container" ]]; then
  echo -e "$RED_CROSS Error: --env must be either 'local' or 'container'."
  exit 1
fi
 
echo -e "\n Building conda environment and installing required dependencies to enable pema ${ROCKET} \n\n"

if $HELP_ARG; then
  echo "Usage: bash setup_env.sh [options]"
  echo "  -h, --help     Show this help message"
  echo "  -e, --env      Running environment [container, local]"
  echo ""
  echo -e "${RED_CIRCLE} Either conda or miniconda is considered to be available. If not, setup_environment.sh will fail."
  echo -e "${RED_CIRCLE} Make sure you run the script from the root folder of the pema repository."
  exit 0
fi

SETUP_WD=$(pwd)


# ====================================
# Step 0: Set up conda
# ====================================

# Exit immediately if a command exits with a non-zero status
set -e

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo "❌ Error: conda is not available in PATH" >&2
    exit 1
fi

# Initialize Conda for this shell
eval "$(conda shell.bash hook)"
echo -e "$WHITE_CIRCLE conda is available and ready to go!"

# Ensure CONDA_PREFIX is set
if [[ -z "$CONDA_PREFIX" ]]; then
    export CONDA_PREFIX="$(conda info --base)"
    if ! grep -Fxq 'export CONDA_PREFIX="$(conda info --base)"' ~/.bashrc; then
        echo 'export CONDA_PREFIX="$(conda info --base)"' >> ~/.bashrc
    fi
    echo "ℹ️ CONDA_PREFIX set to base env: $CONDA_PREFIX"
fi


get_shell_config() {
    echo "$CONDA_PREFIX/etc/conda/activate.d/env_path.sh"
}

SHELL_CONFIG="$(get_shell_config)"
echo "Shell config path: $SHELL_CONFIG"


# ====================================
# Step 1: Set up base conda env
# ====================================

# Create and activate the phendb environment
ENV_NAME="pema"

# Check if the environment already exists
if conda info --envs | grep -q "$ENV_NAME"; then
    echo -e "$GREEN_TICK Environment '$ENV_NAME' already exists. Skipping creation."
else
    # NOTE: SPAdes has compatibility issues with Python -- we need to use Python < 3.10 as long as we stinck with SPAdes 3.14.0
    # SPADes works fine with Python 3.9
    # yet, OBITools 3 works with 3.7 -- thus, we need a second env 
    conda create -n $ENV_NAME python=3.9 -y
    echo -e "$GREEN_TICK A conda environment, called $ENV_NAME, has been built."
fi

conda activate $ENV_NAME

# Activate case 
mkdir -p $CONDA_PREFIX/etc/conda/activate.d

cat <<EOF > "$CONDA_PREFIX/etc/conda/activate.d/env_vars.sh"
#!/bin/bash
export OLD_PATH="\$PATH"
export PATH="\$HOME/.pema:\$PATH"
EOF

chmod +x "$CONDA_PREFIX/etc/conda/activate.d/env_vars.sh"


# Deactivate case
mkdir -p $CONDA_PREFIX/etc/conda/deactivate.d

cat <<EOF > "$CONDA_PREFIX/etc/conda/deactivate.d/env_vars.sh"
#!/bin/bash
export PATH="\$OLD_PATH"
unset OLD_PATH
EOF

chmod +x "$CONDA_PREFIX/etc/conda/deactivate.d/env_vars.sh"


# ====================================
# Step 2: Install software
# ====================================

# Build a hidden folder for pema-related software
if [[ "$RUN_ENV" == "local" ]]; then
  INSTALL_DIR=$HOME/.pema
  mkdir -p "$INSTALL_DIR"
else
  INSTALL_DIR=/opt
fi
cd "$INSTALL_DIR"

# --------------
# Install BDS
# --------------
if [[ "$RUN_ENV" == "local" ]]; then
  BDS_DIR="$INSTALL_DIR/.bds"
  BDS_TGZ="$INSTALL_DIR/bds_Linux.tgz"

  if [[ -x "$BDS_DIR/bds" ]]; then
    echo -e "$GREEN_TICK bds is already installed at $BDS_DIR"
  else
    echo -e "$HOURGLASS Installing bds to $BDS_DIR..."
    cp $SETUP_WD/pema/ext_data/bds_Linux.tgz "$BDS_TGZ"
    tar -xvzf bds_*.tgz
    rm -f "$BDS_TGZ"
    echo -e "BigDataScript programming language was installed at: $BDS_DIR  $TADA"
  fi

  # Add $INSTALL_DIR/.bds to PATH if not already included
  if [[ ":$PATH:" != *":$INSTALL_DIR/.bds:"* ]]; then
    echo "export PATH=\"$INSTALL_DIR/.bds:\$PATH\"" >> $SHELL_CONFIG
    echo -e "Added ${INSTALL_DIR}/.bds to PATH. $TADA"
  fi
fi

# --------------
# Versions
# --------------
# FASTP=
# FASTQC=
# TRIMMOMATIC=
# VSEARCH=
SWARM=3.1.5        # NOTE: note used so far on the installation process, i.e. would change without noticing
SPADES=3.14.0
RDPCLASSIFIER=2.14
RAXML=1.2.2
CREST_PEMA="https://zenodo.org/record/5734317/files/crest.tar.gz"



SHELL_CONFIG="$(get_shell_config)"
echo "Shell config path: $SHELL_CONFIG"


# --------------
# Install fastp
# --------------
if [[ -x $INSTALL_DIR/fastp ]]; then
  echo -e "$GREEN_TICK fastp already exists at $INSTALL_DIR/fastp"
else
  echo -e "$HOURGLASS fastp not found in $INSTALL_DIR. Downloading..."
  wget http://opengene.org/fastp/fastp -O $INSTALL_DIR/fastp && \
  chmod a+x $INSTALL_DIR/fastp && \
  echo -e "$GREEN_TICK fastp downloaded to $INSTALL_DIR/fastp"
fi


# --------------
# Install fastQC
# --------------
if [[ -x $INSTALL_DIR/FastQC ]]; then
  echo -e "$GREEN_TICK fastQC already exists at $INSTALL_DIR/FastQC"
else
  wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip 
  unzip fastqc_v0.11.8.zip
  # rm fastqc_v0.11.8.zip 
  cd FastQC 
  chmod 755 fastqc
fi

# Add $INSTALL_DIR/FastQC/fastqc to PATH if not already included
if [[ ":$PATH:" != *":$INSTALL_DIR/FastQC:"* ]]; then
  echo "export PATH=\"$INSTALL_DIR/FastQC:\$PATH\"" >> $SHELL_CONFIG
  echo -e "Added $INSTALL_DIR/FastQC to PATH. $TADA"
fi

# --------------
# Install cutadapt
# --------------

pipx install cutadapt
pipx ensurepath


# --------------
# Install  OBItools
# --------------
if [[ -x $INSTALL_DIR/obitools4 ]]; then
  echo -e "$GREEN_TICK obitools4 has been installed."
else
  echo -e "$HOURGLASS Installing Obitools4..."
  mkdir obitools4
  cd obitools4
  wget -L -O install_obitools.sh https://raw.githubusercontent.com/metabarcoding/obitools4/master/install_obitools.sh
  bash install_obitools.sh -i .
  echo "export PATH=\"$INSTALL_DIR/obitools4/bin:\$PATH\"" >> $SHELL_CONFIG
  echo -e "Obitools4 is now added on PATH $TADA"
  cd ..
fi


# --------------
# Install VSEARCH
# --------------
if [[ -x $INSTALL_DIR/vsearch ]]; then
  echo -e "$GREEN_TICK VSEARCH already exists at $INSTALL_DIR/vsearch"
else
  echo -e "$HOURGLASS Installing VSEARCH.."
  wget https://github.com/torognes/vsearch/releases/download/v2.9.1/vsearch-2.9.1-linux-x86_64.tar.gz
  tar -zxvf vsearch-2.9.1-linux-x86_64.tar.gz 
  # rm vsearch-2.9.1-linux-x86_64.tar.gz 
  mv vsearch-2.9.1-linux-x86_64 vsearch
fi

# Add $INSTALL_DIR/vsearch to PATH if not already included
if [[ ":$PATH:" != *":$INSTALL_DIR/search/bin:"* ]]; then
  echo "export PATH=\"$INSTALL_DIR/vsearch/bin:\$PATH\"" >> $SHELL_CONFIG
  echo -e "Added $INSTALL_DIR/vsearch/bin to PATH. $TADA"
fi


# --------------
# Install Trimmomatic
# --------------
if [[ -x $INSTALL_DIR/Trimmomatic-0.38 ]]; then
  echo -e "$GREEN_TICK Trimmomatic already exists at $INSTALL_DIR/fastp"
else
  echo -e "$HOURGLASS Installing Trimmomatic.."
  wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.38.zip
  unzip Trimmomatic-0.38.zip
  # rm Trimmomatic-0.38.zip
fi

# --------------
# Install SPAdes
# --------------
if [[ -x $INSTALL_DIR/SPAdes-$SPADES-Linux ]]; then
  echo -e "$GREEN_TICK SPAdes already exists at $INSTALL_DIR/SPAdes-$SPADES-Linux"
else
  echo -e "$HOURGLASS Getting SPAdes binary.."
  wget https://github.com/ablab/spades/releases/download/v$SPADES/SPAdes-$SPADES-Linux.tar.gz
  tar -xzf SPAdes-$SPADES-Linux.tar.gz
  # rm SPAdes-$SPADES-Linux.tar.gz 
  echo -e "SPAdes is now installed. $TADA"
fi

# Add $INSTALL_DIR/SPAdes to PATH if not already included
if [[ ":$PATH:" != *":$INSTALL_DIR/SPAdes-${SPADES}-Linux/bin:"* ]]; then
  echo "export PATH=\"$INSTALL_DIR/SPAdes-${SPADES}-Linux/bin:\$PATH\"" >> "$SHELL_CONFIG"
  echo -e "Added $INSTALL_DIR/SPAdes-$SPADES-Linux/bin to PATH. $TADA"
fi


# --------------
# Install PANDASEQ
# --------------
if [[ -x $INSTALL_DIR/pandaseq ]]; then
  echo -e "$GREEN_TICK PANDAseq already exists at $INSTALL_DIR/pandaseq"
else
  echo -e "$HOURGLASS Installing PANDAseq..."
  git clone http://github.com/neufeld/pandaseq.git
  cd pandaseq && ./autogen.sh
  ./configure --prefix=$INSTALL_DIR"/PANDAseq"
  make
  make install
  chmod -R +777 /home/tools/PANDAseq/pandaseq/.libs/
  cd ..
  echo -e "PANDAseq was installed $TADA"
fi

# Add $INSTALL_DIR/PANDAseq to PATH if not already included
if [[ ":$PATH:" != *":$INSTALL_DIR/PANDAseq/bin:"* ]]; then
  echo "export PATH=\"$INSTALL_DIR/PANDAseq/bin:\$PATH\"" >> $SHELL_CONFIG
  echo -e "Added $INSTALL_DIR/PANDAseq/bin to PATH. $TADA"
fi


# --------------
# Install Swarm
# --------------

if [[ -x $INSTALL_DIR/swarm ]]; then
    echo -e "$GREEN_TICK Swarm is already installed."
else
    echo -e "$HOURGLASS Installing Swarm..."
    git clone https://github.com/torognes/swarm.git && cd swarm/src/ && make
    echo -e "Swarm was installed! $TADA"
fi

# Add $INSTALL_DIR/swarm to PATH if not already included
if [[ ":$PATH:" != *":$INSTALL_DIR/swarm/bin:"* ]]; then
  echo "export PATH=\"$INSTALL_DIR/swarm/bin:\$PATH\"" >> $SHELL_CONFIG
  echo -e "Added $INSTALL_DIR/swarm/bin to PATH. $TADA"
fi


# -----------------
# Install Blast tools
# -----------------

if [[ -x $INSTALL_DIR/ncbi-blast-2.8.1+ ]]; then
  echo -e "$GREEN_TICK Blast+ tools already available"

else 
  wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.8.1/ncbi-blast-2.8.1+-x64-linux.tar.gz
  tar -zxvf ncbi-blast-2.8.1+-x64-linux.tar.gz 
  # rm ncbi-blast-2.8.1+-x64-linux.tar.gz
fi

# Add $INSTALL_DIR/ncbi-blast-2.8.1+/bin to PATH if not already included
if [[ ":$PATH:" != *":$INSTALL_DIR/ncbi-blast-2.8.1+/bin:"* ]]; then
  echo "export PATH=\"$INSTALL_DIR/ncbi-blast-2.8.1+/bin:\$PATH\"" >> $SHELL_CONFIG
  echo -e "Added $INSTALL_DIR/ncbi-blast-2.8.1+/bin to PATH. $TADA"
fi


# Get jq
if command -v jq >/dev/null 2>&1; then
    echo -e "$GREEN_TICK jq is available"
else
    echo -e "$HOURGLASS Getting jq.."
    wget -O ~/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    chmod +x ~/jq
    echo "export PATH=\"$HOME:$PATH\"" >> $SHELL_CONFIG
    echo -e "Added jq in PATH $TADA"
fi


# -----------------
# Install RDP Classifier
# -----------------
if [[ -x $INSTALL_DIR/rdp_classifier_$RDPCLASSIFIER ]]; then

  echo -e "$GREEN_TICK RDP Classifier is already installed"

else

  echo -e "$HOURGLASS RDP Classifier is being installed.. "
  wget -L -O rdp_classifier_$RDPCLASSIFIER.zip "https://sourceforge.net/projects/rdp-classifier/files/rdp-classifier/rdp_classifier_$RDPCLASSIFIER.zip/download"
  unzip rdp_classifier_$RDPCLASSIFIER.zip
  # rm rdp_classifier_$RDPCLASSIFIER.zip

  echo "export PATH=\"$INSTALL_DIR/rdp_classifier_$RDPCLASSIFIER/:\$PATH\"" >> $SHELL_CONFIG
  echo -e "RDP Classifier has been installed $TADA"

fi


RDP_TRAIN_DIR="$INSTALL_DIR/rdp_classifier_$RDPCLASSIFIER/TRAIN"

if [[ -d "$RDP_TRAIN_DIR" ]] && [ "$(ls -A "$RDP_TRAIN_DIR")" ]; then

  echo -e "$GREEN_TICK PEMA trained databases to be use with RDP Classifier have been already retrieved." 

else

  echo -e "$HOURGLASS Download PEMA trained RDP databases..."

  cd rdp_classifier_$RDPCLASSIFIER/

  # TODO: REPLACE THE URL  
  # wget -O TRAIN.zip -L  <URL>
  unzip TRAIN.zip
  rm TRAIN.zip
  cp $RDP_TRAIN_DIR/midori_1/rRNAClassifier.properties $RDP_TRAIN_DIR/12S_v2.0.0/rRNAClassifier.properties

  echo -e "PEMA trained RDP databases were retrieved $TADA"
fi

# -----------------
# Phylogeny based taxonomy assignment
# -----------------

# -----------------
# PaPaRa
# -----------------
cd $INSTALL_DIR
if [[ -x $INSTALL_DIR/papara_static_x86_64 ]]; then
  echo -e "$GREEN_TICK PaPaRa is already available." 
else
  echo -e "$HOURGLASS Download PaPaRa ..."
  wget https://sco.h-its.org/exelixis/resource/download/software/papara_nt-2.5-static_x86_64.tar.gz
  # The untar returns a papara_static_x86_64 file which is to be used 
  tar -zxvf papara_nt-2.5-static_x86_64.tar.gz 
  rm papara_nt-2.5-static_x86_64.tar.gz
fi

# -----------------
# EPA-ng
# -----------------
cd $INSTALL_DIR
if [[ -x $INSTALL_DIR/epa/ ]]; then

  echo -e "$GREEN_TICK Evolutionary Placement Algorithm (EPA)-ng is already available." 
  echo "export PATH=\"$INSTALL_DIR/epa/bin:\$PATH\"" >> "$SHELL_CONFIG"

else

  echo -e "$HOURGLASS Download Evolutionary Placement Algorithm EPA-ng ..."

  git clone --recursive https://github.com/Pbdas/epa.git

  if [[ "$RUN_ENV" == "local" ]]; then

    if ! sudo apt-get install --yes autotools-dev flex bison automake; then
      echo -e "$RED_CROSS Warning: Evolutionary Placement Algorithm installation failed. \
            PEMA will not be able to run phylogeny-based taxonomy assignmnet. \
            Make sure you are running this as root to get this option. PEMA installation will now continue anyway..."
    fi

  else

    apt-get install --"yes" autotools-dev flex bison automake

  fi

  # Make 
  cd epa
  make
  cd ..

  # Add to PATH
  echo "export PATH=\"$INSTALL_DIR/epa/bin:\$PATH\"" >> "$SHELL_CONFIG"
  echo -e "EPA has been installed $TADA"
fi


# -----------------
# RAxML-ng
# -----------------
if [[ -x $INSTALL_DIR/raxml-ng ]]; then
  echo -e "$GREEN_TICK RAxML-ng already available"
else
  echo -e "$HOURGLASS Download RAxML-ng binary.."
  wget https://github.com/amkozlov/raxml-ng/releases/download/${RAXML}/raxml-ng_v${RAXML}_linux_x86_64.zip
  unzip raxml-ng_v${RAXML}_linux_x86_64.zip 
  rm raxml-ng_v${RAXML}_linux_x86_64.zip
  echo -e "$TADA RAxML-ng binary has been downloaded."
fi

# ====================================
# Step 3: pip 
# ====================================

pip install crest4
pip install ncbi-taxonomist

# Add $INSTALL_DIR to PATH if not already included
if [[ ":$PATH:" != *":$INSTALL_DIR/:"* ]]; then
  echo "export PATH=\"$INSTALL_DIR/:\$PATH\"" >> $SHELL_CONFIG
  echo -e "Added $INSTALL_DIR to PATH. Restart your terminal or run: `source $SHELL_CONFIG` $TADA"
fi

# Move back to the setup directory
cd $SETUP_WD

# Get the directory where this script resides
PEMA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Export it for the current session
export PEMA_HOME="$PEMA_HOME"

# Add to shell config if not already present
if ! grep -q "export PEMA_HOME=" "$SHELL_CONFIG"; then
    echo "export PEMA_HOME=\"$PEMA_HOME\"" >> "$SHELL_CONFIG"
    echo -e "PEMA_HOME added to $SHELL_CONFIG $ROCKET"
else
    echo -e "$GREEN_TICK PEMA_HOME already set in $SHELL_CONFIG"
fi


cd $INSTALL_DIR
if ls *.tar.gz *.zip 1> /dev/null 2>&1; then
  echo "Files found, proceeding with removal."
  rm *.tar.gz *.zip
fi

# Remove duplicate PATH-related lines from your config file
# awk '!seen[$0]++ && ($0 ~ "PATH")' "$SHELL_CONFIG" > "$SHELL_CONFIG.tmp" && mv "$SHELL_CONFIG.tmp" "$SHELL_CONFIG"
cp $SHELL_CONFIG $SHELL_CONFIG.bck
awk '
  # For PATH-modifying lines, skip if seen before
  /^export PATH=/ {
    if (seen[$0]++) next
  }
  # Print all other lines and unique PATH lines
  { print }
' "$SHELL_CONFIG" > "$SHELL_CONFIG.tmp" && mv "$SHELL_CONFIG.tmp" "$SHELL_CONFIG"

# Replace extended value of $HOME with the HOME variable
sed -i "s|$HOME|\$HOME|g" $SHELL_CONFIG

source $SHELL_CONFIG

# Good bye!
echo -e "\n\n $TADA PEMA installation has been completed successfully!\n"

