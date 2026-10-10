#!/bin/bash

# Aim:  This sanity check gives an overview of the PEMA Nextflow pipeline:
#       what works well and what does not. Can be used to test whether
#       a new feature causes any issues or not.
#       Should be always run before a new version is to be released.
#
#       Each test runs pema.nf (fastp, Swarm or VSEARCH, then crest4 or RDPClassifier) on the
#       sanity dataset of one marker gene, with a parameters file generated from config_files/pema.yaml.
#
# Usage: ./run_sanity_check.sh [options] [test ...]
#
#   test                16S 18S 12S COI ITS (Swarm, crest4), 16S-vsearch 18S-vsearch (VSEARCH, crest4),
#                       12S-rdp COI-rdp (Swarm, RDPClassifier),
#                       COI-rdp-custom (Swarm, RDPClassifier trained on custom_rdp/custom_ref_db),
#                       COI-crest-custom (Swarm, crest4 database built from custom_crest/custom_ref_db)
#                       (default: all of them)
#   --ncbi              also map the taxonomies to NCBI Taxonomy (set NCBI_API_KEY to go faster)
#   --profile <name>    Nextflow profile(s), e.g. singularity (default: docker)
#   --resume            resume the previous runs
#
# Environment variables:
#   CREST_DBS           folder for the CREST databases, so they are downloaded only once
#                       (default: ~/.crest4)
#   ITS_CREST_DB        name of a custom UNITE database folder under CREST_DBS, needed for ITS
#                       (crest4 has no built-in ITS database); ITS is skipped if not set
#   RDP_DBS             folder with the RDP-trained databases; the RDP tests are skipped without it
#   RDP_12S_DB          RDP database for 12S-rdp (default: 12S_v2.0.0)
#   RDP_COI_DB          RDP database for COI-rdp; COI-rdp is skipped if not set
#
# Author: Haris Zafeiropoulos

set -uo pipefail

SANITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PEMA_DIR="$(dirname "${SANITY_DIR}")"

DATA_URL="https://drive.usercontent.google.com/download?id=1NoZfw3IOWksc1AnSr46HkOMoFautaiTO&export=download&confirm=t"
DATA_TARBALL="${SANITY_DIR}/sanity_data.tar.gz"

CREST_DBS="${CREST_DBS:-${HOME}/.crest4}"
ITS_CREST_DB="${ITS_CREST_DB:-}"
RDP_DBS="${RDP_DBS:-}"
RDP_12S_DB="${RDP_12S_DB:-12S_v2.0.0}"
RDP_COI_DB="${RDP_COI_DB:-}"

# marker -> folder with the reads (inside sanity_check/<marker>/)
declare -A READS=( [16S]=mydata16s [18S]=mydata18s [12S]=mydata12s [COI]=mydataCOI [ITS]=mydataITS )

# test -> marker, clustering algorithm, classifier and database
declare -A MARKER=( [16S]=16S [18S]=18S [12S]=12S [COI]=COI [ITS]=ITS
                    [16S-vsearch]=16S [18S-vsearch]=18S [12S-rdp]=12S [COI-rdp]=COI [COI-rdp-custom]=COI
                    [COI-crest-custom]=COI )
declare -A CLUSTERING=( [16S]=swarm [18S]=swarm [12S]=swarm [COI]=swarm [ITS]=swarm
                        [16S-vsearch]=vsearch [18S-vsearch]=vsearch [12S-rdp]=swarm [COI-rdp]=swarm
                        [COI-rdp-custom]=swarm [COI-crest-custom]=swarm )
declare -A CLASSIFIER=( [16S]=crest [18S]=crest [12S]=crest [COI]=crest [ITS]=crest
                        [16S-vsearch]=crest [18S-vsearch]=crest [12S-rdp]=rdp [COI-rdp]=rdp
                        [COI-rdp-custom]=rdp [COI-crest-custom]=crest )
declare -A DATABASE=( [16S]=silvamod138pr2 [18S]=silvamod138pr2 [12S]=mitofish [COI]=midori253darn
                      [ITS]="${ITS_CREST_DB}" [16S-vsearch]=silvamod138pr2 [18S-vsearch]=silvamod138pr2
                      [12S-rdp]="${RDP_12S_DB}" [COI-rdp]="${RDP_COI_DB}" [COI-rdp-custom]=amvrakikos_coi
                      [COI-crest-custom]=amvrakikos_crest )
ALL_TESTS=(16S 18S 12S COI ITS 16S-vsearch 18S-vsearch 12S-rdp COI-rdp COI-rdp-custom COI-crest-custom)

# The custom RDP database of COI-rdp-custom: trained from these files, into this folder
CUSTOM_RDP_DIR="${SANITY_DIR}/custom_rdp"
CUSTOM_RDP_TAXONOMY="${CUSTOM_RDP_DIR}/custom_ref_db/amvrakikos_species_2019_taxonomy_file.tsv"
CUSTOM_RDP_SEQUENCES="${CUSTOM_RDP_DIR}/custom_ref_db/amvrakikos_species_2019_sequences_file.fasta"

# The custom crest4 database of COI-crest-custom: built from these files, into this folder
CUSTOM_CREST_DIR="${SANITY_DIR}/custom_crest"
CUSTOM_CREST_TAXONOMY="${CUSTOM_CREST_DIR}/custom_ref_db/amvrakikos_species_2019_taxonomy.nds"
CUSTOM_CREST_SEQUENCES="${CUSTOM_CREST_DIR}/custom_ref_db/amvrakikos_species_2019_sequences.fasta"


# ------------                 OPTIONS               -------------------

NCBI=false
PROFILE=docker
RESUME=""
TESTS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ncbi)    NCBI=true ;;
        --profile) PROFILE="$2"; shift ;;
        --resume)  RESUME="-resume" ;;
        -h|--help) sed -n '3,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        16S|18S|12S|COI|ITS|16S-vsearch|18S-vsearch|12S-rdp|COI-rdp|COI-rdp-custom|COI-crest-custom) TESTS+=("$1") ;;
        *) echo "Unknown option or test: $1 (see --help)"; exit 1 ;;
    esac
    shift
done
[[ ${#TESTS[@]} -eq 0 ]] && TESTS=("${ALL_TESTS[@]}")

command -v nextflow >/dev/null || { echo "nextflow is not installed or not in PATH."; exit 1; }


# ------------                 DATA                  -------------------

# Download and extract the sanity dataset if any of the read folders is missing
missing_data=false
for test in "${TESTS[@]}"; do
    marker=${MARKER[$test]}
    [[ -d "${SANITY_DIR}/${marker}/${READS[$marker]}" ]] || missing_data=true
done

if [[ "${missing_data}" == true ]]; then
    if [[ ! -s "${DATA_TARBALL}" ]]; then
        echo "Downloading the sanity dataset (~280 MB)..."
        curl -fL --retry 3 -o "${DATA_TARBALL}" "${DATA_URL}" || {
            echo "Download failed. Get it manually from"
            echo "  https://drive.google.com/file/d/1NoZfw3IOWksc1AnSr46HkOMoFautaiTO/view"
            echo "and save it as ${DATA_TARBALL}"
            rm -f "${DATA_TARBALL}"
            exit 1
        }
    fi
    echo "Extracting the sanity dataset..."
    tar -xzf "${DATA_TARBALL}" -C "${SANITY_DIR}" || { echo "Could not extract ${DATA_TARBALL}"; exit 1; }
fi

mkdir -p "${CREST_DBS}"


# ------------                 TESTS                 -------------------

# Write the parameters file of a test: config_files/pema.yaml with the test's
# reads, output folder, classifier and database
make_params() {
    local test=$1 outdir=$2 params=$3
    local marker=${MARKER[$test]}
    local rdp_dbs="${RDP_DBS}" crest_dbs="${CREST_DBS}" taxonomy="" sequences=""
    local rdp_memory="" train_memory=""
    if [[ "${test}" == COI-rdp-custom ]]; then
        rdp_dbs="${CUSTOM_RDP_DIR}/trained_dbs" taxonomy="${CUSTOM_RDP_TAXONOMY}" sequences="${CUSTOM_RDP_SEQUENCES}"
        # A small database: the default memory (16 GB to train) is more than e.g. GitHub's runners have
        rdp_memory="4 GB" train_memory="4 GB"
    elif [[ "${test}" == COI-crest-custom ]]; then
        crest_dbs="${CUSTOM_CREST_DIR}/trained_dbs" taxonomy="${CUSTOM_CREST_TAXONOMY}" sequences="${CUSTOM_CREST_SEQUENCES}"
    fi
    sed -e "s#^raw_reads:.*#raw_reads: ${SANITY_DIR}/${marker}/${READS[$marker]}#" \
        -e "s#^marker_gene:.*#marker_gene: ${marker}#" \
        -e "s#^outdir:.*#outdir: ${outdir}#" \
        -e "s#^clustering_algo:.*#clustering_algo: ${CLUSTERING[$test]}#" \
        -e "s#^classifier:.*#classifier: ${CLASSIFIER[$test]}#" \
        -e "s#^  database:.*#  database: ${DATABASE[$test]}#" \
        -e "s#^  mount_crest_dbs:.*#  mount_crest_dbs: ${crest_dbs}#" \
        -e "s#^  databases_dir:.*#  databases_dir: ${rdp_dbs}#" \
        -e "s#^    taxonomy:.*#    taxonomy: ${taxonomy}#" \
        -e "s#^    sequences:.*#    sequences: ${sequences}#" \
        -e "${rdp_memory:+s#^  memory:.*#  memory: ${rdp_memory}#}" \
        -e "${train_memory:+s#^    memory:.*#    memory: ${train_memory}#}" \
        -e "s#^  get_ncbi_taxonomy:.*#  get_ncbi_taxonomy: ${NCBI}#" \
        -e "s#^  ncbi_api_key:.*#  ncbi_api_key:#" \
        "${PEMA_DIR}/config_files/pema.yaml" > "${params}"
}

# Check that a test produced a final table with at least one ASV/OTU
check_outputs() {
    local outdir=$1 classifier=$2
    local table="${outdir}/${classifier}_assignment/tax_assigned_table.tsv"
    [[ "${NCBI}" == true ]] && table="${outdir}/ncbi_taxonomy/tax_assigned_with_ncbi.tsv"

    if [[ ! -s "${table}" ]]; then
        echo "missing ${table#"${SANITY_DIR}/"}"
        return 1
    fi
    local clusters=$(( $(wc -l < "${table}") - 1 ))
    if [[ ${clusters} -lt 1 ]]; then
        echo "no ASVs/OTUs in ${table#"${SANITY_DIR}/"}"
        return 1
    fi
    local assigned
    assigned=$(awk -F'\t' '
        NR == 1 { for (i = 1; i <= NF; i++) if ($i == "Taxonomy") col = i; next }
        $col != "" && $col != "No hits" && $col != "Unassigned"' "${table}" | wc -l)
    echo "${clusters} ASVs/OTUs, ${assigned} with a taxonomy"
}

declare -A STATUS DETAILS MINUTES
failed=0

# Why a test cannot run, if it cannot
skip_reason() {
    local test=$1
    if [[ "${test}" == ITS && -z "${DATABASE[$test]}" ]]; then
        echo "crest4 has no built-in ITS database; set ITS_CREST_DB to a UNITE folder in ${CREST_DBS}"
    elif [[ "${test}" == COI-rdp-custom || "${test}" == COI-crest-custom ]]; then
        :   # builds its own database
    elif [[ "${CLASSIFIER[$test]}" == rdp && -z "${RDP_DBS}" ]]; then
        echo "set RDP_DBS to the folder with the RDP-trained databases"
    elif [[ "${CLASSIFIER[$test]}" == rdp && -z "${DATABASE[$test]}" ]]; then
        echo "set RDP_COI_DB to the name of an RDP-trained COI database in ${RDP_DBS}"
    elif [[ "${CLASSIFIER[$test]}" == rdp && ! -d "${RDP_DBS}/${DATABASE[$test]}" ]]; then
        echo "RDP database ${RDP_DBS}/${DATABASE[$test]} not found"
    fi
}

for test in "${TESTS[@]}"; do

    marker=${MARKER[$test]}
    classifier=${CLASSIFIER[$test]}
    name="TEST_${marker}_FASTP_${CLUSTERING[$test]^^}_${classifier^^}"
    [[ "${test}" == *-custom ]] && name="${name}_CUSTOM"
    outdir="${SANITY_DIR}/${marker}/${name}"
    params="${SANITY_DIR}/${marker}/${name}.yaml"
    log="${SANITY_DIR}/${marker}/${name}.log"

    reason=$(skip_reason "${test}")
    if [[ -n "${reason}" ]]; then
        STATUS[$test]=SKIPPED
        DETAILS[$test]="${reason}"
        echo "Skipping ${test}: ${reason}"
        continue
    fi

    echo
    echo "PEMA for ${marker} using fastp, ${CLUSTERING[$test]} and ${classifier} (${DATABASE[$test]}) is about to start"
    [[ "${NCBI}" == true ]] && echo "NCBI Taxonomy IDs will be assigned in the end, on the taxonomies returned."

    [[ -z "${RESUME}" ]] && rm -rf "${outdir}"
    make_params "${test}" "${outdir}" "${params}"

    start_time=$(date +%s)

    # Each test runs in its own folder, so the runs (and -resume) do not interfere
    (
        cd "${SANITY_DIR}/${marker}" && \
        nextflow run "${PEMA_DIR}/pema.nf" \
            --params-file "${params}" \
            -profile "${PROFILE}" \
            -work-dir "${SANITY_DIR}/${marker}/work" \
            ${RESUME}
    ) > "${log}" 2>&1
    exit_code=$?

    MINUTES[$test]=$(( ($(date +%s) - start_time) / 60 ))

    if [[ ${exit_code} -ne 0 ]]; then
        STATUS[$test]=FAILED
        DETAILS[$test]="nextflow exited with ${exit_code}; see ${log#"${SANITY_DIR}/"}"
        failed=$((failed + 1))
    elif DETAILS[$test]=$(check_outputs "${outdir}" "${classifier}"); then
        STATUS[$test]=OK
    else
        STATUS[$test]=FAILED
        failed=$((failed + 1))
    fi

    echo "PEMA for ${test}: ${STATUS[$test]} in ${MINUTES[$test]} minutes (${DETAILS[$test]})"
done


# ------------                 SUMMARY               -------------------

echo
echo "Sanity check summary"
echo "--------------------"
for test in "${TESTS[@]}"; do
    printf "%-12s %-8s %6s  %s\n" "${test}" "${STATUS[$test]}" \
        "${MINUTES[$test]:+${MINUTES[$test]} min}" "${DETAILS[$test]}"
done

exit $(( failed > 0 ))
