#!/bin/bash

# Aim:     Keep track of the number of occurrences of each amplicon in each sample
#          Amplicons (rows) and their occurrences in the different samples (columns).
# 
# Usage:   This script is invoked every time the user selects Swarm, as part of the
#          PEMA preprocessing module, in the swarmDereplicate() function
# 
# Authors: Haris Zafeiropoulos, based on blocks of code from F.Mahe
#          You may find the initial script here:
#          https://github.com/torognes/swarm/wiki/


# Access the first argument
preprocess=$1
sample=$2



if [ "$preprocess" == "fastp" ]; then

    base_filename="${sample%%.*}"  # will keep only everything up to the first dot (".")
    linearized_file="../linearizedSequences/$base_filename.linearized.fa"
    dereplicate_file="../dereplicateSamples/$base_filename.derep.fa"
    mapping_file="../dereplicateSamples/$base_filename.derep.mapping"
    merged_file="../mergedSequences/$base_filename.merged.fastq" 

    # Linearize sequences -- from within the mergedSequences folder
    echo -e "\n\n ==> Build linearize sample's $base_filename file .."

    if [ ! -f "$linearized_file" ]; then
        awk 'NR%4==1 || NR%4==2 {sub(/^@/, ">"); print $0}' "$sample" > "$linearized_file"
    else
        echo "$linearized_file already exists. Skipping linearizing."
    fi

    # Continue with dereplication at the sample level
    # cd ../linearizedSequences/

    # Dereplicate sample
    if [ ! -f "$dereplicate_file" ]; then

        echo -e "\n\n ==> Build dereplicate sample's $base_filename file .."

        # Step 0: Build sequence → first header map
        awk '
            /^@/ {header = $0; next}
            /^[ACGTNacgtn]+$/ {print header "\t" $0}
        ' "$merged_file" > headers_and_seqs.tsv

        # Step 1: Generate FASTA output 
        grep -v "^>" "$linearized_file" | grep -E '^[ACGTacgt]+$' | sort | uniq -c | \
        while read -r abundance sequence; do
            hash=$(printf "%s" "$sequence" | sha1sum | awk '{print $1}')
            printf ">%s_%d_%s\n" "$hash" "$abundance" "$sequence"
        done | \
        sort -t "_" -k2,2nr -k1.2,1d | sed 's/_/\n/2' > "$dereplicate_file"

        # Step 2: Build sequence → header map
        awk '
            /^>/ {
                header = substr($0, 2)  # strip leading >
                split(header, parts, "_")
                hash = parts[1]
                next
            }
            {
                print hash "\t" $0
            }
        ' "$dereplicate_file" > hash_to_seq.tsv

        # Step 3: Join with original headers
        # note:  The `join` command combines lines from two files based on 
        # a shared key (common value in a specified field).
        join -t $'\t' -1 2 -2 2   <(LC_ALL=C sort -t $'\t' -k2,2 hash_to_seq.tsv) \
            <(LC_ALL=C sort -t $'\t' -k2,2 headers_and_seqs.tsv) |\
            awk -F'\t' '{for (i=2; i<=NF; i++) printf "%s%s", $i, (i<NF ? FS : ORS)}'\
            > "$mapping_file"
        
        rm headers_and_seqs.tsv hash_to_seq.tsv

    else

        echo "$dereplicate_file already exists. Skipping dereplication at the sample level."

    fi

else 

    # Linearize sequences -- assuming you're two levels deeper
    base_filename="${sample%%.*}"
    output_file="../../linearizedSequences/$base_filename.merged.linearized.fa"
    if [ ! -f "$output_file" ]; then
        awk 'NR==1 {print ; next} {printf /^>/ ? "\n"$0"\n" : $1} END {printf "\n"}' "$sample" > "$output_file"
    else
        echo "$output_file already exists. Skipping linearizing."
    fi

    # Continue with dereplication at the sample level
    cd ../../linearizedSequences/

    # ------------------

    echo -e "\n\n ==> Build dereplicate samples .."

    base_filename="${sample%%.*}"
    output_file="../dereplicateSamples/${base_filename}.merged.linearized.dereplicated.fa"

    if [ ! -f "$output_file" ]; then

        echo ">> Processing $base_filename"
        tmp_file="${sample}.tmp.fa"

        # Clean up headers
        sed 's/ .*_/./g' "$sample" > "$tmp_file"

        # Count and hash valid sequences
        grep -v "^>" "$tmp_file" | grep -E '^[ACGTacgt]+$' | sort | uniq -c | \
        while read -r abundance sequence; do
            hash=$(printf "%s" "$sequence" | sha1sum | awk '{print $1}')
            printf ">%s_%d_%s\n" "$hash" "$abundance" "$sequence"
        done | \
        sort -t "_" -k2,2nr -k1.2,1d | sed 's/_/\n/2' > "$output_file"

        rm "$tmp_file"
    else
        echo ">> Skipping $base_filename, already dereplicated."
    fi
fi


