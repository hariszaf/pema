#!/usr/bin/env nextflow

process LINEARIZE {

    tag "Convert a multiline fasta to a single line fasta file."

    publishDir "${params.outdir}/linearized", mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

    input:
    path multiline_fasta

    output:
    path "*.fa", emit: linearized_fasta

    script:
    """
    BASENAME=${multiline_fasta.baseName}
    LINEARIZED_FILE="\${BASENAME}.fa"

    # LINEARIZE. Build sequence → first header map
    awk '
        /^>/ {
            if (seq) print seq; print; seq=""; next
        } {seq=seq \$0} END {if (seq) print seq}
    ' "$multiline_fasta" >> "\${LINEARIZED_FILE}"
    """
}

process CONCATENATE_FASTA {

    tag "Combine all dereplicated fasta files into one."

    publishDir "${params.outdir}", mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

    input:
    path derep_files

    output:
    path "all_samples.fa", emit: all_samples

    script:
    """
    cat ${derep_files} | \
    awk 'BEGIN {RS = ">" ; FS = "[_\\n]"}
        {if (NR != 1) {abundances[\$1] += \$2 ; sequences[\$1] = \$3}}
        END {for (amplicon in sequences) {
            print ">" amplicon "_" abundances[amplicon] "_" sequences[amplicon]}}' | \
    sort --temporary-directory=\$(pwd) -t "_" -k2,2nr -k1.2,1d | \
    sed -e 's/\\_/\\n/2' > all_samples.fa
    """
}

process HASH_DEREP_FASTA {

    tag "Dereplicate linearized fasta file."

    publishDir "${params.outdir}/hashing", mode: 'copy'

    container "hariszaf/pema-nf:0.0.1"

    input:
    path linearized_fasta

    output:
    path "hash*.fa", emit: hash_fasta

    script:
    """
    BASENAME=${linearized_fasta.baseName}
    HASH_FILE="hash_\${BASENAME}.fa"

    awk '
        /^>/ {
            split(\$0, a, ";size=")
            abundance = a[2]
            next
        }
        {print abundance "\\t" \$0}
    ' "$linearized_fasta" | \
    while IFS=\$'\\t' read -r abundance sequence; do
        hash=\$(printf "%s" "\$sequence" | sha1sum | awk '{print \$1}')
        printf ">%s_%d\\n%s\\n" "\$hash" "\$abundance" "\$sequence"
    done > "\${HASH_FILE}"
    """
}

process HASH_MAP {
    
    tag "Generate mapping file from dereplication."
    publishDir "${params.outdir}/hashing", mode: 'copy'

    input:
    path derep_fasta
    path nonderep_fasta

    output:
    path "hash_map_*", emit: hash_map

    script:
    """
    BASENAME=${nonderep_fasta.baseName}
    MAPPING_FILE="hash_map_\${BASENAME}.tsv"

    # Step 1: Build sequence → first header map (for fasta files)
    awk '
        /^>/ {
            # Extract ID before ";size="
            split(\$0, a, ";size=")
            header = substr(a[1], 2)   # remove ">" from start
            abundance = a[2]
            next
        }
        {
            # sequence line
            print header "\t" abundance "\t" \$0
        }
    ' "$nonderep_fasta" > headers_and_seqs.tsv

    # Step 2: Build sequence → header map
    awk '
        /^>/ {
            header = substr(\$0, 2)  
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

    join -t \$'\t' -1 2 -2 2 <(LC_ALL=C sort -t \$'\t' -k2,2 hash_to_seq.tsv) \
        <(LC_ALL=C sort -t \$'\t' -k2,2 headers_and_seqs.tsv) |\
        awk -F'\t' '{for (i=2; i<=NF; i++) printf "%s%s", \$i, (i<NF ? FS : ORS)}'\
        > "\${MAPPING_FILE}"
    
    #rm headers_and_seqs.tsv hash_to_seq.tsv

    """
}


// -----------------------   TESTING MODULES ------------------

workflow {

    def underep_ch = Channel.fromPath("${params.input_dir}/*")

    def to_dererp = GUNZIP(underep_ch) \


    // DEREPLICATE_IN_ONE_STEP(to_dererp)

    def linearized   = LINEARIZE(to_dererp)
    def dereplicated = DEREPLICATE(linearized)
    def derep_maps   = HASH_MAP(dereplicated, to_dererp)

    def contingency_table = CONTINGENCY_TABLE(dereplicated.collect())
    def all_samples       = CONCATENATE_FASTA(dereplicated.collect())


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
