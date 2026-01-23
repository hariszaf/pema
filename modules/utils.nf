#!/usr/bin/env nextflow


process GUNZIP {

    tag "Unzip .gz files to original format."

    input:
    path gzip_file

    output:
    path "*", emit: gunzipped_file

    script:
    """
    # Get base filename without .gz
    BASENAME="\$(basename ${gzip_file} .gz)"

    # Unzip to the original extension
    gunzip -c ${gzip_file} > "\${BASENAME}"
    """
}

process LINEARIZE {

    tag "Convert a multiline fasta to a single line fasta file."
    // publishDir "${params.outdir}/linearizedSequences", mode: 'copy'

    input:
    path multiline_fasta

    output:
    path "*_linearized.fa", emit: linearized_fasta

    script:
    """
    BASENAME=${multiline_fasta.baseName}
    LINEARIZED_FILE="\${BASENAME}_linearized.fa"

    # LINEARIZE. Build sequence → first header map
    awk 'NR%4==1 || NR%4==2 {sub(/^@/, ">"); print \$0}' "$multiline_fasta" > "\${LINEARIZED_FILE}"
    """
}

process DEREPLICATE {

    tag "Dereplicate linearized fasta file."
    publishDir "${params.outdir}/dereplicate", mode: 'copy'

    input:
    path linearized_fasta

    output:
    path "*_derep.fa", emit: derep_fasta

    script:
    """
    BASENAME=${linearized_fasta.baseName}
    DEREPLICATE_FILE="\${BASENAME}_derep.fa"

    # 1. Remove FASTA headers | 2. Keep only valid DNA sequences (lines containing only A,C,G,T — case insensitive) | 3. Sort sequences so identical ones are adjacent | 4. Count identical sequences
    # 5. For each unique sequence:
    #    - compute SHA1 hash of the sequence
    #    - create a FASTA header encoding: >hash_abundance_sequence
    # 6. Sort dereplicated entries:
    #    - primarily by abundance (descending)
    #    - secondarily by hash (stable ordering)
    # 7. Convert header format to proper FASTA:
    #       >hash_abundance_sequence
    #       becomes
    #       >hash_abundance
    #       sequence

    grep -v "^>" "$linearized_fasta" | grep -E '^[ACGTacgt]+\$' | sort | uniq -c | \
        while read -r abundance sequence; do
            hash=\$(printf "%s" "\$sequence" | sha1sum | awk '{print \$1}')
            printf ">%s_%d_%s\\n" "\$hash" "\$abundance" "\$sequence"
        done | \
        sort -t "_" -k2,2nr -k1.2,1d | sed 's/_/\\n/2' > "\${DEREPLICATE_FILE}"
    """
}

process HASH_MAP {
    
    tag "Generate mapping file from dereplication."
    publishDir "${params.outdir}/dereplicate", mode: 'copy'

    input:
    path derep_fasta
    path nonderep_fasta

    output:
    path "*_derep_map.tsv", emit: derep_map

    script:
    """
    BASENAME=${nonderep_fasta.baseName}
    MAPPING_FILE="\${BASENAME}_derep_map.tsv"

    # Step 1: Build sequence → first header map
    awk '
        /^@/ {header = \$0; next}
        /^[ACGTNacgtn]+\$/ {print header "\t" \$0}
    ' "$nonderep_fasta" > headers_and_seqs.tsv

    # Step 2: Build sequence → header map
    awk '
        /^>/ {
            header = substr(\$0, 2)  # strip leading >
            split(header, parts, "_")
            hash = parts[1]
            next
        }
        {
            print hash "\t" \$0
        }
    ' "$derep_fasta" > hash_to_seq.tsv


    # Step 3: Join with original headers
    # note:  The `join` command combines lines from two files based on a shared key (common value in a specified field).

    join -t \$'\t' -1 2 -2 2   <(LC_ALL=C sort -t \$'\t' -k2,2 hash_to_seq.tsv) \
        <(LC_ALL=C sort -t \$'\t' -k2,2 headers_and_seqs.tsv) |\
        awk -F'\t' '{for (i=2; i<=NF; i++) printf "%s%s", \$i, (i<NF ? FS : ORS)}'\
        > "\${MAPPING_FILE}"
    
    rm headers_and_seqs.tsv hash_to_seq.tsv

    """
}


process CONTINGENCY_TABLE {

    tag "Dereplication at the study level (contingency table)"

    publishDir "${params.outdir}", mode: 'copy'
    // containercontainer "quay.io/biocontainers/gawk:5.1.0--2"   // or replace with a basic of mine


    input:
    path derep_files

    output:
    path "amplicon_contingency_table.tsv", emit: contingency_table

    script:
    """
    awk 'BEGIN {FS = "[>_]"}

        # Parse the sample files
        /^>/ { 
            contingency[\$2][FILENAME] = \$3
            amplicons[\$2] += \$3
            if (FNR == 1) {
                samples[++i] = FILENAME
            }
        }

        END {
            # Create table header
            printf "amplicon"
            s = length(samples)
            for (i = 1; i <= s; i++) {
                printf "\\t%s", samples[i]
            }
            printf "\\t%s\\n", "total"

            # Sort amplicons by decreasing total abundance (use a coprocess)
            command = "LC_ALL=C sort -k1,1nr -k2,2d"
            for (amplicon in amplicons) {
                printf "%d\\t%s\\n", amplicons[amplicon], amplicon |& command
            }
            close(command, "to")
            FS = "\\t"
            while ((command |& getline) > 0) {
                amplicons_sorted[++j] = \$2
            }
            close(command)

            # Print the amplicon occurrences in the different samples
            n = length(amplicons_sorted)
            for (i = 1; i <= n; i++) {
                amplicon = amplicons_sorted[i]
                printf "%s", amplicon
                for (j = 1; j <= s; j++) {
                    printf "\\t%d", contingency[amplicon][samples[j]]
                }
                printf "\\t%d\\n", amplicons[amplicon]
            }}' *_derep.fa > amplicon_contingency_table.tsv
    """
}

process ALL_SAMPLES {

    tag "Combine all dereplicated fasta files into one."

    // publishDir "${params.outdir}", mode: 'copy'
    // container "quay.io/biocontainers/gawk:5.1.0--2"   // or replace with a basic of mine

    input:
    path derep_files

    output:
    path "all_samples.derep.fa", emit: all_derep_fasta

    script:
    """
    cat *_derep.fa | \
    awk 'BEGIN {RS = ">" ; FS = "[_\\n]"}
        {if (NR != 1) {abundances[\$1] += \$2 ; sequences[\$1] = \$3}}
        END {for (amplicon in sequences) {
            print ">" amplicon "_" abundances[amplicon] "_" sequences[amplicon]}}' | \
    sort --temporary-directory=\$(pwd) -t "_" -k2,2nr -k1.2,1d | \
    sed -e 's/\\_/\\n/2' > ../all_samples.fasta
    """
}

process OLIGOTONS_FROM_SWARM {
    tag "Remove oligotons from Swarm findings."

    publishDir "${params.outdir}"
    // container

    input:
    path swarm_stats
    path swarm_swarms
    path asvs_repr_hash
    val threshold
    path pyscript

    output:
    path "asvs.stats", emit: swarm_stats
    path "asvs.swarms", emit: swarm_seeds
    path "asvs_representatives_hash.fa", emit: asvs_hash

    script:
    """
    python $pyscript $swarm_stats $swarm_swarms $asvs_repr_hash $threshold
    """
}


process ASVS_CONTINGENCY_TABLE {

    tag "Build contingency table using the ASVs returned"

    publishDir "${params.outdir}", mode: 'copy'
    // container ""

    // Usage:
    // nextflow run modules/utils.nf --asvs_stats testingNfModules/swarm/asvs.stats 
    // --asvs_swarms testingNfModules/swarm/asvs.swarms 
    // --contingency_table work/b9/7f599549bf8533ae56bab818bbf702/amplicon_contingency_table.tsv 
    // --script pema/scripts/createASVsContingencyTable.sh  
    // --asvs_repr_hash testingNfModules/swarm/asvs_representatives_hash.fa 

    input:
    path asvs_stats
    path asvs_swarms
    path asvs_repr_hash
    path contingency_table
    path build_sh

    output:
    path "asvs_contingency_hash.tsv", emit: asvs_contingency_hash
    path "asvs_contingency_table.tsv", emit: asvs_contingency_table
    path "asvs_representatives.fa", emit: asvs_to_tax_assign

    script:
    """
    bash $build_sh
    sed -i 's/_[0-9]*//' asvs_representatives.fa
    """
}



// -----------------------   TESTING MODULES ------------------

workflow {

    // def underep_ch = Channel.fromPath("${params.input_dir}/*")
    // // def dereplicated = Channel.fromPath("${params.input_dir}/*_derep.fa").collect()

    // // underep_ch.view()

    // def to_dererp = GUNZIP(underep_ch) \

    // // to_dererp.view()

    // // DEREPLICATE_IN_ONE_STEP(to_dererp)

    // def linearized   = LINEARIZE(to_dererp)
    // def dereplicated = DEREPLICATE(linearized)
    // def derep_maps   = HASH_MAP(dereplicated, to_dererp)

    // def contingency_table = CONTINGENCY_TABLE(dereplicated.collect())
    // def all_samples       = ALL_SAMPLES(dereplicated.collect())


    // ----------   NOW WE CLUSTER AND THEN MOVE ON TO THE NEXT   ----- 

    // If remove_oligotons, then this is now
    def asvs_stats                 = Channel.fromPath("${params.asvs_stats}")
    def asvs_swarms                = Channel.fromPath("${params.asvs_swarms}")
    def asvs_repr_has              = Channel.fromPath("${params.asvs_repr_hash}")

    def threshold    = params.threshold
    def oligo_script = Channel.fromPath("${params.oligo_script}")

    def amplicon_contingency_table = Channel.fromPath("${params.contingency_table}")
    def asv_cont_script            = Channel.fromPath("${params.asv_cont_script}")

    def tas = OLIGOTONS_FROM_SWARM(
        asvs_stats, asvs_swarms, asvs_repr_has, threshold, oligo_script
    )

    // Build ASVS contingency table (after removing oligotons if asked)

    def asvs_contingency_table = ASVS_CONTINGENCY_TABLE(
        tas.swarm_stats, tas.swarm_seeds, tas.asvs_hash, amplicon_contingency_table, asv_cont_script
        // asvs_stats, asvs_swarms, asvs_repr_has, amplicon_contingency_table, asv_cont_script
        )









}
