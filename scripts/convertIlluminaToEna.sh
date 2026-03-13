#!/bin/bash


# Aim:  This script converts Illumina raw data file to the ENA format.
#       All sample files that are going to be used in PEM., they need to be in the ENA format.
#
# Usage:  This script will accomplish this task as long as your paired end raw data files have the following suffixes:
#        forward read:   "_R1_001.fastq.gz"
#        reverese reads: "_R2_001.fastq.gz"
#       The rest of the name is irrelevant. 
#
# Author: Haris Zafeiropoulos



# Keep the directory of the initial data in a variable
directory=${1}
seqPattern=${2}

#!/bin/bash -l

set -euo pipefail

# Input directory and sequence pattern
directory=${1}
seqPattern=${2}

# Resolve absolute path
if [[ "${directory:0:1}" == "/" ]]; then
    directoryPath="$directory"
else
    cd "$directory"
    directoryPath=$(pwd)
fi

directoryPath="${directoryPath%/}"
cd "$directoryPath"

# Create output directory
mkdir -p ena_format

# Create mapping file if not already there
mapping_file="$directoryPath/mapping_files_for_PEMA.tsv"
if [[ ! -f "$mapping_file" ]]; then
    echo -e "initial_label_from_sequencer\tena_format_label\n" > "$mapping_file"
fi

# Set pigz as compressor if available
if command -v pigz &> /dev/null; then
    compressor="pigz"
else
    compressor="gzip"
fi

export compressor

# Function to convert a single pair
convert_pair() {
    r1="$1"
    r2="$2"
    seqPattern="$3"
    directoryPath="$4"
    base=$(basename "$r1")
    sampleId="${base%%_R1_001.fastq.gz}"

    mapping_file="$directoryPath/mapping_files_for_PEMA.tsv"
    tmp_file="$directoryPath/transformations.tmp"
    output_dir="$directoryPath/ena_format"

    # Check if sampleId already in either mapping file or tmp file
    if grep "^${sampleId}" "$mapping_file" 2>/dev/null || \
       grep "^${sampleId}" "$tmp_file" 2>/dev/null; then

        # Try to get the mapped newName from mapping file or tmp file
        newName=$(awk -v sid="$sampleId" '$1 == sid { print $2 }' "$mapping_file" 2>/dev/null || true)
        if [[ -z "$newName" ]]; then
            newName=$(awk -v sid="$sampleId" '$1 == sid { print $2 }' "$tmp_file" 2>/dev/null || true)
        fi

        # If we have a newName, check for existing output files
        if [[ -n "$newName" ]]; then
            found_1=$(find "$output_dir" -name "${newName}_1.fastq.gz" | wc -l)
            found_2=$(find "$output_dir" -name "${newName}_2.fastq.gz" | wc -l)

            if [[ "$found_1" -eq 1 && "$found_2" -eq 1 ]]; then
                echo "[SKIP] $sampleId already processed as $newName"
                return 0
            fi
        fi
    fi

    # Generate unique ERR ID (safe to use random here in parallel context or hash)
    newName=$(printf "ERR%07d" $((1000000 + RANDOM % 8999999)))

    for read in 1 2; do
        if [[ $read == 1 ]]; then file="$r1"; suffix="_1.fastq"; label="/1"; fi
        if [[ $read == 2 ]]; then file="$r2"; suffix="_2.fastq"; label="/2"; fi

        echo ">> Converting sample: $sampleId"

        zcat "$file" | \
        awk -v new="$newName" -v pat="$seqPattern" -v suf="$suffix" -v label="$label" '
            NR % 4 == 1 {
                gsub(/^@.*$/, "@" new ".", $0);
                $0 = $0 NR label
            } 
            { print }
        ' | "$compressor" > "$directoryPath/ena_format/${newName}${suffix}.gz"
    done

    echo -e "$sampleId\t$newName" >> "$directoryPath/transformations.tmp"
}

# Makes the convert_pair function available to child processes, e.g. parallel 
export -f convert_pair

# Pair up files
find . -name "*_R1_001.fastq.gz" | sort | while read -r r1; do
    r2="${r1/_R1_/_R2_}"
    if [[ -f "$r2" ]]; then
        echo "$r1 $r2 $seqPattern $directoryPath"
    fi
done | parallel --colsep ' ' -j 4 convert_pair

# Final mapping file
if [[ -f "$directoryPath/transformations.tmp" ]]; then
    sort -u "$directoryPath/transformations.tmp" >> "$mapping_file"
    rm "$directoryPath/transformations.tmp"
fi
