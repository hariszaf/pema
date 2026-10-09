#!/bin/bash

# Aim:  This sanity check gives an overview of the PEMA Nextflow pipeline:
#       what works well and what does not. Can be used to test whether
#       a new feature causes any issues or not.
#       Should be always run before a new version is to be released.
#
#       Each test runs pema.nf (fastp, Swarm, crest4) on the sanity dataset of one marker gene,
#       with a parameters file generated from config_files/pema.yaml.
#
# Usage: ./run_sanity_check.sh [options] [marker ...]
#
#   marker              16S 18S 12S COI ITS (default: all of them)
#   --ncbi              also map the taxonomies to NCBI Taxonomy (set NCBI_API_KEY to go faster)
#   --profile <name>    Nextflow profile(s), e.g. singularity (default: docker)
#   --resume            resume the previous runs
#
# Environment variables:
#   CREST_DBS           folder for the CREST databases, so they are downloaded only once
#                       (default: ~/.crest4)
#   ITS_CREST_DB        name of a custom UNITE database folder under CREST_DBS, needed for ITS
#                       (crest4 has no built-in ITS database); ITS is skipped if not set
#
# Author: Haris Zafeiropoulos

set -uo pipefail

SANITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PEMA_DIR="$(dirname "${SANITY_DIR}")"

DATA_URL="https://drive.usercontent.google.com/download?id=1NoZfw3IOWksc1AnSr46HkOMoFautaiTO&export=download&confirm=t"
DATA_TARBALL="${SANITY_DIR}/sanity_data.tar.gz"

CREST_DBS="${CREST_DBS:-${HOME}/.crest4}"
ITS_CREST_DB="${ITS_CREST_DB:-}"

# marker -> folder with the reads (inside sanity_check/<marker>/) and crest4 database
declare -A READS=( [16S]=mydata16s [18S]=mydata18s [12S]=mydata12s [COI]=mydataCOI [ITS]=mydataITS )
declare -A CREST_DB=( [16S]=silvamod138pr2 [18S]=silvamod138pr2 [12S]=mitofish [COI]=midori253darn [ITS]="${ITS_CREST_DB}" )
ALL_MARKERS=(16S 18S 12S COI ITS)


# ------------                 OPTIONS               -------------------

NCBI=false
PROFILE=docker
RESUME=""
MARKERS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ncbi)    NCBI=true ;;
        --profile) PROFILE="$2"; shift ;;
        --resume)  RESUME="-resume" ;;
        -h|--help) sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        16S|18S|12S|COI|ITS) MARKERS+=("$1") ;;
        *) echo "Unknown option or marker: $1 (see --help)"; exit 1 ;;
    esac
    shift
done
[[ ${#MARKERS[@]} -eq 0 ]] && MARKERS=("${ALL_MARKERS[@]}")

command -v nextflow >/dev/null || { echo "nextflow is not installed or not in PATH."; exit 1; }


# ------------                 DATA                  -------------------

# Download and extract the sanity dataset if any of the read folders is missing
missing_data=false
for marker in "${MARKERS[@]}"; do
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
# reads, output folder and CREST database
make_params() {
    local marker=$1 outdir=$2 params=$3
    sed -e "s#^raw_reads:.*#raw_reads: ${SANITY_DIR}/${marker}/${READS[$marker]}#" \
        -e "s#^outdir:.*#outdir: ${outdir}#" \
        -e "s#^  database:.*#  database: ${CREST_DB[$marker]}#" \
        -e "s#^  mount_crest_dbs:.*#  mount_crest_dbs: ${CREST_DBS}#" \
        -e "s#^  get_ncbi_taxonomy:.*#  get_ncbi_taxonomy: ${NCBI}#" \
        -e "s#^  ncbi_api_key:.*#  ncbi_api_key:#" \
        "${PEMA_DIR}/config_files/pema.yaml" > "${params}"
}

# Check that a test produced a final table with at least one ASV
check_outputs() {
    local outdir=$1
    local table="${outdir}/crest_assignment/tax_assigned_table.tsv"
    [[ "${NCBI}" == true ]] && table="${outdir}/ncbi_taxonomy/tax_assigned_with_ncbi.tsv"

    if [[ ! -s "${table}" ]]; then
        echo "missing ${table#"${SANITY_DIR}/"}"
        return 1
    fi
    local asvs=$(( $(wc -l < "${table}") - 1 ))
    if [[ ${asvs} -lt 1 ]]; then
        echo "no ASVs in ${table#"${SANITY_DIR}/"}"
        return 1
    fi
    local assigned
    assigned=$(awk -F'\t' '
        NR == 1 { for (i = 1; i <= NF; i++) if ($i == "Taxonomy") col = i; next }
        $col != "" && $col != "No hits"' "${table}" | wc -l)
    echo "${asvs} ASVs, ${assigned} with a taxonomy"
}

declare -A STATUS DETAILS MINUTES
failed=0

for marker in "${MARKERS[@]}"; do

    name="TEST_${marker}_FASTP_SWARM_CREST"
    outdir="${SANITY_DIR}/${marker}/${name}"
    params="${SANITY_DIR}/${marker}/${name}.yaml"
    log="${SANITY_DIR}/${marker}/${name}.log"

    if [[ -z "${CREST_DB[$marker]}" ]]; then
        STATUS[$marker]=SKIPPED
        DETAILS[$marker]="crest4 has no built-in ITS database; set ITS_CREST_DB to a UNITE folder in ${CREST_DBS}"
        echo "Skipping ${marker}: ${DETAILS[$marker]}"
        continue
    fi

    echo
    echo "PEMA for ${marker} using fastp, Swarm and crest4 (${CREST_DB[$marker]}) is about to start"
    [[ "${NCBI}" == true ]] && echo "NCBI Taxonomy IDs will be assigned in the end, on the taxonomies returned."

    [[ -z "${RESUME}" ]] && rm -rf "${outdir}"
    make_params "${marker}" "${outdir}" "${params}"

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

    MINUTES[$marker]=$(( ($(date +%s) - start_time) / 60 ))

    if [[ ${exit_code} -ne 0 ]]; then
        STATUS[$marker]=FAILED
        DETAILS[$marker]="nextflow exited with ${exit_code}; see ${log#"${SANITY_DIR}/"}"
        failed=$((failed + 1))
    elif DETAILS[$marker]=$(check_outputs "${outdir}"); then
        STATUS[$marker]=OK
    else
        STATUS[$marker]=FAILED
        failed=$((failed + 1))
    fi

    echo "PEMA for ${marker}: ${STATUS[$marker]} in ${MINUTES[$marker]} minutes (${DETAILS[$marker]})"
done


# ------------                 SUMMARY               -------------------

echo
echo "Sanity check summary"
echo "--------------------"
for marker in "${MARKERS[@]}"; do
    printf "%-4s %-8s %6s  %s\n" "${marker}" "${STATUS[$marker]}" \
        "${MINUTES[$marker]:+${MINUTES[$marker]} min}" "${DETAILS[$marker]}"
done

exit $(( failed > 0 ))
